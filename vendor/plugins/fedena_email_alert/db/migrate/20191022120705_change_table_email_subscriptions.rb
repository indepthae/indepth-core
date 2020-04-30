class ChangeTableEmailSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :email_subscriptions, :user_id, :integer
    add_column :email_subscriptions, :email, :string
    add_index :email_subscriptions, :user_id
    add_index :email_subscriptions, :email

    EmailSubscription.connection.execute(
     <<-SQL
        update email_subscriptions inner join students on students.id = email_subscriptions.student_id set email_subscriptions.user_id = students.user_id, email_subscriptions.email = students.email
      SQL
    )
  end

  def self.down
    remove_column :email_subscriptions, :user_id, :integer
  end
end
