class AddColumnToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :slug, :string
    add_column :users, :tag, :string
  end
end
