class AddDeviseToAccounts < ActiveRecord::Migration[7.1]
  def self.up
    change_table :accounts do |t|
      ## Devise-required fields

      # Already have email, so no need to add it again

      ## Database authenticatable
      t.string :encrypted_password, null: false, default: ""  # Replace plain password with encrypted_password

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Confirmable (if using email confirmation)
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable (if using lockable functionality)
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

    end

    add_index :accounts, :reset_password_token, unique: true
    # add_index :accounts, :confirmation_token, unique: true if using confirmable
    # add_index :accounts, :unlock_token, unique: true if using lockable
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
