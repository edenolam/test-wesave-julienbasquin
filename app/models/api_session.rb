class ApiSession < ApplicationRecord
  belongs_to :user

  def self.issue!(user)
    token = SecureRandom.hex(32)
    user.api_sessions.create!(token_digest: Digest::SHA256.hexdigest(token), expires_at: 24.hours.from_now)
    token
  end
end
