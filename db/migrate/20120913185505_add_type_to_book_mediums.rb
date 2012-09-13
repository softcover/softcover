class AddTypeToBookMediums < ActiveRecord::Migration
  def change
    add_column :book_media, :type, :string

    add_index :book_media, :type
  end
end
