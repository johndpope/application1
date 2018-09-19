# Geobase

Countries, regions, cities, ZIP codes and landmarks.

## Installation

```ruby
gem 'geobase', git: 'git@bitbucket.org:valynteen_solutions/geobase.git'
```

```bash
bundle install
```

```bash
rake geobase:install:migrations
```

### Seed data

```ruby
# add to db/seeds.rb
Geobase::Engine.load_seed
```

### Migrate and fill in seed data

```bash
rake db:migrate
rake db:seed
```
