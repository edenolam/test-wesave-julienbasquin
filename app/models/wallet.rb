class Wallet < ApplicationRecord
  has_many :operations, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 }
  validates :currency, inclusion: { in: %w[EUR USD GBP] }

  def balance
    totals = operations.group(:kind).sum(:amount)
    totals.fetch("deposit", BigDecimal("0")) - totals.fetch("withdrawal", BigDecimal("0"))
  end
end
