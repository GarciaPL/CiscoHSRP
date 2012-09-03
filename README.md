Perl script for Nagios that can check HSRP state of Cisco host(s) in network using SNMP protocol (only version 3) and return an output about error level (OK, Warning or Critical) related to Nagios.

Main table in MIB where all information related with HSRP state are stored is cHsrpGrpTable, where are many cHsrpGrpEntry objects which correspond with HSRP groups configured on router and each of them contains configuration and status related with this Cisco protocol.

Example snmpwalk over HSRP information in MIB :

SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.2.1.1 = STRING: "pr0jekt" SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.3.1.1 = Gauge32: 105 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.4.1.1 = INTEGER: 1 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.5.1.1 = Gauge32: 0 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.6.1.1 = INTEGER: 2 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.7.1.1 = Gauge32: 0 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.8.1.1 = Gauge32: 0 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.9.1.1 = Gauge32: 3000 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.10.1.1 = Gauge32: 10000 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.11.1.1 = IpAddress: 10.102.33.1 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.12.1.1 = INTEGER: 1 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.13.1.1 = IpAddress: 10.102.33.253 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.14.1.1 = IpAddress: 10.102.33.254 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.15.1.1 = INTEGER: 6 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.16.1.1 = Hex-STRING: 00 00 0C 07 AC 01 SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.17.1.1 = INTEGER: 1

The properly way to examine HSRP state is iterate through SNMP interface ID and HSRP group ID (this in one before last and last one digit from above OID for example 1 and 1), but this script skip this step and only fetch information from cHsrpGrpStandbyState parameter ;) :

1: initial 2: learn 3: listen 4: speak 5: standby 6: active

Additional functionality of this script is that it can inform Nagios about things that are happening with HSRP protocol of host(s) defined in command line.

Parameters :

-h --help print this help message

-u --username=USERNAME username e.g. test_user

-a --authprotocol=PROTOCOL protocol for auth e.g. SHA

-A --authpassword=PASSWORD password for auth

-x --privprotocol=PROTOCOL protocol for auth e.g. DES

-X --privpassword=PASSWORD password for auth

-H --hostname=HOST(s) name or IP address of host(s)

-S --switch=SWITCH name or IP address of switch

Example usage :

./HSRP.pl -u -a -A -x -X -H [,,,...] -S

http://garciapl.blogspot.com/2012/07/monitor-cisco-hsrp-with-snmp_17.html