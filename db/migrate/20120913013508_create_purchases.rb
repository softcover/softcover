class CreatePurchases < ActiveRecord::Migration
  def change
    create_table :purchases do |t|
      t.integer :user_id
      t.integer :book_option_id
      t.integer :discount_code_id
      t.integer :total_price_in_cents
      t.string :stripe_id

      t.timestamps
    end

    add_index :purchases, :user_id
    add_index :purchases, :book_option_id
    add_index :purchases, :discount_code_id
  end
end
