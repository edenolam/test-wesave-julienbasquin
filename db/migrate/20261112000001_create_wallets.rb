class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets do |t|
      t.string :name, null: false
      t.string :currency, null: false, default: "EUR"
      t.timestamps
    end
    create_table :operations do |t|
      t.references :wallet, null: false, foreign_key: true
      t.string :kind, null: false
      t.decimal :amount, precision: 18, scale: 2, null: false
      t.timestamps
    end
    add_check_constraint :operations, "amount > 0", name: "operations_positive_amount"
    add_check_constraint :operations, "kind IN ('deposit', 'withdrawal')", name: "operations_valid_kind"
  end
end
