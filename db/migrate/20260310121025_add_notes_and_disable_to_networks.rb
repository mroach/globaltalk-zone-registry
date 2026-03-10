class AddNotesAndDisableToNetworks < ActiveRecord::Migration[8.1]
  def change
    add_column :networks, :notes, :text
    add_column :networks, :disabled_at, :datetime

    remove_column :zones, :disabled_at
    remove_column :zones, :rejected_at
    remove_column :zones, :last_verified_at
  end
end
