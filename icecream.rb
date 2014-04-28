require 'rest-client'
require 'json'
require 'addressable/uri'
require 'nokogiri'

class IceCreamFinder
  GOOGLE_API_KEY = "ENTER_YOUR_KEY_HERE"
  
  def initialize
    run
  end
  
  def run 
    puts "What is your current address?"
    curr_address = gets.chomp
    start_loc = get_start_loc(curr_address)
    
    all_places = get_places(start_loc)
    
    dest_loc = select_destination(all_places)
    give_directions(start_loc, dest_loc)
  end
  
  def get_start_loc(curr_address)
    url_loc = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "/maps/api/geocode/json",
      :query_values => {:address => curr_address,
                        :sensor => false}).to_s

    response_loc = RestClient.get(url_loc)
    start_loc = JSON.parse(response_loc)
    start_loc["results"][0]["geometry"]["location"].values_at("lat", "lng")
  end

  def get_places(start_loc)
    start_lat, start_lng = start_loc
    url = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "/maps/api/place/nearbysearch/json",
      :query_values => {:key => GOOGLE_API_KEY,
                        :location => "#{start_lat}, #{start_lng}",
                        :rankby => :distance,
                        :keyword => 'ice cream',
                        :sensor => false}).to_s

    response = RestClient.get(url)
    places = JSON.parse(response)

    all_places = []
    places["results"].each_index do |idx|
      all_places << [places["results"][idx]["name"],
      places["results"][idx]["geometry"]["location"].values_at("lat", "lng")]
    end
    
    all_places
  end

  def select_destination(all_places)
    puts "Please select where you'd like to go:"
    
    all_places.each_index do |idx|
      puts "[#{idx}] #{all_places[idx].first}"
    end

    destination_idx = gets.chomp.to_i
    all_places[destination_idx][1]
  end

  def give_directions(start_loc, dest_loc)
    start_lat, start_lng = start_loc
    dest_lat, dest_lng = dest_loc
    
    url_directions = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "/maps/api/directions/json",
      :query_values => {:origin => "#{start_lat}, #{start_lng}",
                        :destination => "#{dest_lat}, #{dest_lng}",
                        :sensor => false
                        }).to_s

    response_directions = RestClient.get(url_directions)
    directions = JSON.parse(response_directions)

    html_directions = directions["routes"][0]["legs"][0]["steps"].each do |step|
      puts Nokogiri::HTML(step["html_instructions"]).text + ". "
    end
  end
end

IceCreamFinder.new