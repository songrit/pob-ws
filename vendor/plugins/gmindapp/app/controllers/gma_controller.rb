class GmaController < ApplicationController
  layout "application"
  helper :all # include all helpers, all the time
  before_filter :admin_action, :only => [:pending, :view_mm, :update_app, :delete_run_call_errors, :logs]

  def logs
    @xmains= GmaXmain.paginate :per_page=>20, :page => params[:page] , :order=>"created_at DESC"
  end
  def debug_xvars
    @xmain = GmaXmain.find params[:id]
  end
  def run_call_errors
#    @gerrors = GmaLog.paginate :conditions=>{:log_type=>"ERROR"}, :order=>"created_at DESC", :per_page=>20, :page => params[:page] 
    @gerrors = GmaLog.paginate :order=>"created_at DESC", :per_page=>20, :page => params[:page] 
  end
  def delete_run_call_errors
    GmaLog.delete_all "log_type='ERROR'"
    redirect_to :action => "run_call_errors"
  end
  def pending
    @xmains= GmaXmain.all :conditions=>"status='R' or status='I' ", :order=>"created_at"
  end
  def search
    s= GmaSearch.new params[:search]
    s.ip= request.env["REMOTE_ADDR"]
    s.save
  end

#  def pending_trans
#    @xmains= GmaXmain.all :conditions=>"status='R' or status='I' ", :order=>"created_at"
#  end
  def report
    @title= "รายงานระบบ"
  end
  def img_services
    g = Gruff::Pie.new(400)
    g.title = "บริการ"
    g.font= THAI_FONT
    g.theme_37signals

    data= GmaXmain.count :group=>"gma_service_id"
    data.each_pair { |k,v|
      s= GmaService.find k
      g.data(s.name, v)
    }
    send_data g.to_blob, :type => 'image/png', :disposition => 'inline'
  end
  def view_mm
    @title= "Mind Map"
  end
  def update_app
    @title= "Update Application from Mindmap"
    @t = [cancel_pending_xmains]
    @t << process_roles
    @t << "if you change models in freemind, please destroy scaffold and tables before update app"
    @t << process_models
    @t << exec_cmd("rake db:migrate").gsub("\n","<br/>")
    @t << process_services
    @t << gen_controllers
    @t << gen_views
    @t << "Application Updated, please restart Rails server"
    ActionController::Routing::Routes.reload
  end
  def process_report
    @xmains= GmaXmain.all :conditions=>['status=? or status=?', 'R', 'I']
  end
  def status
    @xmain= GmaXmain.find params[:id]
    @xvars= @xmain.xvars
    flash.now[:notice]= "รายการ #{@xmain.id} ได้ถูกยกเลิกแล้ว" if @xmain.status=='X'
#    flash.now[:notice]= "transaction #{@xmain.id} was cancelled" if @xmain.status=='X'
  rescue
    flash[:notice]= "could not find transaction id <b> #{params[:id]} </b>"
    redirect_to_root
  end

  private
  def gen_views
    t = ["generate ui<br/>"]
    GmaModule.all.each do |m|
      m.gma_services.each do |s|
        next if s.code=='link'
        dir ="app/views/#{s.module}"
        unless File.exists?(dir)
          Dir.mkdir(dir)
          t << "create directory #{dir}"
        end
        dir ="app/views/#{s.module}/#{s.code}"
        unless File.exists?(dir)
          Dir.mkdir(dir)
          t << "create directory #{dir}"
        end
        xml= REXML::Document.new(s.xml)
        xml.elements.each('*/node') do |activity|
          icon = activity.elements['icon']
          next unless icon
          action= freemind2action(icon.attributes['BUILTIN'])
          next unless ui_action?(action)
          code_name = activity.attributes["TEXT"].to_s
          next if code_name.comment?
          code= name2code(code_name)
          if action=="pdf"
            f= "app/views/#{s.module}/#{s.code}/#{code}.pdf.prawn"
          else
            f= "app/views/#{s.module}/#{s.code}/#{code}.rhtml"
          end
          unless File.exists?(f)
            ff=File.open(f, 'w'); ff.close
            t << "create file #{f}"
          end
        end
      end
    end
    t.join("<br/>")
  end

  def gen_views_old
    doc= get_app
    modules= doc.elements["//node/node[@TEXT='services']"] || REXML::Document.new
    t = ["generate ui<br/>"]
    modules.each_element('node') do |modul|
      module_name= modul.attributes['TEXT']
      next if module_name.comment?
      mname= name2code(module_name)
      modul.each_element('node') do |service|
        # must do this beforre calling name2code which will strip all symbols
        service_name= service.attributes['TEXT']
        next if service_name.comment?
        sname= name2code(service_name)
        # ignore role
        next if sname =~ /role/
        next if sname =~ /link/
        dir ="app/views/#{mname}"
        unless File.exists?(dir)
          Dir.mkdir(dir)
          t << "create directory #{dir}"
        end
        dir ="app/views/#{mname}/#{sname}"
        unless File.exists?(dir)
          Dir.mkdir(dir)
          t << "create directory #{dir}"
        end
        service.each_element('node') do |activity|
          icon = activity.elements['icon']
          next unless icon
          action= freemind2action(icon.attributes['BUILTIN'])
          next unless ui_action?(action)
          code_name = activity.attributes["TEXT"].to_s
          next if code_name.comment?
          code= name2code(code_name)
          if action=="pdf"
            f= "app/views/#{mname}/#{sname}/#{code}.pdf.prawn"
          else
            f= "app/views/#{mname}/#{sname}/#{code}.rhtml"
          end
          unless File.exists?(f)
            ff=File.open(f, 'w'); ff.close
            t << "create file #{f}"
          end
        end
      end
    end
    t.join("<br/>")
  end
  def gen_controllers
    t = ["generate controllers<br/>"]
    modules= GmaModule.all
    modules.each do |m|
      next if controller_exists?(m.code)
      t << "= #{m.code}"
      t << exec_cmd("script/generate rspec_controller #{m.code}").gsub("\n","<br/>")
    end
    t.join("<br/>")
  end
