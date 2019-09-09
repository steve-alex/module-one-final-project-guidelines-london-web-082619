class CreateBookings < ActiveRecord::Migration[5.0]
  def change
    create_table :flights do |t|
      t.string :origin
      t.string :destination
      t.datetime :departure_time
      t.datetime :arrival_time
      t.timestamps
    end

    create_table :people do |t|
      t.string :name
      t.string :email
      t.string :password
      t.timestamps
    end

    create_table :bookings do |t|
      t.belongs_to :person
      t.belongs_to :flight
      t.float :price
      t.timestamps
      #Would you want an extra booking time variable?
    end
  end
end
