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
  attr_accessor :url, :name, :phone, :address, :city, :state, :zip, :email, :provider
  def initialize(name, phone, address, city, state, zip, url, email, provider=nil)
    @url, @name, @phone, @address, @email = url, name, phone, address, email
    @city, @state, @zip = city, state, zip
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

    @default_provider = provider || :switchboard
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
    results=[]

    if @providers[name].nil?
      return results
    elsif num_results.class != Fixnum and num_results == :all
      num_results = -1
    elsif num_results.class != Fixnum
      raise ArgumentError, "num results should be a Fixnum or :all"
    end

    p=@providers[name]

    case p.name
    when :yellowpages
      location = "#{city.capitalize}-#{state.upcase}"
      url = "#{p.uri}/#{p.search_path}?#{p.sk}#{location}/#{keyword}"
    else
      location = URI.escape("#{city.capitalize},#{state.upcase}")
      url = "#{p.uri}/#{p.search_path}?#{p.sk}=#{keyword}&#{p.lk}=#{location}"
    end

    # page = get_page(url)
    # return results if page.nil?
    # results += parse_page(page)

    loop do
      page = get_page(url)
      return results if page.nil?
      results += parse_page(page)

      case p.name
      when :switchboard
        # p page.search("//span[@class='pagingcontrols']").search("a").last
        # p page.search("//span[@class='pagingcontrols']")
        # return []
        if ((num_results >= 0 and results.size >= num_results) or
            (page.search("//span[@class='pagingcontrols']").search("a").last.nil?) or
            (page.search("//span[@class='pagingcontrols']").search("a").last.text != 'Next'))
          break
        end
        url = "#{p.uri}/" + page.search("//span[@class='pagingcontrols']").search("a").last.attribute("href").text
      else
        break
      end
    end

    # Switchboard - determine if there are more results
    # p.search("//span[@class='pagingcontrols']").search("a").last.text == 'Next'

    results
  end

  def parse_page(page=nil)
    results = []
    return results if page.nil?

    # switch board pasring
    parse_switchboard = lambda do |r,i|
      name=nil
      phone = nil
      address, city, state, zip = nil, nil, nil, nil
      url, email = nil, nil

      name=r.search("span[@class='name ']").text
      name=r.search("span[@class='name idearc_red idearc_font_large']").text if name.empty?
      name=r.search("span[@class='name idearc_red idearc_font_large idearc_font_italic']").text if name.empty?
      unless name.empty?
        unless r.search("span[@class='emailline']/a").empty?
          email = r.search("span[@class='emailline']/a")[0].attribute("href").text.sub("mailto:","")
        end
        s=r.search(r.path + "/div/span[@class='Link_SearchTheWeb']/a")
        s=r.search(r.path + "/div[@class='otherlinks']/a") if s.empty?
        unless s.empty?
          unless s[0].attribute("href").text.match(/^\/webresults.htm/)
            m = r.search(r.path + "/div[@class='otherlinks']/a")[0].attribute("href").text.match(/LOC=(.*)/)
            m = r.search(r.path + "/div/span[@class='Link_SearchTheWeb']/a")[0].attribute("href").text.match(/dest=([^&]*)/) if m.nil?
            m = r.search(r.path + "/div/span[@class='Link_SearchTheWeb']/a").first.attribute("href").text.match(/LOC=(.*)/) if m.nil?
            url = URI.unescape(m[1]) unless m.nil?
          end
        end
        unless r.search("a[@class='linklist']").empty?
          m = r.search("a[@class='linklist']")[0].attribute("onclick").text.match(/showSWPhone\('([^']*)'/)
          phone = m[1] unless m.nil?
        end
        unless r.search("span[@class='address']").empty?
          address = r.search("span[@class='address']").text.strip.sub(/,$/, '')
        end
        unless r.search("span[@class='citystatezip']").empty?
          city, state = r.search("span[@class='citystatezip']").text.gsub('zip code', '').strip.split(", ")
        end

        #def YPResult.initialize(name, phone, address, city, state, zip, url, email, provider=nil)
        results << YPResult.new(name, phone, address, city, state, zip, url, email,  @default_provider)
      else
        puts "nothing found for row #{i}"
      end
    end

    # FIXME: results will be out of order from what is on page
    case @default_provider
    when :switchboard
      page.search("//div[@class='ad ']").each_with_index do |r,i|
        parse_switchboard.call(r,i)
      end
      page.search("//div[@class='ad idearc_bgcolor_blue']").each_with_index do |r,i|
        parse_switchboard.call(r,i)
      end
    end

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

