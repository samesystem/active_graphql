# ActiveGraphql
[![Build Status](https://travis-ci.com/samesystem/active_graphql.svg?branch=master)](https://travis-ci.com/samesystem/active_graphql)
[![codecov](https://codecov.io/gh/samesystem/active_graphql/branch/master/graph/badge.svg)](https://codecov.io/gh/samesystem/active_graphql)
[![Documentation](https://readthedocs.org/projects/ansicolortags/badge/?version=latest)](https://samesystem.github.io/active_graphql)

GraphQL client which allows to interact with graphql using ActiveRecord-like API

Detailed documentation can be found at https://samesystem.github.io/active_graphql	

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_graphql'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_graphql

## Usage

You can fetch data from GraphQL in two different ways: using `ActiveGraphql::Client` or using `ActiveGraphql::Model`

### ActiveGraphql::Client

`ActiveGraphql::Client` is a client which allows you to make requests using ruby-friendly code:

```ruby
client = ActiveGraphql::Client.new(url: 'https://example.com/graphql')

client.query(:findUser).inputs(id: 1).outputs(:name, :avatar_url).result
# or same request with AR-style syntax
client.query(:findUser).select(:name, :avatar_url).where(id: 1).result
```

### ActiveGraphql::Model

If you have well structured GraphQL endpoint, which has CRUD actions for each entity then you can interact with GraphQL endpoints using `ActiveGraphql::Model`.
It allows you to have separate class for separate GraphQL entity, Here is an example:

Suppose you have following endpoints in graphql:

* `users(filter: UsersFilter!`) - index action with filtering possibilities
* `user(id: ID!)` - show action

In this case you can create ruby class like this:

```ruby
class User
  include ActiveGraphql::Model

  graphql_url('http://example.com/graphql')
  graphql_attributes :id, :first_name, :last_name, :created_at
end
```

with this small setup you are able to do following:

```ruby
User.where(first_name: 'John').to_a # list all users with name "John"
User.limit(5).to_a # list first 5 users
User.find(1) # find user with ID: 1
User.first(2) # find first 2 users
User.last(3) # find last 3 users
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/samesystem/active_graphql. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveGraphql project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/samesystem/active_graphql/blob/master/CODE_OF_CONDUCT.md).
