class AddAirportCodesToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :origin_code, :string
    add_column :flights, :destination_code, :string
  end
end
