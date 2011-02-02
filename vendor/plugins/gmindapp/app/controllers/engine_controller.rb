class EngineController < ApplicationController
  require "erb"
  require "prawn/core"
  include ERB::Util
  include Prawn::Measurements

  def init
    @service= GmaService.first :conditions=>['module=? AND code=?',
      params[:module], params[:service] ]
#    debugger
    if @service && authorize_init?
      xmain = create_xmain(@service)
      result = create_runseq(xmain)
      unless result
        message = "cannot find action for xmain #{xmain.id}"
        gma_log("ERROR", message)
        flash[:notice]= message
        redirect_to_root and return
      end
      xmain.update_attribute(:xvars, @xvars)
      xmain.gma_runseqs.last.update_attribute(:end,true)
      redirect_to :action=>'run', :id=>xmain.id
    else
      flash[:notice]= "ขออภัย ไม่สามารถทำงานได้"
      gma_log("SECURITY", "unauthorize access: #{params.inspect}")
      redirect_to_root
    end
  end
  def run
    init_vars(params[:id])
    if authorize?
      redirect_to(:action=>"run_#{@runseq.action}", :id=>@xmain.id)
    else
      redirect_to_root
    end
  end
  def run_form
    init_vars(params[:id])
    if authorize?
      if ['F', 'X'].include? @xmain.status
        #      flash[:notice] = "invalid url"
        redirect_to_root
      else
        @title= "xmain id #{@xmain.id}: #{@xmain.name}"
        service= @xmain.gma_service
        if service
          f= "app/views/#{service.module}/#{service.code}/#{@runseq.code}.rhtml"
          @ui= File.read(f)
          @message = "ดำเนินการต่อ &gt;"
          #      @message = "Done" if @runseq.form_step==@xvars[:total_form_steps]
        else
          flash[:notice]= "ไม่สามารถค้นหาบริการที่ต้องการได้"
          redirect_to_root
        end
      end
    else
      redirect_to_root
    end
  end
  def gma_debug(s)
    File.open("log/gma.log", "a") do |f|
      f.puts "#{Time.now}-#{current_user.login}:#{s}"
    end
  end
  def cancel
    GmaXmain.find(params[:id]).update_attributes :status=>'X'
    if params[:return]
      redirect_to params[:return]
    else
      redirect_to_root
    end
  end

  def run_invoke # kaddressbook
    init_vars(params[:id])
    m, s = discover_service(@runseq.code)
    # logger.debug "discover #{m}, #{s}"
    service= GmaService.first :conditions=>['module=? AND code=?', m,s ]
    @invoke_xvars= @xvars
    xmain = create_xmain(service)
    create_runseq(xmain)
    @xvars[:invoke_xvars]= @invoke_xvars
    xmain.update_attribute(:xvars, @xvars)
    xmain.gma_runseqs.last.update_attribute(:end,true)
    @xvars= @invoke_xvars #restore current @xvars
    end_action
  rescue => e
    @xmain.status='E'
    @xvars[:error]= e
    flash[:notice]= "ERROR: Job Abort<br/>#{xml_text e}<hr/>"
    end_action(nil)
  end
  def sign_form
    init_vars(params[:xmain_id])
    eval "@xvars[:#{@runseq.code}] = params"
    params.each { |k,v| get_image(k, params[k]) }
    @xmain.xvars= @xvars
    @xmain.save
    @user= current_user || GmaUser.new
    @system_attributes= %w(commit step authenticity_token action runseq_id controller login xmain_id)
    data_text= render_to_string(:template=>"engine/sign_form_print", :layout=>"utf8")
    @gma_doc= GmaDoc.create :name=> @runseq.name,
      :content_type=>"temp", :data_text=> data_text,
      :gma_xmain_id=>@xmain.id, :gma_runseq_id=>@runseq.id, :gma_user_id=>session[:user_id],
      :ip=> get_ip, :gma_service_id=>@xmain.gma_service_id, :display=>true,
      :secured => @xmain.gma_service.secured
    digest= EzCrypto::Digester.digest64(data_text)
    digest.gsub!(' ','%20')
    digest.gsub!('+','%2B')
    digest.gsub!('=','%3D')
    digest.gsub!("\n",'')
    callback= "#{url_for :action=>:print_sign_form, :id=>@gma_doc.id}"
