module Gma
  require "rexml/document"
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper

  def local_ip
    RestClient.get "http://www.whatismyip.com/automation/n09230945.asp"
  end  

  def ping(server)
    ping_count = 3
    result = `ping -q -c #{ping_count} #{server}`
    $?.exitstatus == 0
  end
  def admin_action
#    flash[:notice]= "admin only"
    redirect_to "/" unless admin?
  end
  def postimg(f)
     agent = Mechanize.new
     page  = agent.get('http://www.postimg.com')
     form  = page.forms.first
     form.file_uploads.first.file_name = f
     result = agent.submit(form)
     result.links[1].uri.to_s
  end
  def gma_notice(s)
    GmaNotice.create :message=>s, :unread=>true
    return true
  end
  def display_notices
    t = []
    GmaNotice.new_notices.each do |n|
      t << n.message
      n.update_attribute :unread, false
    end
    t.join("<br/>")
  end
  def align_text(s, pixel=3)
    "<span style='position:relative; top:-#{pixel}px;'>#{s}</span>"
  end
  def align_img(s, pixel=3)
    "<span style='position:relative; top:#{pixel}px;'>#{s}</span>"
  end
  def fix_thai_year
    "<script type='text/javascript'>
    jQuery('select[id$=_1i] option').each(function(i) {
      this.text= parseInt(this.text)+543;
    });
    </script>"
  end

  def current_user
    if @current_user
      # return @current_user
    elsif (session && session[:user_id]) && User.exists?(session[:user_id])
      @current_user = User.find(session[:user_id])
    else
      @current_user = User.find_or_create_by_login("anonymous") do |u|
        u.role= ""
      end
    end
    @current_user
  end
  alias_method :get_user, :current_user

  def anonymous
    @current_user = User.find_or_create_by_login("anonymous") do |u|
      u.role= ""
    end
#    GmaUser.find_by_login "anonymous"
  end

  def status_icon(runseq)
    case runseq.status
    when 'R'
      image_tag 'user.png'
    when 'F'
      image_tag 'tick.png'
    when 'I'
      image_tag 'control_play.png'
    when 'E'
      image_tag 'logout.png'
    when 'X'
      image_tag 'cross.png'
    else
      image_tag 'cancel.png'
    end
  end
#  def status_icon(runseq)
#    case runseq.status
#    when "F"
#      image_tag "tick.png"
#    when "R"
#      image_tag "user.png"
#    when "I"
#      image_tag "dot.gif"
#    end
#  end
  def admin?
    role= current_user ? current_user.role : ""
    role.upcase.split(",").include?("A")
  rescue
    false
  end
  def login?
    session[:user_id] && GmaUser.exists?(session[:user_id]) && GmaUser.find(session[:user_id]).login!="anonymous"
  end
  alias_method(:logged_in?, :login?)
  
  def sha1(s)
    Digest::SHA1.hexdigest(s)
  end
  def http(href)
    # require 'open-uri'
    if PROXY
      open(href, :proxy=>PROXY).read
    else
      open(href).read
    end
  end
  def true_action?(s)
    %w(call ws redirect invoke email).include? s
  end
  def ui_action?(s)
    %w(form output mail pdf).include? s
  end
  def utf8_bom
    utf8_arr=[0xEF,0xBB,0xBF]
    utf8_str = utf8_arr.pack("c3")
    return utf8_str
  end
  def gma_comment?(s)
    s[0]==35
  end
  def redirect_to_root
    redirect_to root_path
  end
  def root_path
    root+"/"
  end
  def root
    ENV['RAILS_RELATIVE_URL_ROOT'] || ""
  end
  def gma_log(log_type, message)
    # remove params[:password] before log
    log_params= params
    log_params[:password]= nil
    GmaLog.create :log_type=>log_type, :message=>message,
#      :isession => session,
      :iparams=>log_params, :controller=>params[:controller], :action=>params[:action]
  end
  def exec_cmd(s)
    if win32?
      "******** You are using WIN32 system, please copy this command and execute in command prompt ********<br/>"+
      s+"<br/>"+"****************************************************************************************"
    else
      cmd= ExecCmd.new(s)
      cmd.run
      cmd.output
    end
  end
  def link_view_mm(msg)
    "<a href='#{root}/Gma/view_mm'>#{msg}</a>"
  end
  def file_asset_id(source)
    asset_id= ENV["RAILS_ASSET_ID"] ||
      File.mtime("#{RAILS_ROOT}/public/#{source}").to_i.to_s rescue ""
    #source << '?' + asset_id
    image_path "../#{source}?#{asset_id}"
  end
  def date_select_thai(object, method, default= Time.now, disabled=false)
    date_select object, method, :default => default, :use_month_names=>THAI_MONTHS, :order=>[:day, :month, :year], :disabled=>disabled
  end