#  def gen_controllers_old
#    t = ["generate controllers<br/>"]
#    modules= GmaService.all :group=>'module'
#    modules.each do |m|
#      next if controller_exists?(m.module)
#      t << "= #{m.module}"
#      t << exec_cmd("ruby script/generate controller #{m.module}")
#      #add_gma_to_controller(m.module)
#    end
#    t.join("<br/>")
#  end

  def process_services
    t= ["process services"]
    xml= get_app
    protected_services = []
    protected_modules = []
    mseq= 0
    @services= xml.elements["//node[@TEXT='services']"] || REXML::Document.new
    @services.each_element('node') do |m|
      ss= m.attributes["TEXT"]
      code, name= ss.split(':', 2)
      next if code.blank?
      next if code.comment?
      module_code= name2code(code)
      # create or update to GmaModule
      gma_module= GmaModule.find_or_create_by_code module_code
      protected_modules << gma_module.id
      name = module_code if name.blank?
      gma_module.update_attributes :name=> name.strip, :seq=> mseq
      mseq += 1
      seq= 0
      m.each_element('node') do |s|
        service_name= s.attributes["TEXT"].to_s
        t << "= #{module_code}::#{service_name}"
        scode, sname= service_name.split(':', 2)
        sname ||= scode; sname.strip!
        scode= name2code(scode)
        if scode=="role"
          gma_module.update_attribute :role, sname
          next
        end
        if scode.downcase=="link"
          role= get_option_xml("role", s) || ""
          rule= get_option_xml("rule", s) || ""
          gma_service= GmaService.find_or_create_by_module_and_code_and_name module_code, scode, sname
          gma_service.update_attributes :xml=>s.to_s, :name=>sname,
            :listed=>listed(s), :secured=>secured?(s),
            :gma_module_id=>gma_module.id, :seq => seq,
            :role => role, :rule => rule
          seq += 1
          protected_services << gma_service.id
        else
          # normal service
          step1 = s.elements['node']
          role= get_option_xml("role", step1) || ""
          rule= get_option_xml("rule", step1) || ""
          gma_service= GmaService.find_or_create_by_module_and_code module_code, scode
          gma_service.update_attributes :xml=>s.to_s, :name=>sname,
            :listed=>listed(s), :secured=>secured?(s),
            :gma_module_id=>gma_module.id, :seq => seq,
            :role => role, :rule => rule
          seq += 1
          protected_services << gma_service.id
        end
      end
    end
    GmaService.delete_all(["id NOT IN (?)",protected_services])
    GmaModule.delete_all(["id NOT IN (?)",protected_modules])
    t.join("<br/>")
  end
  def cancel_pending_xmains
    GmaXmain.update_all("status='X'", "status='I' or status='R'")
    "all pending tasks are cancelled."
  end
  def process_models
    @app= get_app
    t= ["process models"]
    models= @app.elements["//node[@TEXT='models']"] || REXML::Document.new
    models.each_element('node') do |model|
      t << "= "+model.attributes["TEXT"]
      model_name= model.attributes["TEXT"]
      next if model_name.comment?
      model_code= name2code(model_name)
      unless model_exists?(model_code)
        attr_list= make_fields(model)+" gma_user_id:integer"
        t << "script/generate rspec_model #{model_code} #{attr_list} --force<br/>"
        cmd= exec_cmd("script/generate model #{model_code} #{attr_list} --force").gsub("\n","<br/>")
        t << cmd
        # remove custom layout therefore all controller will default to application.rhtml layout
        # if win32?
        #   t << "del app\\views\\layouts\\#{model_code.pluralize}.html.erb"
        #   exec_cmd "del app\\views\\layouts\\#{model_code.pluralize}.html.erb"
        # else
        #   t << "rm app/views/layouts/#{model_code.pluralize}.html.erb"
        #   exec_cmd "rm app/views/layouts/#{model_code.pluralize}.html.erb"
        # end
        table_name= model_code.downcase.pluralize
        migration_file= cmd.match(/db\/migrate\/\d+_create_#{table_name}.rb/).to_s
        table_statement= "create_table :#{table_name}, :force=>true do |t|"
        s= File.read migration_file
        ss = s.sub("create_table :#{table_name} do |t|", table_statement)
        File.open(migration_file, 'w') { |f| f << ss }
      else
        t << "-- skip because model already exists"
      end
    end
    t.join("<br/>")
  end
  def process_roles
    t = ["process_roles"]
    @app= get_app
    GmaRole.delete_all
    roles= @app.elements["//node[@TEXT='roles']"] || REXML::Document.new
    roles.each_element('node') do |role|
      text= role.attributes['TEXT']
      c,n = text.split(': ')
      next if c.comment?
      GmaRole.create :code=>c.upcase, :name=>n, :gma_user_id=>get_user
      t << "= #{text}"
    end
    t.join("<br/>")
  end
end
