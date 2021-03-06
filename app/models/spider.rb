require 'mechanize'
require "rubygems"
require "bundler/setup"
require "capybara"
require "capybara/dsl"
require "capybara-webkit"
require 'headless'
class Spider
  TIME_VALUE={ }    
  include Capybara::DSL
  
  def self.daily_search(params)
    begin
      
    if Rails.env.production?
      Headless.new(display: 100, destroy_at_exit: false).start
    end
    Capybara.run_server = false
    Capybara.javascript_driver = :webkit_debug
    Capybara.current_driver = :webkit
    spy=Spider.new
      req = Request.create(:desc=>"")
      
      results = spy.get_results_centralpark(params, "daily",req)  # if params["centralpark"] == "1"
      spy.get_results_justpark(params,"daily", req, results)    # if params["gottapark"] == "1"
      spy.get_results_gottapark(params,"daily", req, results)    # if params["gottapark"] == "1"
      spy.get_results_pandaparking(params, "daily",req ,results) # if params["pandaparking"] == "1"
      spy.get_results_parkwhiz(params, "daily",req,results)     # if params["parkwhiz"] == "1"
      spy.get_results_spothero(params, "daily",req,results)     # if params["spothero"] == "1"
     # spy.get_results_justpark
      ids=""
      results.each do |result|
       ids << "#{result['id']},"
      end 
      req.desc = ids
      req.save
   #   result_string = ApplicationController.new.render_to_string(:partial => 'pages/results', :locals => { result_type: "daily" })
   #   message = {:channel => "/searches",
   #              :data => { result_string: result_string}}
   #   uri = URI.parse("http://72.10.36.142:3000/faye")
   #   Net::HTTP.post_form(uri, :message => message.to_json)
    rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     req.desc << e.message.to_s << e.backtrace.inspect.to_s
     req.save
     [results, req]
    end
   
    [results,req]
  end
 
  def self.monthly_search(params)
   results=[]
    begin 
     
    if Rails.env.production?
      Headless.new(display: 100, destroy_at_exit: false).start
    end
    Capybara.run_server = false
    Capybara.javascript_driver = :webkit_debug
    Capybara.current_driver = :webkit
      spy=Spider.new
      req = Request.create(:desc=>"")
      results = spy.get_results_centralpark(params, "monthly", req) #if params["centralpark"] == "1"
      spy.get_results_pandaparking(params, "monthly",req , results) #if params["pandaparking"] == "1"
      spy.get_results_justpark(params, "monthly",req , results) #if params["pandaparking"] == "1"
      ids=""
      results.each do |result|
       ids << "#{result['id']},"
      end 
      req.desc = ids
      req.save
       # FayeController.publish('/searches', {result_string: result_string})
    #  result_string = ApplicationController.new.render_to_string(:partial => 'pages/results', :locals => { result_type: "monthly" })
    #  message = {:channel => "/searches",
    #             :data => { result_string: result_string}}
    #  uri = URI.parse("http://localhost:3000/faye")
    #  Net::HTTP.post_form(uri, :message => message.to_json)
    rescue Exception => e
      puts e.message
      puts e.backtrace
     req.desc << e.message.to_s << e.backtrace.inspect.to_s
      req.save
     [results, req]
    end
    
    [results,req]
  end
  
    
  def self.airport_search(params)
    begin 
    if Rails.env.production?
      Headless.new(display: 100, destroy_at_exit: false).start
    end
    Capybara.run_server = false
    Capybara.javascript_driver = :webkit_debug
    Capybara.current_driver = :webkit
      
    spy=Spider.new
    req = Request.create(:desc=>"")
    results = spy.get_results_airportparkingreservations(params,req) # if params["airportparkingreservations"] == "1"
    spy.get_results_parkingconnection(params,req,results)          # if params["parkingconnection"] == "1"
    spy.get_results_airportparking(params,req, results)             # if params["airportparking"] == "1"
    spy.get_results_aboutairportparking(params, req, results)       # if params["aboutairportparking"] == "1"
    ids=""
    results.each do |result|
     ids << "#{result['id']},"
    end     
    req.desc = ids
    req.save
    # spy.get_results_pnf(params,req)                        # if params["pnf"] == "1"
       # FayeController.publish('/searches', {result_string: result_string})
     
     # result_string = ApplicationController.new.render_to_string(:partial => 'pages/results', :locals => { result_type: "airport" })
     # message = {:channel => "/searches",
     #            :data => { result_string: result_string}}
     # uri = URI.parse("http://localhost:3000/faye")
     # uri = URI.parse("http://72.10.36.142:80/faye")
     # Net::HTTP.post_form(uri, :message => message.to_json)
    rescue Exception => e
      puts e.message
      puts e.backtrace
      req.desc<< e.message.to_s << e.backtrace.inspect.to_s
      req.save
      [results, req]
    end
     
    [results,req]
  end
