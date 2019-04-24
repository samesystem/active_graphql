# Client

## Initialization

to initialize graphql client, simply create new client instance with url:

```ruby
client = ActiveGraphql::Client.new(url: 'http://example.com/graphql')
```

## query and mutation actions

```ruby
mutation = client.mutation(:create_user)
query = client.query(:find_user)
```

### where (alias: input)

In order to filter values you can query with `where` method:

```ruby
query = query.where(name: 'John', date: { from: '2000-01-01' })
```

this will produce following GraphQL:

```graphql
query {
  find_user(name: "John", date: { from: "2000-01-01" }) {
    ...
  }
}
```

### select (alias: output)

In order to select which attributes you want to receive from query then you need to use `select` method:

```ruby
query = query.select(:name, date: [:year])
```

this will produce following GraphQL:

```graphql
query {
  find_user {
    name
    date { year }
  }
}
```

### meta

You can assign meta attributes in order to use them later

```ruby
query = query.meta(custom: true)
query = query.meta(also_custom: 'yes')
query.meta_attributes # => { :custom => true, :also_custom => "yes" }
```
