require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'yaml'
require 'pry'
require 'webmock/rspec'
require_relative '../hparser.rb'

# Disalowing the "real" web access
WebMock.disable_net_connect!(allow_localhost: true)

describe HParser do   
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

    @hparser = HParser.new
  end
  
  after(:each) do
    # clean all yml files from the repo when testing
    Dir.glob(File.expand_path('spec/*.yml')).each {|f| File.delete f}
    Dir.glob(File.expand_path('./*.yml')).each {|f| File.delete f}
  end      

  describe "when parsing the url" do    
    it "should not read any content from an empty url" do
      hcontent = @hparser.get_header_content
      expect(hcontent).to eq("")
    end

    it "should read a head section with a title" do
      hcontent = @hparser.get_header_content 'https://meetyl.com'
      expect(hcontent.to_json).to be == @header_stub.to_json
    end

  end

  describe "when no URL is informed" do
    it "should get the word count json" do
      @hparser.get_header_content 'https://meetyl.com'    
      expect(@hparser.get_word_count).to be == "{\"content-length\":1,\"228148\":1,\"content-type\":1,\"text\":1,\"html\":1,\"charset\":1,\"utf\":1,\"8\":1,\"x-frame-options\":1,\"SAMEORIGIN\":1,\"x-request-guid\":1,\"c9484d02\":1,\"fe11\":1,\"4802\":1,\"a56e\":1,\"da0cef2ea119\":1,\"accept-ranges\":1,\"bytes\":1,\"date\":1,\"Sun\":1,\"21\":2,\"May\":1,\"2017\":1,\"28\":1,\"22\":1,\"GMT\":1}"
    end       
  end    

  describe "when counting words" do
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