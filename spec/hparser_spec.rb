require 'nokogiri'
require 'open-uri'
require 'json'
require 'yaml'
require 'pry'

WORDS_FILE = File.expand_path('../words.yml', __FILE__)

# Header parser for the code challenge
class HParser
  def get_header_content(url=nil)
    return '' if url.nil? or url.empty?

    doc = Nokogiri::HTML(open("https://meetyl.com/"))
    return '' if doc.nil?

    read_tag = doc.xpath("//head")
    return '' if read_tag.empty?

    header = read_tag[0]
    res = {}

    header.children.each do |c|
      res["#{c.name}"] =  "#{c.children.first}" if not c.children.nil? and not c.children.empty?
    end
      
    process_words res

    return res
  end

  def process_words(header_hash, dbfile=nil)
    filename = WORDS_FILE
    filename = dbfile if not dbfile.nil?
        
    words = load_from_yaml filename

    # update the hash with word occurrences
    header_hash.each do |i|
      words[i[0]] = words[i[0]].nil? ? i[1] : words[i[0]] + i[1]
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
    it "should read a parser" do
      hcontent = HParser.new.get_header_content
      expect(hcontent).to eq("")
    end

    # Functional??? TODO: Mock the web access -- Webmock
    it "should read a parser" do
      hcontent = HParser.new.get_header_content 'https://meetyl.com/'
      expect(hcontent.to_json).to be == "{\"title\":\"Meetyl\"}"
    end
  end

  describe "when counting words" do
    before(:each) do
      @hparser = HParser.new
    end

    after(:each) do
      # clean all yml files from the repo
      Dir.glob(File.expand_path('spec/*.yml')).each {|f| puts "Deleting: #{f} : #{File.delete f}"}
    end      

    let(:input_hash){
      {"h1" => 1,
      "h2" => 1,
      "h3" => 1
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
      hash = {}
      hash["h2"] = 1
      @hparser.process_words input_hash, filename
      size = @hparser.process_words hash, filename
      expect(size).to be > 0            

      res = @hparser.load_from_yaml filename
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res["h2"]).to eq(2)

      File.delete(File.expand_path('../tmpwords.yml', __FILE__))      
    end          
  end
end 