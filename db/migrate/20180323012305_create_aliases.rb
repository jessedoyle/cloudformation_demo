class CreateAliases < ActiveRecord::Migration[5.2]
  def change
    create_table :aliases do |t|
      t.string :instance_id
      t.string :value
    end
    add_index :aliases, :instance_id
  end
end
