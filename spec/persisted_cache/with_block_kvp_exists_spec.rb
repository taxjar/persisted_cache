require 'spec_helper'

describe 'PersistedCacheTest' do
  include_context 'persisted_cache'
  context "when a block is passed" do
    subject{SomeModel.new.cached_method(options)}
    let(:options){{}}
    context "persisted key value pair exists" do
      let(:persisted_value){[1,2,3,4,5]}
      before{manually_create_persisted_key_value_pair}
      context "cache miss" do
        it "returns and caches value from db" do
          expect(subject.size).to eql(persisted_value.size)
          expect(Rails.cache.read(key).size).to eql(persisted_value.size)
        end
        context "persist option passed in" do
          let(:options){{persist: true}}
          it "saves to the db, sets the cache and returns value" do
            expect{subject}.to change(PersistedCache::KeyValuePair, :count).by(0)
            expect(subject.size).to eql(50)
            expect(Rails.cache.read(key).size).to eql(50)
          end
          context "fail_on_cache_miss option passed in" do
            let(:options){{persist: true, fail_on_cache_miss: true}}
            it "raises an error" do
              expect{subject}.to raise_error(PersistedCache::InvalidOptions)
            end
          end
          context "with other options passed in" do
            let(:options){{persist: true, foo: :bar}}
            it "respects the other options" do
              expect(Rails.cache).to receive(:write).with(key, (1..50).map{|i| i}, {:persist=>true, :foo=>:bar, :force=>true})
              subject
            end
          end
        end
        context "fail_on_cache_miss option passed in" do
          let(:options){{fail_on_cache_miss: true}}
          it "does not raise an error" do
            expect{subject}.not_to raise_error
          end
        end
        context "skip_rails_cache option passed in" do
          let(:options){{persist: true, skip_rails_cache: true}}
          it "updates db, sets the cache and returns value" do
            Rails.cache.write(key, [1,2,3])
            expect(Rails.cache.read(key).size).to eql(3)
            expect{subject}.to change(PersistedCache::KeyValuePair, :count).by(0)
            expect(subject.size).to eql(50)
            expect(Rails.cache.read(key).size).to eql(50)
          end
        end
      end
      context "cache hit" do
        let(:value){[1]}
        before{manually_set_cache_value}
        it "returns value from cache" do
          expect(Rails.cache.read(key)).to eql(value)
          expect(subject.size).to eql(1)
          expect(Rails.cache.read(key).size).to eql(1)
        end
        context "persist option passed in" do
          let(:options){{persist: true}}
          it "saves to the db, sets the cache and returns value" do
            expect{subject}.to change(PersistedCache::KeyValuePair, :count).by(0)
            expect(subject.size).to eql(50)
            expect(Rails.cache.read(key).size).to eql(50)
          end
          context "fail_on_cache_miss option passed in" do
            let(:options){{persist: true, fail_on_cache_miss: true}}
            it "raises an error" do
              expect{subject}.to raise_error(PersistedCache::InvalidOptions)
            end
          end
        end
        context "skip_rails_cache option passed in" do
          let(:options){{persist: true, skip_rails_cache: true}}
          it "updates db, sets the cache and returns value" do
            Rails.cache.write(key, [1,2,3])
            expect(Rails.cache.read(key).size).to eql(3)
            expect{subject}.to change(PersistedCache::KeyValuePair, :count).by(0)
            expect(subject.size).to eql(50)
            expect(Rails.cache.read(key).size).to eql(50)
          end
        end
        context "fail_on_cache_miss option passed in" do
          let(:options){{fail_on_cache_miss: true}}
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
