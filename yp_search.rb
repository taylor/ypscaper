require 'myconfig'
require 'ypscraper'
require 'csv'

yp = YPScraper.new(:switchboard)

results = []

if ARGV.size < 3
  puts "Usage: #{$0} [-csv] <query> <city> <state> [# of results (defaults to all)]"
  puts "use -csv if you want csv output"
  exit
end

query=ARGV[0]
if query == "-csv"
  usecsv=true
  ARGV.shift
  query=ARGV[0]
end
city=ARGV[1]
state=ARGV[2]
num_results = ARGV[3].nil? ? :all : ARGV[3].to_i

puts "Getting #{num_results} results"

results = yp.search(query, city, state, :num_results=>num_results)
#results = yp.search("Periodontics Dentists", "austin", "tx" , :num_results=>:all)

if usecsv
  puts "Name, Website, Address, City, State, Phone, Email"
  results.each_with_index do |r,i|
    puts CSV.generate_line([r.name,r.url,r.address,r.city,r.state,r.phone,r.email])
  end
else
  results.each_with_index do |r,i|
    puts %{#{i+1} - #{r.name}
      #{r.url.nil? ? 'no website' : r.url }
      #{r.address.empty? ? 'no address' : r.address} / #{r.phone.nil? ? 'no phone' : r.phone}}
  end
end
