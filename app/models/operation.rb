class Operation < ApplicationRecord
  belongs_to :wallet

  validates :kind, inclusion: { in: %w[deposit withdrawal] }
  validates :amount, numericality: { greater_than: 0, less_than: 10**16 }
  validate :amount_has_at_most_two_decimal_places
  validate :sufficient_balance, on: :create

  private

  def amount_has_at_most_two_decimal_places
    value = BigDecimal(amount_before_type_cast.to_s, exception: false)
    errors.add(:amount, "must have at most two decimal places") if value&.finite? && value != value.round(2)
  end

  def sufficient_balance
    if kind == "withdrawal" && amount && wallet && amount > wallet.balance
      errors.add(:amount, "exceeds available balance")
    end
  end
end
