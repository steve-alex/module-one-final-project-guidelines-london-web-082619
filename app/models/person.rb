class Person < ActiveRecord::Base
    has_many :bookings
    has_many :flights, through: :bookings
end