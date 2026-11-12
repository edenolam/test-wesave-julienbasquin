module PreciseDecimal
  extend ActiveSupport::Concern

  private

  def validate_decimal(attribute)
    value = BigDecimal(public_send("#{attribute}_before_type_cast").to_s, exception: false)
    unless value&.finite? && value > 0 && value < 10**16 && value == value.round(8)
      errors.add(attribute, "must be positive, finite, below 10^16 and have at most 8 decimals")
    end
  end
end