#------------------------------------airport search methods -----------------------------------------------------------
def get_results_pnf(params, req, results)

begin 
    list=[]
    city=params[:wherebox_airp].split(" (")[0].gsub(" ","-")
    short_name = params[:wherebox_airp].split(" (")[1].gsub("(","").gsub(")","").upcase
    agent = Mechanize.new{|a| a.follow_meta_refresh= true}
    agent.user_agent_alias = "Linux Firefox"
    agent.get("http://www.pnf.com")
    f = agent.page.forms.first
    f.city=short_name
    f.leave_date= params[:from]
    f.leave_time=params[:Items]
    f.return_date= params[:to]
    f.return_time=params[:Items2]
    f.submit
    sleep 2
    agent.page.search(".location").each do |loc|
      object = Hash.new
      object["location"] = loc.search(".title").first.text
      
      part =  loc.search(".reserve-now a").first[:href]
      object["href"] = "http://www.pnf.com/reserve/#{part}#parking"
      
      s = loc.search(".info p").first.text
      add = s.split(/[\t]+/)[0].gsub!(/[\r]+/, "").gsub!(/[\n]+/, "")
      add << s.split(/[\t]+/)[1].gsub!(/[\r]+/, "").gsub!(/[\n]+/, "")
      object["address"] = add
      object["price"] = loc.search(".ratetotal").first.text
      object["urlimage"]=""
      list << object
    end
    #save_results(results,"airport","www.pnf.com", req)    
   rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  end
 
   
  
def get_results_aboutairportparking(params, req, results)

begin 
    #results=[]
    city=params[:wherebox_airp].split(" (")[0].gsub(" ","-")
    short_name = params[:wherebox_airp].split(" (")[1].gsub("(","").gsub(")","").upcase
    if Rails.env.production?
      headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false)
    end
    visit("http://www.aboutairportparking.com")
    value="0"
    all(:css, "#edit-airport option").each do |option|
      if short_name == option.text.split("(").last.gsub(")","")
        value = option.value
      end
    end
    all(:css, "#edit-airport").first.set(value)
    fill_in('edit-start-date', :with => "#{params[:from]}")
    fill_in('edit-end-date', :with => "#{params[:to]}")
    all(:css, "#edit-submit")[1].click
    sleep 2
    links=[]
    all(:css, "div.airport_parking").each do |lot|
     if  lot.all(:css, ".parking_teaser_buttons a").size > 0
      links << "http://www.aboutairportparking.com/#{lot.all(:css, ".parking_teaser_name a").first[:href]}"
     end
    end
    all(:css, "div.airport_parking_sponsored").each do |lot|
     if  lot.all(:css, ".parking_teaser_buttons a").size > 0
      links << "http://www.aboutairportparking.com/#{lot.all(:css, ".parking_teaser_name a").first[:href]}"
     end
    end

    links.each do |link|
      begin
        href = link
      object = Hash.new
      if Source.find_by_name("aboutairportparking").places.find_by_href(link) != nil
        find_place("aboutairportparking", link, object)
        object["href"] = link
      else
        visit(link)
        object["location"] = all(:css, "div.main_content h1").first.text
        object["address"] = "#{all(:css, ".parking_address").first.text} #{all(:css, ".parking_address").last.text}"
        if all(:css, ".parking_price .parking-rate-rate").size > 0
          object["price"] = all(:css, ".parking_price .parking-rate-rate").first.text
        elsif all(:css, ".parking_price div").size > 1
           price1 = all(:css, ".parking_price div").first.text.split(" ").first    
           price2 = all(:css, ".parking_price div").last.text.split(" ").first    
            if price1 == price2
              object["price"] = "#{price1}"
            else
              object["price"] = "#{price1} - #{price2}"
            end 
        else
          object["price"] = all(:css, ".parking_price").first.text
        end
        object["href"] =  "http://www.aboutairportparking.com/#{all(:css, ".red-button-120").first[:onclick].split("=").last.gsub("'","")}"
        if all(:css, "img.imagecache-parking_lot_resized").size > 0 
          object["urlimage"] = all(:css, "img.imagecache-parking_lot_resized").first[:src]
        else
        object["urlimage"]=""
        end
      
        save_place(object,"aboutairportparking",link)
        find_place("aboutairportparking", link, object)
      end
        results<<object
      end
    end
    #save_results(results,"airport","www.aboutairportparking.com",req)    
    results 
  rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  end

  
