require 'digest'

# 1. Arqumentlərin sayını yoxlayırıq (Dəqiq 2 arqument olmalıdır)
if ARGV.length != 2
  puts "Usage: 10-password_cracked.rb HASHED_PASSWORD DICTIONARY_FILE"
  exit
end

hashed_password = ARGV[0].downcase
dictionary_file = ARGV[1]

# Parolun tapılıb-tapılmadığını izləmək üçün flag
password_found = false

begin
  # 2. Sözlük faylını sətir-sətir oxuyuruq
  File.open(dictionary_file, "r").each_line do |line|
    # Sətrin sonundakı boşluqları və yeni sətir (\n) simvolunu təmizləyirik
    password = line.strip
    
    # Parolun SHA-256 heş dəyərini hesablayırıq
    current_hash = Digest::SHA256.hexdigest(password)

    # 3. Əgər heşlər uyğun gələrsə, parolu çap edib dövrü dayandırırıq
    if current_hash == hashed_password
      puts "Password found: #{password}"
      password_found = true
      break
    end
  end

  # 4. Əgər bütün sözlük bitdisə və parol tapılmadısa
  unless password_found
    puts "Password not found in dictionary."
  end

rescue Errno::ENOENT
  puts "Error: Dictionary file '#{dictionary_file}' not found."
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
