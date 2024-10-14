class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :email
      t.string :username
      t.string :phonenumber
      t.string :address
      t.string :password
      t.string :gender
      t.boolean :is_admin

      t.timestamps
    end
    add_index :accounts, :email, unique: true
    add_index :accounts, :username, unique: true
  end
end
