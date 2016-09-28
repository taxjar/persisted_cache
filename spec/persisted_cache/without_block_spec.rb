require 'spec_helper'

describe 'PersistedCacheTest' do
  include_context 'persisted_cache'
  context "when no block is passed" do
    subject{Rails.cache.fetch(key)}
    context "cache miss" do
      it "should return false" do
        expect(subject).to be_falsey
      end
    end
    context "cache hit" do
      let(:value){'blafoo'}
      before{manually_set_cache_value}
      it "should return value" do
        expect(subject).to eql(value)
      end
    end
  end
  context "cache delete" do
    let(:key_to_delete){'delete-me'}
    let(:value){[41,2,33,14,95]}
    before do
      expect{Rails.cache.fetch(key_to_delete, persist: true){value}}.to change(PersistedCache::KeyValuePair, :count).by(1)
      expect(Rails.cache.fetch(key_to_delete)).to eql(value)
    end
    subject{Rails.cache.delete(key_to_delete, delete_persisted: true)}
    it "should remove the pair from cache and db" do
      expect(Rails.cache.fetch('key_to_delete')).to be_nil
      expect{subject}.to change(PersistedCache::KeyValuePair, :count).by(-1)
    end
  end

  context "expiration" do
    let(:expires_in){1.second}
    subject{Rails.cache.fetch(key, expires_in: expires_in){'hey now'}}
    it "should not be affected" do
      subject
      sleep 2
      expect(Rails.cache.fetch(key)).to be_nil
    end
  end

  private

  def manually_set_cache_value
    Rails.cache.write(key, value)
  end

  def manually_create_persisted_key_value_pair
    PersistedCache::KeyValuePair.create!(key: key, value: persisted_value)
  end

end
