# persisted_cache

DB layer for Rails.cache.fetch.

Rails.cache.fetch(key){block} is pretty clean. On cache miss, the block is executed. Results are stored in the Rails cache and returned. Subsequent calls are returned from the cache. Easy peasy. We use this for things like dashboard tiles which take some time to build and don't change very often. 

Recently we decided to lean on this technique a little harder. We build reports that can include a million rows. In order to display them quickly, we've always used summary tables. Easy enough, but we always seemed to be wanting another column that wasn't summarized.

After this happened a few times, we decided to ditch the summary table approach and just do long running queries at night against the models with all the detail. Instead of building a summarization model which can go out of date, we'd just store the data as a serialized hash every night. If we learned we needed another column, we could just start storing it. We wouldn't want to pull those hashes out of the db all the time though, so we would cache them. 

It seemed natural to extend Rails.cache.fetch to persist and cache them at the same time. On cache miss, if an option of `persisted_cache: 'read'` is passed to Rails.cache.fetch or Rails.cache.read, persisted_cache tries to fall back to a value in the db. If it's not there, the block is executed and the value is stored in the cache as usual. If `persisted_cache: 'read'` is not passed, the db is not checked at all.

To prime the cache, `persisted_cache: 'write'` is passed as an option to the fetch method. The block is executed and saved in the db.

The first time Rails.cache.fetch or Rails.cache.read are called for the key with the `persisted_cache: 'read'` option, it is pulled from the db and stored in Rails cache.

We needed to handle the case when a new user was looking for reports before we generated them and they weren't cached yet. Use the `persisted_cache: 'require'` option for this. It causes a `PersistedCache::MissingRequiredCache` exception to be raised if there is no value in the cache. (We rescue this in the controller to show u/i which says the report is being built.)

If there is reason to delete the key instead of just updating the value, a `persisted_cache: 'delete'` option can be passed to Rails.cache.delete which will delete the key value pair from the db when it is cleared from the cache.

Finally this table could get large. We needed to be able to save these results in a different db. This is supported by allowing an alternate base class for the KeyValuePair model to be specified in *initializers/persisted_cache.rb*.

### Installation

Note: This has only been tested on Rails 4.2.5.1 and Rails 5.0.0.1.

Add it to your Gemfile:

```ruby
gem 'persisted_cache', '~> 0.1.0', git: 'https://github.com/taxjar/persisted_cache.git'
```

Run `bundle install`. Next, run the generator:

```
rails g persisted_cache:install
```

This will create an initializer in *config/initializers/persisted_cache.rb*.

It will also create a migration file in *db/migrate/[VERSION]_create_persisted_cache_key_value_pairs.rb*.

Run migrations. **Note:** If you are using a different database, move the migration file to the appropriate path before migrating!

```
rake db:migrate
```

### Example

In the console...

By passing `persisted_cache: 'write'` we write the value of the block to the key_value_pairs table.

```ruby
2.1.8 :011 > Rails.cache.fetch('my_key', persisted_cache: 'write'){[:foo, :bar, :baz]}
...
  SQL (0.4ms)  INSERT INTO "key_value_pairs" ("key", "value", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["key", "my_key"], ["value", "---\n- :foo\n- :bar\n- :baz\n"], ["created_at", "2016-09-22 20:43:34.756302"], ["updated_at", "2016-09-22 20:43:34.756302"]]
   (0.7ms)  COMMIT  
 => [:foo, :bar, :baz]
```

Next time we call fetch it returns the value from the cache (notice no DB queries in the logs and value is not from the block.)

```ruby
2.1.8 :012 > Rails.cache.fetch('my_key', persisted_cache: 'read'){[:something, :else]}
 => [:foo, :bar, :baz] 
```

If we clear the cache, we see that the next call gets its result from the DB, not the block.

```ruby
2.1.8 :013 > Rails.cache.clear
 => "OK" 
2.1.8 :014 > Rails.cache.fetch('my_key', persisted_cache: 'read'){[:something, :else]}
  PersistedCache::KeyValuePair Load (0.6ms)  SELECT  "key_value_pairs".* FROM "key_value_pairs" WHERE "key_value_pairs"."key" = $1  ORDER BY "key_value_pairs"."id" ASC LIMIT 1  [["key", "my_key"]]
 => [:foo, :bar, :baz] 
```

It has now been set in the cache again, so subsequent calls do not hit the DB.

```ruby
2.1.8 :015 > Rails.cache.fetch('my_key', persisted_cache: 'read'){[:something, :else]}
  => [:foo, :bar, :baz] 
```

### Using an Alternate Database

When you run `rails generate persisted_cache:install`, an initializer and a migration are created. If you have an alternate DB set up on your system, move the migration file to the appropriate path before migrating, and set the base class used for the `PersistedCache::KeyValuePair` model to one that has a connection to your alternate DB. There's a good explanation of how to set up an alternate DB in your rails app [here](http://www.ostinelli.net/setting-multiple-dbs-rails-definitive-guide/).

*config/initializers/persisted_cache.rb*

```ruby
PersistedCache.configure do |config|
  config.base_class = BulkStorage::Base
end
```

### Exceptions

As mentioned above, if the `fail_on_cache_miss: true` option is passed a `PersistedCache::MissingRequiredCache` exception will be raised if the key value pair does not exist in the cache or DB. 

If `fail_on_cache_miss: true` is passed along with `persist: true` a `PersistedCache::InvalidOptions` exception will be raised.
