require 'rubygems'
require 'mechanize'
require 'uri'

class YPProvider
  attr_reader :name
  attr_accessor :uri, :search_path,
    :sk, # search key
    :lk  # location key
  def initialize(name, uri, sp, sk, lk)
    @name = name
    @uri, @search_path, @sk, @lk = uri, sp, sk, lk
  end
end

class YPResult
  attr_accessor :url, :name, :phone, :address, :email, :provider
  def initialize(name, phone, address, url, email, provider=nil)
    @url, @name, @phone, @address, @email = url, name, phone, address, email
    @provider = provider
  end
end

class YPScraper
  attr_reader :default_provider, :providers
  attr_accessor :agent, :city, :state
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

  def search(keyword, city, state, opts={})
    page        = nil
    name        = opts[:provider] || @default_provider
    num_results = opts[:num_results] || 10
    url = nil

    if @providers[name].nil?
      return nil
    end

    if num_results.class != Fixnum and num_results != :all
      raise ArgumentError, "num results should be a Fixnum or :all"
    end

    p=@providers[name]

    p p.name
    case p.name
    when :yellowpages
      location = "#{city.capitalize}-#{state.upcase}"
      url = "#{p.uri}/#{p.search_path}?#{p.sk}#{location}/#{keyword}"
    else
      location = URI.escape("#{city.capitalize},#{state.upcase}")
      url = "#{p.uri}/#{p.search_path}?#{p.sk}=#{keyword}&#{p.lk}=#{location}"
    end

    #url = 'http://www.switchboard.com/results.htm?KW=dentist&LO=Austin%2CTX&R=&SD=&PARMAPI=SRC%3Dswitchboard2%26sessionId%3DFD6061260DCE4E9E5BE4D8B75AF429D2%26C%3Ddentist%26PS%3D10%26STYPE%3DS%26L%3DAustin%2BTX%26XSL%3Doff%26EG%3D2%26paging%3D1%26PBL%3Dtrue%26PI%3D10'
    p url

    page = get_page(url)

    results=[]

    parse_results = lambda do |r,i|
      n=nil
      p n
      n=r.search("span[@class='name ']").text
      n=r.search("span[@class='name idearc_red idearc_font_large']").text if n.empty?
      n=r.search("span[@class='name idearc_red idearc_font_large idearc_font_italic']").text if n.empty?

      results << YPResult.new(n, nil, nil, nil, nil, @default_provider) if not n.empty?
      puts "nothing found for row #{i}" if n.nil?
    end

    # FIXME: results will be out of order from what is on page
    #page.search("//div[@class='body']")
    #
    # page.search("//div[regex(., 'ad\s.*')]", Class.new {
    #   def regex node_set, regex
    #     node_set.find_all { |node| node['class'] =~ /#{regex}/ }
    #   end
    # }.new).each_with_index {|r,i| parse_results.call(r,i) }

    page.search("//div[@class='ad ']").each_with_index {|r,i| parse_results.call(r,i) }
    page.search("//div[@class='ad idearc_bgcolor_blue']").each_with_index {|r,i| parse_results.call(r,i) }

    results.each {|r| p r.name}

    results
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

