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
      :hotel_name=>"ซีซี บลูม โฮเต็ล", :brochure=>nil, :pending_qty=>0, 
      :pending_fee => 0, :total_fee => 0.0, :zip => nil, :license => "123"   }
    rr1= Rr1.create @rr1
    @rr3= {:rr1_id=>rr1.id, :month=>begin_of_last_month, :balance_in=>0, :qty_in=>0, 
      :balance=>652908, :qty=>265, :balance_out=>0, :qty_out=>0, 
      :amount=>652908, :fee=>6529.08, :interest=>0, :fine=>0, 
      :total=>6529.08, :receipt_book=>nil, :receipt_no=>nil, :district_id => 545  }
    $xvars= {:enter_rr1=>{:rr1=>@rr1}, :enter_rr3=>{:rr3=>@rr3}, 
      :select_hotel => {:hotel_id=>rr1.id}, :p=>{} }
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
  def begin_of_last_month
    d= Date.today
    if d.month==1
      m = 12
      y = d.year-1
    else
      m = d.month-1
      y = d.year
    end
    dd= Date.new y, m, 1
  end
  it "should have booking report" do
    get :booking_report
  end
  it "should render pdf" do
    get :report, :format=>'pdf'
  end
  it "should add hotel" do
    Rr1.delete_all
    post :create_hotel
    rr1= Rr1.first
    r= clean_data(rr1.attributes.to_options)
    # check with r.diff(@rr1) in Rails
    r.should == @rr1
  end
  it "should assign district_id when create rr3" do
    $xmain= mock_model(GmaXmain)
    $runseq= mock_model(GmaRunseq)
    post :create_fee
    rr3= Rr3.first
    rr3.district_id.should == @rr1[:district_id]
  end
  it "should have report" do
    rr3= Rr3.create @rr3
    District.stub(:find).and_return(mock_model(District,:name=>'test'))
    get :index
    # debugger
    assigns[:revenues][0][:district_id].should == @rr1[:district_id]
    assigns[:revenues][0][:total].should be_close @rr3[:total], 0.01
    assigns[:revenues][0][:total_ytd].should be_close @rr3[:total], 0.01
    assigns[:revenues][0][:qty].should == 1
    assigns[:revenues][0][:qty_ytd].should == 1
  end
  it "should show list of hotels" do
    @rr1s= mock_model(Rr1)
    Rr1.should_receive(:find).and_return([@rr1s])
    get :hotels
    assigns[:rr1s].should == [@rr1s]
  end
  it "associate user to hotel"
  it "should be able to edit rr1 hotel"
  it "should assign hotel to user"
  it "should receive fee (rr3)"
  it "should have account receivable report"
  it "should have revenue analysis report"
  it "should remove hotel"
end
