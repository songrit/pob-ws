require 'spec_helper'

describe HotelsController do
  integrate_views
  before do
    Hotel.delete_all
    Hotel.create! :code=>'TEST1', :lat => 7.8, :lng => 98
    Hotel.create! :code=>'TEST2', :lat => 7.8, :lng => 99
  end

  it "should show map of all hotels" do
    get :hotels
    response.should be_success
  end
  it "should show reservation by year/month/day"
  it "should show occupancy by year/month/day"
  it "should have hotels management for PAO"
  
end
