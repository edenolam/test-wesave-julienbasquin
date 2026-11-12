# Tests create their own records. db:prepare also loads seeds on a fresh database.
return if Rails.env.test?

# Entirely fictional instruments and prices, expressed in EUR.
catalog = [
  [ "FR0000000001", "ETF fictif de démonstration", "etf", "100.00" ],
  [ "FR0000000019", "ETF Monde — fictif", "etf", "150.00" ],
  [ "FR0000000027", "ETF Europe — fictif", "etf", "80.00" ],
  [ "FR0000000035", "ETF Obligations — fictif", "etf", "50.00" ],
  [ "FR0000000043", "Action Technologie — fictive", "stock", "120.00" ],
  [ "FR0000000050", "Action Énergie — fictive", "stock", "45.00" ],
  [ "FR0000000068", "Obligation Entreprise — fictive", "bond", "1000.00" ],
  [ "FR0000000076", "Fonds Diversifié — fictif", "fund", "200.00" ]
]

ActiveRecord::Base.transaction do
  assets = catalog.map do |isin, name, type, _|
    Asset.find_or_create_by!(isin: isin) do |asset|
      asset.name = name
      asset.asset_type = type
    end
  end

  # Preserve the original demonstration's two price points.
  [ [ 7.days.ago.to_date, "100.00" ], [ Date.current, "105.50" ] ].each do |date, value|
    assets.first.prices.find_or_create_by!(quoted_on: date) { |price| price.value = value }
  end

  catalog.each_with_index do |(_, _, _, initial), index|
    (0..90).each do |day|
      date = Date.current - 90 + day
      value = BigDecimal(initial) * (1 + BigDecimal(day.to_s) * (index + 1) / 10_000)
      assets[index].prices.find_or_create_by!(quoted_on: date) { |price| price.value = value.round(8) }
    end
  end

  # Known credentials only for local development, never for production.
  if Rails.env.development?
    user = User.find_or_create_by!(email: "demo@example.test") do |record|
      record.password = "Demonstration-12345!"
    end
    # Stable anchor: repeated seeds do not move trades or duplicate the history.
    anchor = user.created_at.to_date - 60
    {
      "Épargne diversifiée" => [ [ 1, "20" ], [ 2, "15" ], [ 7, "10" ] ],
      "Profil prudent" => [ [ 3, "40" ], [ 6, "3" ], [ 7, "5" ] ],
      "Profil dynamique" => [ [ 1, "10" ], [ 4, "25" ], [ 5, "30" ] ]
    }.each do |name, holdings|
      portfolio = user.portfolios.find_or_create_by!(name: name)
      holdings.each do |asset_index, quantity|
        asset = assets[asset_index]
        [ [ "buy", quantity, anchor ], [ "sell", "2", anchor + 30 ] ].each do |side, count, date|
          portfolio.trades.find_or_create_by!(asset: asset, side: side, executed_at: date.to_time.change(hour: 12)) do |trade|
            trade.quantity = count
            trade.unit_price = asset.prices.where(quoted_on: ..date).order(quoted_on: :desc).first&.value || BigDecimal(catalog[asset_index][3])
          end
        end
      end
    end
    puts "Compte local : demo@example.test / Demonstration-12345!"
    puts "3 portefeuilles de démonstration avec achats et ventes."
  end
  puts "Catalogue fictif : #{assets.size} actifs avec 91 jours de cours."
end
