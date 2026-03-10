class UniqueUserName < ActiveRecord::Migration[8.1]
  def change
    change_column :users, :name, :citext
    add_index :users, :name, unique: true
  end
end
