# From: https://forum.mikrotik.com/viewtopic.php?t=118386
# With some refactoring + naming + adding of info

:global widthCapInterface 20;
:global widthDhcpComment 20;
:global widthDhcpHostName 20;
:global widthDhcpIP (3*4+3);
:global widthMacAddr (6*2+5);
:global widthRadioName 15;
:global widthRxRate 22;
:global widthRxSignal 4;
:global widthTxRate 22;

:global pads {
  "";
  " ";
  "  ";
  "   ";
  "    ";
  "     ";
  "      ";
  "       ";
  "        ";
  "         ";
  "          ";
  "           ";
  "            ";
  "             ";
  "              ";
  "               ";
  "                ";
  "                 ";
  "                  ";
  "                   ";
  "                    ";
  "                     ";
  "                      ";
}

# call like this: [$addPads "string" to=10 pads=$pads]
# will use the pads in $pads and pad up to $to chars
:global addPads do={
  # With a "correct" $to, this can support up to len $1 + max string in pads
  :if ([:len $1] <= $to) do={
    :return ("$1".$pads->($to - [:len $1]))
  }
  # Pad to max that we support in $pads
  :return ("$1".$pads->([:len $pads] - [:len $1]))
}

# Keep synchronized with item prints below
:global header ("" \
  . [$addPads "CAP" to=$widthCapInterface pads=$pads] . " " \
  . [$addPads "MAC" to=$widthMacAddr pads=$pads] . " " \
  . [$addPads "DHCP IP" to=$widthDhcpIP pads=$pads] . " " \
  . [$addPads "DHCP Hostname" to=$widthDhcpHostName pads=$pads] . " " \
  . [$addPads "RX" to=$widthRxSignal pads=$pads] . " " \
  . [$addPads "RX Rate" to=$widthRxRate pads=$pads] . " " \
  . [$addPads "TX Rate" to=$widthTxRate pads=$pads] . " " \
  . "Extra info")
:put $header

:foreach i in=[/caps-man registration-table find] do={
  # fixed size
  :local macAddr [/caps-man registration-table get $i mac-address]

  # small size range
  :local rxSignal [/caps-man registration-table get $i rx-signal]
  :set rxSignal [$addPads $rxSignal to=$widthRxSignal pads=$pads]
  :local rxRate [/caps-man registration-table get $i rx-rate]
  :set rxRate [$addPads $rxRate to=$widthRxRate pads=$pads]
  :local txRate [/caps-man registration-table get $i tx-rate]
  :set txRate [$addPads $txRate to=$widthTxRate pads=$pads]
  :local dhcpIP [/ip dhcp-server lease get [find where mac-address=$macAddr] address]
  :set dhcpIP [$addPads $dhcpIP to=$widthDhcpIP pads=$pads]

  # freeform
  :local dhcpHostName [/ip dhcp-server lease get [find where mac-address=$macAddr] host-name]
  :set dhcpHostName [$addPads $dhcpHostName to=$widthDhcpHostName pads=$pads]
  :local capInterface [/caps-man registration-table get $i interface]
  :set capInterface [$addPads $capInterface to=$widthCapInterface pads=$pads]

  # optional
  :local radioName [/caps-man registration-table get $i radio-name]
  :if ([:len $radioName] != 0) do={
    :set radioName (" radio=".[$addPads $radioName to=$widthRadioName pads=$pads])
  }
  :local dhcpComment [/ip dhcp-server lease get [find where mac-address=$macAddr] comment]
  :if ([:len $dhcpComment] != 0) do={
    :set dhcpComment (" dhcp_comment=".[$addPads $dhcpComment to=$widthdhcpComment pads=$pads])
  }

  # The last two are optional, so have to include the separator in the string
  :put ("$capInterface $macAddr $dhcpIP $dhcpHostName $rxSignal $rxRate $txRate$dhcpComment$radioName")
}
