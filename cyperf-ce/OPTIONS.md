
 <table border="1" style="border-collapse: collapse;">
  <thead>
    <tr>
      <th style="padding: 8px;">Option</th>
      <th style="padding: 8px;">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td colspan="2" style="padding: 8px;"><strong>Server specific</strong></td>
    </tr>
    <tr>
      <td style="padding: 8px;">-s, --server</td>
      <td style="padding: 8px;">Run in server mode</td>
    </tr>
    <tr>
      <td colspan="2" style="padding: 8px;"><strong>Client specific</strong></td>
    </tr>
    <tr>
      <td style="padding: 8px;">-c, --client <host></td>
      <td style="padding: 8px;">Run in client mode, connecting to <host>.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-b, --bitrate #[KMG][/#]</td>
      <td style="padding: 8px;">Target bitrate in bits/second.<br>Default: 10G/s<br>Max: 10G/s<br>This option cannot be used with --cps option.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-P, --parallel #</td>
      <td style="padding: 8px;">Number of parallel client sessions to run.<br>Tuning this option can help in improving bitrate and connection rate.<br>Default: Number of available CPU cores.<br>Max: 64000</td>
    </tr>
    <tr>
      <td colspan="2" style="padding: 8px;"><strong>Other options</strong></td>
    </tr>
    <tr>
      <td style="padding: 8px;">--cps [#KMG][/#]</td>
      <td style="padding: 8px;">Target connection rate.<br>Optionally a connection rate limit value can be provided but it is only useful in client.<br>Default: 100K connections per second.<br>Max: 100K connections per second.<br>If this option is used, it must be used in both server and client commands.<br>This option cannot be used together with -b / --bitrate option.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-p, --port #</td>
      <td style="padding: 8px;">Server will listen on the specified port.<br>Client will connect to the specified port.<br>Default: 5201</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-B, --bind <host></td>
      <td style="padding: 8px;">Bind to the interface associated with the IP address <host>.<br>If any interface cannot be found with the specified IP address in the host, or if an interface can be found with the specified IP address but its state is not UP, cyperf will print an error message and will not continue.<br>In client, if this option is not provided, cyperf will select the required IP address and interface from linux route table.<br>In server, it is recommended to use this option if there are more than one usable interface in the host but if not provided, cyperf will try to bind to all usable IP addresses and associated interfaces (maximum 4 interfaces).</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-l, --length #[KMG]</td>
      <td style="padding: 8px;">Length of buffer to transmit / receive.<br>cyperf will attempt to use this much data as a single block to read and write repeatedly. Increasing it may help increasing bitrate and decreasing it may help increasing connection rate.<br>Default: For bandwidth test, 100 MB and for connection rate test, 1 B.<br>If this option is used, it must be used in both server and client commands.<br>This option cannot be used together with -F / --file option.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-F, --file &lt;filepath&gt;</td>
      <td style="padding: 8px;">Transmit / receive the specified file.<br>cyper will attempt to use this file as a single block to read and write repeatedly. The file needs to exist in the specified path, cannot be empty and cannot be more than 128 megabytes in size.<br>If this option is used, it must be used in both server and client commands.<br>This option cannot be used together with -l / --length option.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">--bidir</td>
      <td style="padding: 8px;">Run in bidirectional mode.<br>In this mode both client and server send and receive data simultaneously.<br>If this option is used, it must be used in both server and client commands.<br>This option cannot be used together with -R / --reverse option.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-R, --reverse</td>
      <td style="padding: 8px;">Run in reverse mode.<br>In this mode, server sends and client receives the data.<br>If this option is used, it must be used in both server and client commands.<br>This option cannot be used together with --bidir option.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-i, --interval #</td>
      <td style="padding: 8px;">Seconds between periodic statistics reports.<br>Default: 3 seconds</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-t, --time #</td>
      <td style="padding: 8px;">Time in seconds to run the test for.<br>Default: 600 seconds</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-w, --window #[KMG]</td>
      <td style="padding: 8px;">Set window size / socket buffer size.<br>This option can be used to influence the starting window size during TCP handshake. A larger window size can help with achieving higher bitrate.<br>Default: For bandwidth test, 1 MB and for connection rate test, 4096 bytes.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">--detailed-stats</td>
      <td style="padding: 8px;">Show more detailed stats in console.<br>This option can be used to show more detailed stats like ARP stats, ethernet and IP level packet stats and TCP stats.<br>These stats can be helpful in debugging different network issues.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">--csv-stats &lt;filepath&gt;</td>
      <td style="padding: 8px;">Write all stats to specified csv file.<br>The parent directory of the specified file must exist and the specified file must not exist. Otherwise cyperf will print an error message and will not continue.<br>If this option is used, the stats dumped in csv file is always detailed stats, but depending on whether --detailed-stats option is provided, either basic stats or detailed stats are printed in console.</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-v, --version</td>
      <td style="padding: 8px;">Show version information and quit</td>
    </tr>
    <tr>
      <td style="padding: 8px;">-h, --help</td>
      <td style="padding: 8px;">Show quick help and quit</td>
    </tr>
    <tr>
      <td style="padding: 8px;">--about</td>
      <td style="padding: 8px;">Show the Keysight contact and license information.</td>
    </tr>
  </tbody>
</table>