def get_results_airportparking(params, req, results)
  list = YAML.load(File.open("output.yml"))
  begin 
    #results=[]
    city=params[:wherebox_airp].split(" (")[0].gsub(" ","-")
    short_name = params[:wherebox_airp].split(" (")[1].gsub("(","").gsub(")","").upcase
    if Rails.env.production?
      headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false)
    end  
   
    url="https://www.airportparking.com/airports/#{list["#{short_name}"]}"
    visit(url)
    sleep 1
    within("#updatefrm") do
      fill_in 'park_from', :with => "#{params[:from]}"
      fill_in 'park_to', :with => "#{params[:to]}"
    end
    #binding.pry
    #find_button('Update Rates').click
    all(:css,"#updatefrm button.btn-danger").first.click
    sleep 4
    links=[]
    all(:css,"div.lot").each do |lot|
      if lot.all(:css, "#reserve_button").size >0
        if lot.all(:css, "#reserve_button").first.text == "Park Here"
          links << "http://www.airportparking.com/#{lot.find(:css, "span.lot-title a")[:href]}"
        end
      end
    end
    #------
    links.each do |link|
      begin 
        href = link.split("/reservation?").first
        object = Hash.new
        if Source.find_by_name("airportparking").places.find_by_href(href) != nil
          find_place("airportparking", href, object)
          object["href"]=link
        else
         visit(link)
         object["urlimage"] = all(:css, "div#photos img").first[:src]
         all(:css, "#details_container form button").first.click
         sleep 3
          
         object["location"] = all(:css,"div#review_reservation_container div#lot_title").first.text
         if all(:css,"div#review_reservation_container div#price_breakdown_container div").size> 0 
          object["address"] = all(:css,"div#review_reservation_container div#price_breakdown_container div")[4].text
          object["address"] << all(:css,"div#review_reservation_container div#price_breakdown_container div")[5].text
         elsif
          object["address"] = all(:css,"#review_reservation_container div.span6.offset1 div")[4].text
          object["address"] << all(:css,"div#review_reservation_container div.span6.offset1 div")[5].text
         end
         object["price"] = all(:css,"span.reservation-subtotal-amount").first.text
         object["href"] = current_url
         save_place(object,"airportparking",href)
        find_place("airportparking", href, object)
        end
      end
      results<<object
    end
    results
   rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  end



  #--------------------  http://www.parkingconnection.com/
