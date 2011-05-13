class PaoController < ApplicationController
  def index
    render :text=> "coming soon...", :layout => true 
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
