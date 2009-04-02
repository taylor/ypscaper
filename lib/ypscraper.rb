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
  attr_reader :default_provider, :providers
  attr_accessor :agent
  protected :agent

  def initialize(provider=nil, proxy_host=nil, proxy_port=nil)
    @agent = WWW::Mechanize.new

    if not (proxy_host.nil? or proxy_port.nil?)
      @agent.set_proxy(proxy_host, proxy_port)
    end

    @agent.user_agent_alias = 'Mac Safari'

    @default_provider = provider || :superpages
    @current_provider = @default_provider

    @providers = {}
    { :superpages => { :uri => 'http://yellowpages.superpages.com', :search_path => 'listings.jsp', :sk => 'C', :lk => 'L' },
      :switchboard => { :uri => 'http://www.switchboard.com', :search_path => 'results.htm', :sk => 'KW', :lk => 'LO' },
      :yellowpages => { :uri => 'http://www.yellowpages.com', :search_path => 'categories/', :lk => '-' }
    }.each_pair do |name,p|
      @providers[name] = YPProvider.new(name, p[:uri], p[:search_path], p[:sk], p[:lk])
    end
  end

  def provider(n=@current_provider)
    @providers[n]
  end

  def add_provider(name, uri, sp, sk, lk)
    @providers[name] =  YPProvider.new(name, uri, sp, sk, lk)
  end

  def default_provider=(name=nil)
    set_provider(name)
  end

  def set_provider(name=nil)
    if @providers[name].nil?
      false
    else
      @default_provider = name
      true
    end
  end

  def search(keyword, city, state, name=@default_provider)
    if @providers[name].nil?
      return nil
    end

    p=@providers[name]

    case p.lk
    when '-'
      location = "#{city.capitalize}-#{state.upcase}"
    else
      location = "#{city.capitalize}, #{state.upcase}"
    end

    url = "#{p.uri}/#{p.search_path}?#{p.sk}=#{keyword}&#{p.lk}=#{location}"
    #get_page(url)
    false
  end

  def get_page(url)
    page=nil
    maxtries=5
    r=0
    loop do
      page = @agent.get(url)
      r+=1
      break unless page.nil? or r >= maxtries
    end
    page
  end



  # switchboard
  # http://www.switchboard.com/results.htm?KW=dentist&LO=austin%2C+tx
  #
  # superpages
  # http://yellowpages.superpages.com/listings.jsp?CS=L&MCBP=true&search=Find+It&SRC=&C=dentist&STYPE=S&L=austin%2Ctx&x=0&y=0
  #
  # yellow pages
  # http://www.yellowpages.com/categories/Austin-TX/dentist
  # location is CITY-STATE where City starts with a capital letter and State is the abberviation
end

