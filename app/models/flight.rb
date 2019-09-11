class Flight < ActiveRecord::Base
    has_many :bookings
    has_many :persons, through: :bookings
end