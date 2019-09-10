#Unirest is  a set of lightweight HTTP libraries that allow GET, POST, PUT, PATCH and DELETE requests
require 'unirest'
require 'pry'
require 'JSON'
require 'active_support/core_ext/hash'


class Search
  attr_reader :origin, :destination, :outbound_date, :inbound_date

  @@max_results = 5

  ###### Instance methods ######

  def initialize(origin:, destination:, outbound_date:, inbound_date: "")
    @origin = origin
    @destination = destination
    @outbound_date = outbound_date
    @inbound_date = inbound_date
    @search_results = nil
    Unirest.timeout(30)
  end

  #Run the search and return an array of unique flight hashes
  def run_search
    session = create_session
    #binding.pry
    return "Search timed out. Please try again." if !session
    session_key = get_key(session)
    get_search_results(session_key)
    return "Search timed out. Please try again." if !@search_results
    flights = cheapest_unique_flights(create_flights)
    #Limit the number of results returned
    flights.length > @@max_results ? flights.slice(0...@@max_results) : flights
  end


  private

  #POST method: create a Skyscanner session with search parameters
  def create_session()
    begin
      response = Unirest.post(
        "https://skyscanner-skyscanner-flight-search-v1.p.rapidapi.com/apiservices/pricing/v1.0",
        headers:{
          "X-RapidAPI-Host" => "skyscanner-skyscanner-flight-search-v1.p.rapidapi.com",
          "X-RapidAPI-Key" => "c036ae2334msh6e52f9287ee7e7ap1fbff8jsnb8c6fa5b89b5",
          "Content-Type" => "application/x-www-form-urlencoded"
        },
        parameters:{
          "inboundDate" => self.inbound_date,
          "cabinClass" => "economy",
          "children" => 0,
          "infants" => 0,
          "country" => "UK",
          "currency" => "GBP",
          "locale" => "en-US",
          "originPlace" => self.origin,
          "destinationPlace" => self.destination,
          "outboundDate" => self.outbound_date,
          "adults" => 1
        }
      )
    rescue RuntimeError
      return nil
    end
    #Call create_session until the response is valid
    #NEED TO CREATE TIMEOUT!!
    valid_response?(response) ? response : create_session()
  end

  #Check that the POST method HTTPResponse header contains a valid :location
  def valid_response?(response)
    ##! What other ways could we check a valid response?
    response.headers[:location]
  end

  #Extract the session key (string) from the raw POST response
  def get_key(session)
    session_url = session.headers[:location]
    session_url.split("/").last
  end

  #Poll the session results and save them to the search_results instance variable
  def get_search_results(session_key)
    begin
      raw_results = Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.rapidapi.com/apiservices/pricing/uk2/v1.0/#{session_key}?sortType=price&sortOrder=asc&stops=0&pageIndex=0&pageSize=10",
      headers:{
        "X-RapidAPI-Host" => "skyscanner-skyscanner-flight-search-v1.p.rapidapi.com",
        "X-RapidAPI-Key" => "c036ae2334msh6e52f9287ee7e7ap1fbff8jsnb8c6fa5b89b5"
      })
    rescue RuntimeError
      return nil
    end

    #Generate search_results hash from XML response
    @search_results = Hash.from_xml(raw_results.body)
    binding.pry
  end

  def create_flights
    all_flights = get_itineraries.each do | itin |
      matching_leg = get_legs.find { | leg | leg["Id"] == itin["flight_id"] }
      #needs to create m
      itin["departure_time"] = matching_leg["Departure"]
      itin["arrival_time"] = matching_leg["Arrival"]
    end
  end

  #Extract itineraries from search results hash
  def get_itineraries
    itin_array = @search_results["PollSessionResponseDto"]["Itineraries"]["ItineraryApiDto"]
    itin_array.each_with_object([]) do | itin, array |
      flight = {}
      flight["flight_id"] = itin["OutboundLegId"]

      if itin["PricingOptions"]["PricingOptionApiDto"].is_a?(Array)
        flight["price"] = itin["PricingOptions"]["PricingOptionApiDto"][0]["Price"]
      else
        flight["price"] = itin["PricingOptions"]["PricingOptionApiDto"]["Price"]
      end

      array << flight
    end
  end

  #Return an array of legs that match an itinerary (departure time data)
  def get_legs
    @search_results["PollSessionResponseDto"]["Legs"]["ItineraryLegApiDto"]
  end

  def get_airports
    @search_results["PollSessionResponseDto"]["Places"]["PlaceApiDto"]
  end

  #Takes in a list of flights and returns the cheapest flight for each arrival time
  def cheapest_unique_flights(flights)
    flights.uniq { | flight | flight["arrival_time"] }
  end

  ###### Class methods ######

  #Return the first skyscanner airport code from a city name
  def self.get_airport_from_city(city)
    response = Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.rapidapi.com/apiservices/autosuggest/v1.0/UK/GBP/en-GB/?query=#{city}",
    headers:{
      "X-RapidAPI-Host" => "skyscanner-skyscanner-flight-search-v1.p.rapidapi.com",
      "X-RapidAPI-Key" => "407d1ed52amsh672332be486dc02p1be71fjsn7639b4ef4b82"
    })
    places_hash = Hash.from_xml(response.body)

    if !places_hash["AutoSuggestServiceResponseApiDto"]["Places"]
      return nil
    elsif places_hash["AutoSuggestServiceResponseApiDto"]["Places"]["PlaceDto"].is_a?(Array)
      return places_hash["AutoSuggestServiceResponseApiDto"]["Places"]["PlaceDto"][0]["PlaceId"]
    else
      places_hash["AutoSuggestServiceResponseApiDto"]["Places"]["PlaceDto"]["PlaceId"]
    end
  end

<<<<<<< HEAD
end

search1 = Search.new("LOND-sky", "SFO-sky", "2020-01-10")
puts search1.run_search
puts search = Search.get_airport_from_city("London")
0
=======
end
>>>>>>> 322fabb36a051f1b957ef53a33d0ee86aa86d110
