class Search
  attr_reader :origin_code, :destination_code, :outbound_date, :inbound_date, :cabin_class

  #Sets the maximum number of results returned by any search
  @@max_results = 5

  ###### Instance methods ######

  def initialize(origin_code:, destination_code:, outbound_date:, inbound_date: "", cabin_class:)
    @origin_code = origin_code
    @destination_code = destination_code
    @outbound_date = outbound_date
    @inbound_date = inbound_date
    @cabin_class = cabin_class
  end
  
  def run_search
    #Run the search and return an array of unique flight hashes, cheapest first
    #Establish a Skyscanner session
    begin
      @session = Timeout::timeout(10) { create_session }
    rescue Timeout::Error
      return nil
    end
    # Extracts the session key from the HTTP POST response
    get_key
    # Polls Skyscanner session until results status is "UpdatesCompleted"
    begin
      Timeout::timeout(60) { get_search_results }
    rescue Timeout::Error
      return nil
    end
    # Checks search results are valid
    return nil if !search_results_valid?
    # Return unique flights up to the Search class @@max_results limit
    flights = unique_flights(create_flights)
    flights.length > @@max_results ? flights.slice(0...@@max_results) : flights
  end


  private

  def create_session()
    # POST method: create a Skyscanner session with search parameters
    response = Unirest.post(
      "https://skyscanner-skyscanner-flight-search-v1.p.rapidapi.com/apiservices/pricing/v1.0",
      headers:{
        "X-RapidAPI-Host" => "skyscanner-skyscanner-flight-search-v1.p.rapidapi.com",
        "X-RapidAPI-Key" => "c036ae2334msh6e52f9287ee7e7ap1fbff8jsnb8c6fa5b89b5",
        "Content-Type" => "application/x-www-form-urlencoded"
      },
      parameters:{
        "inboundDate" => self.inbound_date,
        "cabinClass" => self.cabin_class,
        "children" => 0,
        "infants" => 0,
        "country" => "UK",
        "currency" => "GBP",
        "locale" => "en-US",
        "originPlace" => self.origin_code,
        "destinationPlace" => self.destination_code,
        "outboundDate" => self.outbound_date,
        "adults" => 1
      }
    )
    # Attempts to create sessions until 201 response or function times out
    response.code == 201 ? response : create_session()
  end

  def get_key
    # Extract the session key (string) from the raw POST response
    session_url = @session.headers[:location]
    @session_key = session_url.split("/").last
  end

  def get_search_results
    # Poll the session results, converts them to a hash, and saves it to the search_results instance variable
    raw_results = Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.rapidapi.com/apiservices/pricing/uk2/v1.0/#{@session_key}?sortType=price&sortOrder=asc&pageIndex=0&pageSize=10",
    headers:{
      "X-RapidAPI-Host" => "skyscanner-skyscanner-flight-search-v1.p.rapidapi.com",
      "X-RapidAPI-Key" => "c036ae2334msh6e52f9287ee7e7ap1fbff8jsnb8c6fa5b89b5"
    })
    # Generate search_results hash from XML response
    @search_results = Hash.from_xml(raw_results.body)
    # Run get_search_results until Skyscanner response status is "UpdatesComplete"
    get_search_results if @search_results["PollSessionResponseDto"]["Status"] != "UpdatesComplete"
  end

  def search_results_valid?
    @search_results["PollSessionResponseDto"]["Itineraries"]
  end


  def create_flights
    # Creates an array of all the flights that are queried by the API
    flights = create_itineraries
    add_departure_and_arrival_time(flights)
    add_departure_and_arrival_airport(flights)
    flights
  end

  def create_itineraries
    # Creates a flight object hash for each flight queried by the API, then associates a flight_id and price with that flight object
    get_itineraries.each_with_object([]) do | itin, array |
      flight = {}
      flight["flight_id"] = itin["OutboundLegId"]
    # Check whether itinerary contains multiple pricing options before attempting to access them
      if itin["PricingOptions"]["PricingOptionApiDto"].is_a?(Array)
        flight["price"] = itin["PricingOptions"]["PricingOptionApiDto"][0]["Price"]
      else
        flight["price"] = itin["PricingOptions"]["PricingOptionApiDto"]["Price"]
      end

      array << flight
    end
  end

  def add_departure_and_arrival_time(flights)
    # Gives each flight an associated departure and arrival time using the Skyscanner "Legs" attribute
    flights.each do |flight|
      matching_leg = get_legs.find { | leg | leg["Id"] == flight["flight_id"] }
      flight["departure_time"] = matching_leg["Departure"]
      flight["arrival_time"] = matching_leg["Arrival"]
    end
  end

  def add_departure_and_arrival_airport(flights)
    # Adds in the departure and arrival airport codes and names using the Skyscanner "Places" attribute
    flights.each do |flight|
      matching_leg = get_legs.find { | leg | leg["Id"] == flight["flight_id"] }
      # Matches the leg to the relevant airport, and extracts their names and codes
      origin_airport = find_airport_details(matching_leg["OriginStation"])
      destination_airport = find_airport_details(matching_leg["DestinationStation"])
      flight["origin_code"] = origin_airport["Code"]
      flight["destination_code"] = destination_airport["Code"]
      flight["origin"] = origin_airport["Name"]
      flight["destination"] = destination_airport["Name"]
    end
  end

  def find_airport_details(airport_id)
    # Returns the information about an airport using its Skyscanner OriginStation ID
    get_airports.find { |airport| airport["Id"] == airport_id }
  end

  def get_itineraries
    # Extracts the array of itineraries from the search results
      @search_results["PollSessionResponseDto"]["Itineraries"]["ItineraryApiDto"]
  end
  
  def get_legs
    # Extracts the array of legs from the search results
    @search_results["PollSessionResponseDto"]["Legs"]["ItineraryLegApiDto"]
  end

  def get_airports
    # Extract the array of airports from the search results
    @search_results["PollSessionResponseDto"]["Places"]["PlaceApiDto"]
  end

  
  def unique_flights(flights)
    # Takes in a array of flights and returns a new array without the duplicates
    flights.uniq { | flight | flight["arrival_time"] && flight["departure_time"] }
  end

  ###### Class methods ######

  def self.get_airport_from_city(city)
    # Return the first skyscanner airport code that matches the given city name
    places_hash = airport_names_api_request(city)

    if !places_hash["AutoSuggestServiceResponseApiDto"]["Places"]
      return nil
    elsif places_hash["AutoSuggestServiceResponseApiDto"]["Places"]["PlaceDto"].is_a?(Array)
      return places_hash["AutoSuggestServiceResponseApiDto"]["Places"]["PlaceDto"][0]["PlaceId"]
    else
      places_hash["AutoSuggestServiceResponseApiDto"]["Places"]["PlaceDto"]["PlaceId"]
    end
  end

  def self.airport_names_api_request(city)
    response = Unirest.get("https://skyscanner-skyscanner-flight-search-v1.p.rapidapi.com/apiservices/autosuggest/v1.0/UK/GBP/en-GB/?query=#{city}",
      headers:{
        "X-RapidAPI-Host" => "skyscanner-skyscanner-flight-search-v1.p.rapidapi.com",
        "X-RapidAPI-Key" => "407d1ed52amsh672332be486dc02p1be71fjsn7639b4ef4b82"
      })
    Hash.from_xml(response.body)
  end

end