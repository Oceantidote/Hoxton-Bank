class AddEnduserIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :enduser_id, :string
  end
end
