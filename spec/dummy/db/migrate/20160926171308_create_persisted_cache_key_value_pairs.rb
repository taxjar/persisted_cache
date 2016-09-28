class CreatePersistedCacheKeyValuePairs < ActiveRecord::Migration
  def change
    create_table :key_value_pairs do |t|
      t.string :key
      t.text :value

      t.timestamps null: false
    end
    add_index :key_value_pairs, :key
  end
end