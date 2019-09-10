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

    # def search_flights
    #     origin_code = Search.get_airport_from_city(get_airport_code("from")
    #     destination_code = Search.get_airport_from_city(get_airport_code("to")
    #     #get departure date
    # end

    # def get_airport_code(from_or_to)
    #     @prompt.ask("What city are you flying #{from_or_to}?") do |q|
    #         q.required true
    #         q.validate /^[A-Za-z'\-&]{2,30}$/
    #         q.modify :down
    #     end
    # end

    def get_date(departing_or_returning)
        date = @prompt.ask("What date are you #{departing_or_returning}? DD-MM-YYYY") do |q|
            q.required true
            q.validate /^(?:(?:31(\/|-|\.)(?:0?[13578]|1[02]))\1|(?:(?:29|30)(\/|-|\.)(?:0?[13-9]|1[0-2])\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})$|^(?:29(\/|-|\.)0?2\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\d|2[0-8])(\/|-|\.)(?:(?:0?[1-9])|(?:1[0-2]))\4(?:(?:1[6-9]|[2-9]\d)?\d{2})$/
        end
        valid_date?(date) ? date : get_date(departing_or_returning)
    end

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



end

session = Session.new
p session.get_date("departing")
# session.welcome
# session.sign_in_prompt
# session.main_menu



