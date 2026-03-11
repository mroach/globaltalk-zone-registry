class AddCoordiantesToExternalZones < ActiveRecord::Migration[8.1]
  def change
    add_column :external_zones, :coordinates, :point
  end
end
