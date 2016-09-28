require 'rails/generators'
require 'rails/generators/migration'

module PersistedCache
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      def copy_initializer
        template '../templates/persisted_cache_initializer.rb', 'config/initializers/persisted_cache.rb'
      end

      def self.next_migration_number(path)
        next_migration_number = current_migration_number(path) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        migration_template "create_persisted_cache_key_value_pairs.rb",
          "db/migrate/create_persisted_cache_key_value_pairs.rb"
      end

    end
  end
end