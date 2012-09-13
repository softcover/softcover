class CreateBookOptions < ActiveRecord::Migration
  def change
    create_table :book_options do |t|
      t.integer :book_id
      t.integer :price_in_cents
      t.string :name

      t.timestamps
    end

    add_index :book_options, :book_id
  end
end
