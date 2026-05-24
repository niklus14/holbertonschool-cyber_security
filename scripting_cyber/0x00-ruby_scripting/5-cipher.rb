#!/usr/bin/env ruby

class CaesarCipher
    def initialize(shift)
      @shift = shift
    end
  
    def encrypt(message)
      cipher(message, @shift)
    end
  
    def decrypt(message)
      cipher(message, -@shift)
    end
  
    private
  
    def cipher(message, shift)
      message.chars.map do |char|
        if char =~ /[A-Za-z]/ # Check if the character is a letter
          base = char.ord < 91 ? 'A'.ord : 'a'.ord # Determine if uppercase or lowercase
          ((char.ord - base + shift) % 26 + base).chr # Shift within A-Z or a-z
        else
          char # Non-alphabet characters remain unchanged
        end
      end.join
    end
  end
  
