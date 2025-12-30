class OptionalProductName < ActiveRecord::Migration[8.1]
  def change
    change_column_null :products, :name, true
  end
end
