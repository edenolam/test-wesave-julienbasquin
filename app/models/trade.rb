class Trade < ApplicationRecord
  include PreciseDecimal
  belongs_to :portfolio
  belongs_to :asset
  validates :side, inclusion: { in: %w[buy sell] }
  validates :executed_at, presence: true
  validate { validate_decimal(:quantity) }
  validate { validate_decimal(:unit_price) }
  validate do
    errors.add(:executed_at, "cannot be in the future") if executed_at && executed_at > Time.current
  end
  validate :chronological_position, on: :create
  before_update { throw :abort }
  before_destroy { throw :abort }

  # All callers, including console and seeds, serialize writes for a portfolio.
  around_save :serialize_creation, if: :new_record?

  private

  def serialize_creation
    portfolio.with_lock do
      validate!
      yield
    end
  end

  def chronological_position
    return unless portfolio && asset && executed_at && quantity&.positive? && %w[buy sell].include?(side)

    entries = portfolio.trades.where(asset_id: asset_id).order(:executed_at, :id).to_a
    entries << self
    balance = BigDecimal("0")
    entries.sort_by.with_index { |trade, index| [ trade.executed_at, index ] }.each do |trade|
      balance += trade.side == "buy" ? trade.quantity : -trade.quantity
      if balance.negative?
        errors.add(:quantity, "would create a negative position")
        break
      end
    end
  end
end