#    doc= "http://#{request.env['HTTP_HOST']}#{url_for :action=>:validate, :id=>@gma_doc.id}"
    #headers["Status"] = "301 Moved Permanently"
    #redirect_to "http://#{songrit('localhost')}/engine/signing?digest=#{digest}&login=#{current_user.login}&callback=#{callback}"
#    headers["Status"] = "301 Moved Permanently"
    @redirect = "http://#{songrit('localhost')}/engine/signing?login=#{current_user.login}&callback=#{callback}&digest=#{digest}"
  end
  def print_sign_form
    @gma_doc= GmaDoc.find params[:id]
    signature= params[:sig].gsub('%2B','+')
    signature.gsub!(' ','+')
    @gma_doc.signature= signature
    @gma_doc.content_type= "signed document"
    @gma_doc.save
    init_vars(@gma_doc.gma_xmain_id)
    @message = @runseq.end ? "สิ้นสุดการทำงาน" : "ดำเนินการต่อ"
  end
  def end_sign_form
    init_vars(params[:xmain_id])
    end_action
  end
  def end_form
    init_vars(params[:xmain_id])
    eval "@xvars[:#{@runseq.code}] = {} unless @xvars[:#{@runseq.code}]"
    params.each { |k,v|
      if params[k].respond_to? :original_filename
        get_image(k, params[k])
      elsif params[k].is_a?(Hash)
        eval "@xvars[:#{@runseq.code}][:#{k}] = v"
        params[k].each { |k1,v1|
          next unless v1.respond_to?(:original_filename)
          get_image1(k, k1, params[k][k1])
        }
      else
        eval "@xvars[:#{@runseq.code}][:#{k}] = v"
      end
    }
    end_action
  end
  # process images from first level
  def get_image(key, params)
    # use mongo to store image
#    upload = Upload.create :content=> params.read
    doc = GmaDoc.create(
      :name=> key.to_s,
      :gma_xmain_id=> @xmain.id,
      :gma_runseq_id=> @runseq.id,
      :filename=> params.original_filename,
      :content_type => params.content_type || 'application/zip',
 #     :data_text=> upload.id.to_s,
      :data_text=> '',
      :display=>true,
      :secured => @xmain.gma_service.secured )
    path = defined?(IMAGE_LOCATION) ? IMAGE_LOCATION : "tmp"
    File.open("#{path}/f#{doc.id}","wb") { |f|
      f.puts(params.read)
    }
    eval "@xvars[:#{@runseq.code}][:#{key}] = '#{url_for(:action=>'document', :id=>doc.id)}' "
    eval "@xvars[:#{@runseq.code}][:#{key}_doc_id] = #{doc.id} "
  end
  # process images from second level, e.g,, fields_for
  def get_image1(key, key1, params)
    # use mongo to store image
