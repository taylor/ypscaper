require 'myconfig'
include MyConfig
require 'ypscraper'

describe YPScraper do
  before(:all) do
    @s = MyConfig.settings
  end

  before(:each) do
    @yp = YPScraper.new(:switchboard)
  end

  it "should have a default provider if no specific provider is specified" do
    yp = YPScraper.new
    yp.default_provider.should_not == nil
  end

  it "should have a provider switchboad set if switchboard is specified when creating a new YP object" do
    @yp.default_provider.should == :switchboard
  end

  it "should have a valid url for provider switchboard" do
    @yp.provider[:switchboard][:uri].should == 'http://www.switchboard.com'
  end

  it "should have a default path set for provider switchboard" do
    @yp.provider[:switchboard][:search_path].should == "results.htm"
  end

  it "should have a keyword identifier of 'KW' for provider switchboard" do
    @yp.provider[:switchboard][:sk].should == "KW"
  end


  it "should have a location identifier of 'LO' for provider switchboard" do
    @yp.provider[:switchboard][:lk].should == "LO"
  end

  it "should be able to get a page using mechanize if a url is given for get_page" do
    @yp.get_page(@yp.provider[@yp.default_provider][:uri]).title.should == 'foo'
  end

  it "should have a valid title set when for provider switchboard" do
    @yp = YPScraper.new(:switchboard)
    @yp.search("dentist", "austin, tx").title.should == "dentist in Austin, TX - Yellow Pages - Switchboard.com"
  end

    #@yp.provider[:switchboard][:search_path].should == "results.htm?KW=dentist&LO=austin%2C+tx"
end
