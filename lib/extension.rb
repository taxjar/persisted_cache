module PersistedCache
  module Extension

    def fetch(name, options = nil)
      options = merged_options(options)
      if options && options[:persist]
        if options[:fail_on_cache_miss]
          raise PersistedCache::InvalidOptions.new("Cannot persist if fail_on_cache_miss is true.")
        end
        options.merge!(force: true)
      end
      super
    end

    def read(name, options = nil)
      unless result = super
        if persisted_value = PersistedCache::KeyValuePair.where(key: name).first.try(:value)
          Rails.cache.write(name, persisted_value, options)
          result = persisted_value
        end
      end
      result
    end

    def save_block_result_to_cache(name, options)
      options = merged_options(options)
      if options && options[:persist]
        value = yield
        PersistedCache::KeyValuePair.where(key: name).first.try(:destroy)
        PersistedCache::KeyValuePair.create!(key: name, value: value)
        unless options[:skip_rails_cache]
          Rails.cache.write(name, value, options)
        else
          Rails.cache.delete(name, options)
        end
        return value
      end
      if persisted_value = PersistedCache::KeyValuePair.where(key: name).first.try(:value)
        Rails.cache.write(name, persisted_value, options)
        return persisted_value
      else
        if options[:fail_on_cache_miss]
          raise PersistedCache::MissingRequiredCache.new("Required cached object does not exist in cache.")
        end
      end
      super
    end

    def delete(name, options = nil)
      if options && options[:delete_persisted]
        PersistedCache::KeyValuePair.where(key: name).first.try(:destroy)
      end
      super
    end

  end
end



ActiveSupport::Cache::Store.instance_eval do
  prepend PersistedCache::Extension
end