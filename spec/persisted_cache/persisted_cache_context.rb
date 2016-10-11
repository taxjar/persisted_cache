shared_context 'persisted_cache' do
  let(:key){'some_model_cached_method_key'}
  before do
    PersistedCache::KeyValuePair.destroy_all
    Rails.cache.clear
  end
end