#    upload = Upload.create :content=> params.read
    doc = GmaDoc.create(
      :name=> "#{key}_#{key1}",
      :gma_xmain_id=> @xmain.id,
      :gma_runseq_id=> @runseq.id,
      :filename=> params.original_filename,
      :content_type => params.content_type || 'application/zip',
#      :data_text=> upload.id.to_s,
      :data_text=> '',
      :display=>true, :secured => @xmain.gma_service.secured )
    path = defined?(IMAGE_LOCATION) ? IMAGE_LOCATION : "tmp"
    File.open("#{path}/f#{doc.id}","wb") { |f|
       f.puts(params.read)
   }

    eval "@xvars[:#{@runseq.code}][:#{key}][:#{key1}] = '#{url_for(:action=>'document', :id=>doc.id)}' "
    eval "@xvars[:#{@runseq.code}][:#{doc.name}_doc_id] = #{doc.id} "
  end
  def run_output
    init_vars(params[:id])
    service= @xmain.gma_service
    disp= get_option("display")
    display = (disp && !affirm(disp)) ? false : true
    if service
      f= "app/views/#{service.module}/#{service.code}/#{@runseq.code}.rhtml"
      @ui= File.read(f)
      if GmaDoc.exists? :gma_runseq_id=>@runseq.id
        @gma_doc= GmaDoc.find_by_gma_runseq_id @runseq.id
        GmaDoc.update @gma_doc.id, :data_text=> render_to_string(:inline=>@ui, :layout=>"utf8"),
          :gma_xmain_id=>@xmain.id, :gma_runseq_id=>@runseq.id, :gma_user_id=>session[:user_id],
          :ip=> get_ip, :gma_service_id=>service.id, :display=>display,
          :secured => @xmain.gma_service.secured
      else
        @gma_doc= GmaDoc.create :name=> @runseq.name,
          :content_type=>"output", :data_text=> render_to_string(:inline=>@ui, :layout=>"utf8"),
          :gma_xmain_id=>@xmain.id, :gma_runseq_id=>@runseq.id, :gma_user_id=>session[:user_id],
          :ip=> get_ip, :gma_service_id=>service.id, :display=>display,
          :secured => @xmain.gma_service.secured
      end
      @message = "ดำเนินการต่อ"
      @message = "สิ้นสุดการทำงาน" if @runseq.end
      eval "@xvars[:#{@runseq.code}] = url_for(:controller=>'engine', :action=>'document', :id=>@gma_doc.id)"
    else
      flash[:notice]= "ไม่สามารถค้นหาบริการที่ต้องการได้"
      redirect_to_root
    end
    #display= get_option("display")
    unless display
      end_action
    end
  end
  def end_output
    init_vars(params[:xmain_id])
    end_action
  end
  def run_pdf
    init_vars(params[:id])
    service= @xmain.gma_service
    @t = "tmp/pdf#{current_user.login}#{Time.now.strftime("%y%m%d%H%M%S")}.pdf"
    f= File.read "app/views/#{service.module}/#{service.code}/#{@runseq.code}.pdf.prawn"
    Prawn::Document.generate @t, :page_size   => eval(get_option("size")),
      :page_layout => get_option("layout").to_sym do |pdf|
      eval(f)
    end
    @message = get_option("message")||"Next &gt;"
  end
  def send_pdf
    d= File.read params[:f]
    send_data d, :filename=>"envelope.pdf", :type => 'application/pdf', :disposition => 'inline'
  end
  def run_ws
    init_vars(params[:id])
    href= render_to_string :inline=>get_option('url', @runseq)
    result= http(href)
    eval "@xvars[:#{@runseq.code}] = result"
    end_action
  end
  # old ws post to queue and gets run by Nso::LaborController#pending_tasks
  # which call EngineController#ws_dispatch
  def run_ws0
    init_vars(params[:id])
    href= render_to_string :inline=>get_option('url', @runseq)
    if request.remote_ip=="127.0.0.1"
      @xvars[@runseq.code.to_sym]= @xvars[:result] = 'ws not call because running from localhost'
    else
      GmaWsQueue.create :gma_runseq_id=>@runseq.id, :url=>href, :poll_url=>href,
        :next_poll_at=> Time.now, :wait=>WS_WAIT, :status=>'I', :user_id=>get_user.id
    end
    end_action
  end
  def run_mail
    init_vars(params[:id])
    service= @xmain.gma_service
    f= "app/views/#{service.module}/#{service.code}/#{@runseq.code}.rhtml"
    @ui= File.read(f)
    @gma_doc= GmaDoc.create :name=> @runseq.name,
      :content_type=>"output", :data_text=> render_to_string(:inline=>@ui, :layout=>"utf8"),
      :gma_xmain_id=>@xmain.id, :gma_runseq_id=>@runseq.id, :gma_user_id=>session[:user_id],
      :ip=> get_ip, :gma_service_id=>service.id, :display=>true,
      :secured => @xmain.gma_service.secured
    eval "@xvars[:#{@runseq.code}] = url_for(:controller=>'engine', :action=>'document', :id=>@gma_doc.id)"
    sender= render_to_string(:inline=>get_option('from'))
    recipients= render_to_string(:inline=>get_option('to'))
    recipients= 'songrit@velocall.com' if recipients.blank?
    subject= render_to_string(:inline=>get_option('subject')) || "#{@runseq.code}"
    Notifier.deliver_gma(sender,recipients,subject, @gma_doc.data_text) unless defined?(DONT_SEND_MAIL)
    end_action
  end
  def run_do
    init_vars(params[:id])
    @runseq.start ||= Time.now
    @runseq.status= 'R' # running
    $runseq_id= @runseq.id; $user_id= get_user.id
    set_global
