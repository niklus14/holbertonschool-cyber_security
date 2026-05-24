require 'open-uri'
require 'uri'
require 'fileutils'

def download_file(url, local_path)
  # Validate URL
  begin
    uri = URI.parse(url)
    raise "Invalid URL" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue => e
    puts "Error: #{e.message}"
    return
  end

  # Ensure the directory for the local file exists
  FileUtils.mkdir_p(File.dirname(local_path))

  puts "Downloading file from #{url}..."
  begin
    URI.open(url) do |file|
      File.open(local_path, 'wb') do |local_file|
        local_file.write(file.read)
      end
    end
    puts "File downloaded and saved to #{local_path}."
  rescue => e
    puts "Error downloading file: #{e.message}"
  end
end

# Main script execution
if ARGV.length != 2
  puts "Usage: #{File.basename(__FILE__)} URL LOCAL_FILE_PATH"
else
  url = ARGV[0]
  local_path = ARGV[1]
  download_file(url, local_path)
end
