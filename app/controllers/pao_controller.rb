class PaoController < ApplicationController
  def index
    render :text=> "coming soon...", :layout => true 
  end

  # gma
  def create_hotel
    rr1= Rr1.create $xvars[:enter_rr1][:rr1]
    $xvars[:rr1_id]= rr1.id
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
    rr1.pending_fee = rr3.balance_out
    rr1.pending_qty = rr3.qty_out
    rr1.total_fee += rr3.total
    rr1.save
    $xvars[:rr3_id]= rr3.id
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
