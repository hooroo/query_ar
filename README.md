# QueryAr

> Best pronounced like a pirate: QueryARRR!

Gives you a DSL to build filtered, scoped, paged and sorted ActiveRecord queries, based on a parameters hash

### Really quick usage example

Given this ActiveRecord model:

```ruby
class User
  scope :older_than, ->(years) { where("age > ?", years) }
end
```

You can declare a query:

```ruby
class UserQuery
  include QueryAr

  defaults sort_by: 'last_name'

  queryable_by  :first_name, :last_name
  scopeable_by  :older_than
end
```

Then use it to query your model safely and succinctly from controller params:

```ruby

# GET /users
# params = { "older_than"=>30, "first_name"=>"Stu", "limit"=>5, "offset"=>0 }

def index
  query = UserQuery.new(params)
  render json: query.all
end
```

### I've seen enough, how do I install it?

Add this line to your application's Gemfile:

    gem 'query_ar'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install query_ar

### Need more info? A real-world example

We have a Place (ActiveRecord) model with attributes and scopes to filter on, so we have all of the power of the AR query DSL at our fingertips.

```ruby

class Place < ActiveRecord::Base

  scope :in_group, ->(place_grouping) { ... }

  scope :nearby_place_id, ->(place_id) { ... }

end
```

We want to provide a REST API with, amongst other things, an index action for querying lists of places.

The [Hooroo Places](http://places.hooroo.com) API might accept this request for GET-ing the first 10 "See & Do" places near Mamasita with "Museum" in the name, ordered by name:

```
"/api/places?in_group=see_do&nearby_place_id=mamasita&name=museum&sort_by=name&limit=10&offset=0"
```

When our Rails app receives this request it parses the query string as a params hash, like this:

```
{"in_group"=>"see_do", "nearby_place_id"=>"mamasita", "name"=>"museum", "sort_by"=>"name", "limit"=>10, "offset"=>0}
```

This gem provides a standard, declarative way to get from the above params hash, to a queried ActiveRecord relation like this:

```ruby
Place.in_group('see_do')
  .nearby_place_id('mamasita')
  .where(name: 'museum')
  .order('name')
  .limit(10)
  .offset(0)
```

### Define a query

Continuing our example, here's what the PlaceQuery would look like:

```ruby
class PlaceQuery
  include QueryAr

  defaults sort_by: 'name', sort_dir: 'ASC',
    limit: 10, offset: 0

  queryable_by  :name, :street_address
  scopeable_by  :in_group, :nearby_place_id
end
```

The above class deals with building queries for the Place model, and declares that:

* there will be specific default sorting and pagination for Places
* only Place attributes ```#name``` and ```#street_address``` can be queried on
* the Place scopes that can be applied are ```#in_group``` and ```#nearby_place_id```

In our Places Controller, we use this class like so:

```ruby
def index
  query = PlaceQuery.new(params)
  render json: query.all
end
```

The public interface of every query object is as follows:

```ruby
query.all
#=> #<ActiveRecord::Relation [Place(id: 157 name: Melbourne Museum)...]>

query.count
#=> 10 # number of records #all contains

query.total
#=> 13 # total (unpaginated) result count

query.summary
#=> {
#     offset: 0, limit: 10,
#     sort_by: 'name', sort_dir: 'ASC',
#     count: 10, total: 13
#   }
```

The summary is designed to be placed into the JSON response as a meta key, although the details of serialising the response into JSON is intentionally left out of this gem.

If you have any comments or questions, please feel free to get in touch.

Of course, Pull Requests are very welcome. If you have any doubts about the appropriateness of a particular feature you want to add, please don't hesitate to create a GitHub issue and we can discuss.

## TODO:

* Write up documentation for eagerloading with .includes.
* Right now we get errors when we don't .include any relations

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
