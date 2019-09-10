class Person < ActiveRecord::Base
    has_many :bookings
    has_many :flights, through: :bookings

    def update_flight(origin:, destination:, arrival_time:, departure_time:, price:)
        if Flight.exists?(origin: origin, destination: destination, departure_time: departure_time, arrival_time: arrival_time)
            flight = Flight.find_by(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
        else
            flight = Flight.create(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
        end
        Booking.update
        
    end

end