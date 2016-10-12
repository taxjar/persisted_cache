module PersistedCache
  module Extension

    def fetch(name, options = nil)
      options = merged_options(options)
      if options && options[:persisted_cache] == 'write'
        options.merge!(force: true)
      end
      super
    end

    def read(name, options = nil)
      unless result = super
        return unless options && %w{read require}.include?(options[:persisted_cache])
        if persisted_value = PersistedCache::KeyValuePair.where(key: name).first.try(:value)
          Rails.cache.write(name, persisted_value, options)
          result = persisted_value
        end
      end
      result
    end

    def save_block_result_to_cache(name, options)
      options = merged_options(options)
      if options && options[:persisted_cache] == 'write'
        value = yield
        PersistedCache::KeyValuePair.where(key: name).first.try(:destroy)
        PersistedCache::KeyValuePair.create!(key: name, value: value)
        Rails.cache.delete(name, options)
        return value
      end
      if %w{read require}.include?(options[:persisted_cache])
        if persisted_value = PersistedCache::KeyValuePair.where(key: name).first.try(:value)
          Rails.cache.write(name, persisted_value, options)
          return persisted_value
        else
          if options[:persisted_cache] == 'require'
            raise PersistedCache::MissingRequiredCache.new("Required cached object does not exist in cache.")
          end
        end
      end
      super
    end

    def delete(name, options = nil)
      if options && options[:persisted_cache] == 'delete'
        PersistedCache::KeyValuePair.where(key: name).first.try(:destroy)
      end
      super
    end

  end
end



ActiveSupport::Cache::Store.instance_eval do
  prepend PersistedCache::Extension
end