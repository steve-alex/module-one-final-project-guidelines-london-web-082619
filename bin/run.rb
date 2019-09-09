#require_relative '../config/environment'
require 'tty-prompt'

$prompt = TTY::Prompt.new

def welcome
    puts "Welcome to Skyscourer ✈️"
    puts "The fight booking service similar to, but legally distinct from, Skyscanner"
end

def sign_in
    $prompt.select("To start, sign in or create an account:", %w(Sign\ in "Create\ account))
end

welcome
sign_in
