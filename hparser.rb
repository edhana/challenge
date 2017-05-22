require 'net/http'
require 'json'
require 'yaml'

# Header parser for the code challenge
class HParser
  WORDS_FILE = File.expand_path('../words.yml', __FILE__)

  def get_header_content(url=nil)
    return '' if url.nil? or url.empty? # TODO: Colocar o processamento das palavras aqui

    # sanitaze the url
    s_url = url.split("://")
    s_url = s_url.last    
    
    header_elements = {}
    http = Net::HTTP.start s_url
    response = http.head('/')
    response.header.each {|k, v| header_elements[k] = v}
    http.finish

    process_words header_elements

    return header_elements
  end

  def process_words(header_hash, dbfile=nil)
    filename = WORDS_FILE
    filename = dbfile if not dbfile.nil?
        
    words = load_from_yaml filename

    # update the hash with word occurrences
    header_hash.each do |i| 
      words[i[0]] = (words[i[0]] ||= 0) + 1
      i[1].split(/[^[[:word:]]]+/).each {|w| words[w] = (words[w] ||= 0) + 1}
    end       

    File.write(filename, words.to_yaml) 
  end    

  def load_from_yaml filename
    begin
      return YAML::load_file(filename)
    rescue 
      return {}
    end    
  end  
end