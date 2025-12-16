class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :sku
      t.string :name, null: false
      t.string :url, null: false
      t.decimal :current_price, precision: 10, scale: 2
      t.datetime :last_checked_at
      t.string :check_status, default: 'pending'

      t.timestamps
    end

    add_index :products, :url, unique: true
    add_index :products, :sku
    add_index :products, :last_checked_at
  end
end
