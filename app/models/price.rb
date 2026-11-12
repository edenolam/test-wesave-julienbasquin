class Price < ApplicationRecord
  include PreciseDecimal
  belongs_to :asset
  validates :quoted_on, presence: true, uniqueness: { scope: :asset_id }
  validate { validate_decimal(:value) }
  validate do
    errors.add(:quoted_on, "cannot be in the future") if quoted_on && quoted_on > Date.current
  end
end
