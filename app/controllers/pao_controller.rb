class PaoController < ApplicationController
  def index
    @revenues= []
    @districts= Rr3.all(:group=>:district_id, :select => "district_id", 
      :conditions => ['month >= ? and month<= ?', 
      Date.new(Time.now.year,1,1), end_of_last_month]).
      map(&:district_id)
    # @district_names= District.find(@districts).map(&:name)
    @districts.each do |d|
      name= District.find(d).name
      rr3_this_month= Rr3.all :conditions => ['month >= ? and month<= ? and district_id= ?', begin_of_last_month, end_of_last_month, d ]
      qty= rr3_this_month.map(&:rr1_id).uniq.count
      rr3_ytd= Rr3.all :conditions => ['month >= ? and month<= ? and district_id= ?', Date.new(Time.now.year,1,1), end_of_last_month, d ]
      qty_ytd= rr3_ytd.map(&:rr1_id).uniq.count
      total= Rr3.sum :total, :conditions => ['month >= ? and month<= ? and district_id= ?', begin_of_last_month, end_of_last_month, d ]
      total_ytd= Rr3.sum :total, :conditions => ['month >= ? and month<= ? and district_id= ?', Date.new(Time.now.year,1,1), end_of_last_month, d ]
      @revenues << {:district_id=>d, :total=>total, :qty=>qty, 
        :total_ytd=>total_ytd, :qty_ytd => qty_ytd, :name=>name }
    end
  end
  def detail
    @begin_of_year= Date.new Time.now.year
    @rr1s= Rr1.all :conditions => {:district_id=>params[:id]}, :order => "hotel_name" 
    @district_name= District.find(params[:id]).name
  end
  def hotels
    @rr1s= Rr1.all :order=>:district_id
  end

  # gma
  def create_hotel
    rr1= Rr1.create $xvars[:enter_rr1][:rr1]
    $xvars[:rr1_id]= rr1.id
    $xvars[:p][:return]= "/pao"
  end
  def create_room
    unless $xvars[:enter_room][:room][:name].empty?
      rr1= Rr1.find $xvars[:rr1_id]
      rr1.rooms << Room.create($xvars[:enter_room][:room])
    end
  end
  def create_fee
    rr1= Rr1.find $xvars[:select_hotel][:hotel_id]
    rr3= rr1.rr3s.build $xvars[:enter_rr3][:rr3]
    # rr3.rr1_id= rr1.id
    rr3.amount = rr1.pending_fee+rr3.balance-rr3.balance_out
    rr3.fee = rr3.amount/100
    rr3.total = rr3.fee+rr3.interest+rr3.fine
    item = "ค่าธรรมเนียมบำรุง อบจ. จากผู้เข้าพักในโรงแรม ประจำเดือน #{THAI_MONTHS[rr3.month.month]} #{rr3.month.year+543}"
    receipt= Receipt.create :section=> "กองคลัง",
      :payee => rr1.hotel_name, :item => item, :amount => rr3.fee,
      :gma_xmain_id => $xmain.id, :gma_runseq_id => $runseq.id 
    rr3.receipt_book= 9000
    rr3.receipt_no= receipt.id
    rr1.pending_fee = rr3.balance_out
    rr1.pending_qty = rr3.qty_out
    rr1.total_fee += rr3.total
    rr3.district_id= rr1.district_id
    rr1.save
    rr3.save
    $xvars[:rr3_id]= rr3.id
    $xvars[:receipt_id]= receipt.id
    $xvars[:p][:return]= "/pao"
  end
  
  # ajax
  def get_districts
    province= Province.find params[:id]
    prompt= "<option value="">..กรุณาเลือกอำเภอ</option>"
    render :text => prompt+@template.options_from_collection_for_select(province.districts,:id,:name)
  end
  def get_sub_districts
    district= District.find params[:id]
    render :text => @template.options_from_collection_for_select(district.sub_districts,:id,:name)
  end
end
