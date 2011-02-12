class SongritController < ApplicationController
  include ActionView::Helpers::DebugHelper
  include ERB::Util
  require "csv"
  require "hpricot"
  require "open-uri"
  require 'nokogiri'
  require 'mechanize'

  def test_ip
    render :text => request.ip
  end
  def test_escape
    render :text => html_escape("<aa>")
  end
  def end_of_last_month
    d= Date.today
    dd= Date.new d.year, d.month, 1
    render :text=> dd-1
  end
  def send_dloc_mail
    count= 0
    DlocMail.unsent.each do |m|
      from= "dlocthai@gmail.com"
      #    if m.recipient =~ /^([0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$/
      Notifier.deliver_gma(from, m.recipient.chomp(","), m.subject, m.body||="" )
      #    end
      m.sent= true
      m.save
      count += 1
    end
    logger.info "#{Time.now}: sent #{count} mails\n\n"
    render :text => "#{Time.now}: sent #{count} mails\n\n"
  end
  def test_user_agent
    render :text => request.user_agent
  end
  def test_rmagick
    img_orig = Magick::Image.read("tmp/f6").first
#    img = img_orig.matte_floodfill("white")
    img_orig.write("tmp/f0.gif")
    render :text => "done"
  end
  def test_postimg
    p = postimg("/media/DATA/pictures/2print/IMAG0742.jpg")
    render :text => "<a href='#{p}'>#{p}</a>"
  end
end

