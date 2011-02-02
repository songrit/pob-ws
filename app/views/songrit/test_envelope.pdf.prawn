pdf.font("#{RAILS_ROOT}/public/charm.ttf")
pdf.font_size 16
pdf.text_box @sender, :at=>[75,235]

pdf.font_size 20
pdf.text_box @recipient, :at=>[255,130]