def get_results_parkingconnection(params,req, results)
   begin 
    #results=[]
    city=params[:wherebox_airp].split(" (")[0].gsub(" ","-")
    short_name = params[:wherebox_airp].split(" (")[1].gsub("(","").gsub(")","")
    if Rails.env.production?
      headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false)
    end  
    url="http://www.parkingconnection.com/locations/#{city}-#{short_name}-airport-parking/?dpnLocations=#{short_name}&txtCheckinDt=#{params[:from]}&dpnCheckInTime=#{params[:Items]}&txtCheckoutDt=#{params[:to]}&dpnCheckOutTime=#{params[:Items2]}&UnitID&FacilityID&sendbutton2"
    visit(url)
    sleep 1
    all(:css,"div.locationLot").each do |lot|
      object = Hash.new
      
      if lot.all(:css,"div.rateInfoContainer div.lotInfo div.reserveLotButtonNotAvailable").size > 0
        object["href"] = lot.find(:css,"div.rateInfoContainer div.lotInfo ul li.noBorder a")[:href]
      else
        facilityid = lot.find(:css,"div.rateInfoContainer div.lotInfo div.reserveLotButton p.facilityID").text
        unitid = lot.find(:css,"div.rateInfoContainer div.lotInfo div.reserveLotButton p.unitID").text
        object["href"] = "https://www.airportparkingconnection.com/apc/api/Checkout.aspx?dpnLocations=#{short_name}&txtCheckinDt=#{params[:from]}&dpnCheckInTime=#{params[:Items]}&txtCheckoutDt=#{params[:to]}&dpnCheckOutTime=#{params[:Items2]}&UnitID=#{unitid}&FacilityID=#{facilityid}&sendbutton2="
      end
      link = object["href"]
      if Source.find_by_name("parkingconnection").places.find_by_href(link) != nil
        find_place("parkingconnection", link, object)
        
        #object["href"] = link
     else
      object["location"] = lot.find(:css,"h3").text
      object["location"] << lot.find(:css,"span").text
      object["address"] = lot.find(:css,"p.locationAddress").text
      object["price"] = lot.find(:css,"div.rateInfoContainer div.rate").text
      object["source"] = "parkingconnection"         
      save_place(object,"parkingconnection",link)
      find_place("parkingconnection", link, object)
     end

      
            results<<object
    end
    #save_results(results,"airport","www.parkingconnection.com",req)    
    results
  rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  end



  def get_results_airportparkingreservations(params,req)
   begin 
    results=[]
    list = YAML.load(File.open("public/airpreserv.yml"))
    short_name = params[:wherebox_airp].split(" (")[1].gsub("(","").gsub(")","").upcase
    url = list["#{short_name}"]
  
    if Rails.env.production?
     
      headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false)
     # headless = Headless.new
     # headless.start
    end  
    visit(url)
    sleep 1
    #binding.pry
    all(:css, "div.parkinglot-data").each do |item|
      if item.all(:css, "a.parkHere").size > 0
        object = Hash.new
        object["location"]= item.all(:css, "h3").first.text
        object["price"] = item.all(:css, "span.rate-iphone").first.text.insert(-3,".")
         object["href"] = "http://www.airportparkingreservations.com/#{item.all(:css, "a.more-details").first[:href]}"  
        
        results<<object
      end
    end

       
  # all(:css, "div.sr-v3-right div.reserve-box em.price").each_with_index do |item,index|
  #   if results[index].present?
  #   #  object.location = slice[0].text
  #     object = results[index]
  #     object["price"]= item.text
  #   end
  # end

  #all(:css, "a.more-details").each_with_index do |item,index|
  #   if results[index].present?
  #   #  object.location = slice[0].text
  #     object = results[index]
  #     object["href"]= "http://www.airportparkingreservations.com#{item[:href]}"
  #   end
  # end
  #binding.pry
    results.each do |r|
    link = r["href"] 
     if Source.find_by_name("airportparkingreservations").places.find_by_href(link) != nil
        object = r
        find_place("airportparkingreservations", link, object)
        r = object
        #object["href"] = link
     else
        visit(r["href"])
        r["address"] = "#{all(:css, "p.address").first.text}"
        if all(:css, "li.imgLiquidFill img").size > 0
          r["urlimage"] = all(:css, "li.imgLiquidFill img").first[:src]
        end
        object = r
        save_place(object,"airportparkingreservations",link)
        find_place("airportparkingreservations", link, object)
     end
  end
  #save_results(results,"airport","www.airportparkingreservations.com",req)    
  results
   rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  end
 #------------------------------------------------------- 

