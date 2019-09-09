class Booking < ActiveRecord::Base
    belongs_to :flight
    belongs_to :person

=begin

Method available

build_person(attributes = {}), build_flight(attributes = {})
    => Creates associations, but does not save yet

create_person(attributes = {}), create_flight(attributes = {})
    => Creates associations and saves them

create_author!
    => Does the same as create_association, but raises ActiveRecord::RecordInvalid if the record is invalid.

=end

end