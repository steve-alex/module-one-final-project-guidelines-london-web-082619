class Flight < ActiveRecord::Base
    has_many :bookings
    has_many :persons, through: :bookings

    def exists?
        #Already exists in active record
    end

    def self.create_flight
        #Already exists in active record
    end

    def get_bookings #Works!!!
        self.bookings.each do |booking|
            puts "#{booking.person.name}, #{booking.price}"
        end
    end

    def number_of_bookings #Works!!!
        self.bookings.length
    end

    def self.flights_in_arrival_location(location)
    end

    def self.bookings_per_flight_by_arrival_location(location)
    end

end