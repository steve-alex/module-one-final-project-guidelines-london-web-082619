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


    #####################
    ###### Welcome ######
    #####################

    #Run the session
    def run_session
        welcome
        sign_in_prompt
        main_menu
    end


    #Welcome the user to Skyscourer
    def welcome
        puts
        puts "🛫   Welcome to Skyscourer  🛬"
        puts "~~ the flight booking service similar to, but legally distinct from, Skyscanner ~~"
        puts
    end

    #Prompt the user to sign in
    def sign_in_prompt
        puts
        choice = @prompt.select("To start, sign in or create an account:", ["Sign in", "Register", "Quit"])
        case choice
        when "Sign in"
            sign_in
        when "Register"
            register
        when "Quit"
            process_main_menu_choice("Log out")
        end
    end

    #Get and validate sign-in details
    def sign_in
        puts
        puts "Sign in with your email and password.\n"
        email = get_email
        password = get_password("Enter")
        if Person.exists?(email: email, password: password)
            self.user = Person.find_by(email: email, password: password)
        else  
            no_user
        end
    end

    #Handle sign-in requests where the user does not exist
    def no_user
        puts
        choice = @prompt.select("That user doesn't exist.", ["Try again", "Register", "Quit"])
        case choice
        when "Try again"
            sign_in
        when "Register"
            register
        when "Quit"
            process_main_menu_choice("Log out")
        end
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
            q.validate /^[^ ]{8,100}$/
        end
    end


    #######################
    ###### Main menu ######
    #######################

    #List a signed-in user's options
    def main_menu
        puts
        choice = @prompt.select("What would you like to do, #{self.user.name}?") do | menu |
            menu.choice("Search and book flights")
            menu.choice("View booked flights")
            menu.choice("Cancel a booking")
            menu.choice("Change password")
            menu.choice("Log out")
        end
        process_main_menu_choice(choice)
    end

    #Process the user's decision on the main menu. Handles all quit/logout commands
    def process_main_menu_choice(input)
        case input
        when "Search and book flights"
            search_and_book_flights
        when "View booked flights"
            view_booked_flights    
        when "Cancel a booking"
            cancel_booking
        when "Change password"
            change_password
        when "Log out"
            puts
            puts "Thanks for shopping with Skyscourer!"
            puts
            exit
        end
    end


    ###########################
    ###### Flight search ######
    ###########################

    #Run the search and booking flow from start to finish
    def search_and_book_flights
        search_results = search_flights
        valid_results?(search_results)
        flight_choice = select_flight_to_book(search_results)
        book_flight(search_results[flight_choice])
        puts
        puts "Flight booked!"
        main_menu
    end

    #Returns search results for user input
    def search_flights
        origin_code = get_airport_code("from")
        destination_code = get_airport_code("to")
        outbound_date = format_date(get_date("departing"))
        results = Search.new(origin_code: origin_code, destination_code: destination_code, outbound_date: outbound_date).run_search
    end

    #Validates the search results set
    def valid_results?(results)
        if !results
            puts
            puts "No flights found. Please try an alternative route."
            main_menu
        end
    end

    #Returns the index of the user's chosen flight in the results array
    def select_flight_to_book(results)
        formatted_results = format_results(results)
        choose_flight(formatted_results)
    end

    #Book the specified flight in the given results set
    def book_flight(flight_hash)
        flight = Flight.find_or_create_by(
            flight_hash.filter { | k, v | k != "price" && k != "flight_id" }
        )
        booking = Booking.create(
            person_id: self.user.id,
            flight_id: flight.id,
            price: flight_hash["price"]
        )
    end

    #Takes a city name from the user and returns the airport code
    def get_airport_code(from_or_to)
        city = @prompt.ask("What city are you flying #{from_or_to}?") do |q|
            q.required true
            q.validate /^[A-Za-z\-& ]{2,30}$/
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

    

    #Prompt the user to book a flight returned by their search
    def choose_flight(formatted_results)
        choice = @prompt.select("Choose a flight to book") do | menu |
            formatted_results.each_with_index do | result, index |
                menu.choice(result, index)
            end
            menu.choice("◀️ Back")
        end
        main_menu if choice == "◀️ Back"
        choice
    end

    #Format the raw search results
    def format_results(results)
        results.map do | flight |
            "✈️ #{flight['origin_name']} #{flight['origin_code']} ⏱#{flight['departure_time']} → #{flight['destination_name']} #{flight['destination_code']} ⏱#{flight['arrival_time']} 💷#{flight['price']}"
        end
    end


    ##########################
    ###### View flights ######
    ##########################

    #Show the user the flights they've booked
    def view_booked_flights
        puts
        puts  "Here are your flights: "
        puts get_booked_flights
        puts
        input = @prompt.select("Finished?", ["◀️ Main menu", "❌ Log out"])
        process_view_flights_choice(input)    
    end

    #Fetch and format the user's flights array
    def get_booked_flights
        results = self.user.flights.each_with_object([]) do | flight, array |
            matching_booking = self.user.bookings.find { | booking | booking.flight_id == flight.id }
            array << {
                        "origin_name" => flight.origin,
                        "origin_code" => flight.origin_code,
                        "destination_name" => flight.destination,
                        "destination_code" => flight.destination_code,
                        "departure_time" => flight.departure_time,
                        "arrival_time" => flight.arrival_time,
                        "price" => matching_booking.price
                     }
        end
        format_results(results)
    end

    #Process the user's decision after viewing their flights
    def process_view_flights_choice(input)
        case input
        when "◀️ Main menu"
            main_menu
        when "❌ Log out"
            process_main_menu_choice("Log out")
        end
    end



    ##########################
    ###### Cancel flights ######
    ##########################
    
    def cancel_booking
        choice = @prompt.select("Choose a booking to cancel") do | menu |
            get_booked_flights.each_with_index do | result, index |
                menu.choice(result, index)
            end
        end
        booking_id = self.user.bookings.find_by(flight: self.user.flights[choice]).id
        Booking.destroy(booking_id)
        puts
        puts "Success! Booking cancelled."
        main_menu
    end

    #############################
    ###### Change password ######
    #############################
    
    #Run the change password flow
    def change_password
        verify_password
        self.user.update(password: get_password("Create new"))
        puts "Success! Password updated."
        puts
        main_menu
    end

    #Confirm the user's identity before they change their password
    def verify_password
        old_password = @prompt.mask("Old password:") do |q|
            q.required true
            q.validate /^.*{,100}$/
        end
        if old_password != self.user.password
            puts
            puts "Incorrect password. Please try again."
            verify_password
        else
            true
        end
    end
        




end

Session.new.run_session
