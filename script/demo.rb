require "net/http"
require "json"
require "securerandom"
require "time"

# Runs inside the API container against the actual HTTP server.
def request(method, path, payload = nil, token: nil, expected: 200)
  uri = URI("http://127.0.0.1:3000/api/v1/#{path}")
  req = Net::HTTP.const_get(method).new(uri)
  req["Content-Type"] = "application/json"
  req["Authorization"] = "Bearer #{token}" if token
  req.body = JSON.generate(payload) if payload
  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
  abort "#{method} #{path}: HTTP #{response.code} #{response.body}" unless response.code.to_i == expected
  response.body.to_s.empty? ? nil : JSON.parse(response.body)
end

credentials = { email: "demo-#{SecureRandom.hex(6)}@example.test", password: SecureRandom.hex(16) }
request("Post", "users", { user: credentials }, expected: 201)
token = request("Post", "session", { session: credentials }, expected: 201).fetch("token")
portfolio = request("Post", "portfolios", { portfolio: { name: "Démonstration", currency: "EUR" } }, token: token, expected: 201)
asset = request("Get", "assets", token: token).find { |entry| entry["isin"] == "FR0000000001" }
abort "Run make seed first" unless asset
path = "portfolios/#{portfolio.fetch('id')}"
request("Post", "#{path}/trades", { trade: { asset_id: asset.fetch("id"), side: "buy", quantity: "10", unit_price: "100", executed_at: Time.now.utc.iso8601 } }, token: token, expected: 201)
puts "Positions: #{JSON.generate(request('Get', "#{path}/positions", token: token))}"
puts "Valorisation: #{JSON.generate(request('Get', "#{path}/valuation", token: token))}"
request("Delete", "session", token: token, expected: 204)
puts "Démonstration HTTP réussie : inscription, connexion, portefeuille, achat, positions, valorisation, déconnexion."
