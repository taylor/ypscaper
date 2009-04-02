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

  it "should have a default provider of yellowpages if yellowpages is specified when creating a new YP object" do
    yp = YPScraper.new(:yellowpages)
    yp.default_provider.should == :yellowpages
  end

  it "should be able to access the uri for the default provider via the provider method and receive a valid response" do
    @yp.provider.uri.should == "http://www.switchboard.com"
  end

  it "should be able to access the uri for superpages when super pages is passed to the provider method" do
    @yp.provider(:superpages).uri.should == 'http://yellowpages.superpages.com'
  end

  it "should be able to add new providers" do
    @yp.add_provider(:foo, 'http://foo.com', 'sp', 'sk', 'location')
    @yp.provider(:foo).uri.should == 'http://foo.com'
  end

  it "should have a default path set for provider switchboard" do
    @yp.provider(:switchboard).search_path.should == "results.htm"
  end

  it "should have a keyword identifier of 'KW' for provider switchboard" do
    @yp.provider(:switchboard).sk.should == "KW"
  end


  it "should have a location identifier of 'LO' for provider switchboard" do
    @yp.provider(:switchboard).lk.should == "LO"
  end

  # FIXME: use mock/stub instead of actuall call possibly
  it "should be able to get a url and show the title for that page" do
    @yp.get_page(@yp.provider(:switchboard).uri).title.should == 'Yellow Pages, White Pages, Maps, and more - Switchboard.com'
  end

  it "should be able to set default provider for searching and other methods" do
    @yp.set_provider(:superpages).should == true
    @yp.default_provider.should == :superpages
  end

  it "should return false and not change default provider if provider specified for set_provider is not found" do
    @yp.set_provider(:invalid_provider).should == false
    @yp.default_provider.should == :switchboard
  end


  it "should be able to search and get valid title for page" do
    @yp.search("dentist", "austin, tx").title.should == "dentist in Austin, TX - Yellow Pages - Switchboard.com"
  end

  #@yp.provider[:switchboard][:search_path].should == "results.htm?KW=dentist&LO=austin%2C+tx"
end
