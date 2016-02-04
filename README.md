# ExNeo

A lightweight library to interface with a Neo4j rest server.


## Create a session

```elixir
session = ExNeo.Session.create("http://localhost:7474")
```

or

```elixir
# Uses http://localhost:7474 as the default url.
session = ExNeo.Session.create()
```

### Session Config

Add the following to `config/config.exs` to change the default url:
```
config :ex_neo, url: defualt_url_here
```

## Cypher

Commit a cypher statement:

```
statement = "MATCH (node) RETURN node LIMIT 1"
session = ExNeo.Session.create()
ExNeo.commit_statement(session, statement)
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ex_neo to your list of dependencies in `mix.exs`:

        def deps do
          [{:ex_neo, "~> 0.0.1"}]
        end

  2. Ensure ex_neo is started before your application:

        def application do
          [applications: [:ex_neo]]
        end
