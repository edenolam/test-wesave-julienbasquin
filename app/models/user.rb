class User < ApplicationRecord
  has_secure_password
  has_many :portfolios, dependent: :restrict_with_exception
  has_many :api_sessions, dependent: :destroy
  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, if: -> { new_record? || password.present? }
end
