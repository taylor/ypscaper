require 'rubygems'
require 'mechanize'

class YPScraper
  attr_reader :default_provider
  attr_accessor :provider, :current_provider
  
  def initialize(provider=nil)
    @default_provider = provider || :superpages
    @provider = {
      :superpages => { :uri => 'http://yellowpages.superpages.com', :search_path => 'listings.jsp', :sk => 'C', :lk => 'L' },
      :switchboard => { :uri => 'http://www.switchboard.com', :search_path => 'results.htm', :sk => 'KW', :lk => 'LO' },
      :yellowpages => { :uri => 'http://www.yellowpages.com', :search_path => 'categories/', :lk => '-' }
    }

    @current_provider = @default_provider
  end

  def search(keyword, location)
  end

  # switchboard
  # results.htm?cid=&MEM=1&ypcobrand=1&PR=&ST=&inputwhat_dirty=1&KW=dentist&initial=&inputwhere_dirty=1&LO=austin%2C+tx&SD=-1&search.x=0&search.y=0&search=Search&semChannelId=&semSessionId
  # superpages
  # http://yellowpages.superpages.com/listings.jsp?CS=L&MCBP=true&search=Find+It&SRC=&C=dentist&STYPE=S&L=austin%2Ctx&x=0&y=0
end

