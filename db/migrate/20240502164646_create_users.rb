class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :tracking_number
      t.string :aftership_status
      t.string :expected_delivery_date
      t.string :string

      t.timestamps
    end
  end
end
