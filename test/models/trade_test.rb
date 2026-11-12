require "test_helper"

class TradeTest < ActiveSupport::TestCase
  test "trade history is immutable" do
    user = User.create!(email: "model@example.test", password: "long-password-123")
    portfolio = user.portfolios.create!(name: "Demo")
    asset = Asset.create!(isin: "FR0000000002", name: "Demo", asset_type: "stock")
    trade = portfolio.trades.create!(asset: asset, side: "buy", quantity: "1", unit_price: "2", executed_at: 1.hour.ago)
    assert_not trade.update(quantity: 2)
    assert_not trade.destroy
    assert_equal BigDecimal("1"), trade.reload.quantity
  end

  test "prices validate precision and date" do
    asset = Asset.create!(isin: "FR0000000003", name: "Demo", asset_type: "fund")
    assert_not asset.prices.new(value: "0.000000001", quoted_on: Date.current).valid?
    assert_not asset.prices.new(value: "10", quoted_on: Date.tomorrow).valid?
  end
end
