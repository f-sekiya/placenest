class CreatePlaces < ActiveRecord::Migration[7.1]
  def change
    create_table :places do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :ancestry
      t.text :description
      t.integer :position

      t.timestamps
    end
    
    add_index :places, :ancestry
    add_index :places, [:user_id, :ancestry]
  end
end
