class Session

    def initialize
        @user = nil
        @prompt = TTY::Prompt.new
    end
    
    def run_session
        # Run the session
        welcome
        sign_in_prompt
        main_menu
    end


    private

    #####################
    ###### Welcome ######
    #####################

    def welcome
        # Welcome the user to Skyscourer
        puts
        puts "
   ┌───────────────────────────────────────────────────────────────────────────┐                                                                      
   |  ,---.  ,--.                                                              |
   | '   .-' |  |,-. ,--. ,--.,---.  ,---. ,---. ,--.,--.,--.--. ,---. ,--.--. |
   | `.  `-. |     /  \\  '  /(  .-' | .--'| .-. ||  ||  ||  .--'| .-. :|  .--' | 
   | .-'    ||  \\  \\   \\   ' .-'  `)\\ `--.' '-' ''  ''  '|  |   \\   --         |    
   | `-----' `--'`--'.-'  /  `----'  `---' `---'  `----' `--'    `----'`--'    |
   |                 `---'                                                     |
   └───────────────────────────────────────────────────────────────────────────┘
      "
        puts "🛫  the flight booking service similar to, but legally distinct from, Skyscanner 🛬"
        puts
    end

    def sign_in_prompt
        # Prompt the user to sign in
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
    
    def sign_in
        # Get and validate sign-in details
        puts
        puts "Sign in with your email and password.\n"
        email = get_email
        password = get_password("Enter")
        if Person.exists?(email: email, password: password)
            @user = Person.find_by(email: email, password: password)
        else  
            no_user
        end
    end

    def no_user
        # Handle sign-in requests where the user does not exist
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
 
    def register
        # Register a new user
        puts
        name = @prompt.ask("Enter your name:") do |q|
            q.required true
            q.validate /^[\p{L}\s'.-]+$/
            q.messages[:valid?] = "Please enter a valid name"
            q.modify :capitalize
        end
        email = get_email
        password = get_password("Create")
        @user = Person.create(name: name, email: email, password: password)
    end

    def get_email
        # Prompt the user for their email address
        email = @prompt.ask("Enter email:") do |q|
            q.required true
            q.validate /^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/
            q.messages[:valid?] = "Please enter a valid email"
            q.modify :down
        end
    end
    
    def get_password(state)
        # Prompt the user to enter or create a password depending on the argument passed in
        password = @prompt.mask("#{state} password (min. 8 characters):") do |q|
            q.required true
            q.validate /^[^ ]{8,100}$/
            q.messages[:valid?] = "Passwords must be at least 8 characters"
        end
    end


    #######################
    ###### Main menu ######
    #######################

    def main_menu
        # List a signed-in user's options
        puts
        choice = @prompt.select("What would you like to do, #{@user.name}?") do | menu |
            menu.choice("Search and book flights")
            menu.choice("View booked flights")
            menu.choice("Cancel a booking")
            menu.choice("Change password")
            menu.choice("Log out")
        end
        process_main_menu_choice(choice)
    end

    def process_main_menu_choice(input)
        # Process the user's decision on the main menu. Handles all quit/logout commands
        case input
        when "Search and book flights"
            run_search_flow
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

    def run_search_flow
        # Run the search and booking flow from start to finish
        puts
        search_results = search_flights
        valid_results?(search_results)
        flight_choice = select_flight_to_book(search_results)
        book_flight(search_results[flight_choice])
        puts
        puts "Flight booked!"
        main_menu
    end

    def search_flights
        # Returns search results for user input
        origin_code = get_airport_code("from")
        destination_code = get_airport_code("to")
        outbound_date = format_date(get_date("departing"))
        cabin_class = get_cabin_class
        puts
        # Display loading animation while search runs
        results = nil
        spinner = TTY::Spinner.new("Searching for flights :spinner 🛫  :spinner", format: :arrow_pulse)
        spinner.run do
            results = Search.new(origin_code: origin_code, destination_code: destination_code, outbound_date: outbound_date, cabin_class: cabin_class).run_search
        end
        spinner.stop('done')
        results
    end

    def valid_results?(results)
        # Validates the search results set
        if !results
            puts
            puts "No flights found. Please try an alternative route or change your search date."
            main_menu
        end
    end

    def select_flight_to_book(results)
        # Takes in a results array, prompts the user to select a flight to book, and returns the index of their choice
        formatted_results = format_results(results)
        choose_flight(formatted_results)
    end

    def book_flight(flight_hash)
        # Create flight and booking objects from the search result chosen by the user
        flight = Flight.find_or_create_by(
            flight_hash.filter { | k, v | k != "price" && k != "flight_id" }
        )
        booking = Booking.create(
            person_id: @user.id,
            flight_id: flight.id,
            price: flight_hash["price"]
        )
    end

    def get_airport_code(from_or_to)
        # Takes a city name from the user and returns the airport code
        city = @prompt.ask("What city are you flying #{from_or_to}?") do |q|
            q.required true
            q.validate /^[A-Za-z\-& ]{2,30}$/
            q.messages[:valid?] = "Please enter a valid city"
            q.modify :down
        end
        code = Search.get_airport_from_city(city)
        # Reruns function until valid input is provided
        valid_airport?(code) ? code : get_airport_code(from_or_to)
    end

    def valid_airport?(code)
        # Checks that the code returned is valid
        if code
            return true
        else
            puts
            puts "That city doesn't have an airport. Please try again."
            return false
        end
    end

    def get_date(departing_or_returning)
        # Takes a string ("departing" or "returning") and gets departure or return date from user
        date = @prompt.ask("What date are you #{departing_or_returning}? DD-MM-YYYY") do |q|
            q.required true
            q.validate /(^(((0[1-9]|1[0-9]|2[0-8])[\/\-](0[1-9]|1[012]))|((29|30|31)[\/\-](0[13578]|1[02]))|((29|30)[\/\-](0[4,6,9]|11)))[\/\-](19|[2-9][0-9])\d\d$)|(^29[\/\-]02[\/\-](19|[2-9][0-9])(00|04|08|12|16|20|24|28|32|36|40|44|48|52|56|60|64|68|72|76|80|84|88|92|96)$)/
            q.messages[:valid?] = "Dates must use the format DD-MM-YYYY"
        end
        # Reruns function until valid date is provided
        valid_date?(date) ? date : get_date(departing_or_returning)
    end

    def valid_date?(date)
        #Checks user's date is not in the past or too far in the future
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

    def format_date(date)
        # Formats date for input into the Skyscanner API
        date_chunks = date.split(/[\-\/\.]/)
        new_date = [date_chunks[2], date_chunks[1], date_chunks[0]].join("-")
    end

    def get_cabin_class
        # Gives the user a choice of cabin class to search
        cabin_class = @prompt.select("What cabin class would you like to book?") do |menu|
            menu.choice('Economy', 'economy')
            menu.choice('Premium Economy', 'premiumeconomy')
            menu.choice('Business', 'business')
            menu.choice('First', 'first')
        end
    end

    def choose_flight(formatted_results)
        # Prompts the user to book a flight returned by their search
        puts
        choice = @prompt.select("Choose a flight to book") do | menu |
            formatted_results.each_with_index do | result, index |
                menu.choice(result, index)
            end
            menu.choice("◀️  Back")
        end
        main_menu if choice == "◀️  Back"
        choice
    end

    def format_results(results)
        # Formats the raw search results
        results.map do | flight |
            departure_time = format_time(flight['departure_time'])
            arrival_time = format_time(flight['arrival_time'])
            "✈️  #{flight['origin']} #{flight['origin_code']} ⏱ #{departure_time} → #{flight['destination']} #{flight['destination_code']} ⏱ #{arrival_time} 💰 #{flight['price']}"
        end
    end

    def format_time(time)
        # Format time in user-friendly format
        DateTime.parse(time).strftime("%l:%M %p, %d %b, %Y")
    end


    ##########################
    ###### View flights ######
    ##########################

    def view_booked_flights
        # Show the user the flights they've booked
        puts
        if @user.bookings.reload[0]
            puts "Here are your bookings:"
            puts get_booked_flights
        else
            puts "You don't have any bookings yet."
        end
        puts
        input = @prompt.select("Finished?", ["◀️  Main menu", "❌  Log out"])
        process_view_flights_choice(input)    
    end

    def get_booked_flights
        # Fetch and format the user's flights array (uses reload to refresh cached values)
        results = @user.flights.reload.each_with_object([]) do | flight, array |
            matching_booking = @user.bookings.find { | booking | booking.flight_id == flight.id }
            booking_details = flight.attributes.reject { | k, v | k == "id" }
            booking_details["price"] = matching_booking.price
            array << booking_details
        end
        format_results(results)
    end

    def process_view_flights_choice(input)
        # Process the user's decision after viewing their flights
        case input
        when "◀️  Main menu"
            main_menu
        when "❌  Log out"
            process_main_menu_choice("Log out")
        end
    end



    ############################
    ###### Cancel flights ######
    ############################
    
    def cancel_booking
        puts
        if @user.bookings.reload[0]
            choice = @prompt.select("Choose a booking to cancel") do | menu |
                get_booked_flights.each_with_index { | result, index | menu.choice(result, index) }
                menu.choice("◀️  Back")
            end
            # User's choice is represented by the array index of the flight they select
            process_cancellation(choice)
        else
            puts "You don't have any bookings yet."
            main_menu
        end
    end

    def process_cancellation(choice)
        # Destroys the selected flight using the index passed from cancel_booking
        main_menu if choice == "◀️  Back"
        booking_id = @user.bookings.find_by(flight: @user.flights[choice]).id
        Booking.destroy(booking_id)
        puts
        puts "Success! Booking cancelled."
        main_menu
    end

    #############################
    ###### Change password ######
    #############################
    
    def change_password
        # Run the change password flow
        verify_password
        @user.update(password: get_password("Create new"))
        puts "Success! Password updated."
        puts
        main_menu
    end

    def verify_password
        # Confirm the user's identity before they change their password
        puts
        old_password = @prompt.mask("Enter your old password:") do |q|
            q.required true
            q.validate /^.*{,100}$/
            q.messages[:valid?] = "Password is too long"
        end
        if old_password != @user.password
            puts
            puts "Incorrect password. Please try again."
            # Reruns the function until a matching password is entered
            verify_password
        else
            true
        end
    end

end