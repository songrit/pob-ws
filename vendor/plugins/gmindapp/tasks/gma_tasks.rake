namespace :gma do
  task :sync do
    system "rsync -ruv vendor/plugins/gmindapp/db/migrate db"
    system "rsync -ruv vendor/plugins/gmindapp/public ."
  end

  task :init=>:environment do
    system "rsync -ruv vendor/plugins/gmindapp/db/migrate db"
    system "rsync -ruv vendor/plugins/gmindapp/public ."
    system "git clone git://github.com/defunkt/exception_logger.git vendor/plugins/exception_logger"
    system "haml --rails ."
    system "git clone git://github.com/aaronchi/jrails.git vendor/plugins/jrails"
    system "script/generate exception_migration"
    system "rake db:migrate"
    system "touch public/index.mm"
    GmaUser.find_or_create_by_login :login=>"anonymous", :role=>""
    system "cp vendor/plugins/gmindapp/asset/application.html.erb app/views/layout"
    system "cp vendor/plugins/gmindapp/asset/_login.html.erb app/views/layout"
    system "cp vendor/plugins/gmindapp/asset/index.mm public"
    system "cp vendor/plugins/gmindapp/asset/utf8.html.erb app/views/layout"
    system "cp vendor/plugins/gmindapp/asset/mail.rb config/initializers"
    system "cp vendor/plugins/gmindapp/asset/smtp_tls.rb lib"
    system "cp vendor/plugins/gmindapp/asset/application.js public/javascripts"
  end

  task :test=>:environment do
    TgelUser.create :login => "bbb"
  end
end