#    $xvars = @xvars
#    $xmain = @xmain
#    $runseq = @runseq
#    result= eval("#{@xvars[:custom_controller]}.new.#{@runseq.code}")
    controller = Kernel.const_get(@xvars[:custom_controller]).new
    result = controller.send(@runseq.code)
    init_vars_by_runseq($runseq_id)
    @xvars = $xvars
    @xvars[@runseq.code.to_sym]= result
    @xvars[:current_step]= @runseq.rstep
    @runseq.status= 'F' #finish
    @runseq.stop= Time.now
    @runseq.save
    end_action
  rescue => e
    @xmain.status='E'
    @xvars[:error]= e
    @xmain.xvars= $xvars
    @xmain.save
    @runseq.status= 'F' #finish
    @runseq.stop= Time.now
    @runseq.save
    flash[:notice]= "Sorry, there was some problem processing your request."
#    flash[:notice]= "ERROR: Job Abort xmain #{@xmain.id} runseq #{@runseq.id}<br/>#{xml_text e}<hr/>"
    gma_log("ERROR", "Job Abort xmain #{@xmain.id} runseq #{@runseq.id}<br/>#{xml_text e}<hr/>")
#    end_action(nil)
#    end_action
    redirect_to_root
  end
  def run_call
    init_vars(params[:id])
    # change from 'fork' (use in nso project) to 'background'
    if affirm(get_option('background', @runseq))
      fork "engine/run_call_background/#{@runseq.id}"
    else
      @runseq.start ||= Time.now
      @runseq.status= 'R' # running
      $runseq_id= @runseq.id; $user_id= get_user.id
      result= eval("#{@xvars[:custom_controller]}.new.#{@runseq.code}")
      init_vars_by_runseq($runseq_id)
      @xvars[@runseq.code.to_sym]= result
      @xvars[:current_step]= @runseq.rstep
      @runseq.status= 'F' #finish
      @runseq.stop= Time.now
      @runseq.save
    end
    end_action
  rescue => e
    @xmain.status='E'
    @xvars[:error]= e
    @xmain.xvars= @xvars
    @xmain.save
    @runseq.status= 'F' #finish
    @runseq.stop= Time.now
    @runseq.save
    flash[:notice]= "Sorry, there was some problem processing your request."
#    flash[:notice]= "ERROR: Job Abort xmain #{@xmain.id} runseq #{@runseq.id}<br/>#{xml_text e}<hr/>"
    gma_log("ERROR", "Job Abort xmain #{@xmain.id} runseq #{@runseq.id}<br/>#{xml_text e}<hr/>")
#    end_action(nil)
#    end_action
    redirect_to_root
  end
  def run_call_background # pass params runseq_id
    init_vars_by_runseq(params[:id])
    m = name2camel(@xmain.gma_service.app.code)
    c = name2camel(@xmain.gma_service.module)
    controller= "#{m}::#{c}Controller"
    # mark F to avoid infinite loop in case controller error
    @runseq.status= 'F'
    $runseq_id= @runseq.id
    result= eval("#{controller}.new.#{@runseq.code}")
    init_vars_by_runseq($runseq_id)
    @xvars[@runseq.code.to_sym]= result
    @xvars[:current_step]= @runseq.rstep
    #end_action
    @xmain.xvars= @xvars
    @xmain.save
    @runseq.status= 'F' #finish
    @runseq.stop= Time.now
    @runseq.save
    render :text => "Done: #{@runseq.id} #{@runseq.code} at #{Time.now}"
  end
  def run_if
    init_vars(params[:id])
