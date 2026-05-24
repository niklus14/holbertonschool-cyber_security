#!/usr/bin/env ruby

require 'net/http'
require 'json'

def get_request(url)
  # Parse the URL
  uri = URI(url)
  
  # Perform the HTTP GET request
  response = Net::HTTP.get_response(uri)
  
  # Extract the status code and status message
  status_code = response.code
  status_message = response.message
  
  # Extract and parse the response body
  response_body = JSON.parse(response.body)
  
  # Print the output in the specified format
  puts "Response status: #{status_code} #{status_message}"
  puts "Response body:"
  puts JSON.pretty_generate(response_body)
end
