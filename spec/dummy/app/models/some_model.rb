class SomeModel
  def cached_method(options={})
    Rails.cache.fetch('some_model_cached_method', options) do
      (1..50).map{|i| i}
    end
  end
end