# CiscoHSRP

This script written in Perl is dedicated for Nagios which can check **HSRP** state of Cisco host(s) in network using SNMP protocol (only version 3) and return an output about error level (OK, Warning or Critical) related to Nagios.

Main table in MIB where all information related with HSRP state are stored is cHsrpGrpTable, where are many cHsrpGrpEntry objects which correspond with HSRP groups configured on router and each of them contains configuration and status related with this Cisco protocol.

Example snmpwalk over HSRP information in MIB :

SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.2.1.1 = STRING: "pr0jekt"<br/>
SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.3.1.1 = Gauge32: 105<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.4.1.1 = INTEGER: 1<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.5.1.1 = Gauge32: 0<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.6.1.1 = INTEGER: 2<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.7.1.1 = Gauge32: 0<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.8.1.1 = Gauge32: 0<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.9.1.1 = Gauge32: 3000<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.10.1.1 = Gauge32: 10000<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.11.1.1 = IpAddress: 10.102.33.1<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.12.1.1 = INTEGER: 1<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.13.1.1 = IpAddress: 10.102.33.253<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.14.1.1 = IpAddress: 10.102.33.254<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.15.1.1 = INTEGER: 6<br/> SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.16.1.1 = Hex-STRING: 00 00 0C 07 AC 01<br/>
SNMPv2-SMI::enterprises.9.9.106.1.2.1.1.17.1.1 = INTEGER: 1<br/>

The properly way to examine HSRP state is iterate through SNMP interface ID and HSRP group ID (this in one before last and last one digit from above OID for example 1 and 1), but this script skip this step and only fetch information from cHsrpGrpStandbyState parameter :

1: initial<br/>
2: learn<br/>
3: listen<br/>
4: speak<br/> 
5: standby<br/>
6: active

Additionaly script can inform Nagios about things that are happening with HSRP protocol of host(s) defined in command line.

**Parameters**

-h --help print this help message<br/>
-u --username=USERNAME username e.g. test_user<br/>
-a --authprotocol=PROTOCOL protocol for auth e.g. SHA<br/>
-A --authpassword=PASSWORD password for auth<br/>
-x --privprotocol=PROTOCOL protocol for auth e.g. DES<br/>
-X --privpassword=PASSWORD password for auth<br/>
-H --hostname=HOST(s) name or IP address of host(s)<br/>
-S --switch=SWITCH name or IP address of switch<br/>

**Example usage**<br/><br/>
perl HSRP.pl -u -a -A -x -X -H [,,,...] -S

**Info**<br/><br/>
http://garciapl.blogspot.com/2012/07/monitor-cisco-hsrp-with-snmp_17.html
