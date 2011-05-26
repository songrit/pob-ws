class CreateRr3s < ActiveRecord::Migration
  def self.up
    create_table :rr3s, :force=>true do |t|
      t.integer :rr1_id
      t.integer :addition
      t.date :month
      t.float :balance_in, :default => 0 
      t.integer :qty_in, :default => 0
      t.float :balance, :default => 0
      t.integer :qty, :default => 0
      t.float :balance_out, :default => 0
      t.integer :qty_out, :default => 0
      t.float :amount, :default => 0
      t.float :fee, :default => 0
      t.float :interest, :default => 0
      t.float :fine, :default => 0
      t.float :total, :default => 0
      t.integer :receipt_book
      t.integer :receipt_no
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :rr3s
  end
end
