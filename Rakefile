require 'active_record'

namespace :db do   
  task :configure_connection do
    ActiveRecord::Base.establish_connection(
      :adapter => "mysql2",
      :database => "fireboard"
    )
  end
  
  desc "Run all migrations at migrations path"
    task :migrate => :configure_connection do
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Migrator.migrate("db/migrate")
  end

  desc "Rollbacks a migration"
  task :rollback => :configure_connection do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.rollback("db/migrate")
  end
end

