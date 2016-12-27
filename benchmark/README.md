## Benchmarks against Mongrel2

### With simple echo handlers

### Das Mongrel2

10 concurrent threads with 100 requests which means 10K
Which also means C10K...

```
ab -l -c 10 -n 100 http://127.0.0.1:6767/test\?id\=1\&uid\=asdf > mongrel_echo.benchmark
```

Using the command above below is the benchmark results.
Yeah simply nothing, it just got stuck and benchmark results as is:

```
This is ApacheBench, Version 2.3 <$Revision: 1748469 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)...
```

### Die Ringbahn

10 concurrent threads with 100 requests which means 10K

```
ab -l -c 10 -n 100 http://127.0.0.1:6767/test\?id\=1\&uid\=asdf > ringbahn_echo.benchmark
```

Using the command above below is the benchmark results.

```
This is ApacheBench, Version 2.3 <$Revision: 1748469 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient).....done


Server Software:        Ringbahn
Server Hostname:        127.0.0.1
Server Port:            6767

Document Path:          /test?id=1&uid=asdf
Document Length:        403 bytes

Concurrency Level:      10
Time taken for tests:   0.070 seconds
Complete requests:      100
Failed requests:        12
   (Connect: 0, Receive: 0, Length: 12, Exceptions: 0)
Total transferred:      54990 bytes
HTML transferred:       40290 bytes
Requests per second:    1438.75 [#/sec] (mean)
Time per request:       6.950 [ms] (mean)
Time per request:       0.695 [ms] (mean, across all concurrent requests)
Transfer rate:          772.62 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   1.4      1       7
Processing:     2    6   2.5      5      14
Waiting:        2    5   2.5      4      14
Total:          3    7   2.8      6      15

Percentage of the requests served within a certain time (ms)
  50%      6
  66%      7
  75%      8
  80%      8
  90%     12
  95%     13
  98%     15
  99%     15
 100%     15 (longest request)
```

### Behind of highly burdened handler system

### Das Mongrel

10 concurrent threads with 100 requests which means 10K

```
This is ApacheBench, Version 2.3 <$Revision: 1748469 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient).....done


Server Software:
Server Hostname:        127.0.0.1
Server Port:            6767

Document Path:          /test?id=1&uid=asdf
Document Length:        10 bytes

Concurrency Level:      10
Time taken for tests:   0.577 seconds
Complete requests:      100
Failed requests:        0
Total transferred:      23600 bytes
HTML transferred:       1000 bytes
Requests per second:    173.41 [#/sec] (mean)
Time per request:       57.667 [ms] (mean)
Time per request:       5.767 [ms] (mean, across all concurrent requests)
Transfer rate:          39.97 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   0.5      1       2
Processing:    22   55  30.5     43     157
Waiting:       22   55  30.5     42     157
Total:         24   56  30.5     43     157

Percentage of the requests served within a certain time (ms)
  50%     43
  66%     46
  75%     52
  80%     75
  90%     87
  95%    141
  98%    153
  99%    157
 100%    157 (longest request)

```

### Die Ringbahn

10 concurrent threads with 100 requests which means 10K

Better throughput even without kernel polling is disabled.

```
This is ApacheBench, Version 2.3 <$Revision: 1748469 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient).....done


Server Software:        Ringbahn
Server Hostname:        127.0.0.1
Server Port:            6767

Document Path:          /test?id=1&uid=asdf
Document Length:        10 bytes

Concurrency Level:      10
Time taken for tests:   0.546 seconds
Complete requests:      100
Failed requests:        0
Total transferred:      29100 bytes
HTML transferred:       1000 bytes
Requests per second:    183.00 [#/sec] (mean)
Time per request:       54.645 [ms] (mean)
Time per request:       5.464 [ms] (mean, across all concurrent requests)
Transfer rate:          52.00 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   1.2      0       6
Processing:     8   52  39.2     45     165
Waiting:        8   51  39.1     45     165
Total:          9   53  39.1     47     166

Percentage of the requests served within a certain time (ms)
  50%     47
  66%     60
  75%     73
  80%     80
  90%    117
  95%    140
  98%    158
  99%    166
 100%    166 (longest request)

```
