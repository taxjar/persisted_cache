require 'spec_helper'

describe 'PersistedCacheTest' do
  include_context 'persisted_cache'
  context "when a block is passed" do
    subject{SomeModel.new.cached_method(options)}
    let(:options){{persisted_cache: 'read'}}
    context "persisted key value pair exists" do
      let(:persisted_value){[1,2,3,4,5]}
      let!(:existing_kvp){PersistedCache::KeyValuePair.create!(key: key, value: persisted_value)}
      context "cache miss" do
        it "sets rails cache from db and returns value" do
          expect(PersistedCache::KeyValuePair).to receive(:create!).never
          expect(Rails.cache).to receive(:write).with(key, persisted_value, options)
          expect(subject).to eql(persisted_value)
        end
        context "persist option passed in" do
          let(:options){{persisted_cache: 'write'}}
          it "updates db, does not set the rails cache and returns value" do
            expect(PersistedCache::KeyValuePair.find_by_key(key).id).to eql(existing_kvp.id)
            expect{subject}.to change(PersistedCache::KeyValuePair, :count).by(0)
            expect(PersistedCache::KeyValuePair.find_by_key(key).id).not_to eql(existing_kvp.id)
            expect(subject).to eql(SomeModel.method_results)
            PersistedCache::KeyValuePair.destroy_all
            expect(Rails.cache.read(key)).to be_nil
          end
        end
        context "fail_on_cache_miss option passed in" do
          let(:options){{persisted_cache: 'require'}}
          it "does not raise an error" do
            expect{subject}.not_to raise_error
          end
        end
      end
      context "cache hit" do
        let(:value){[1]}
        before{manually_set_cache_value}
        it "returns value from cache" do
          expect(PersistedCache::KeyValuePair).to receive(:where).never
          expect(subject).to eql(value)
        end
        context "persist option passed in" do
          let(:options){{persisted_cache: 'write'}}
          it "updates db, deletes the key from the rails cache and returns value" do
            expect(Rails.cache.read(key)).to eql(value)
            expect(PersistedCache::KeyValuePair.find_by_key(key).id).to eql(existing_kvp.id)
            expect{subject}.to change(PersistedCache::KeyValuePair, :count).by(0)
            expect(PersistedCache::KeyValuePair.find_by_key(key).id).not_to eql(existing_kvp.id)
            expect(subject).to eql(SomeModel.method_results)
            PersistedCache::KeyValuePair.destroy_all
            expect(Rails.cache.read(key)).to be_nil
          end
        end
        context "fail_on_cache_miss option passed in" do
          let(:options){{persisted_cache: 'require'}}
          it "does not raise an error" do
            expect{subject}.not_to raise_error
          end
        end
      end
    end
  end

  private

  def manually_set_cache_value
    Rails.cache.write(key, value)
  end


end
