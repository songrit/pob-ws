class CreateReceipts < ActiveRecord::Migration
  def self.up
    create_table :receipts, :force=>true do |t|
      t.string :section
      t.string :payee
      t.string :item
      t.float :amount
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :receipts
  end
end
