# Model

## Setup

To create graphql model, you need to include `ActiveGraphql::Model` module in your ruby class like this:

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
    c.attribute :name
  end
end

User.find(3).name # => "John"
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

### active_graphql.primary_key

By default primary key is `id`, but you can change it like this:

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.primary_key :email
  end
end

User.find('john@example.com') # will execute in GraphQL: 'query { user(email: "john@example.com") }'
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

### merge

Use `merge` method in order to merge multiple queries:

```ruby
# same as User.where(name: 'John', surname: 'Doe') :
users = User.where(name: 'John').merge(User.where(surname: 'Doe'))
```

### or

Use `or` method in order to query using "or" predicate:

```ruby
# same as User.where(or: { name: 'John', surname: 'Doe' }) :
users = User.where(name: 'John').or(User.where(surname: 'Doe'))
```

Keep in mind that your endpoint must support filtering by "or" key like this:

```graphql
  query {
    users(filter: { or: { name: 'John', surname: 'Doe' } }) {
      ...
    }
  }
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

### paginate

you can also paginate records:

```ruby
User.paginate(page: 1, per_page: 3)
```

### page

you can also paginate records:

```ruby
User.page(1)
```

### Selecting certain fields

You can select only attributes which you want to be selected from model, like this:

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.url 'http://example.com/graphql'
    c.attributes :id, :first_name, location: %i[street city], name: :full_name
  end

  def self.main_data
    select(:first_name, location: :city, name: :full_name)
  end
end

User.main_data
```

This will produce GraphQL:
```graphql
query {
  users {
    firstName
    location {
      city
    }
    name {
      fullName
    }
  }
}
```

### defining custom queries

You can define your custom queries by adding class method, like this:

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.attributes :id
  end

  def self.with_custom
    where(custom: true)
  end
end

User.where(id: 1).with_custom
```

this will produce GraphQL:

```graphql
query {
  users(filter: { id: 1, custom: true } ) {
    id
  }
}
```

### mutate

You can define your custom mutations by adding instance method, like this:

```ruby
class User
  include ActiveGraphql::Model

  active_graphql do |c|
    c.attributes :id, :first_name, :last_name
  end

  def update_name(first_name, last_name)
    mutate(:update_name, input: { first_name: 'Fancy', last_name: 'Pants' })
  end
end

User.last.update_name('Fancy', 'Pants')
```

This will produce GraphQL:
```graphql
mutation {
  updateName(id: 99, input: { firstName: 'Fancy', lastName: 'Pants' }) {
    id
    firstName
    lastName
    ...
  }
}
```

## Requirements for GraphQL server side

In order to make active_graphql work, server must met some conditions.

### Naming requirements

Resource, attribute and field names must be in camelcase

#### Resource name requirements for CRUD actions

Let's say we have `BlogPost` resource, so CRUD actions should be named like this:
- `blogPost(id: ID!)` (aka, `show` action)
- `blogPosts(filter: FilterInput)` (aka, `index` action)
- `createBlogPost(input: SomeCreateInput!)` (aka, `create` action)
- `updateBlogPost(id: ID!, input: SomeUpdateInput!)` (aka, `update` action)
- `destroyBlogPost(id: ID!)` (aka, `destroy` action)

### Requirements for Model#find methods

In order to make Model#find work, server must have resource in singular form with single `id: ID!` argument.

Example: `user(id: ID!)`

### Requirements for Model#all, Model#find_each methods

In order to make Model#all and Model#find_each work, server must have resource in plural form and also response should be paginated.

Example:
```
users(first: Integer, last: Integer, before: String, after: String) {
  edges {
    node {
      ...
    }
  }
}
```

### Requirements for Model#where, Model#find_by methods

In order to make Model#where and Model#find_by work, server must have resource in plural form with `filter: SomeFilterInput` argument. Also resource must match requirements for Model#all too (see previous section)

Example:
```
type UsersFilterInput {
  firstName: String!
  lastName: String!
}

users(filter: UserFilterInput) {
  edges {
    node {
      ...
    }
  }
}
```

### Requirements for Model#or method

In order to make Model#or resouce must match requirements for `Model#where` method. Also `filter` input must have `or` argument

Example:
```
type UsersFilterInput {
  or: UsersOrFilterInput
  groupId: [ID!],
  name: String!
}

type UsersOrFilterInput {
  groupId: [ID!],
  name: String!
}

users(filter: UserFilterInput) {
  edges {
    node {
      ...
    }
  }
}
```

### Requirements for Model#count

In order to make Model#where and Model#find_by work, server must have resource in plural form. This resource must have `total:Integer` **output** field:

Example:
```
users() {
  total
  edges {
    node {
      ...
    }
  }
}
```
