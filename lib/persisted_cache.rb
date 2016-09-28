require 'extension'
module PersistedCache

  class MissingRequiredCache < Exception; end
  class InvalidOptions < Exception; end
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
    k = Class.new(PersistedCache.configuration.base_class) do
      validates :key, uniqueness: true
      serialize :value
      self.table_name = 'key_value_pairs'
    end
    PersistedCache.const_set 'KeyValuePair', k
  end

  class Configuration
    attr_accessor :base_class

    def initialize
      base_class = ActiveRecord::Base
    end

  end

end