class CreateBookMedia < ActiveRecord::Migration
  def change
    create_table :book_media do |t|
      t.string :name
      t.integer :book_id
      t.string :url

      t.timestamps
    end

    add_index :book_media, :book_id
  end
end
