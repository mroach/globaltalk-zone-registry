class RemovePhysicalLayer < ActiveRecord::Migration[8.1]
  def up
    remove_column :zones, :physical_layer
  end

  def down
    add_column :zones, :physical_layer, null: false, default: "ethertalk"
  end
end
