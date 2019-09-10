class Person < ActiveRecord::Base
    has_many :bookings
    has_many :people, through: :bookings
=begin

    def book_flight(origin:, destination:, arrival_time:, departure_time:, price:)
        if Flight.exists?(origin: origin, destination: destination, departure_time: departure_time, arrival_time: arrival_time)
            flight = Flight.find_by(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
        else
            flight = Flight.create(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
        end
        Booking.create(:flight => flight, :person => self, :price => price)
    end

    def update_flight(origin:, destination:, arrival_time:, departure_time:, price:)
        if Flight.exists?(origin: origin, destination: destination, departure_time: departure_time, arrival_time: arrival_time)
            flight = Flight.find_by(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
        else
            flight = Flight.create(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
        end
        Booking.update
        
    end
=end
end