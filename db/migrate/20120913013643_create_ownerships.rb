class CreateOwnerships < ActiveRecord::Migration
  def change
    create_table :ownerships do |t|
      t.integer :user_id
      t.integer :purchase_id
      t.string :email
      t.string :token

      t.timestamps
    end

    add_index :ownerships, [:user_id, :purchase_id], uniq: true
  end
end
