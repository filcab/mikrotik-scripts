# mikrotik-scripts
Miscellaneous scripts for Mikrotik routers

## capsman-reg-table.rsc
#### Show registration table for CAPsMAN with added information
Based on a Mikrotik forum post: https://forum.mikrotik.com/viewtopic.php?t=118386

Dumps the same information as CAPsMAN's Registration Table tab, but with additional information to help identify clients:
- Device (DHCP hostname)
- AP
- Rates
- RSSI

Added alignment to the table information

## dhcp-leases-to-dns.rsc
#### Add a DNS entry when granting a DHCP lease

Based on a-a's gist: https://gist.github.com/a-a/31ec7f004cb4bb02dace4823f1b57737

Added an optional domain prefix (default to "dhcp"). It's not the most useful as we already had the DHCP server config name.
