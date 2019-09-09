#require_relative '../config/environment'
require 'tty-prompt'
require 'pry'

$prompt = TTY::Prompt.new

def welcome
    puts "Welcome to Skyscourer ✈️"
    puts "The flight booking service similar to, but legally distinct from, Skyscanner"
end

def sign_in_or_register(user_type)
    if user_type == "Sign in"
        sign_in
    elsif user_type == "Create account"
        #create_account
    end
end

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
    if User.exists?(email: email, password: password)
        puts "create_session"
    else  
        no_user
end

def no_user
    choice = $prompt.select("That user doesn't exist.", %w("Try again" "Create account"))
    choice == "Try again" ? sign_in : puts "Register"
end

welcome
user_type = $prompt.select("To start, sign in or create an account:", %w("Sign in" "Create account"))
sign_in_or_register(user_type)