#  def step(s, total) # graphic background
#    s = (s==0)? 1: s.to_i
#    total = total.to_i
#    out =[]
#    (s-1).times {|ss| out << "<span class='step_done' >#{ss+1}</span>" }
#    out << "<span class='step_now' >#{s}</span>"
#    for i in s+1..total
#      out << "<span class='step_more' >#{i}</span>"
#    end
#    text=""
#    out.each_with_index do |item, index|
#      text << item
#      text << "<br/>" if ((index+1)%7==0 && index!=0)
#    end
#    text
#  end
  def step(s, total) # square text
    s = (s==0)? 1: s.to_i
    total = total.to_i
    out ="<div class='step'>"
    (s-1).times {|ss| out += "<span class='steps_done'>#{(ss+1)}</span>" }
    out += %Q@<span class='step_now' >@
    out += s.to_s
    out += "</span>"
    out += %Q@@
    for i in s+1..total
      out += "<span class='steps_more'>#{i}</span>"
    end
    out += "</div>"
  end
#  def step(s, total) # Wingdings text
#    s = (s==0)? 1: s.to_i
#    total = total.to_i
#    out = %Q(<div class='step' style="font: 72pt 'Wingdings 2';">)
#    (s-1).times {|ss| out += (117+ss).chr }
#    out += %Q@<span style="color:red;">@
#    out += (116+s).chr
#    out += "</span>"
#    for i in s...total
#      out += (106+i).chr
#    end
#    out += "</div>"
#  end

  def win32?
    (RUBY_PLATFORM =~ /linux/).nil?
  end
  def nbsp(n)
    "&nbsp;"*n
  end
  def role_name(code)
    role= GmaRole.find_by_code(code)
    return role ? role.name : ""
  end
  def set_global
    $xmain= @xmain ; $runseq = @runseq ; $user = current_user ; $xvars= @xmain.xvars
  end
  def authorize? # use in pending tasks
    @runseq= @xmain.gma_runseqs.find @xmain.current_runseq
    return false unless @runseq
    @user = current_user
    set_global
#    debugger
    return false unless eval(@runseq.rule) if @runseq.rule
    return true if true_action?(@runseq.action)
    return false if check_wait
    return true if @runseq.role.blank?
    if @runseq.role
      return false unless @user.role
      return @user.role.upcase.split(',').include?(@runseq.role.upcase)
    end
  end

  def authorize_init? # use when initialize new transaction
    xml= @service.xml
    step1 = REXML::Document.new(xml).root.elements['node']
    role= get_option_xml("role", step1) || ""
#    rule= get_option_xml("rule", step1) || true
    return true if role==""
    user= get_user
    unless user
      return role.blank?
    else
      return false unless user.role
      return user.role.upcase.split(',').include?(role.upcase)
    end
  end
  def check_wait(runseq=@runseq)
    xml= REXML::Document.new(runseq.xml).root
    wait=[]
    xml.each_element('///node') do |n|
      text= n.attributes['TEXT']
      if text =~ /wait/i
        n.elements.each("node") do |nn|
          wait << nn.attributes['TEXT']
        end
      end
    end
    done= true
    unless wait.blank?
      wait.each do |w|
        runseq= @xmain.gma_runseqs.find_by_code w
        if runseq
          done= false unless runseq.status=='F'
        else
          gma_log("ERROR","check_wait: cannot find runseq.code='#{w}'")
        end
      end
    end
    !done
  end
#  def check_wait(runseq=@runseq)
#    wait= get_option('wait', runseq)
#    if wait
#      xvars= runseq.gma_xmain.xvars
#      return xvars[wait.to_sym] ? false : true
#    else
#      return false
#    end
#  end
  def get_ip
    request.env['HTTP_X_FORWARDED_FOR'] || request.env['REMOTE_ADDR']
  end
  def get_option(opt, runseq=@runseq)
    xml= REXML::Document.new(runseq.xml).root
    url=''
    xml.each_element('///node') do |n|
      text= n.attributes['TEXT']
      url= text if text =~/^#{opt}:\s*/
    end
    c, h= url.split(':', 2)
    opt= h ? h.strip : false
  end
  alias_method :get_option_runseq, :get_option
