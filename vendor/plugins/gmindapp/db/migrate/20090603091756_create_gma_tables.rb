class AddGmaTables < ActiveRecord::Migration
  def self.up

    create_table "gma_docs", :force => true do |t|
      t.string   "name"
      t.string   "filename"
      t.string   "content_type"
      t.text     "data_text"
      t.integer  "gma_xmain_id"
      t.integer  "gma_runseq_id"
      t.integer  "gma_user_id"
      t.integer  "gma_service_id"
      t.string    "ip"
      t.boolean  "display"
      t.boolean  "secured", :default=>false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_logs", :force => true do |t|
      t.string   "log_type"
      t.text     "message"
      t.string   "controller"
      t.string   "action"
      t.text     "iparams"
      t.text     "isession"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_modules", :force => true do |t|
      t.string   "code"
      t.string   "name"
      t.string   "role"
      t.integer  "seq"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_notices", :force => true do |t|
      t.string   "message"
      t.boolean  "unread"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_redirect_queues", :force => true do |t|
      t.string   "url"
      t.string   "status"
      t.integer  "gma_runseq_id"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_roles", :force => true do |t|
      t.string   "code"
      t.string   "name"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_runseqs", :force => true do |t|
      t.string   "action"
      t.string   "status",        :limit => 1
      t.string   "code"
      t.text     "name"
      t.integer  "location_id"
      t.string   "role"
      t.string   "rule"
      t.integer  "gma_xmain_id"
      t.integer  "rstep"
      t.integer  "form_step"
      t.datetime "start"
      t.datetime "stop"
      t.boolean  "end"
      t.text     "xml"
      t.integer  "gma_user_id"
      t.string   "ip"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_services", :force => true do |t|
      t.string   "module"
      t.string   "code"
      t.text     "name"
      t.integer  "gma_module_id"
      t.text     "xml"
      t.string   "auth"
      t.string   "role"
      t.string   "rule"
      t.integer  "seq"
      t.boolean  "listed"
      t.boolean  "secured"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_songrits", :force => true do |t|
      t.string   "code"
      t.string   "value"
      t.text     "description"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_users", :force => true do |t|
      t.string   "login"
      t.string   "password"
      t.string   "email"
      t.string   "title"
      t.string   "fname"
      t.string   "lname"
      t.string   "role"
      t.string   "cellphone"
      t.string   "photo"
      t.string   "org"
      t.string   "position"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_ws_queues", :force => true do |t|
      t.string   "url"
      t.text     "body"
      t.string   "poll_url"
      t.integer  "wait"
      t.integer  "status"
      t.integer  "gma_runseq_id"
      t.datetime "next_poll_at"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_xmains", :force => true do |t|
      t.string   "status"
      t.text     "xvars"
      t.datetime "start"
      t.integer  "gma_service_id"
      t.datetime "stop"
      t.integer  "current_runseq"
      t.string   "name"
      t.integer  "location_id"
      t.integer  "gma_user_id"
      t.string   "ip"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "gma_searches", :force => true do |t|
      t.string   "q"
      t.string   "ip"
      t.integer  "gma_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table :searches, :force=>true do |t|
      t.string :item
      t.string :class
      t.integer :trip_id
      t.integer :waypoint_id
      t.integer :gma_user_id

      t.timestamps
    end

    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end

    create_table "logged_exceptions", :force => true do |t|
      t.column :exception_class, :string
      t.column :controller_name, :string
      t.column :action_name,     :string
      t.column :message,         :text
      t.column :backtrace,       :text
      t.column :environment,     :text
      t.column :request,         :text
      t.column :created_at,      :datetime
    end

    create_table :news do |t|
      t.string :subject
      t.text :body
      t.boolean :stick
      t.integer :gma_user_id

      t.timestamps
    end
    
    add_index :sessions, :session_id
    add_index :sessions, :updated_at
    add_index :gma_docs, :gma_xmain_id
    add_index :gma_docs, :gma_runseq_id
    add_index :gma_docs, :gma_service_id
    add_index :gma_xmains, :gma_service_id
    add_index :gma_runseqs, :code
    add_index :gma_runseqs, :gma_xmain_id
    add_index :gma_services, :gma_module_id
    add_index :gma_songrits, :code
  end

  def self.down
    drop_table "gma_services"
    drop_table "gma_xmains"
    drop_table "gma_runseqs"
    drop_table "gma_docs"
    drop_table "gma_ws_queues"
    drop_table "gma_redirect_queues"
    drop_table "gma_roles"
    drop_table "gma_songrits"
    drop_table "gma_users"
    drop_table "gma_logs"
    drop_table "gma_notices"
    drop_table "gma_searches"
    drop_table "searches"
    drop_table "sessions"
    drop_table "logged_exceptions"
    drop_table "news"
  end
end
