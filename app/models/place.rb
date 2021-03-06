class Place < ActiveRecord::Base
  attr_accessible :href, :location, :address, :price, :urlimage, :desc, :source_id, :gmaps4rails_address, :latitude, :longitude, :gmaps
  belongs_to :source
  acts_as_gmappable
  def gmaps4rails_address
#describe how to retrieve the address from your model, if you use directly a db column, you can dry your code, see wiki
  "#{self.address}, USA" 
end

def gmaps4rails_infowindow
  "<h5>#{location}</h5>" << "<h5>#{address}</h5>" <<"<p>#{price}</p>" <<"<a href=#{href} target='_blank' >#{source} </a>"
end

end