#  def get_option_xml_old(opt, xml)
#    #xml= REXML::Document.new(runseq.xml).root
#    url=''
#    xml.each_element('node') do |n|
#      text= n.attributes['TEXT']
#      url= text if text =~/^#{opt}:\s*/
#    end
#    c, h= url.split(':', 2)
#    opt= h ? h.strip : false
#  end
  # new get_option return h, false or nil if not found
  def get_option_xml(opt, xml)
    #xml= REXML::Document.new(runseq.xml).root
    if xml
      url=''
      xml.each_element('node') do |n|
        text= n.attributes['TEXT']
        url= text if text =~/^#{opt}/
      end
      return nil if url.blank?
      c, h= url.split(':', 2)
      opt= h ? h.strip : true
    else
      return nil
    end
  end
  def get_mm_links(runseq=@runseq)
    xml= REXML::Document.new(runseq.xml).root
    url=[]
    xml.each_element('///node') do |n|
      text= n.attributes['TEXT']
      next unless text =~/^link/i
      n.each_element('node') do |nn|
        if nn.elements['node']
          link_url= nn.elements['node'].attributes['TEXT']
          link_text = nn.attributes['TEXT']
          tip= link_url
        else
          link_url= root_path
          link_text = "#{nn.attributes['TEXT']}"
          tip= "<span style='color:red'>warning: no link specified in mindmap</span>"
        end
        url<< {:text=>link_text, :url=> link_url, :tip=> tip}
      end
    end
    url
  end
  def get_default_role
    default_role= GmaRole.find_by_code 'default'
    return default_role ? default_role.name.to_s : ''
  end
  def xml_text(s)
    html_escape(s).gsub("\n","<br/>")
  end
  def index_mm
#    findex= "#{RAILS_ROOT}/public/index.mm"
#    fmain= "#{RAILS_ROOT}/main.mm"
#    if File.exists?(findex)
#      f= findex
#    elsif File.exists?(fmain)
#      f= fmain
#    else
#      return nil
#    end
    "#{RAILS_ROOT}/public/index.mm"
  end
  # use in view_mm.rhtml
  def gma_root
    findex= "#{RAILS_ROOT}/public/index.mm"
    fmain= "#{RAILS_ROOT}/main.mm"
    if File.exists?(findex)
      return "public/index.mm"
    else
      return "main.mm"
    end
  end
  def get_app
    f= index_mm
    t= REXML::Document.new(File.read(f).gsub("\n","")).root
    recheck= true ; first_pass= true
    while recheck
      recheck= false
      t.elements.each("//node") do |n|
        if n.attributes['LINK'] # has attached file
          if first_pass
            f= "#{RAILS_ROOT}/public/#{n.attributes['LINK']}"
          else
            f= n.attributes['LINK']
          end
          next unless File.exists?(f)
          tt= REXML::Document.new(File.read(f).gsub("\n","")).root.elements["node"]
          make_folders_absolute(f,tt)
          tt.elements.each("node") do |tt_node|
            n.parent.insert_before n, tt_node
          end
          recheck= true
          n.parent.delete_element n
        end
#        if smile?(n) # has attached file
#          if first_pass
#            f= "#{RAILS_ROOT}/#{n.attributes['TEXT']}.mm"
#          else
#            f= "#{n.attributes['TEXT']}.mm"
#          end
#          next unless File.exists?(f)
#          tt= REXML::Document.new(File.read(f).gsub("\n","")).root.elements["node"]
#          make_folders_absolute(f,tt)
#          tt.elements.each("node") do |tt_node|
#            n.parent.insert_before n, tt_node
#          end
#          recheck= true
#          n.parent.delete_element n
#        end
      end
      first_pass = false
    end
    t
  end
  def make_folders_absolute(f,tt)
    # inspect all nodes that has attached file (2 cases) and replace relative path with absolute path
    tt.elements.each("//node") do |nn|
