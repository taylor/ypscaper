require 'myconfig'
include MyConfig
require 'ypscraper'

describe YPScraper do
  before(:all) do
    @s = MyConfig.settings
    #@yp = YPScraper.new
  end

  it "should go have a default URI to use if no specific yellow page provider is selected" do
    p "Showing default yellow page provider URI"
    @yp = YPScraper.new
    @yp.uri.to_s.shold != nil
  end
end
