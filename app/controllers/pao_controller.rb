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
