#!/usr/bin/ruby

class Dicegen
  def initialize file_name
    parse_wordlist file_name
  end

  def parse_wordlist file_name
    @word_list ||= []
    state = :start
    File.open(file_name).each do |line|
      next if /^\W*$/.match line
      case state
      when :start
        if /^-----BEGIN PGP SIGNED MESSAGE-----$/.match line
          state = :body
        else
          self.class.syntax_error line
        end
      when :body
        parts = /^(\d{5})\W+([^ \t\n]+)$/.match line
        if !parts.nil? && parts.size == 3
          @word_list[parts[1].to_i] = parts[2]
        elsif /^-----BEGIN PGP SIGNATURE-----$/.match line
          break
        end
      end
    end
  end

  def self.syntax_error line
    puts "Unexpected line in word list: '#{line}'"
    nil
  end

  def roll_word
    roll = 0
    (1..5).each do |i|
      roll *= 10
      roll += Random.rand(6) + 1
    end
    result = { :roll => roll,
               :word => @word_list[roll] }
    roll_word if result[:word].nil?
    result
  end

  def roll_phrase count
    phrase = []
    (1..count).each do
      phrase << roll_word
    end
    phrase
  end

  def self.usage_error cmd_name, argv
    puts "Usage: #{cmd_name} FILE COUNT"
    exit 1
  end

  def self.main argv
    usage_error($0, ARGV) unless argv.length == 2 and /^\d+$/.match(argv[1])
    gen = Dicegen.new(argv[0])
    roll_strings = []
    word_strings = []
    phrase = gen.roll_phrase(argv[1].to_i)
    (0..phrase.length-1).each do |i|
      roll = phrase[i][:roll].to_s
      word = phrase[i][:word]
      next if word.nil?
      width = word.length > roll.length ? word.length : roll.length
      roll_strings << sprintf("%#{width}s", roll)
      word_strings << sprintf("%#{width}s", word)
    end
    puts roll_strings.join(' ')
    puts word_strings.join(' ')
    exit 0
  end
end

Dicegen.main ARGV
