pdf.font_families.update("sarabun" => { 
  :normal => "#{RAILS_ROOT}/public/fonts/sarabun.ttf",
  :bold=> "#{RAILS_ROOT}/public/fonts/sarabun_bold.ttf" })
pdf.font("sarabun")
head= {:align=>:center, :size=>24, :style=>:bold}
pdf.text "รายงานการจองห้องพักโรงแรม", head
pdf.text "ระบบแลกเปลี่ยนข้อมูลกลางฯ องค์การบริหารส่วนจังหวัดภูเก็ต", head
pdf.move_down 20
details= [["วันที่จอง", "โรงแรม", "ลูกค้า", "วันที่เข้าพัก"]]  
@bookings.each do |booking|
  next unless booking.hotel
  doc = Nokogiri::XML(booking.reservation)
  customer= doc.xpath('//Customer')
  details += [[ date_thai(booking.created_at), booking.hotel.name, 
    "#{(customer/'NamePrefix').text} #{(customer/'GivenName').text} #{(customer/'Surname').text}",
    date_thai(booking.start_on, :date_only=>true) ]]
end
pdf.table(details, :header=>true, :width => pdf.bounds.width, :row_colors => ["FFFFFF","EEEEEE"])