#-------------------------------------------------------------- 
  def get_results_cheapairportparking(params,req)
   begin 
    results=[]
    short_name = params[:wherebox_airp].split(" ")[1].gsub("(","").gsub(")","")
    url = params[:wherebox_airp_full]
    
    if Rails.env.production?
   
      headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false)
     # headless = Headless.new
     # headless.start
    end  
    "http://www.cheapairportparking.org/parking/find.php?airport=#{short_name}&FromDate=03%2F05%2F2013&from_time=1&ToDate=03%2F06%2F2013&to_time=15"
    visit(url)
    sleep 1
    all(:css, "div.sr-v3-left div.headline").each do |item|
      object = Hash.new
      object["location"]= item.text
      results<<object
    end

       
    all(:css, "div.sr-v3-right div.reserve-box em.price").each_with_index do |item,index|
      if results[index].present?
      #  object.location = slice[0].text
        object = results[index]
        object["price"]= item.text
      end
    end
    save_results(results,"airport","www.cheapairportparking.org",req)    
     rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  end

#--------------------------------------------------------Spothero -----------
  def get_results_spothero(params, type,req, results)
   begin 
    
     location = params[:wherebox]
    if location.present?
     arr = location.split(",")
     city = arr[0].strip.gsub(" ","-")
     state = arr[1].strip
    end
    
    if Rails.env.production?
      
      headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false)
      #headless = Headless.new
      #headless.start
    end  
    
    visit("http://www.spothero.com/")
    all(:css,"#search_string").first.set(params[:wherebox])
    all(:css,"#submit-search").first.click
    sleep 15

    list=[]
    
    all(:css, ".result").each do |lot|
     # id = lot.find(:css, ".btnSpotMe")[:id]
     # list << "https://spothero.com/#{city}/spot/#{id}?start_date=#{params[:from].gsub("/","-")}&start_time=#{params[:Items].gsub(":","").gsub(" ","")}&end_date=#{params[:to].gsub("/","-")}&end_time=#{params[:Items2].gsub(":","").gsub(" ","")}"
      first_part = lot.find(:css, ".price")[:href].split("?start_date").first
      list << first_part + "?start_date=#{params[:from].gsub("/","-")}&start_time=#{params[:Items].gsub(":","").gsub(" ","")}&end_date=#{params[:to].gsub("/","-")}&end_time=#{params[:Items2].gsub(":","").gsub(" ","")}"

    end
    list.each do |url|
      begin
        href= url.split("?start_date").first
        if Source.find_by_name("spothero").places.find_by_href(href) != nil
          object = Hash.new
          find_place("spothero", href, object)
          object["href"]= url
        else

          object = Hash.new
          visit(url)
          sleep 2
          object["location"] = all(:css, ".facility-title").first.text
          object["address"] = all(:css, ".location-address").first.text
          if all(:css, "#hourly .priceByTimeListCheckout dt").size > 0
            object["price"] = all(:css, "#hourly .priceByTimeListCheckout dt").first.text
          else
            object["price"] = "n/a"
          end
          object["href"] = url
          object["urlimage"] = all(:css, "#carousel img").first[:src] rescue nil
          
          save_place(object, "spothero" , href)
          find_place("spothero", href, object)
        end 
        results << object
      rescue Exception => e
       puts e.message  
       puts e.backtrace.inspect  
       results
      end
     end
    
   # debugger
    #save_results(results,"daily","www.spothero.com",req)    
   results  
   rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  end


   
  
