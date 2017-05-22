#!/usr/local/bin/ruby
require_relative "./hparser.rb"

if __FILE__ == $0
  if ARGV[0].nil? or ARGV[0].empty?
    puts "Printing the word cound JSON ..."
    puts HParser.new.get_word_count
  else
    puts "Retrieving header data from #{ARGV[0]} ..."
    hparser = HParser.new
    puts "Header data from url(#{ARGV[0]}): #{hparser.get_header_content ARGV[0]}"
    puts "Data saved on file #{HParser::WORDS_FILE}"
  end
end