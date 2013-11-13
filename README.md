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
  scopable_by  :older_than
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

I'm going to release to rubygems shortly, once I'm certain the interface won't change too much. Right now you
can add to your Gemfile and reference github if you're a brave soul.

### Need more info? A real-world example

We have a Place (ActiveRecord) model with attributes and scopes to filter on, so we have all of the power of the AR query DSL at our fingertips.

```ruby

class Place < ActiveRecord::Base

  scope :in_group, ->(place_grouping) { ... }

  scope :nearby_place_id, ->(place_id) { ... }

end
```

We want to provide a REST API with, amongst other things, an index action for querying lists of places.

The [Hooroo Places](http://places.hooroo.com) API accepts this request for GET-ing the first 10 "See & Do" places near Mamasita with "Museum" in the name, ordered by name. 
It also allows requests to specify (according to the pattern set out in the [JSON API spec](http://jsonapi.org/) what related objects to serialise, too:

```
"/api/places?include=images,comments.author&in_group=see_do&nearby_place_id=mamasita&name=museum&sort_by=name&limit=10&offset=0"
```

When our Rails app receives this request it parses the query string as a params hash, like this:

```
{"include"=>"images,comments.author", "in_group"=>"see_do", "nearby_place_id"=>"mamasita", "name"=>"museum", "sort_by"=>"name", "limit"=>10, "offset"=>0}
```

QueryAr provides a standard, declarative way to get from the above params hash, to a queried ActiveRecord relation like this:

```ruby
Place.includes(:images, comments: [:author]).
  .in_group('see_do')
  .nearby_place_id('mamasita')
  .where(name: 'museum')
  .order('name')
  .limit(10)
  .offset(0)
```

### Define a query

Continuing our example, the object responsible for taking a set of params and constructing a scoped and eager-loaded AR relation is the Query. 
Here's what the PlaceQuery would look like:

```ruby
class PlaceQuery
  include QueryAr

  defaults sort_by: 'name', sort_dir: 'ASC',
    limit: 10, offset: 0

  queryable_by :name, :street_address
  scopable_by  :in_group, :nearby_place_id
  includable   :images, comments: [:author]
end
```

The above class deals with building queries for the Place model, and declares that:

* there will be specific default sorting and pagination for Places
* only Place attributes ```#name``` and ```#street_address``` can be queried on
* the Place scopes that can be applied are ```#in_group``` and ```#nearby_place_id```
* ```place.images```, ```place.comments``` and ```place.comments.author``` are the only place relations that *can* be included in the JSON response

In our Places Controller, we use this class like so:

```ruby
def index
  places = PlaceQuery.new(params).all
  render json: places
end
```

You can also find single records. Includes will still be taken into consideration:

```ruby
def index
  place = PlaceQuery.new(params).find
  render json: place
end
```

The find method will look for a param called ```id``` by default, but you can pass another key in if your params are named differently:

```ruby
def index
  place = PlaceQuery.new(params).find(:place_id)
  render json: place
end
```

The public interface of every query object is as follows:

```ruby
query.all
#=> #<ActiveRecord::Relation [Place(id: 157 name: Melbourne Museum)...]>

query.find
#=> Place

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

### Run-down of DSL:

#### defaults

Keys and values specifying defaults for things like ```sort_by```, ```sort_dir```, ```limit``` and ```offset```.

#### queryable_by

Declares what attributes can be queried in the ActiveRecord ```where``` clause.

#### scopable_by

Declares which scopes on your model can be queried on.


#### includable

Declares what related items on your model's graph can be included in the response. Allowing the client to specify what size of payload they require.

## Summary

If you have any comments or questions, please feel free to get in touch.

Of course, Pull Requests are very welcome. If you have any doubts about the appropriateness of a particular feature you want to add, please don't hesitate to create a GitHub issue and we can discuss.

## TODO:

* Make global defaults configurable in code (initialiser/yaml)
* Query on attributes belonging to included relations

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
