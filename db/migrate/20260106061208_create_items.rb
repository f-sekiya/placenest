class CreateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :place, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :quantity, null: false, default: 1
      t.text :note
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
