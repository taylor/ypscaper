require 'rubygems'
require 'mechanize'

class YPProvider
  attr_reader :name
  attr_accessor :uri, :search_path,
    :sk, # search key
    :lk  # location key
  def initialize(name, uri, sp, sk, lk)
    @name = name
    @uri, @search_path, @sk, @lk = uri, sp, sk, lk
    # @provider = {
    #   :superpages => { :uri => 'http://yellowpages.superpages.com', :search_path => 'listings.jsp', :sk => 'C', :lk => 'L' },
    #   :switchboard => { :uri => 'http://www.switchboard.com', :search_path => 'results.htm', :sk => 'KW', :lk => 'LO' },
    #   :yellowpages => { :uri => 'http://www.yellowpages.com', :search_path => 'categories/', :lk => '-' }
    # }
  end

end

class YPScraper
  attr_reader :default_provider
  attr_accessor :providers, :current_provider
  
  def initialize(provider=nil)
    @default_provider = provider || :superpages

    @providers = {}

    { :superpages => { :uri => 'http://yellowpages.superpages.com', :search_path => 'listings.jsp', :sk => 'C', :lk => 'L' },
      :switchboard => { :uri => 'http://www.switchboard.com', :search_path => 'results.htm', :sk => 'KW', :lk => 'LO' },
      :yellowpages => { :uri => 'http://www.yellowpages.com', :search_path => 'categories/', :lk => '-' }
    }.each_pair do |name,p|
      @providers[name] = YPProvider.new(name, p[:uri], p[:search_path], p[:sk], p[:lk])
    end

    @current_provider = @default_provider
  end

  def provider(n=@current_provider)
    @providers[n]
  end

  def add_provider(name, uri, sp, sk, lk)
      @providers[name] =  YPProvider.new(name, uri, sp, sk, lk)
  end

  def search(keyword, location)
  end

  # switchboard
  # results.htm?cid=&MEM=1&ypcobrand=1&PR=&ST=&inputwhat_dirty=1&KW=dentist&initial=&inputwhere_dirty=1&LO=austin%2C+tx&SD=-1&search.x=0&search.y=0&search=Search&semChannelId=&semSessionId
  # superpages
  # http://yellowpages.superpages.com/listings.jsp?CS=L&MCBP=true&search=Find+It&SRC=&C=dentist&STYPE=S&L=austin%2Ctx&x=0&y=0
  # yellow pages
  # location is CITY-STATE where City starts with a capital letter and State is the abberviation
end

