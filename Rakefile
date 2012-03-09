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

namespace :reports do
  task :configure_connection do
    ActiveRecord::Base.establish_connection(
      :adapter => "mysql2",
      :database => "fireboard"
    )
  end
  desc "Rollback all reports made today"
  task :rollback => :configure_connection do
    class Report < ActiveRecord::Base
    end
    system("rm -rf ./charts/#{Time.now.strftime("%Y%m%d")}")
    deleted = 0
    reports = Report.all
    reports.each do |report|
      if report.created_at.day == Time.now.day
        report.delete
        deleted += 1
      end
    end
    p "#{deleted} entries was destroyed"
  end
end

