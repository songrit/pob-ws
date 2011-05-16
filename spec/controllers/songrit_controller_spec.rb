require 'spec_helper'

describe SongritController do
  it "should fix tambon" do
    SubDistrict.delete_all
    SubDistrict.create :name=>"ตำบลกกก"
    SubDistrict.create :name=>"ตำบล11ตำบล22"
    get :fix_tambon
    SubDistrict.all.map(&:name).should == ['กกก','11ตำบล22']
  end
end
