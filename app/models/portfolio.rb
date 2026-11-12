class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :trades, dependent: :restrict_with_exception
  validates :name, presence: true, length: { maximum: 100 }
  validates :currency, inclusion: { in: [ "EUR" ] }

  def positions(at: Time.current)
    totals = Hash.new { |hash, key| hash[key] = BigDecimal("0") }
    trades.where(executed_at: ..at).each do |trade|
      totals[trade.asset_id] += trade.side == "buy" ? trade.quantity : -trade.quantity
    end
    assets = Asset.where(id: totals.keys).index_by(&:id)
    totals.sort.filter_map do |asset_id, quantity|
      next if quantity.zero?
      { asset_id: asset_id, isin: assets.fetch(asset_id).isin, quantity: quantity.to_s("F") }
    end
  end

  def valuation(on:)
    holdings = positions(at: on.end_of_day)
    missing = []
    total = BigDecimal("0")
    holdings.each do |position|
      price = Price.where(asset_id: position[:asset_id], quoted_on: ..on).order(quoted_on: :desc).first
      if price
        total += BigDecimal(position[:quantity]) * price.value
      else
        missing << position[:asset_id]
      end
    end
    { date: on.iso8601, currency: currency, value: missing.empty? ? total.round(2).to_s("F") : nil,
      missing_asset_ids: missing }
  end
end
