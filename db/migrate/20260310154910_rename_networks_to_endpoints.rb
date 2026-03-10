class RenameNetworksToEndpoints < ActiveRecord::Migration[8.1]
  def change
    rename_table :networks, :endpoints
  end
end
