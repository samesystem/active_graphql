# Model

## Setup

To create graphql model, you need to include `Model` module in your ruby class like this:

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.url 'http://localhost:3000'
    c.attributes :id, :first_name, :last_name
  end
end
```

Attributes also can be nested, like this:

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.attributes location: [:city, :country, :street]
  end
end

User.find(3).location # { city: 'London', country: ... }
```

### active_graphql.url

Sets url where all GraphQL queries should go

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.url 'http://localhost:3000'
  end
end
```

### active_graphql.attributes

Sets attributes which can be fetched from graphql

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.attributes :id, :first_name, :last_name
  end
end

User.find(3).first_name # => some name returned from graphql
```

### active_graphql.attribute

Sets attribute which can be fetched from graphql

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.attribute :id
    c.attribute :location, [:lat, :lan], decorate_with: :decorate_location
  end

  def decorate_location(location_value)
    Location.new(lat: location_value[:lat], lan: location_value[:lan])
  end
end

User.find(3).first_name # => some name returned from graphql
```

#### nested attributes

You can have nested attributes. Nested values will be returned as hash:

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.attribute :id
    c.attribute :location, [:lat, :long]
  end
end

User.find(3).location #=> { lat: 25.0, long: 26.0 }
```

#### decorated attributes

You can use decorator methods in order to modify model attribute values. It's very in combination with nested values

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.attribute :name, decorate_with: :make_fancy_name
  end

  def make_fancy_name(original_name)
    "Mr. #{original_name}"
  end
end

User.find(3).name #=> "Mr. John"
```

### active_graphql.resource_name

Sets attributes which can be fetched from graphql

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.resource_name :admin_user
    c.attributes :id
  end
end

User.where(name: 'John').to_graphql # => "query { adminUsers(name: "John") { id } }"
```

## Methods

### find

Use `find` method in order to find record:

```ruby
user = User.find(5)
```

### update

Use `update` to update record on graphql side:

```ruby
User.find(5).update(first_name: 'John') # => true or false
```

### update!

Use `update!` to update record on graphql side:

```ruby
User.find(5).update!(first_name: 'John') # => true or exception
```

### destroy

Use `destroy` in order to delete record on graphql side:

```ruby
User.find(5).destroy # => true or false
```

### create

to create model on graphql side simply use `create` method, like this:

```ruby
user = User.create(first_name: 'John', last_name: 'Doe')
```

### create!

as in ActiveRecord, there is `create!` method which will raise error when create fails:

```ruby
user = User.create!(first_name: 'John', last_name: 'Doe')
```

### where

Use `where` method in order to find multiple record:

```ruby
users = User.where(name: 'John')
```

### order

Use `order` when you need to sort results:

```ruby
users.order(created_at: :desc)
```

### find_each

In order to iterate through multiple pages, you need to use `find_each` method

```ruby
User.all.find_each do |user|
  do_something(user)
end
```

