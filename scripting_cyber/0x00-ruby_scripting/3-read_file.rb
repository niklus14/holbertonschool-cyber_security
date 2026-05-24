require 'json'

def count_user_ids(path)
  file_content = File.read(path)
  data = JSON.parse(file_content)

  counts = Hash.new(0)

  data.each do |item|
    if item['userId']
      counts[item['userId']] += 1
    end
  end

  counts.each do |user_id, count|
    puts "#{user_id}: #{count}"
  end
rescue Errno::ENOENT
  puts "Xəta: #{path} faylı tapılmadı!"
rescue JSON::ParserError
  puts "Xəta: Fayl düzgün JSON formatında deyil!"
end
