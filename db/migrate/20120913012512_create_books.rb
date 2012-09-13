class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.text :title
      t.integer :user_id

      t.timestamps
    end

    add_index :books, :user_id
  end
end
