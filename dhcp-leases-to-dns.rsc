# MikroTik (RouterOS) script for automatically setting DNS records
# for clients when they obtain a DHCP lease.
#
# author SmartFinn <https://gist.github.com/SmartFinn>
# based on https://github.com/karrots/ROS-DDNS
# modified 20200412 a-a to allow multiple IPs per host
# modified 20200417 a-a, add functionality to strip anything after hostname, add variables to control optional features.
# modified 20200901 filcab, add a way to have a domain prefix for DHCP-related hostnames

# Set to "true" if adding multiple IP addresses to the same hostname is acceptable, ie for clients with wireless and a wire.
:local allowRoundRobin "true";
# Set to "true" if only the hostname should be provided to DNS. Fixes issue where host reports a FQDN instead of hostname, for example reports to DHCP "test.example.org" and gets put in dns as "testexampleorg.example.org".
:local stripFQDN "true";

# Set to some prefix to be added to the domain. We end up with host.prefix.domain names
:local domainPrefix "$leaseServerName.dhcp";
:local domain;
:local fqdn;
:local hostname;
:local safeHostname;
:local token "$leaseServerName-$leaseActMAC";
:local ttl [/ip dhcp-server get $leaseServerName lease-time];
# Getting the domain name from DHCP server. If a domain name is not
# specified will use hostname only
/ip dhcp-server network {
  :do {
    :set domain [get [find where ($leaseActIP in address)] domain];
#   Add a dot before domain name
    :set domain ("." . $domain);
  } on-error={
    :set domain "";
  };
};

:if ([:len $domainPrefix] != 0) do={
  :set domain ("." . $domainPrefix . $domain);
};

:if ($leaseBound = 1) do={
  :log debug "$leaseServerName: Processing bound lease $leaseActMAC ($leaseActIP)";
  /ip dhcp-server lease {
    :set hostname [get [find active-mac-address=$leaseActMAC] host-name];
  };
# Delete unallowed chars from the hostname, and strip everything after the hostname, if set.
  :local firstLabel "true";
  :for i from=0 to=([:len $hostname]-1) do={
    :local char [:pick $hostname $i];
    :if ($firstLabel = "true") do={
      :if ($char = "." && $stripFQDN = "true") do={
        :set $firstLabel "false";
      };
      :if ($char~"[a-zA-Z0-9-]") do={
        :set safeHostname ($safeHostname . $char);
      };
    };
  };
  :if ([:len $safeHostname] > 0) do={
    :set fqdn ($safeHostname . $domain);
    /ip dns static {
      :local itemId [find name=$fqdn];
      :if ($itemId != "") do={
#       This DNS entry already exists
        :if ([get $itemId comment] = $token) do={
          :if ([get $itemId address] != $leaseActIP) do={
            set $itemId address=$leaseActIP ttl=$ttl;
            :log info "Update DNS entry: $fqdn -> $leaseActIP ($leaseActMAC)";
          };
        } else={
          :if ([get $itemId address] = $leaseActIP) do={
#         This hostname, IP, and MAC already exist
          :log warning "Cannot to add DNS entry. $fqdn already exists with this IP and MAC";
          } else {
#         This hostname exists already but for different MAC address
          add name=$fqdn address=$leaseActIP ttl=$ttl comment=$token
          :log info "Add additional DNS entry: $fqdn -> $leaseActIP ($leaseActMAC)";
          }
        };
      } else={
#       Add DNS entry if it does not exist
#       TODO: fix logic to allow hostname to change without leaving duplicates behind
        add name=$fqdn address=$leaseActIP ttl=$ttl comment=$token;
        :log info "Add DNS entry: $fqdn -> $leaseActIP ($leaseActMAC)";
      };
    };
  };
} else={
# Remove entry when lease expires ($leaseBound=0)
  :log debug "$leaseServerName: Processing deassigned lease $leaseActMAC ($leaseActIP)";
  /ip dns static {
    :local itemId [find comment=$token];
    :if ($itemId != "") do={
      :set fqdn ([get $itemId name]);
      remove $itemId;
      :log info "Remove DNS entry: $fqdn -> $leaseActIP ($leaseActMAC)";
    };
  };
};
