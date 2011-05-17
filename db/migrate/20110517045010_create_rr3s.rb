class CreateRr3s < ActiveRecord::Migration
  def self.up
    create_table :rr3s, :force=>true do |t|
      t.integer :rr1_id
      t.integer :addition
      t.integer :month
      t.float :balance_in
      t.float :balance
      t.float :balance_out
      t.float :amount
      t.float :fee
      t.float :interest
      t.float :fine
      t.float :total
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
