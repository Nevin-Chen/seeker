class CreatePriceHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :price_histories do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false
      t.datetime :recorded_at, null: false
      t.string :source

      t.timestamps
    end

    add_index :price_histories, [ :product_id, :recorded_at ]
    add_index :price_histories, :recorded_at
  end
end
