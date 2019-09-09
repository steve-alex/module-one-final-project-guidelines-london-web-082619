class Person < ActiveRecord::Base
    has_many :bookings
    has_many :people, through: :bookings

    def create_booking(origin:, destination:, arrival_time:, departure_time:, booking_price:)
        #Search results hash keys will have to match create_booking parameters key
        if Flight.exists?(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
            flight = Flight.find_by(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
        else
            Flight.create(origin: origin, destination: destination, arrival_time: arrival_time, departure_time: departure_time)
        end
    
        Booking.create(:flight => flight, :person => self, :booking_price => booking_price)
        nil
    end

    def update_booking(new_departure_time)
    end

end