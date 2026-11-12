require "test_helper"

class ConcurrentTradesTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "concurrent sales cannot oversell a position" do
    User.find_by(email: "concurrent@example.test")&.destroy!
    user = User.create!(email: "concurrent@example.test", password: "long-password-123")
    portfolio = user.portfolios.create!(name: "Concurrent")
    asset = Asset.create!(isin: "FR0000000004", name: "Concurrent", asset_type: "etf")
    portfolio.trades.create!(asset: asset, side: "buy", quantity: "10", unit_price: "1", executed_at: 1.day.ago)
    ready = Queue.new
    start = Queue.new
    results = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          own_portfolio = Portfolio.find(portfolio.id)
          ready << true
          start.pop
          begin
            own_portfolio.trades.create!(asset_id: asset.id, side: "sell", quantity: "7", unit_price: "1", executed_at: 1.hour.ago)
            results << :created
          rescue ActiveRecord::RecordInvalid
            results << :rejected
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:value)
    assert_equal [ :created, :rejected ], 2.times.map { results.pop }.sort
    assert_equal "3.0", portfolio.positions.first[:quantity]
  ensure
    threads&.each(&:join)
    Trade.where(portfolio_id: portfolio.id).delete_all if portfolio&.persisted?
    portfolio&.destroy!
    asset&.destroy!
    user&.reload&.destroy!
  end
end
