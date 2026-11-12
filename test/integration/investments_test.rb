require "test_helper"

class InvestmentsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "julien@example.test", password: "long-password-123")
    @headers = { "Authorization" => "Bearer #{ApiSession.issue!(@user)}" }
    @portfolio = @user.portfolios.create!(name: "Investments")
    @asset = Asset.create!(isin: "FR0000000001", name: "Demo ETF", asset_type: "etf")
    @time = 2.days.ago.change(usec: 0)
  end

  test "registration login logout and invalid credentials" do
    post "/api/v1/users", params: { user: { email: " NEW@example.test ", password: "long-password-123" } }, as: :json
    assert_response :created
    assert_equal "new@example.test", response.parsed_body["email"]
    post "/api/v1/session", params: { session: { email: "new@example.test", password: "wrong" } }, as: :json
    assert_response :unauthorized
    post "/api/v1/session", params: { session: { email: "new@example.test", password: "long-password-123" } }, as: :json
    assert_response :created
    token = response.parsed_body.fetch("token")
    assert_not ApiSession.exists?(token_digest: token)
    headers = { "Authorization" => "Bearer #{token}" }
    delete "/api/v1/session", headers: headers
    assert_response :no_content
    get "/api/v1/portfolios", headers: headers
    assert_response :unauthorized
  end

  test "authentication expiry and ownership" do
    get "/api/v1/portfolios"
    assert_response :unauthorized
    other = User.create!(email: "other@example.test", password: "long-password-123")
    foreign = other.portfolios.create!(name: "Private")
    %w[positions valuation trades].each do |endpoint|
      get "/api/v1/portfolios/#{foreign.id}/#{endpoint}", headers: @headers
      assert_response :not_found
    end
    post "/api/v1/portfolios/#{foreign.id}/trades", params: { trade: trade_params }, headers: @headers, as: :json
    assert_response :not_found
    @user.api_sessions.update_all(expires_at: 1.minute.ago)
    get "/api/v1/portfolios", headers: @headers
    assert_response :unauthorized
  end

  test "create list and validate portfolios" do
    post "/api/v1/portfolios", params: { portfolio: { name: "Savings", user_id: 0 } }, headers: @headers, as: :json
    assert_response :created
    assert_equal @user.id, Portfolio.last.user_id
    post "/api/v1/portfolios", params: { portfolio: { name: "", currency: "USD" } }, headers: @headers, as: :json
    assert_response :unprocessable_entity
    get "/api/v1/portfolios", headers: @headers
    assert_equal 2, response.parsed_body.size
    get "/api/v1/portfolios?offset=wrong", headers: @headers
    assert_response :bad_request
  end

  test "buy sell positions and overselling" do
    submit_trade
    assert_response :created
    submit_trade(side: "sell", quantity: "3", executed_at: @time + 1.hour)
    assert_response :created
    get "/api/v1/portfolios/#{@portfolio.id}/positions", headers: @headers
    assert_equal "7.0", response.parsed_body.first["quantity"]
    assert_no_difference "Trade.count" do
      submit_trade(side: "sell", quantity: "8", executed_at: @time + 2.hours)
    end
    assert_response :unprocessable_entity
    get "/api/v1/portfolios/#{@portfolio.id}/trades", headers: @headers
    assert_equal 2, response.parsed_body.size
  end

  test "reject backdated sale breaking future position" do
    submit_trade
    submit_trade(side: "sell", quantity: "10", executed_at: @time + 2.hours)
    submit_trade(side: "sell", quantity: "1", executed_at: @time + 1.hour)
    assert_response :unprocessable_entity
    assert_equal 2, @portfolio.trades.count
  end

  test "reject invalid decimal values dates and assets" do
    [ { quantity: "0" }, { quantity: "-1" }, { quantity: "NaN" },
      { quantity: "1.000000001" }, { unit_price: "Infinity" }, { unit_price: "abc" },
      { side: "other" }, { executed_at: "invalid" }, { executed_at: 1.day.from_now }, { asset_id: 0 } ].each do |changes|
      assert_no_difference "Trade.count" do
        submit_trade(**changes)
      end
      assert_response :unprocessable_entity
    end
  end

  test "historical valuation uses latest prior price and reports missing prices" do
    submit_trade
    get "/api/v1/portfolios/#{@portfolio.id}/valuation", headers: @headers
    assert_nil response.parsed_body["value"]
    assert_equal [ @asset.id ], response.parsed_body["missing_asset_ids"]
    @asset.prices.create!(value: "12.12345678", quoted_on: @time.to_date)
    @asset.prices.create!(value: "20", quoted_on: Date.current)
    get "/api/v1/portfolios/#{@portfolio.id}/valuation", params: { date: @time.to_date.iso8601 }, headers: @headers
    assert_equal "121.23", response.parsed_body["value"]
    get "/api/v1/portfolios/#{@portfolio.id}/valuation", headers: @headers
    assert_equal "200.0", response.parsed_body["value"]
    get "/api/v1/portfolios/#{@portfolio.id}/valuation", params: { date: "invalid" }, headers: @headers
    assert_response :bad_request
    get "/api/v1/portfolios/#{@portfolio.id}/valuation", params: { date: Date.tomorrow.iso8601 }, headers: @headers
    assert_response :bad_request
  end

  test "catalog prices and missing payload" do
    get "/api/v1/assets", headers: @headers
    assert_equal @asset.isin, response.parsed_body.first["isin"]
    get "/api/v1/assets/#{@asset.id}/prices", headers: @headers
    assert_equal [], response.parsed_body
    post "/api/v1/portfolios", params: {}, headers: @headers, as: :json
    assert_response :bad_request
  end

  private

  def trade_params
    { asset_id: @asset.id, side: "buy", quantity: "10", unit_price: "10.50", executed_at: @time.iso8601 }
  end

  def submit_trade(**changes)
    post "/api/v1/portfolios/#{@portfolio.id}/trades", params: { trade: trade_params.merge(changes) }, headers: @headers, as: :json
  end
end