#    debugger
    condition= eval(@runseq.code)
    match_found= false
    if condition
      xml= REXML::Document.new(@runseq.xml).root
      next_runseq= nil
      text = xml.elements['//node/node'].attributes['TEXT']
      match, name= text.split(':',2)
      label= name2code(name.strip)
      if condition==match
        if label=="end"
          @end_job= true
        else
          next_runseq= @xmain.gma_runseqs.find_by_code label
          match_found= true if next_runseq
          @runseq_not_f= false
        end
      end
    end
    unless match_found || @end_job
      next_runseq= @xmain.gma_runseqs.find :first, :conditions=>"rstep=#{@xvars[:current_step]+1}"
    end
    end_action(next_runseq)
  end
  def ws_dispatch
    GmaWsQueue.all(:conditions=>["status != 'F'"]).each do |ws|
      puts "Time now is #{Time.now} next poll at is #{ws.next_poll_at}\n"
      next if Time.now < ws.next_poll_at
      puts "process #{ws.id}"
      result= REXML::Document.new(http(ws.poll_url)).root
      if result and result.elements['async']
        ws.poll_url= result.elements['async'].attributes['poll_url']
        wait= result.elements['async'].attributes['wait'].to_i
        ws.wait = wait unless wait==0
        ws.next_poll_at = Time.now + ws.wait*60
        ws.status= 'R'
        ws.save
      else
        @runseq= GmaRunseq.find ws.gma_runseq_id
        @xmain= @runseq.gma_xmain
        @xvars= @xmain.xvars
        @xvars[@runseq.code.to_sym] = @xvars[:result]= result.to_s
        ws.status= 'F'
        @runseq.status='F'
        @xmain.xvars= @xvars
        @xmain.save; @runseq.save; ws.save
      end
    end
    render :text => "done"
  end
  def run_redirect
    init_vars(params[:id])
    next_runseq= @xmain.gma_runseqs.first :conditions=>["id != ? AND code = ?",@runseq.id, @runseq.code]
    @xmain.current_runseq= next_runseq.id
    end_action(next_runseq)
  end
  def document
    path = defined?(IMAGE_LOCATION) ? IMAGE_LOCATION : "tmp"
    if GmaDoc.exists?(params[:id])
      doc = GmaDoc.find params[:id]
      if doc.secured
        if current_user.secured? || doc.gma_user_id==session[:user_id]
          view= true
        else
          view= false
        end
      else
        view= true
      end
      if view
        if %w(output temp).include?(doc.content_type)
          render :text=>doc.data_text, :layout => false
        else
          data= read_binary("#{path}/f#{params[:id]}")
          send_data(data, :filename=>doc.filename, :type=>doc.content_type, :disposition=>"inline")
  #        send_data(Upload.find(doc.data_text).content.to_s, :filename=>doc.filename, :type=>doc.content_type, :disposition=>"inline")
        end
      else
        gma_notice "SEC: ไม่สามารถเรียกดูข้อมูลได้"
        redirect_to "/"
      end
    else
      data= read_binary("public/images/file_not_found.jpg")
      send_data(data, :filename=>"img_not_found.png", :type=>"image/png", :disposition=>"inline")
    end
  end
  def signed_document
    @doc = GmaDoc.find params[:id]
    render :layout=>false
  end
  def read_binary(path)
    File.open path, "rb" do |f| f.read end
  end

  private
  def create_xmain(service)
    c = name2camel(service.module)
    custom_controller= "#{c}Controller"
    GmaXmain.create :gma_service_id=>service.id,
      :start=>Time.now,
      :name=>service.name,
      :ip=> get_ip,
      :status=>'I', # init
      :gma_user_id=>get_user.id,
      :xvars=> {
        :gma_service_id=>service.id, :p=>params,
        :id=>params[:id],
        :user_id=>get_user.id, :custom_controller=>custom_controller,
        :host=>request.host,
        :referer=>request.env['HTTP_REFERER'] }
  end
  def create_runseq(xmain)
    @xvars= xmain.xvars
    default_role= get_default_role
    xml= xmain.gma_service.xml
    root = REXML::Document.new(xml).root
    i= 0; j= 0 # i= step, j= form_step
    root.elements.each('node') do |activity|
      text= activity.attributes['TEXT']
      next if gma_comment?(text)
      next if text =~/^rule:\s*/
      action= freemind2action(activity.elements['icon'].attributes['BUILTIN']) if activity.elements['icon']
      return false unless action
      i= i + 1
      output_display= false
      if action=='output'
        display= get_option_xml("display", activity)
        if display && !affirm(display)
          output_display= false
        else
          output_display= true
        end
      end
      j= j + 1 if (action=='form' || output_display)
      @xvars[:referer] = activity.attributes['TEXT'] if action=='redirect'
      if action!= 'if'
        scode, name= text.split(':', 2)
        name ||= scode; name.strip!
        code= name2code(scode)
      else
        code= text
        name= text
      end
      role= get_option_xml("role", activity) || default_role
      rule= get_option_xml("rule", activity) || "true"
      runseq= GmaRunseq.create :gma_xmain_id=>xmain.id,
        :name=> name, :action=> action,
        :code=> code, :role=>role.upcase, :rule=> rule,
        :rstep=> i, :form_step=> j, :status=>'I',
        :xml=>activity.to_s
      xmain.current_runseq= runseq.id if i==1
    end
    @xvars[:total_steps]= i
    @xvars[:total_form_steps]= j
  end
  def init_vars(xmain)
    @xmain= GmaXmain.find xmain
    @xvars= @xmain.xvars
    @runseq= @xmain.gma_runseqs.find @xmain.current_runseq
