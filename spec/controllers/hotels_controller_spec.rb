require 'spec_helper'

describe HotelsController do

  it "should have hotels management for PAO"
  
  describe "Availability" do
    it "should find availability" do
      get :avail, :id=>1, :d1 => "2004-08-02", :d2 => "2004-08-03"
      # 2 inventories, 1 day
      assigns[:availabilities].count.should == 2
    end
  end

end
