class UniqueZoneNames < ActiveRecord::Migration[8.1]
  def change
    add_index :zones, :name, unique: true
  end
end
