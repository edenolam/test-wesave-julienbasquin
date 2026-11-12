class CreateInvestmentModels < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true
    create_table :api_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :api_sessions, :token_digest, unique: true
    create_table :portfolios do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :currency, null: false, default: "EUR"
      t.timestamps
    end
    add_check_constraint :portfolios, "currency = 'EUR'", name: "portfolios_eur"
    create_table :assets do |t|
      t.string :isin, null: false
      t.string :name, null: false
      t.string :asset_type, null: false
      t.timestamps
    end
    add_index :assets, :isin, unique: true
    create_table :prices do |t|
      t.references :asset, null: false, foreign_key: true
      t.decimal :value, precision: 24, scale: 8, null: false
      t.date :quoted_on, null: false
      t.timestamps
    end
    add_index :prices, [ :asset_id, :quoted_on ], unique: true
    add_check_constraint :prices, "value > 0 AND value < 'Infinity'::numeric", name: "prices_positive"
    create_table :trades do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :asset, null: false, foreign_key: true
      t.string :side, null: false
      t.decimal :quantity, precision: 24, scale: 8, null: false
      t.decimal :unit_price, precision: 24, scale: 8, null: false
      t.datetime :executed_at, null: false
      t.timestamps
    end
    add_index :trades, [ :portfolio_id, :executed_at ]
    add_check_constraint :trades, "side IN ('buy', 'sell')", name: "trades_side"
    %w[quantity unit_price].each do |column|
      add_check_constraint :trades, "#{column} > 0 AND #{column} < 'Infinity'::numeric", name: "trades_#{column}_positive"
    end
  end
end
