require 'myconfig'
include MyConfig
require 'ypscraper'

describe YPScraper do
  before(:all) do
    @s = MyConfig.settings
    # FIXME: validate cached web pages for testing are less than 1 day old
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
    # yp = YPScraper.new
    # yp.expects(:get_page).with(@yp.provider(:switchboard).uri).title.returns('Yellow Pages, White Pages, Maps, and more - Switchboard.com')
    # yp.get_page(@yp.provider(:switchboard).uri).title.should == 'Yellow Pages, White Pages, Maps, and more - Switchboard.com'
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

  it "should return an empty list for an search that finds no results" do
    @yp.search("random search stuff", "austin", "tx").should == []
  end

  it "should have 10 or more items in results for default search" do
    @yp.search("dentist", "austin", "tx").size.should >= 10
  end

  it "should have 20 items found when specifying 20 items and search finds 20 or more items" do
    @yp.search("dentist", "austin", "tx" , :num_results=>20).size.should >= 20
  end

  it "should have a valid name for the 1st search result" do
    @yp.search("dentist", "austin", "tx")[0].name.should match(/Avery/)
  end

  it "should have a valid address for results with addresses" do
    @yp.search("dentist", "austin", "tx")[0].address.should == '12171 West Parmer Lane'
  end

  it "should have a valid phone number for results with phone numbers" do
    @yp.search("dentist", "austin", "tx")[0].phone.should == '(512) 260-0084'
  end

  it "should have a valid email for results with email addresses" do
    @yp.search("dentist", "austin", "tx")[0].email.should == 'averyortho@gmail.com'
  end

  it "should have a valid website address for results with a website" do
    @yp.search("dentist", "austin", "tx")[1].url.should == 'www.DoctorGarza.com'
  end
end
