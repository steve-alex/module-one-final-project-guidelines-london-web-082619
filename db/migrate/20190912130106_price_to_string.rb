class PriceToString < ActiveRecord::Migration[5.0]
  def change
    change_column :bookings, :price, :string
  end
end
