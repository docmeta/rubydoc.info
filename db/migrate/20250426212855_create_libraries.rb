class CreateLibraries < ActiveRecord::Migration[8.0]
  def change
    create_table :libraries do |t|
      t.string :name
      t.string :source
      t.string :owner
      t.boolean :primary_fork, default: true
      t.json :versions

      t.timestamps
    end
    add_index :libraries, [ :name, :source, :owner ], unique: true
    add_index :libraries, :source
    add_index :libraries, :owner
  end
end