#      if smile?(nn)
#        nn.attributes['TEXT']= File.expand_path(File.dirname(f))+"/#{nn.attributes['TEXT']}"
#      end
      if nn.attributes['LINK']
        nn.attributes['LINK']= File.expand_path(File.dirname(f))+"/#{nn.attributes['LINK']}"
      end
    end
  end
  def smile?(n)
    # check to see if node has smile icon which indicates file attachment
    n.elements["icon"] && n.elements["icon"].attributes["BUILTIN"]=="ksmiletris"
  end
  def get_service(s)
    m,c= s.split("/")
    GmaService.first :conditions=>["module= ? AND code= ?", m,c]
  end

  def name2code(s)
    # rather not ignore # symbol cause it could be comment
    code, name = s.split(':')
    code.downcase.strip.gsub(' ','_').gsub(/[^#_\/a-zA-Z0-9]/,'')
  end
  def name2camel(s)
    s.gsub(' ','_').camelcase
  end
  def model_exists?(model)
    File.exists? "#{RAILS_ROOT}/app/models/#{model}.rb"
  end
  def controller_exists?(modul)
    File.exists? "#{RAILS_ROOT}/app/controllers/#{modul}_controller.rb"
  end
  def make_fields(n)
    f= ""
    n.each_element('node') do |nn|
      next if nn.attributes['TEXT'] =~ /\#.*/
      k,v= nn.attributes['TEXT'].split(/:\s*/,2)
      v ||= 'integer'
      v= 'float' if v=~/double/i
      f << " #{name2code(k.strip)}:#{v.strip} "
    end
    f
  end

  # old listed use edge to identified unlisted services, on my machine it's very
  # difficult to see the difference between thin edge and normal edge
#  def listed(node)
#    edge= node.elements["edge"]
#    return edge ? node.elements["edge"].attributes["WIDTH"] != "thin" : true
#  end
  def listed(node)
    icons=[]
    node.each_element("icon") do |nn|
      icons << nn.attributes["BUILTIN"]
    end
    return !icons.include?("closed")
##    icon= node.elements["icon"]
#    return icon ? node.elements["icon"].attributes["BUILTIN"] != "closed" : true
  end
  def secured?(node)
    icons=[]
    node.each_element("icon") do |nn|
      icons << nn.attributes["BUILTIN"]
    end
    return icons.include?("password")
  end
  def freemind2action(s)
    case s.downcase
    #when 'bookmark' # Excellent
    #  'call'
    when 'bookmark' # Excellent
      'do'
    when 'attach' # Look here
      'form'
    when 'edit' # Refine
      'pdf'
    when 'wizard' # Magic
      'ws'
    when 'help' # Question
      'if'
    when 'forward' # Forward
      'redirect'
    when 'kaddressbook' #Phone
      'invoke' # invoke new service along the way
    when 'pencil'
      'output'
    when 'mail'
      'mail'
    end
  end
  def affirm(s)
    s =~ /[y|yes|t|true]/i
  end
  def negate(s)
    s =~ /[n|no|f|false]/i
  end
  def get_xvars
    @runseq= GmaRunseq.find($runseq_id)
    @xmain= @runseq.gma_xmain
    @xvars= @xmain.xvars
  end
  def save_xvars
    @xmain.xvars= @xvars
    @xmain.save
  end
  def date_thai(d= Time.now, options={})
    unless d
      ""
    else
      y = d.year+543
      if options[:monthfull]
        mh= ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฏาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม']
      else
        mh= ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.']
      end
      if options[:date_only]
        d.day.to_s+" "+mh[d.month-1]+" "+y.to_s
      else
        d.day.to_s+" "+mh[d.month-1]+" "+y.to_s+" เวลา "+sprintf("%02d",d.hour.to_s)+":"+sprintf("%02d",d.min.to_s)
      end
    end
  end
  def date_us(d= Time.now, options={})
    if options[:date_only]
      d.strftime("%b %e, %Y")
#      d.day.to_s+" "+mh[d.month-1]+" "+y.to_s
    else
      d.strftime("%b %e, %Y at ") + d.strftime("%I:%M%p").gsub(/^0/,'')
#      d.day.to_s+" "+mh[d.month-1]+" "+y.to_s+" เวลา "+sprintf("%02d",d.hour.to_s)+":"+sprintf("%02d",d.min.to_s)
    end
  end
  def tis620(t)
    cd = Iconv.new("TIS-620", "UTF-8")
    cd.iconv(t)
  end
  def utf8(t)
    #cd = Iconv.new("UTF-8", "TIS-620")
    cd = Iconv.new("UTF-8//IGNORE", "TIS-620")
    cd.iconv(t)
  end
  def set_songrit(k,v)
    songrit = GmaSongrit.find_by_code k
    songrit = GmaSongrit.new :code=> k unless songrit
    songrit.value= v
#    if session && session[:user_id]
#      songrit.gma_user_id= session[:user_id]
#    end
    songrit.save
  end
  def songrit(k, default='')
    songrit = GmaSongrit.find_by_code(k)
    begin
      gma_user_id= session[:user_id]
    rescue
      gma_user_id= nil
    end
    songrit= GmaSongrit.create(:code=>k, :value=>default, :gma_user_id=>gma_user_id) unless songrit
    return songrit.value
  end
end

##########
class ExecCmd
  attr_reader :output,:cmd,:exec_time
  #When a block is given, the command runs before yielding
  def initialize cmd
    @cmd=cmd
    @cmd_run=cmd+" 2>&1" unless cmd=~/2>&1/
    if block_given?
      run
      yield self
    end
  end
  #Runs the command
  def run
    t1=Time.now
    IO.popen(@cmd_run){|f|
      @output=f.read
      @process=Process.waitpid2(f.pid)[1]
    }
    @exec_time=Time.now-t1
  end
  #Returns false if the command hasn't been executed yet
  def run?
    return false unless @process
    return true
  end
  #Returns the exit code for the command. Runs the command if it hasn't run yet.
  def exitcode
    run unless @process
    @process.exitstatus
  end
  #Returns true if the command was succesfull.
  #
  #Will return false if the command hasn't been executed
  def success?
    return @process.success? if @process
    return false
  end
end

class NilClass
  def center(n,c)
    c*n
  end
end
class String
  def comment?
    self[0]==35 # check if first char is #
  end
  def to_wwp_code
    s= self.dup
    s.downcase!
    s.gsub! /[\s\-_]/, ""
    s
  end
end

module ActionView
  module Helpers
    class FormBuilder
#      def date_select_thai(method)
#        self.date_select method, :use_month_names=>THAI_MONTHS, :order=>[:day, :month, :year]
#      end
      def date_select_thai(method, default= Time.now, disabled=false)
        date_select method, :default => default, :use_month_names=>THAI_MONTHS, :order=>[:day, :month, :year], :disabled=>disabled
      end
      def datetime_select_thai(method, default= Time.now, disabled=false)
        datetime_select method, :default => default, :use_month_names=>THAI_MONTHS, :order=>[:day, :month, :year], :disabled=>disabled
      end

      def point(o={})
        o[:zoom]= 11 unless o[:zoom]
        o[:width]= '500px' unless o[:width]
        o[:height]= '300px' unless o[:height]
        if o[:lat].blank?
          o[:lat] = 37.5
          o[:lng] = -95
          o[:zoom] = 4
        end

        text = <<-EOT
  <script type='text/javascript'>
  //<![CDATA[
    var latLng;
    var map_#{self.object_name};
    var marker_#{self.object_name};

    function initialize() {
      var lat =  #{o[:lat]};
      var lng =  #{o[:lng]};
      //var lat =  position.coords.latitude"; // HTML5 pass position in function initialize(position)
      // google.loader.ClientLocation.latitude;
      //var lng =  position.coords.longitude;
      // google.loader.ClientLocation.longitude;
      latLng = new google.maps.LatLng(lat, lng);
      map_#{self.object_name} = new google.maps.Map(document.getElementById("map_#{self.object_name}"), {
        zoom: #{o[:zoom]},
        center: latLng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
      });
      marker_#{self.object_name} = new google.maps.Marker({
        position: latLng,
        map: map_#{self.object_name},
        draggable: true,
      });
      google.maps.event.addListener(marker_#{self.object_name}, 'dragend', function(event) {
        $('##{self.object_name}_lat').val(event.latLng.lat());
        $('##{self.object_name}_lng').val(event.latLng.lng());
      });
      google.maps.event.addListener(map_#{self.object_name}, 'click', function(event) {
        $('##{self.object_name}_lat').val(event.latLng.lat());
        $('##{self.object_name}_lng').val(event.latLng.lng());
        move();
      });
      $('##{self.object_name}_lat').val(lat);
      $('##{self.object_name}_lng').val(lng);

    };


    function move() {
      latLng = new google.maps.LatLng($('##{self.object_name}_lat').val(), $('##{self.object_name}_lng').val());
      map_#{self.object_name}.panTo(latLng);
      marker_#{self.object_name}.setPosition(latLng);
    }

    google.maps.event.addDomListener(window, 'load', initialize);
    //if (navigator.geolocation) {
    // navigator.geolocation.getCurrentPosition(initialize);
    //} else {
    // google.maps.event.addDomListener(window, 'load', no_geo);
    //}


  //]]>
  </script>
  Latitude: #{self.text_field :lat, :style=>"width:200px"}
  Longitude: #{self.text_field :lng, :style=>"width:200px"}
  <p/>
  <div id='map_#{self.object_name}' style='width:#{o[:width]}; height:#{o[:height]};'></div>
  <script>
    $('##{self.object_name}_lat').change(function() {move()})
    $('##{self.object_name}_lng').change(function() {move()})
  </script>
EOT
      end
    end
  end
end

class Float
  alias_method(:original_to_s, :to_s) unless method_defined?(:original_to_s)

  def is_whole?
    self % 1 == 0
  end

  def to_s
    self.is_whole? ? self.to_i.to_s : self.original_to_s
  end
end