#-------------------------------------------- www.gottaprk.com -------------------------------------  
  def get_results_gottapark(params,type,req, results)
   begin 
     list = []
    location=params[:wherebox]
    if location.present?
     arr = location.split(",")
     city = arr[0].strip.gsub(" ","-")
     state = arr[1].strip
    end
   
    if Rails.env.production?
      headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false)
    end  
    visit("http://www.gottapark.com/")
    fill_in "search_key", :with =>"#{location}"
    fill_in "date_from", :with =>"#{params[:from].gsub("/","-")}"
    #fill_in "time_from", :with =>"#{params[:items]}"
    select "#{params[:Items]}", :from=>"time_from"
    fill_in "date_to", :with =>"#{params[:to].gsub("/","-")}"
    #fill_in "time_to", :with =>"#{params[:items2]}"
    select "#{params[:Items2]}", :from=>"time_to"
    find(:xpath,'//div[@id="homeboxbutton"]/input').click
    all(:xpath,'//div[@id="smallsearchbox"]/div/div[@class="details"]/p[@class="address"]').each do |item|
       object = Hash.new
       object["address"]= item.text
      list<<object
    end
   
    all(:xpath,'//p[@class="price"]').each_with_index do |item,index|
    if list[index].present?
      #  object.location = slice[0].text
        object = list[index]
        object["price"]= item.text[0..-3]
      end
    end
    
    all(:css, "p.title a").each_with_index do |item,index|
    if list[index].present?
      #  object.location = slice[0].text
        object = list[index]
        object["location"]= item.text
      end
    end


    all(:css, "p.address").each_with_index do |item,index|
    if list[index].present?
      #  object.location = slice[0].text
        object = list[index]
        path=item.text.split(",").first.gsub(" ","-")
        object["href"]= "http://www.gottapark.com/parking/#{city}/#{path}"
          
    end

    end
   
    list.each do |object|
     href = object["href"] 
      if Source.find_by_name("gottapark").places.find_by_href(href) != nil
          find_place("gottapark", href, object)
     else
      visit(object["href"])
       if all(:css, "img#lp_photo").size>0
        object["urlimage"] = all(:css, "img#lp_photo").first[:src]
       end
      save_place(object, "gottapark" , href)
      find_place("gottapark", href, object)
     end
      results << object
    end
    #save_results(results,type,"www.gottapark.com",req)    
   
    results
   rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  end
  
#------------------------------------  www.pandaparking.com --------------------------------------------
  
  def get_results_pandaparking(params,type,req, results)
   begin
    list =[]
     location = params[:wherebox]
    arr = location.split(",")
    city = arr[0].strip.gsub(" ","-")
    state = arr[1].strip 
   
    if Rails.env.production?
      headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false)
    end  

    if type != 'daily'
      visit("https://www.parkingpanda.com/Search/?location=#{city}&monthly=true&daily=false")
	    sleep 5
      pickup_panda("monthly",req, results)
      # visit("https://www.parkingpanda.com/Search/?location=#{city}&start=#{params[:from]}&end=#{params[:to]}3&monthly=true&daily=false")
      #visit "https://www.parkingpanda.com"
      #fill_in "ctl00$container$txtSearch", :with =>"#{city}, #{state}, USA"
      #fill_in "ctl00$container$txtSearchStartDate", :with => "02/23/2013"
      #find(:xpath, '//input[@name="ctl00$container$btnSearch"]').click
     # if all(:xpath,'//a[@id="lnkMonthlyParking"]').size>0
	   #   all(:xpath,'//a[@id="lnkMonthlyParking"]').first.click
      #  if all(:css, "span.location-rate").size>0
       #   if all(:css, "span.location-rate").first.text=="monthly"
        #  end
        #end
      #end
    else
      visit("https://www.parkingpanda.com/Search/?location=#{city}&monthly=false&daily=true")
      sleep 1
      pickup_panda("daily",req, results)
    end
    rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end
  results
  end                                          
#------------------------------------------ pickup
def pickup_panda(desc,req, results)
  list =[]
    all(:xpath, "//div[@class='location-details']/h2").each do |item|
     #object = Result.new
     #object.address = item.text
       object = Hash.new
       object["location"]= item.text
     #  object["address"] = item.text
      list<<object
    end
   # all(:xpath, "//div[@class='location-details']/p").each_slice(2).with_index do |slice,index|
   #   if list[index].present?
      #  object.location = slice[0].text
   #     object = list[index]
   #     object["address"] << ", #{slice[0].text}"
   #   end
   # end
    all(:xpath, "//span[@class='location-price']").each_with_index do |item,index|
      if list[index].present?
        #object.price = item.text
        object = list[index]
        object["price"]= item.text
        #object.save
      end
    end
    all(:css, "div.location-reserve a.btn.btn-parking").each_with_index do |item,index|
      if list[index].present?
        #object.price = item.text
        object = list[index]
        #object["href"]= "https://www.parkingpanda.com#{item[:href]}"
        object["href"]= item[:href]
        #object.save
      end
    end
    all(:css, "div.location-image img").each_with_index do |item,index|
      if list[index].present?
        #object.price = item.text
        object = list[index]
        object["urlimage"]= item[:src]
        #object.save
      end
    end
    
    list.each do |object|
      href = object["href"].split("&start").first 
      if Source.find_by_name("pandaparking").places.find_by_href(href) != nil
          find_place("pandaparking", href, object)
      else
          
          visit(href)
          sleep 2
          object["address"] = find(:css,"#purchase-vehicle").text rescue nil
          save_place(object, "pandaparking" , href)
          find_place("pandaparking", href, object)
      end
      results << object
    end
    results
