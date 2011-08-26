pdf.font_families.update("sarabun" => { 
  :normal => "#{RAILS_ROOT}/public/fonts/sarabun.ttf",
  :bold=> "#{RAILS_ROOT}/public/fonts/sarabun_bold.ttf" })
pdf.font("sarabun")
head= {:align=>:center, :size=>24, :style=>:bold}
pdf.text "รายงานการรับเงินค่าธรรมเนียมบำรุงองค์การบริหารส่วนจังหวัด", head
pdf.text "จากผู้เข้าพักในโรงแรม", head
m= begin_of_last_month
pdf.text "ประจำเดือน #{MONTHS[m.month-1]} #{m.year+543}", head
@districts.each do |district_id|
  pdf.move_down 20
  district = District.find district_id
  total_this_month = 0
  total_ytd = 0
  rr1s= Rr1.all :conditions => {:district_id=>district_id}, :order => "hotel_name" 
  details= [["ลำดับที่", "โรงแรม / ที่พัก", "ใบอนุญาต", "ค่าธรรมเนียมเดือนนี้", "ค่าธรรมเนียมตั้งแต่ต้นปี"]]  
  details += rr1s.each_with_index.map do |rr1, i|
    ytd = Rr3.sum(:fee, :conditions=>['month>=? AND rr1_id=?', @begin_of_year, rr1.id])
    this_month = Rr3.sum(:fee, :conditions=>['month>=? AND month<=? AND rr1_id=?', begin_of_last_month, end_of_last_month, rr1.id])
    total_this_month += this_month
    total_ytd += ytd
    [ i+1, rr1.hotel_name, rr1.license || '-', num(this_month,2), num(ytd,2) ]
  end
  details += [['','','รวม',num(total_this_month,2), num(total_ytd,2)]]
  pdf.text "อำเภอ #{district.name}", :style=>:bold
  pdf.table(details, :header=>true, :width => pdf.bounds.width, :row_colors => ["FFFFFF","EEEEEE"]) do
    column(3..4).align = :right
  end
end
