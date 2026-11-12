class Asset < ApplicationRecord
  has_many :prices, dependent: :restrict_with_exception
  has_many :trades, dependent: :restrict_with_exception
  validates :isin, uniqueness: true, format: { with: /\A[A-Z]{2}[A-Z0-9]{9}[0-9]\z/ }
  validates :name, presence: true, length: { maximum: 200 }
  validates :asset_type, inclusion: { in: %w[etf fund stock bond] }
end
