# Panzer

Multi-process service monitor for Crystal, to squeeze all the juice from modern
multicore CPUs; also featuring zero-downtime restarts.

Multi-process is achieved using a "monitor process" that will load the
application, allowing to load configuration and create servers once, then
forking the monitor application into a specified number of processes. The
"monitor process" will monitor workers, and restart them whenever one fails, so
the number of running workers is constant.

Zero-downtime is achieved using a "main process" whose sole job is to start a
"monitor process", starting a new one in parallel when asked to (on `SIGUSR1`),
then killing the previous process once the new has started. It also takes care
to restart a new "monitor process" if the current one ever crashes.

Please note that zero-downtime is still a work-in-progress for incoming socket
connections. A restart of the example provided below seems to never miss a
connection, but still generates some read/write errors.

## Install

Add `panzer` to your shard's dependencies, then run `shards install`. This will
build and install a `bin/panzer` executable into your project.

```yaml
dependencies:
  panzer:
    github: ysbaddaden/panzer
```

## Usage

You need a worker process.

It's a simple class that implements a `run` method —that musn't return,
otherwise your worker will terminate. This `run` method will be executed in each
worker, forked from the monitor process, but the class initializer and any code
loaded by your worker will be executed once.

You'll may want to delay or have to reconnect some connections in each worker
for resources that can't be shared between processes (e.g. database
connections).

Example:

```crystal
require "http/server"
require "panzer/monitor"

class MyWorker
  include Panzer::Worker

  getter port : Int32
  private getter server : HTTP::Server

  # The worker is initialized once
  def initialize(@port)
    @server = HTTP::Server.new(port) do |ctx|
      ctx.response.content_type = "text/plain"
      ctx.response.print "Hello world, got #{context.request.path}!"
    end

    # force creation of underling TCPServer
    @server.bind
  end

  # The run method is executed for *each* worker
  def run
    logger.info "listening on #{server.local_address}"
    server.listen
  end
end

# Start the monitor that will manage worker processes:
Panzer::Monitor.run(MyWorker.new(8080), count: 8)
```

You may now build and run your application:

```shell
$ crystal build --release src/my_worker.cr -o bin/my_worker
$ bin/panzer bin/my_worker
```

You may restart your application by sending the `SIGUSR1` signal to the main
process, which `1234` is the PID of the main process:

```shell
$ kill -USR1 1234
```

You may tell your application to exit gracefully by sending the `SIGTERM`
signal, that will be propagated down to each worker:

```shell
$ kill -TERM 1234
```

## TODO

main process:

  - [ ] support a YAML file (`config/panzer.yml`) to read configuration from (?)
  - [ ] --quiet and --verbose CLI start options
  - [ ] --timeout CLI option
  - [ ] retry delay to restart monitor on successive crashes (--delay option)
  - [ ] restart main process itself on SIGUSR2

monitor process:

  - [ ] detect CPU number and use it as default workers count
  - [ ] retry delay to restart workers on successive crashes
  - [ ] print worker status on SIGTTIN

panzerctl helper (?):

  - [ ] requires main process to save `tmp/panzer.pid` file
  - [ ] `--pid=/tmp/panzer.pid` option
  - [ ] status (send SIGTTIN)
  - [ ] reload (send SIGUSR1)
  - [ ] restart (send SIGUSR2)
  - [ ] shutdown (send SIGTERM)
  - [ ] exit (send SIGINT)

tests:

  - [ ] integration tests that will build/run/kill/assert processes

## Authors

- Julien Portalier (creator, maintainer)
