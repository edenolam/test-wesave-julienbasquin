# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_12_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_sessions_on_user_id"
  end

  create_table "assets", force: :cascade do |t|
    t.string "isin", null: false
    t.string "name", null: false
    t.string "asset_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["isin"], name: "index_assets_on_isin", unique: true
  end

  create_table "operations", force: :cascade do |t|
    t.bigint "wallet_id", null: false
    t.string "kind", null: false
    t.decimal "amount", precision: 18, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wallet_id"], name: "index_operations_on_wallet_id"
    t.check_constraint "amount > 0::numeric", name: "operations_positive_amount"
    t.check_constraint "kind::text = ANY (ARRAY['deposit'::character varying::text, 'withdrawal'::character varying::text])", name: "operations_valid_kind"
  end

  create_table "portfolios", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "currency", default: "EUR", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
    t.check_constraint "currency::text = 'EUR'::text", name: "portfolios_eur"
  end

  create_table "prices", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.decimal "value", precision: 24, scale: 8, null: false
    t.date "quoted_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id", "quoted_on"], name: "index_prices_on_asset_id_and_quoted_on", unique: true
    t.index ["asset_id"], name: "index_prices_on_asset_id"
    t.check_constraint "value > 0::numeric AND value < 'Infinity'::numeric", name: "prices_positive"
  end

  create_table "trades", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.bigint "asset_id", null: false
    t.string "side", null: false
    t.decimal "quantity", precision: 24, scale: 8, null: false
    t.decimal "unit_price", precision: 24, scale: 8, null: false
    t.datetime "executed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_trades_on_asset_id"
    t.index ["portfolio_id", "executed_at"], name: "index_trades_on_portfolio_id_and_executed_at"
    t.index ["portfolio_id"], name: "index_trades_on_portfolio_id"
    t.check_constraint "quantity > 0::numeric AND quantity < 'Infinity'::numeric", name: "trades_quantity_positive"
    t.check_constraint "side::text = ANY (ARRAY['buy'::character varying, 'sell'::character varying]::text[])", name: "trades_side"
    t.check_constraint "unit_price > 0::numeric AND unit_price < 'Infinity'::numeric", name: "trades_unit_price_positive"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "wallets", force: :cascade do |t|
    t.string "name", null: false
    t.string "currency", default: "EUR", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "api_sessions", "users"
  add_foreign_key "operations", "wallets"
  add_foreign_key "portfolios", "users"
  add_foreign_key "prices", "assets"
  add_foreign_key "trades", "assets"
  add_foreign_key "trades", "portfolios"
end
