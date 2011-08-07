require 'spec_helper'

describe "/pao/fee/print_doc.rhtml" do
  include PaoHelper

  before(:each) do
    $xvars= {:total_steps=>5, :rr3_id=>11, :enter_rr3=>{:rr3=>{"month(1i)"=>"2011", "qty"=>"300", "balance_out"=>"50000", "month(2i)"=>"6", "month(3i)"=>"1", "qty_out"=>"50", "addition"=>"1", "balance"=>"300000"}, :controller=>"engine", :action=>"end_form", :commit=>"ดำเนินการต่อ", :step=>"2", :xmain_id=>"64", :runseq_id=>"235", :normal=>"n"}, :total_form_steps=>4, :user_id=>2, :host=>"pob-ws.local", :current_step=>5, :p=>{"module"=>"pao", "service"=>"fee", "action"=>"init", "controller"=>"engine", "return"=>"/pao"}, :gma_service_id=>59, :receipt_id=>7, :referer=>"http://pob-ws.local/engine/run_output/63", :id=>nil, :create_fee=>"/pao", :custom_controller=>"PaoController", :select_hotel=>{:controller=>"engine", :hotel_id=>"3", :action=>"end_form", :hotel_name=>"zzz", :commit=>"ดำเนินการต่อ", :step=>"1", :xmain_id=>"64", :runseq_id=>"234"}}
    @rr3= stub_model(Rr3, "balance_out"=>50000, "qty"=>300, "interest"=>0, "receipt_no"=>7, "month"=>"Wed, 01 Jun 2011", "district_id"=>545, "amount"=>260000, "gma_user_id"=>2, "total"=>2600, "id"=>11, "qty_in"=>0, "qty_out"=>50, "receipt_book"=>9000, "fee"=>2600, "fine"=>0, "addition"=>1, "balance_in"=>0, "rr1_id"=>3, "balance"=>300000)
    Rr3.stub(:find).and_return(@rr3)
    @rr1= stub_model Rr1, "address"=>"1", "province_id"=>66, "zip"=>"00000", "code"=>"zzz", "doc"=>nil, "hotel_name"=>"zzz", "manager_citizen"=>"ไทย", "manager_province_id"=>66, "owner_district_id"=>545, "district_id"=>545, "license"=>"1/2", "owner_sub_district_id"=>6772, "gma_user_id"=>1, "manager_address"=>"222", "manager_national"=>"ไทย", "owner_dob"=>"Mon, 03 Jul 1911", "owner_phone"=>"076-111-222", "sub_district_id"=>6770, "total_fee"=>3500, "id"=>3, "lng"=>98.368, "owner_name"=>"abc", "pending_qty"=>50, "street"=>"รัษฏา", "manager_phone"=>"076-222-333", "owner_street"=>"รัษฎา", "manager_name"=>"xyz", "phone"=>"076-123-456", "at"=>"zzz", "brochure"=>1, "manager_district_id"=>545, "owner_citizen"=>"ไทย", "lat"=>7.86884, "manager_dob"=>"Mon, 03 Jul 1911", "manager_sub_district_id"=>6770, "manager_street"=>"ราชปรารภ", "owner_address"=>"123", "owner_national"=>"ไทย", "owner_province_id"=>66, "pending_fee"=>50000
    @rr3.stub(:rr1).and_return(@rr1)
    @receipt= stub_model Receipt, "section"=>"กองคลัง", "amount"=>2600, "gma_runseq_id"=>236, "gma_user_id"=>2, "gma_xmain_id"=>64, "id"=>7, "item"=>"ค่าธรรมเนียมบำรุง อบจ. จากผู้เข้าพักในโรงแรม ประจำเดือน มิถุนายน 2554", "payee"=>"zzz"
    Receipt.stub(:find).and_return(@receipt)
    # template.stub(:authorized? => true)
  end
 

  it "renders multiple months" do
    # Fail; pending copy districts, provinces into test db
    # render
    # response.should include_text("มกราคม กุมภาพันธ์")
  end
end