end
#-------------------------------------  www.centralparking.com -------------------------------------------------  
                                               


def get_results_justpark(params,type,req, results)
  begin  
   location = params[:wherebox]
    arr = location.split(",")
    city = arr[0].strip.gsub(" ","-")
    state = arr[1].strip 
    agent = Mechanize.new{|a| a.follow_meta_refresh= true}
    agent.user_agent_alias = "Linux Firefox"
    #agent.get("https://www.justpark.com/search/?filter=1&order=&q=#{city}%2C+#{state}%2C+United+States&start_date=31+Jul+2014&start_time=07%3A00%3A00&end_date=31+Jul+2014&end_time=08%3A00%3A00")
    agent.get("https://www.justpark.com/search/?filter=1&order=&q=#{city}%2C+#{state}%2C+United+States")
    agent.page.search("div.listing-container").each do |container|
      x = (type == "daily" ? 0 : 1)
      if container.search("span:contains('Long term only')").size == x
        object = Hash.new
        object["href"] = "https://www.justpark.com#{container.search("span.title a").first["href"]}"
        link = object["href"]
        if Source.find_by_name("justpark").places.find_by_href(link) != nil
          find_place("justpark", link, object)
        else
          object["location"] = "#{container.search("span.title").first.text}, #{city}, #{state}"
          object["address"] = object["location"]
          object["price"] =  container.search("p.price").first.text
          object["source"] = "justpark"         
          save_place(object,"justpark",link)
          find_place("justpark", link, object)
        
        end
        results<<object
      end
    end
    #binding.pry
    #agent.get("#{agent.page.uri.to_s}map/?&start_date=#{params[:from]}&start_time=#{params[:Items].gsub(" ","")}&end_date=#{params[:to]}&end_time=#{params[:Items2].gsub(" ","")}")
    results
    rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end

end
def get_results_parkwhiz(params,type,req, results)
  begin  
    
    location = params[:wherebox]
    agent = Mechanize.new{|a| a.follow_meta_refresh= true}
    agent.user_agent_alias = "Linux Firefox"
    agent.get("http://www.parkwhiz.com/search/?destination=#{params[:wherebox].split(",").first}")
    
    #form = agent.page.forms[2]
    
    #form.destination=location
    #form.submit
   sleep 1
   # binding.pry
    agent.get("#{agent.page.uri.to_s}map/?&start_date=#{params[:from]}&start_time=#{params[:Items].gsub(" ","")}&end_date=#{params[:to]}&end_time=#{params[:Items2].gsub(" ","")}")
    links = []
    agent.page.search(".search-list-card-body").each do |link|
      links << "http://www.parkwhiz.com#{link[:href]}"
    end
   # binding.pry
    links.each do |link|
      href = link.split("/?start").first
      begin
      #---
        if Source.find_by_name("parkwhiz").places.find_by_href(href) != nil
          object = Hash.new
          find_place("parkwhiz", href, object)
          object["href"]= link
        else
          object = Hash.new
          # debugger
          page =  agent.get(link)
          sleep 1
          object["location"] = agent.page.parser.at("[@itemprop = 'name']").text
          object["address"] = agent.page.search(".address").first.text
          #agent.page.search(".address span").each do |s|
          # object["address"] << s.text 
          #end
          #binding.pry
          if  agent.page.search(".btn-book").size > 0
            object["price"] = "$#{agent.page.search(".btn-book span").first.text.gsub("$","") rescue ""} #{agent.page.search(".btn-book sup").last.text rescue ""}"
          end
          object["href"] = link
          if agent.page.search("#photos img").size > 0
            url =  agent.page.search("#photos img").first[:src]
            url.slice!(0).slice!(0)
            object["urlimage"] = "http://#{url}"
          end
          save_place(object, "parkwhiz" , href)
          find_place("parkwhiz", href, object)
        end
        results << object
     #------
     end
    end
    
    results
    rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     results
    end

