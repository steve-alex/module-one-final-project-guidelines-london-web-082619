#require_relative '../config/environment'
require 'tty-prompt'
require 'pry'

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

    #Check whether user is signing in or registering
    def sign_in_or_register(user_type)
        if user_type == "Sign in"
            sign_in
        elsif user_type == "Create account"
            #create_account
        end
    end

    #Get and validate sign-in details
    def sign_in
        puts "Sign in with your email and password.\n"
        email = $prompt.ask("Enter email:") do |q|
            q.required true
            q.validate /^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/
            q.modify :trim, :down
        end
        password = $prompt.mask("Enter password (min. 8 characters):") do |q|
            q.required true
            q.validate /^[^ ]{6,100}$/
        end
        if Person.exists?(email: email, password: password)
            self.
            puts "create_session"
        else  
            no_user
        end
    end

    #Handle sign-in requests where the user does not exist
    def no_user
        choice = $prompt.select("That user doesn't exist.", %w("Try again" "Create account"))
        choice == "Try again" ? sign_in : puts "Register"
    end
end

session = Session.new
welcome
user_type = $prompt.select("To start, sign in or create an account:", %w("Sign in" "Create account"))
sign_in_or_register(user_type)



