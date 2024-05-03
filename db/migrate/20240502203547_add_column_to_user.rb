class AddColumnToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :slug, :string
    add_column :users, :tag, :string
    change_column :users, :tracking_number, :integer
  end
end
