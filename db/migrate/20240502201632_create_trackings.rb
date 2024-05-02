class CreateTrackings < ActiveRecord::Migration[7.1]
  def change
    create_table :trackings do |t|
      t.string :date
      t.string :datetime
      t.string :status
      t.integer :tracking_number
      t.string :string

      t.timestamps
    end
  end
end
