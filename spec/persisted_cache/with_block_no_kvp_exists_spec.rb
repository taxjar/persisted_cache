require 'spec_helper'

describe 'PersistedCacheTest' do
  include_context 'persisted_cache'
  context "when a block is passed" do
    subject{SomeModel.new.cached_method(options)}
    let(:options){{use_persisted: true}}
    context "no persisted key value pair exists" do
      context "cache miss" do
        it "sets rails cache from db and returns value" do
          expect(Rails.cache.read(key)).to be_nil
          expect(PersistedCache::KeyValuePair).to receive(:create!).never
          expect(subject).to eql(SomeModel.method_results)
          expect(Rails.cache.read(key)).to eql(SomeModel.method_results)
        end
        context "persist option passed in" do
          let(:options){{persist: true}}
          it "saves to the db, does not set the rails cache and returns value" do
            expect(PersistedCache::KeyValuePair).to receive(:create!)
            expect(subject).to eql(SomeModel.method_results)
            expect(Rails.cache.read(key)).to be_nil
          end
          context "fail_on_cache_miss option passed in" do
            let(:options){{persist: true, fail_on_cache_miss: true}}
            it "raises an error" do
              expect{subject}.to raise_error(PersistedCache::InvalidOptions)
            end
          end
        end
        context "fail_on_cache_miss option passed in" do
          let(:options){{use_persisted: true, fail_on_cache_miss: true}}
          it "raises an error" do
            expect{subject}.to raise_error(PersistedCache::MissingRequiredCache)
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
          let(:options){{persist: true}}
          it "saves to the db, does not set the rails cache and returns value" do
            expect(PersistedCache::KeyValuePair).to receive(:create!)
            expect(subject).to eql(SomeModel.method_results)
            expect(Rails.cache.read(key)).to be_nil
          end
          context "fail_on_cache_miss option passed in" do
            let(:options){{persist: true, fail_on_cache_miss: true}}
            it "raises an error" do
              expect{subject}.to raise_error(PersistedCache::InvalidOptions)
            end
          end
        end
        context "fail_on_cache_miss option passed in" do
          let(:options){{use_persisted: true, fail_on_cache_miss: true}}
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

  def manually_create_persisted_key_value_pair
    PersistedCache::KeyValuePair.create!(key: key, value: persisted_value)
  end

end
