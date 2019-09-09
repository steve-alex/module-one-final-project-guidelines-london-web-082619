#require_relative '../config/environment'
require 'tty-prompt'
require 'pry'
require_relative '../config/environment'

$prompt = TTY::Prompt.new

class Session
    attr_accessor :user

    def initialize
        @user = nil
    end


    ###### Instance methods ######

    #Welcome the user to Skyscourer
    def welcome
        puts "Welcome to Skyscourer ✈️"
        puts "The flight booking service similar to, but legally distinct from, Skyscanner"
    end

    #Prompt the user to sign in
    def sign_in_prompt
        user_type = $prompt.select("To start, sign in or create an account:", %w(Sign\ in Register))
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
        choice = $prompt.select("That user doesn't exist.", %w("Try again" "Create account"))
        choice == "Try again" ? sign_in : register
    end

    #Register a new user
    def register
        name = $prompt.ask("Enter your name:") do |q|
            q.required true
            q.validate /^[A-Za-z]{2,30}$/
            q.modify :capitalize
        end
        email = get_email
        password = get_password("Create")
        Person.create(name: name, email: email, password: password)
    end

    #Prompt the user for their email address
    def get_email
        email = $prompt.ask("Enter email:") do |q|
            q.required true
            q.validate /^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/
            q.modify :down
        end
    end

    #Prompt the user to enter or create a password
    def get_password(state)
        password = $prompt.mask("#{state} password (min. 8 characters):") do |q|
            q.required true
            q.validate /^[^ ]{6,100}$/
        end
    end

    #List a signed-in user's options
    def display_options
        puts "Welcome, #{self.user.name}!"
        choice = $prompt.select("What would you like to do?") do | menu |
            menu.choice("Search flights")
            menu.choice("View booked flights")
            menu.choice("Change a flight")
            menu.choice("Cancel a flight")
        end
    end

end

session = Session.new
session.welcome
session.sign_in_prompt
session.display_options



