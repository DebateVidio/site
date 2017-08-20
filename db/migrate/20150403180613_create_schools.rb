class CreateSchools < ActiveRecord::Migration[4.2]
  def change
    create_table :schools do |t|
      t.string :name
      t.string :short_name
      t.timestamps null: false
    end
  end
end
