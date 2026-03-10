class AddSlugToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :slug, :string

    reversible do |dir|
      dir.up do
        # yes, bad for performance, but not a big deal with a dozen records
        User.select(:id, :name, :slug).each do |user|
          user.update_column(:slug, format("%s-%03i", user.name.parameterize, rand(1000)))
        end
      end
    end

    change_column_null :users, :slug, false

    add_index :users, :slug, unique: true
  end
end
