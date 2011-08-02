namespace :gma do
  desc 'Create YAML test fixtures from data in an existing database. Defaults to development database.  Set RAILS_ENV to override.'
  task :gen_fixture => :environment do
    sql  = "SELECT * FROM %s"
    table_name = ENV['table']
    ActiveRecord::Base.establish_connection
    i = "000"
    File.open("#{RAILS_ROOT}/spec/fixtures/#{table_name}.yml", 'w') do |file|
      data = ActiveRecord::Base.connection.select_all(sql % table_name)
      file.write data.inject({}) { |hash, record|
        hash["#{table_name}_#{i.succ!}"] = record
        hash
      }.to_yaml
    end
  end
  
  namespace :db do
    desc "Copy dev db to test db (task #272)" 
    task :test=>"gma:dev2test" do
    end
    
    desc "Update development and test db"
    task :all=>["gma:db:dev", "gma:db:test"] do
    end
    
    desc "truncate all tables"
    task :truncate=>"gma:db:init" do
      result = ActiveRecord::Base.establish_connection(@abcs)
      puts result
      my = Mysql::new(@abcs["host"], @abcs["username"], @abcs["password"])
      my.select_db(@abcs["database"])
      tables= my.real_query "show full tables where Table_type='BASE TABLE'"
      tables.each do |table|
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table[0]}")
      end
    end

    desc "init db variables"
    task :init do
      load 'config/environment.rb'
      require 'mysql'
      @abcs = ActiveRecord::Base.configurations["development"]
    end

    desc "Migrate and import development db"
    task :dev=>"gma:db:truncate" do
      unless ENV['sql']
        puts 'Usage: rake gma:db:dev sql=<filename>'
        exit
      end
      load 'config/environment.rb'
      abcs = ActiveRecord::Base.configurations
      s= File.open(ENV['sql']).read
      File.open("db/ului_development.sql", "w+") do |f|
        s.gsub!(/DEFINER=`.+`@`.+`/,"DEFINER='#{abcs["development"]["username"]}'@'localhost' ")
        f << s
      end
      ActiveRecord::Base.establish_connection(abcs["development"])
      #`mysql -h #{abcs["development"]["host"]} -u #{abcs["development"]["username"]} -p#{abcs["development"]["password"]} #{abcs["development"]["database"]} < db/truncate_all.sql`
      ActiveRecord::Base.connection.execute("SET AUTOCOMMIT = 0")
      ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0")
      `mysql -h #{abcs["development"]["host"]} -u #{abcs["development"]["username"]} -p#{abcs["development"]["password"]} #{abcs["development"]["database"]} < db/ului_development.sql`
      ActiveRecord::Base.connection.execute("SET AUTOCOMMIT = 1")
      ActiveRecord::Base.connection.execute("COMMIT")
      ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1")
    end
    
  end

  desc "Copy dev db to test db (task #272)" 
  task :dev2test do
    load 'config/environment.rb'
    abcs = ActiveRecord::Base.configurations
    ActiveRecord::Base.establish_connection(abcs["development"])
    File.open("db/ului_development.sql", "w+") do |f|
      s= `mysqldump -h #{abcs["development"]["host"]} -u #{abcs["development"]["username"]} -p#{abcs["development"]["password"]} #{abcs["development"]["database"]}`
      s.gsub!(/DEFINER=`.+`@`.+`/,"DEFINER='#{abcs["test"]["username"]}'@'localhost' ")
      f << s
    end
    ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{abcs['test']['database']}")
    ActiveRecord::Base.connection.execute("CREATE DATABASE #{abcs['test']['database']}")
    ActiveRecord::Base.connection.execute("GRANT ALL PRIVILEGES ON #{abcs['test']['database']}.* to '#{abcs["test"]["username"]}'@localhost IDENTIFIED BY '#{abcs["test"]["password"]}'")
    ActiveRecord::Base.establish_connection(abcs["test"])
    ActiveRecord::Base.connection.execute("SET AUTOCOMMIT = 0")
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0")
   `mysql -h #{abcs["test"]["host"]} -u #{abcs["test"]["username"]} -p#{abcs["test"]["password"]} #{abcs["test"]["database"]} < db/ului_development.sql`
    ActiveRecord::Base.connection.execute("SET AUTOCOMMIT = 1")
    ActiveRecord::Base.connection.execute("COMMIT")
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1")
  end
end