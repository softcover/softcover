class CreateBookMediumOptions < ActiveRecord::Migration
  def change
    create_table :book_medium_options do |t|
      t.integer :book_medium_id
      t.integer :book_option_id

      t.timestamps
    end

    add_index :book_medium_options, :book_medium_id
    add_index :book_medium_options, :book_option_id
  end
end
