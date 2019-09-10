#require_relative '../config/environment'
require 'tty-prompt'
require 'pry'
require_relative '../config/environment'

class Session
    attr_accessor :user

    def initialize
        @user = nil
        @prompt = TTY::Prompt.new
    end


    ###### Instance methods ######

    #Welcome the user to Skyscourer
    def welcome
        puts
        puts "🛫   Welcome to Skyscourer 🛬"
        puts "~~ the flight booking service similar to, but legally distinct from, Skyscanner ~~"
        puts
    end

    #Prompt the user to sign in
    def sign_in_prompt
        user_type = @prompt.select("To start, sign in or create an account:", ["Sign in", "Register"])
        if user_type == "Sign in"
            sign_in
        elsif user_type == "Register"
            register
        end
    end

    #Get and validate sign-in details
    def sign_in
        puts "Sign in with your email and password.\n"
        email = get_email
        password = get_password("Enter")
        if Person.exists?(email: email, password: password)
            self.user = Person.where(email: email, password: password)
        else  
            no_user
        end
    end

    #Handle sign-in requests where the user does not exist
    def no_user
        choice = @prompt.select("That user doesn't exist.", %w(Try\ again Create\ account))
        choice == "Try again" ? sign_in : register
    end

    #Register a new user
    def register
        name = @prompt.ask("Enter your name:") do |q|
            q.required true
            q.validate /^[A-Za-z]{2,30}$/
            q.modify :capitalize
        end
        email = get_email
        password = get_password("Create")
        self.user = Person.create(name: name, email: email, password: password)
    end

    #Prompt the user for their email address
    def get_email
        email = @prompt.ask("Enter email:") do |q|
            q.required true
            q.validate /^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/
            q.modify :down
        end
    end

    #Prompt the user to enter or create a password
    def get_password(state)
        password = @prompt.mask("#{state} password (min. 8 characters):") do |q|
            q.required true
            q.validate /^[^ ]{6,100}$/
        end
    end

    #List a signed-in user's options
    def main_menu
        puts "Welcome, #{self.user.name}!"
        choice = @prompt.select("What would you like to do?") do | menu |
            menu.choice("Search flights")
            menu.choice("View booked flights")
            menu.choice("Change a flight")
            menu.choice("Cancel a flight")
        end
        process_main_menu_choice(choice)
    end

    # def process_main_menu_choice(input)
    #     case input
    #     when "Search flights"
    #     when "View booked flights"
    #     when "Change a flight"
    #     when "Cancel a flight"
    #     end
    # end

    def search_flights
        origin_code = get_airport_code("from")
        destination_code = get_airport_code("to")
        outbound_date = format_date(get_date("departing"))
        results = Search.new(origin: origin_code, destination: destination_code, outbound_date: outbound_date).run_search
    end

    #Takes a city name from the user and returns the airport code
    def get_airport_code(from_or_to)
        city = @prompt.ask("What city are you flying #{from_or_to}?") do |q|
            q.required true
            q.validate /^[A-Za-z'\-&]{2,30}$/
            q.modify :down
        end

        code = Search.get_airport_from_city(city)
        valid_airport?(code) ? code : get_airport_code(from_or_to)
    end

    #Checks that the code returned is valid
    def valid_airport?(code)
        if code
            return true
        else
            puts
            puts "That city doesn't have an airport. Please try again."
            return false
        end
    end

    #Takes a string ("departing" or "returning") and gets departure or return date from user
    def get_date(departing_or_returning)
        date = @prompt.ask("What date are you #{departing_or_returning}? DD-MM-YYYY") do |q|
            q.required true
            q.validate /(^(((0[1-9]|1[0-9]|2[0-8])[\/\-](0[1-9]|1[012]))|((29|30|31)[\/\-](0[13578]|1[02]))|((29|30)[\/\-](0[4,6,9]|11)))[\/\-](19|[2-9][0-9])\d\d$)|(^29[\/\-]02[\/\-](19|[2-9][0-9])(00|04|08|12|16|20|24|28|32|36|40|44|48|52|56|60|64|68|72|76|80|84|88|92|96)$)/
        end
        valid_date?(date) ? date : get_date(departing_or_returning)
    end

    #Checks user's date is valid
    def valid_date?(date)
        datetime = DateTime.strptime(date, "%d-%m-%Y")
        if datetime > DateTime.now.next_year 
            puts "Sorry, you can't book flights after #{DateTime.now.next_year.strftime("%d-%m-%Y")}."
            return false
        elsif datetime < DateTime.now
            puts "You can't book flights in the past, Marty."
            return false
        end
        true
    end

    #Formats date for input into the Skyscanner API
    def format_date(date)
        date_chunks = date.split(/[\-\/\.]/)
        new_date = [date_chunks[2], date_chunks[1], date_chunks[0]].join("-")
    end


    ##########################
    ###### View flights ######
    ##########################
    # def view_booked_flights
    #     flight_list = []
    #     Person.bookings.map do | booking |
    #         flight_list[:price] = booking.price
    #     end
    #     Person.flights.map do | flight |

    # def booking_to_string(booking)
    #     Person.bookings.each_with_object([]) do | booking |
    #         booking_string = <<-BOOKING
    #             #{booking.flight.origin.capitalize} 
    #             #{booking.flight.origin_code} 


end

session = Session.new
# session.welcome
# session.sign_in_prompt
# session.main_menu
search1 = Search.new(origin: "LOND-sky", destination: "SFO-sky", outbound_date: "2020-01-20")
p search1.run_search




