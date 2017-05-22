require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'yaml'
require 'pry'
require 'webmock/rspec'

# Disalowing the "real" web access
WebMock.disable_net_connect!(allow_localhost: true)

WORDS_FILE = File.expand_path('../words.yml', __FILE__)

# Header parser for the code challenge
class HParser
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

describe HParser do    
  describe "when parsing the url" do
    before(:each) do
      @header_stub = {"content-length"=>"228148",
          "content-type"=>"text/html; charset=utf-8",
          "x-frame-options"=>"SAMEORIGIN",
          "x-request-guid"=>"c9484d02-fe11-4802-a56e-da0cef2ea119",
          "accept-ranges"=>"bytes",
          "date"=>"Sun, 21 May 2017 21:28:22 GMT"}

      stub_request(:head, "http://meetyl.com/").
         with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: "", headers: @header_stub)
 
      strbody =<<-STR 
      <head>
        <title>test title</title>
        <h1>another test title</h1>
      </head>
      STR
      
      stub_request(:head, "http://gmail.com/").
         with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: "", headers: @header_stub)      
    end
    
    it "should not read any content from an empty url" do
      hcontent = HParser.new.get_header_content
      expect(hcontent).to eq("")
    end

    it "should read a head section with a title" do
      hcontent = HParser.new.get_header_content 'https://meetyl.com'
      expect(hcontent.to_json).to be == @header_stub.to_json
    end

  end

  describe "when no URL is informed" do
    it "should return an error message when word db exists"
    it "should print the word count"      
  end    

  describe "when counting words" do
    before(:each) do
      @hparser = HParser.new
    end

    after(:each) do
      # clean all yml files from the repo
      Dir.glob(File.expand_path('spec/*.yml')).each {|f| File.delete f}
    end      

    let(:input_hash){
      {"content-length"=>"228148",
       "content-type"=>"text/html;"
      }
    }    
    
    it "should return an empty hash for non-existent file" do
      words = @hparser.load_from_yaml("wrongfile")
      expect(words).to be_empty      
    end
    
    it "should load the words hash from file" do      
      words = @hparser.load_from_yaml(
        File.expand_path('../fixtures/words_fixture.yml', __FILE__))

      expect(words).not_to be_nil
      expect(words).not_to be_empty
      expect(words.size).to eq(3)
    end   

    it "should process words from hash" do
      size = @hparser.process_words input_hash, File.expand_path('../tmpwords.yml', __FILE__)
      File.delete(File.expand_path('../tmpwords.yml', __FILE__))
      expect(size).to be > 0            
    end          

    it "should add occurences to existing hash" do
      filename = File.expand_path('../tmpwords.yml', __FILE__)
      hash = {"content-length"=>"228148"}
      @hparser.process_words input_hash, filename
      size = @hparser.process_words hash, filename
      expect(size).to be > 0            

      res = @hparser.load_from_yaml filename
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res["content-length"]).to eq(2)

      File.delete(File.expand_path('../tmpwords.yml', __FILE__))      
    end          
  end
end 