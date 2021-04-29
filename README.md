# spiski.live

## Prerequisites

* Elixir 1.11+
* Redis with default config

## Open 80 port for Cowboy webserver work directly

```shell
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/lib/erlang/erts-11.1/bin/beam.smp
```

## Deploy

```shell
git pull 
kill -9 beam.smp 
export MIX_ENV=prod
mix do deps.get, deps.compile
elixir --erl "-detached" -S mix run --no-halt
```

## Run

```shell
MIX_ENV=prod elixir --erl "-detached" -S mix run --no-halt
```