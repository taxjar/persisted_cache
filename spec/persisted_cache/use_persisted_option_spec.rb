require 'spec_helper'

describe 'use_persisted option' do
  include_context 'persisted_cache'
  context "when true" do
    let(:options){{use_persisted: true}}
    let(:db_result){PersistedCache::KeyValuePair.new(key: key, value: SomeModel.method_results)}
    subject{SomeModel.new.cached_method(options)}
    it "should hit the db" do
      expect(PersistedCache::KeyValuePair).to receive(:where).and_return([db_result])
      expect(subject).to eql(SomeModel.method_results)
      expect(Rails.cache.read(key)).to eql(SomeModel.method_results)
    end
  end
  context "when not true" do
    let(:options){{}}
    subject{SomeModel.new.cached_method(options)}
    it "should not hit the db" do
      expect(PersistedCache::KeyValuePair).to receive(:where).never
      expect(subject).to eql(SomeModel.method_results)
      expect(Rails.cache.read(key)).to eql(SomeModel.method_results)
    end
  end
end