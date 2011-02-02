class ServiceController < ApplicationController
  def test
    render :text=>"hello, I'm TGEL"
  end
  def cancel_pending_xmains
    Xmain.update_all("status='X'", "status='I'")
    get_xvars
    @xvars[:cancel_pending_xmains]= "Xmain.update_all"
    save_xvars
  end
  def destroy_app
    get_xvars
    @app= App.find(@xvars[:id])
    exec_cmd("svn cleanup")
    exec_cmd("svn commit -m 'delete app #{@app.code}'")
    @app.destroy
  end
  def remove_roles
    get_xvars
    Role.delete_all "app_id=#{@xvars[:id]}"
  end
  def remove_app_folder
    get_xvars
    @app= App.find @xvars[:id]
    cmd= exec_cmd("svn cleanup")
    cmd= exec_cmd("svn rm tgel/#{@app.code} --force")
    @xvars[:notice_folder]= cmd
    save_xvars
  end
  def destroy_services
    get_xvars
    GmaService.delete_all "app_id=#{@xvars[:id]}"
  end
  def destroy_controllers
    get_xvars
    @app= App.find @xvars[:id]
    modules= @app.gma_services.all :group=>'module'
    tt= ''
    modules.each do |m|
      cmd= exec_cmd("ruby script/destroy controller #{@app.code}/#{m.module} --svn --force")
      tt << cmd
    end
    @xvars[:notice_controllers]= tt
    save_xvars
    cmd = exec_cmd("svn commit -m 'destroy controllers'")
  end
  def destroy_models
    get_xvars
    @app= App.find @xvars[:id]
    f= "tgel/#{@app.code}/index.mm"
    xml= REXML::Document.new(File.read(f).gsub("\n","")).root
    models= xml.elements["//node[@TEXT='models']"]
    tt= ''
    models.each_element('node') do |n|
      model= name2code(n.attributes["TEXT"])
      if model_exists?(model)
        cmd = exec_cmd("ruby script/destroy model #{model} --svn --force")
        tt << cmd
      end
    end
    @xvars[:notice_model] = "<p/>destroy models: #{tt}"
    save_xvars
    cmd = exec_cmd("svn commit -m 'destroy models'")
  end
  def destroy_tables
    get_xvars
    @app= App.find @xvars[:id]
    cmd = exec_cmd("ruby script/generate migration remove_app_#{@app.code}")
    migrate= cmd.match(/db\/migrate\/\d+_remove_app_#{@app.code}.rb/).to_s
    f= "tgel/#{@app.code}/index.mm"
    xml= REXML::Document.new(File.read(f).gsub("\n","")).root
    models= xml.elements["//node[@TEXT='models']"]
    tt= "def self.up\n"
    models.each_element('node') do |n|
      model= name2code(n.attributes["TEXT"])
      if model_exists?(model)
        table_name= model.downcase.pluralize
        tt << "    drop_table :#{table_name}\n"
      end
    end
    s= File.read migrate
    ss = s.sub("def self.up", tt)
    File.open(migrate, 'w') { |f| f << ss }
    cmd = exec_cmd("rake db:migrate")
    cmd << exec_cmd("ruby script/destroy migration remove_app_#{@app.code}")
    @xvars[:notice_tables] = "<p/>rake: #{cmd}"
    save_xvars
  end
  def svn_checkout
    get_xvars
    notice= ""
    @app= App.new form2hash(@xvars[:new_app], 'app')
    notice << '<p/>svn export:<br/>'
    notice << exec_cmd("svn export #{@app.svn}/index.mm")
    notice << '<hr/>'
    xml= REXML::Document.new(File.read('index.mm').gsub("\n","")).root
    d_node= xml.elements["//node[@TEXT='doc']/node[@TEXT='description']/node"]
    description= d_node ? d_node.attributes['TEXT'] : ''
    @app.code= xml.elements['//node'].attributes['TEXT']
    @app.description= description
    @app.xml= xml.to_s
    @app.save
    File.delete('index.mm')
    dir= "tgel/#{@app.code}"
#    notice << exec_cmd("svn mkdir #{dir}")
    Dir.mkdir(dir)
    notice << '<p/>svn checkout:<br/>'
    notice << exec_cmd("svn checkout #{@app.svn} #{dir} --username #{@app.username} --password #{@app.password}")
    notice << '<hr/>'
    @xvars[:app_id]= @app.id
    @xvars[:notice_svn]= notice
    save_xvars
  end
  def svn_update
    get_xvars
#    notice= ""
    @xvars[:app_id]= @xvars[:id]
    @app= App.find_by_code @xvars[:p][:app_code]
    dir= "tgel/#{@app.code}"
#    notice << '<p/>svn update:<br/>'
#    notice << exec_cmd("svn update #{@app.svn} #{dir} --username #{@app.username} --password #{@app.password}")
#    notice << '<hr/>'
#    @xvars[:notice_svn]= notice
    f= "tgel/#{@app.code}/index.mm"
    xml= REXML::Document.new(File.read(f).gsub("\n","")).root
    @app.code= xml.elements['//node'].attributes['TEXT']
    @app.xml= xml.to_s
    @app.save
#    @xvars[:notice_svn]= notice
    save_xvars
  end
  def copy_assets
    get_xvars
    @app= App.find_by_code @xvars[:p][:app_code]
    # css
    dir_name= "tgel/#{@app.code}/css/"
    dir_name_public= "public/stylesheets/#{@app.code}"
    Dir.mkdir(dir_name_public) unless File.exist?(dir_name_public)
    Dir.entries(dir_name).each do |f|
      next if ['.','..','.svn'].include?(f)
      File.copy(dir_name+f, dir_name_public)
    end
    # js
    dir_name= "tgel/#{@app.code}/js/"
    dir_name_public= "public/javascripts/#{@app.code}"
    Dir.mkdir(dir_name_public) unless File.exist?(dir_name_public)
    Dir.entries(dir_name).each do |f|
      next if ['.','..','.svn'].include?(f)
      File.copy(dir_name+f, dir_name_public)
    end
    # img
    dir_name= "tgel/#{@app.code}/img/"
    dir_name_public= "public/images/#{@app.code}"
    Dir.mkdir(dir_name_public) unless File.exist?(dir_name_public)
    Dir.entries(dir_name).each do |f|
      next if ['.','..','.svn'].include?(f)
      File.copy(dir_name+f, dir_name_public)
    end
  end
  def update_roles
    get_xvars
    @app= App.find_by_code @xvars[:p][:app_code]
    f= "tgel/#{@app.code}/index.mm"
    xml= REXML::Document.new(File.read(f).gsub("\n","")).root
    @app.xml= xml.to_s
    @app.save
    roles= xml.elements["//node[@TEXT='roles']"]
    roles.each_element('node') do |role|
      text= role.attributes['TEXT']
      c,n = text.split(': ')
      next if c =~ /^\#/
      Role.delete_all(:app_id=>@app.id, :code=>c)
      Role.create :app_id=>@app.id, :code=>c.upcase, :name=>n, :user_id=>@xvars[:user_id]
    end
    true
  end
  def process_models
    get_xvars
    @app= App.find_by_code @xvars[:p][:app_code]
    f= "tgel/#{@app.code}/index.mm"
    xml= REXML::Document.new(File.read(f).gsub("\n","")).root
    models= xml.elements["//node[@TEXT='models']"]
    models.each_element('node') do |n|
      model= name2code(n.attributes["TEXT"])
      unless model_exists?(model)
        cmd= ExecCmd.new("ruby script/generate model #{model} --svn --force")
        cmd.run
        table_name= model.downcase.pluralize
        migrate= cmd.output.match(/db\/migrate\/\d+_create_#{table_name}.rb/).to_s
        SchemaMigration.delete migrate.match(/\d{14}/).to_s
        fields= "create_table :#{table_name}, :force=>true, :options=>'engine=myisam default charset=utf8' do |t|\n"
        #model2hash(n).each_pair { |k,v| fields << "      t.#{v} :#{k}\n" }
        fields << make_fields(n)
        fields << "      t.integer :user_id"
        s= File.read migrate
        ss = s.sub("create_table :#{table_name} do |t|", fields)
        File.open(migrate, 'w') { |f| f << ss }
      end
    end
    cmd= ExecCmd.new("rake db:migrate")
    cmd.run
    @xvars[:notice_model] = "<p/>rake: #{cmd.output}"
    #cmd = exec_cmd("svn commit -m 'generate models'")
    save_xvars
  end
  def process_services
    get_xvars
    @app= App.find_by_code @xvars[:p][:app_code]
    f= "tgel/#{@app.code}/index.mm"
    xml= REXML::Document.new(File.read(f).gsub("\n","")).root
    GmaService.delete_all "app_id=#{@app.id}"
    GmaService.delete_all "app_id IS NULL"
    @services= xml.elements["//node[@TEXT='services']"]
    @services.each_element('node') do |m|
      ss= m.attributes["TEXT"]
      code, name= ss.split(':', 2)
      module_code= name2code code
      m.each_element('node') do |s|
        service_name= s.attributes["TEXT"].to_s
        scode, sname= service_name.split(':', 2)
        sname ||= scode; sname.strip!
        GmaService.create :app_id=>@app.id,
          :module=>module_code,
          :code=>name2code(scode),
          :xml=>s.to_s,
          :name=>sname,
          :listed=>listed(s)
      end
    end
    true
  end
  def gen_controllers
    get_xvars
    @app= App.find_by_code @xvars[:p][:app_code]
    modules= @app.gma_services.all :group=>'module'
    tt= ''
    modules.each do |m|
      next if controller_exists?(@app.code,m.module)
      tt << exec_cmd("ruby script/generate controller #{@app.code}/#{m.module}")+"\n"
    end
    @xvars[:notice_controllers]= tt
    #cmd = exec_cmd("svn commit -m 'generate controllers'")
    save_xvars
  end
  def gen_views
    get_xvars
    @app= App.find_by_code @xvars[:p][:app_code]
    doc= REXML::Document.new(@app.xml).root
    modules= doc.elements['//node/node']
    notice= ''
    modules.each_element('node') do |modul|
      mname= name2code(modul.attributes['TEXT'])
      dir ="tgel/#{@app.code}/ui/#{mname}"
      unless File.exists?(dir)
        Dir.mkdir(dir)
        notice << "<br/>create #{dir}"
      end
      begin
        modul.each_element('node') do |service|
          sname= name2code(service.attributes['TEXT'])
          dir ="tgel/#{@app.code}/ui/#{mname}"
          unless File.exists?(dir)
            Dir.mkdir(dir)
            notice << "<br/>create #{dir}"
          end
          dir ="tgel/#{@app.code}/ui/#{mname}/#{sname}"
          unless File.exists?(dir)
            Dir.mkdir(dir)
            notice << "<br/>create #{dir}"
          end
          service.each_element('node') do |activity|
            next unless activity.elements['icon']
            action= freemind2action(activity.elements['icon'].attributes['BUILTIN'])
            next unless action=='form'
            code= name2code(activity.attributes["TEXT"].to_s)
            f= "tgel/#{@app.code}/ui/#{mname}/#{sname}/#{code}.rhtml"
            unless File.exists?(f)
              ff=File.open(f, 'w'); ff.close
              notice << "<br/>create file #{f}"
            end
          end
        end
      rescue
        next
      end
    end
    @xvars[:notice_views]= notice
    save_xvars
  end
  
  private
  def make_fields(n)
    f= ""
    n.each_element('node') do |nn|
      next if nn.attributes['TEXT'] =~ /\#.*/
      k,v= nn.attributes['TEXT'].split(/:\s*/,2)
      v ||= 'integer'
      f << "      t.#{v.strip} :#{name2code(k.strip)}\n"
    end
    f
  end
end