#    authorize?
    @xvars[:current_step]= @runseq.rstep
    session[:xmain_id]= @xmain.id
    session[:runseq_id]= @runseq.id
    unless params[:action]=='run_call'
      @runseq.start ||= Time.now
      @runseq.status= 'R' # running
      @runseq.save
    end
    $xmain= @xmain; $xvars= @xvars
    $runseq_id= @runseq.id; $user_id= get_user.id
  end
  def init_vars_by_runseq(runseq_id)
    @runseq= GmaRunseq.find runseq_id
    @xmain= @runseq.gma_xmain
    @xvars= @xmain.xvars
    #@xvars[:current_step]= @runseq.rstep
    @runseq.start ||= Time.now
    @runseq.status= 'R' # running
    @runseq.save
  end
  def end_action(next_runseq = nil)
    #    @runseq.status='F' unless @runseq_not_f
    @runseq.status='F'
    @runseq.gma_user_id= session[:user_id]
    @runseq.stop= Time.now
    @runseq.save
    @xmain.xvars= @xvars
    @xmain.status= 'R' # running
    @xmain.save
    next_runseq= @xmain.gma_runseqs.find_by_rstep @runseq.rstep+1 unless next_runseq
    if @end_job || !next_runseq # job finish
      @xmain.xvars= @xvars
      @xmain.status= 'F' unless @xmain.status== 'E' # finish
      @xmain.stop= Time.now
      @xmain.save
      if @xvars[:p][:return]
        redirect_to @xvars[:p][:return] and return
      else
        redirect_to_root and return
      end
    else
      @xmain.update_attribute :current_runseq, next_runseq.id
      redirect_to :action=>'run', :id=>@xmain.id and return
    end
  end

  def discover_service(code)
    m,s = code.split("/")
    # use existing module as default if mm not specify module
    ( s= m ; m= @xmain.gma_service.module ) unless s
    return m,s
  end
end
