```
cyperf -h
```
```
Usage: sudo cyperf [-s|-c host] [options]
            cyperf [-h|--help] [-v|--version] [--about]

Quick help, for detailed information, check the man page by running "man cyperf"

Server specific:
  -s, --server                run in server mode
Client specific:
  -c, --client    <host>      run in client mode, connecting to <host>
  -b, --bitrate   #[KMG][/#]  target bitrate in bits/sec (0 for unlimited)
  -P, --parallel  #           number of parallel client sessions to run
Other options:
  -p, --port      #           server port to listen on/connect to
  -i, --interval  #           seconds between periodic statistics reports
  -t, --time      #           time in seconds to run the test for (default 600 secs)
  --cps           [#KMG][/#]  target connection rate in connections/seconds
                              the value is optional and takes effect in client side only
  --bidir                     run in bidirectional mode.
                              client and server send and receive data.
  -R, --reverse               run in reverse mode.
                              server sends and client receives.
  -l, --length    #[KMG]      length of buffer to read or write
  -F, --file      <filepath>  transmit / receive the specified file.
  -B, --bind      <host>      bind to the interface associated with the address <host>
  -w, --window    #[KMG]      set TCP starting window size / socket buffer size
  --detailed-stats            show more detailed stats in console
  --csv-stats     <filepath>  write all stats to specified csv file
  -v, --version               show version information and quit
  -h, --help                  show this quick help and quit
  --about                     show the Keysight contact and license information.

[KMG] indicates options that support a K/M/G suffix for kilo-, mega-, or giga-
 ```