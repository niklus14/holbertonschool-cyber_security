require 'net/http'
require 'uri'
require 'json'

def post_request(url, body_params = {})
  # 1. URL-i analiz edirik
  uri = URI.parse(url)

  # 2. HTTP POST sorğusunu hazırlayırıq
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = body_params.to_json

  # 3. Sorğunu göndəririk
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  # 4. Tapşırıqdakı formata uyğun olaraq nəticəni çap edirik
  puts "Response status: #{response.code} #{response.message}"
  puts "Response body:"
  puts response.body
rescue StandardError => e
  puts "Xəta baş verdi: #{e.message}"
end
