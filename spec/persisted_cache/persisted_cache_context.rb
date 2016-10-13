class SomeModel
  def self.method_results
    (1..50).map{|i| i}
  end
  def cached_method(options={})
    Rails.cache.fetch('some_model_cached_method_key', options) do
      SomeModel.method_results
    end
  end
end

shared_context 'persisted_cache' do
  let(:key){'some_model_cached_method_key'}
  before do
    PersistedCache::KeyValuePair.destroy_all
    Rails.cache.clear
  end
end