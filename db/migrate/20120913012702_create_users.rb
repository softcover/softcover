class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :encrypted_password
      t.string :reset_password_token

      t.timestamps
    end

    add_index :users, :email
  end
end
