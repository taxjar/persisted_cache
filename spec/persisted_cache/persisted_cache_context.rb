shared_context 'persisted_cache' do
  let(:key){'some_model_cached_method'}
  before do
    PersistedCache::KeyValuePair.destroy_all
    Rails.cache.clear
  end
end