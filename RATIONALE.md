# PANZER

## Worker: Monitor starts a worker process:

  1. run a Worker instance in its own `fork`

## Monitoring: Panzer starts a monitor process:

  1. load application, execute global configuration (e.g. `TCPServer.new`)
  2. when monitor has loaded: send SIGVTALRM to monitor process
  3. forks N worker processes
  4. on SIGCHLD:
    1. collect zombie worker processes
    2. fork worker processes to replenish pool
  5. on SIGTERM:
    1. send SIGTERM to worker processes (exit gracefully)
    2. don't replenish pool anymore
    3. send SIGINT to worker processes (exit now) after timeout
    4. exit
  6. on SIGINT (first time):
    1. behave as SIGTERM

TODO:

  7. on SIGINT (second time):
    1. send SIGINT to worker processes (exit now)
    2. exit
  8. on SIGTTIN:
    1. print monitor status
    1. print workers' status

## Zero downtime: Panzer starts a main process:

  1. forks/execs monitor process
  2. on SIGUSR1:
    1. forks/execs a new monitor process (which then forks new worker processes)
  3. on SIGVTALRM:
    1. tells old monitor process to gracefully terminate (SIGTERM)
    2. tells old monitor process to exit after timeout (SIGINT)
  4. on SIGTERM:
    1. send SIGTERM to monitor process (exit gracefully)
    2. exit
  5. on SIGINT (first time):
    1. behave as SIGTERM
  6. on SIGINT (second time):
    1. send SIGINT to monitor process (exit now)
    2. exit

TODO:

  7. on SIGTTIN:
    1. print main process status
    2. send SIGTTIN to monitor process

## TREE

Running state:

  - panzer:main
    - panzer:monitor
      - panzer:worker (1)
      - panzer:worker (2)
      - panzer:worker (3)
      - panzer:worker (4)

Restarting state:

  - panzer:main
    - panzer:monitor (exiting)
      - panzer:worker (2, exiting)
      - panzer:worker (4, exiting)
    - panzer:monitor (new)
      - panzer:worker (1)
      - panzer:worker (2)
      - panzer:worker (3)
      - panzer:worker (4)
