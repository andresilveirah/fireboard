class CreateReport < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.integer :bug_occurrences, :default => 0
      t.integer :project_id
      
      t.timestamps
    end
    
    add_index :reports, :project_id
  end
  
  def self.down
    drop_table :reports
  end
end