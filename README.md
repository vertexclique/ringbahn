![Ringbahn](http://i.imgur.com/9dIl75w.png)
### High performance multiple backend web server

[![Build Status](https://travis-ci.org/vertexclique/ringbahn.svg?branch=master)](https://travis-ci.org/vertexclique/ringbahn) [![Hex.pm](https://img.shields.io/hexpm/v/ringbahn.svg)](https://hex.pm/packages/ringbahn) [![Hex.pm](https://img.shields.io/hexpm/dt/ringbahn.svg)](https://hex.pm/packages/ringbahn) [![Coverage Status](https://coveralls.io/repos/github/vertexclique/ringbahn/badge.svg)](https://coveralls.io/github/vertexclique/ringbahn) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/vertexclique/ringbahn.svg)](https://beta.hexfaktor.org/github/vertexclique/ringbahn) [![Hex.pm](https://img.shields.io/hexpm/l/ringbahn.svg)](https://hex.pm/packages/ringbahn)

## Requirements

* Erlang/OTP 19
* Elixir 1.3.4
* Mix 1.3.4

## Running

Install elixir and mix:
```
$ brew install elixir
```

Install project dependencies with:
```
$ mix deps.get
```

Start with internal default conf:
```
$ mix run --no-halt
```

Start with external conf
```
$ mix escript.build
$ ./ringbahn --config=../some_config_dir/config.ring.json
```

For debugging use iex
```
iex -S mix
```

[![asciicast](https://asciinema.org/a/97359.png)](https://asciinema.org/a/97359)

_We are at an early development stage, please use it with caution._

# Configuration

By default Ringbahn uses json files for configuration.
To distinguish between other json files please prefer using `.ring.json` extension.
It may use templating support later on... (with EEx or any other choice)

Example configuration is like:

```json
{
    "settings": {
        "backend": "ZMQ",                  # Defines the backend interface to talk with handlers
        "worker_count": 4,                 # Defines how many internal processes should be started
        "port_offset": 100,                # Defines the intervals for instance ports
        "disable_access_logging": true     # Disables access logging (Not Implemented)
    },
    "static_dir": {                        # Static DIR serving (Not implemented)
        "base": "public",
        "index_file": "index.html",
        "default_ctype": "text/plain"
    },
    "server": {
        "pid_file": "/run/ringbahn.pid",                                 # PID file (Not Implemented)
        "uuid": "edc0a43a-9d93-4d3d-93db-94c3a581ab17",                  # Ringbahn Server UUID (will be muxed by worker_count)
        "access_log": "/log/access.log",                                 # Access log file basename (Not Implemented)
        "error_log": "/log/error.log",                                   # Error log file basename (Not Implemented)
        "port": 6767,                                                    # Starting port for server endpoint (will be muxed by port_offset)
        "default_host": "localhost",                                     # Default host name for serving through...
        "hosts": {                                                       # Every host declaration goes inside of this
            "localhost": [                                               # Route declarations goes inside of this host
                {
                    "route": "/test",                                    # Route that will be handled
                    "send_spec": "127.0.0.1",                            # Send address that will be used to send incoming request to handlers
                    "send_port": 10000,                                  # Port that will be used for send
                    "send_ident": "f983c23e-9058-4c9c-56ec-7f9f9a34c9ma",# Identifier for sender server process group
                    "recv_spec": "127.0.0.1",                            # Receive address that will be used for receiving responses from handlers
                    "recv_port": 10001,                                  # Port that will be used for receive
                    "recv_ident": "t3ok87np-9058-4c9c-9treu-7f9f9a34c9ka"# Identifier for receiver server process group
                }
            ]
        }
    }
}
```

In depth documentation is available in project page:
http://vertexclique.github.io/ringbahn

## TODOs

* Regex in urls and globbing
* Make kernel polling if it is available.
* Remove nasty dialyzer errors.
* Declare type specs. [ONGOING]
* Write more tests. [ONGOING]
* Access log, Error log support.
* Pidfile watching, fsevents.
* Implement Protobuf backend.
* Autogen UUID4s.
* Static DIR serving.

## Benchmarks

Benchmarks are in `benchmark` directory. It will be organized when new backends kicked in by time.
Please head to the README of benchmarks for more info.

<sub><sup>Ringbahn über Ostkreuz</sup></sub>
