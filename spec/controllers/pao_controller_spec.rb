require 'spec_helper'

describe PaoController do
  before(:each) do
    Rr1.delete_all
    @rr1= {:manager_street=>"ปฏัก", :manager_citizen=>"อเมริกัน", 
      :manager_sub_district_id=>6777, 
      :owner_street=>"ไวโอมิง อเวนิว นอร์ธเวสต์ ยูนิต 402 วอชิงตัน ดีซี 20009 อเมริกา", 
      :address=>"84/21", :owner_citizen=>"อเมริกัน", :street=>"ปฏัก", 
      :sub_district_id=>6777, :doc=>nil, :owner_province_id=>66, :lat=>7.8411, 
      :at=>"บริษัท โอนนิ่งพาราไดซ์ จำกัด", :owner_dob=>"1965-05-15", 
      :province_id=>66, :manager_dob=>"1956-05-15", :manager_national=>"อเมริกัน", 
      :district_id=>545, :manager_phone=>"086-604-1333", 
      :lng=>98.2951, :owner_sub_district_id=>nil, 
      :owner_name=>"นายเอ็ดเวิร์ด สก็อต ยูพีโร่", 
      :manager_province_id=>66, :phone=>"076-333-222", :gma_user_id=>nil, 
      :owner_phone=>"", :code=>"CC", :manager_district_id=>545, 
      :manager_address=>"84/21", :owner_national=>"อเมริกัน", 
      :manager_name=>"นายเคนเน็ท จาค๊อป มิลเลอร์", 
      :owner_district_id=>nil, :owner_address=>"1870", 
      :hotel_name=>"ซีซี บลูม โฮเต็ล", :brochure=>nil }
    $xvars= {:enter_rr1=>{:rr1=>@rr1}}
  end
  # clean up data created by Rails and convert dates to SQL format
  def clean_data(r)
    r.delete(:id)
    r.delete(:created_at)
    r.delete(:updated_at)
    r[:owner_dob]= r[:owner_dob].to_date.strftime('%F')
    r[:manager_dob]= r[:manager_dob].to_date.strftime('%F')
    return r
  end
  it "should add hotel" do
    post :create_hotel
    rr1= Rr1.first
    r= clean_data(rr1.attributes.to_options)
    r.should == @rr1
  end
  it "should add room"
  it "should edit hotel"
  it "should remove hotel"
  it "should receive fee"
  it "should generate reports"
end