end                                              

def get_results_centralpark(params,type,req)
  begin  
    results = []
    location = params[:wherebox]
    arr = location.split(",")
    city = arr[0].strip.gsub(" ","-")
    state = arr[1].strip 
	   
    headless = Headless.new(display: 100, reuse: true, destroy_at_exit: false) if Rails.env.production?
    
    if city.downcase =="new-york"
      city_short = "nyc"
    else
      city_short = city.gsub(" ","").gsub("-"," ") 
    end
    visit("http://#{city_short}.centralparking.com/parking-near/#{city}-#{state}-USA.html")
    list=[]
    all(:css,'.hasCoupon td.itemLabel a').each do |url|
      list << url[:href]
      
    end
    if type == 'daily'
      det="#Tab_standard-rates"
    else
     det="#Tab_monthly-rates"
    end
    list.each do |url|
      href = "http://#{city_short}.centralparking.com#{url}#{det}"
      if Source.find_by_name("centralparking").places.find_by_href("http://#{city_short}.centralparking.com#{url}#{det}") != nil
        object = Hash.new
        find_place("centralparking", href, object)
        object["href"] = href
      else
        visit("http://#{city_short}.centralparking.com#{url}")
        object = Hash.new
        object["href"]= "http://#{city_short}.centralparking.com#{url}#{det}"
        if all(:css,"dl.info dd").size>0
          object["address"] = all(:css,"dl.info dd").first.text
          if object["address"].include?(city.gsub("-"," ")) == false
            object["address"] << ", #{city}, #{state}"
          end 
        end
        
        if all(:css, "div.column_1-5.left h1").size>0
           object["location"] = all(:css, "div.column_1-5.left h1").first.text
        end
        if type == 'daily'
          if all(:css, "table.layout-table-1 tr td").size>3
            object["price"] = all(:css, "table.layout-table-1 tr td")[3].text
          end
        else
          if all(:css, "div.monthly-parking-rates p").size>0
           object["price"] = all(:css, "div.monthly-parking-rates p")[0].text
          end
        end
        save_place(object,"centralparking",href)
        find_place("centralparking", href, object)
      end
	    results<<object
     
     end
    results  
    rescue Exception => e  
     puts e.message  
     puts e.backtrace.inspect  
     req.desc<< e.message.to_s << e.backtrace.inspect.to_s
     req.save
     results
    end
end


  
  
#---------------------------------------------------------------------------------------------------------------  
def save_place(object,source,href)
    place = Source.find_by_name(source).places.new
    place.location = object["location"] if object["location"]
    place.address = object["address"] if object["address"]
    place.price = object["price"] if object["price"]
    place.href = href
    place.urlimage = object["urlimage"] if object["urlimage"]
    place.save
end

def find_place(source,href,object)
    place = Source.find_by_name(source).places.find_by_href(href)
      #    object["href"]= link
          object["id"] = place.id rescue nil
          object["location"] = place.location if place.location != nil
          object["address"] = place.address if place.address != nil
          object["source"] = source
          object["price"] = place.price if place.address != nil
          object["urlimage"] = place.urlimage if place.address != nil
          object["latitude"] = place.latitude if place.latitude != nil 
          object["longitude"] = place.longitude if place.longitude != nil
          object["gmaps4rails_address"] = place.gmaps4rails_address if place.gmaps4rails_address != nil
          
       # debugger
object
end

def save_results(results,type,source,req) 
    
  results.each do |o|
      if o["href"] != nil
        item = req.results.new
        item.address = o["address"]
        item.location = o["location"]
        item.price = o["price"]
        if o["urlimage"].present? 
          item.urlimage = o["urlimage"]
        end
        item.href = o["href"]
        item.desc= type
        item.source = source
        item.save
      end
    end
end

end
