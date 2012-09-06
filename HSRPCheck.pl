#!/usr/bin/perl -w
######################################
# Info : Check Cisco 2800 Series HSRP Status
# Version : 1.0
# Date : 11 lipca 2012
# Author  : Lukasz Ciesluk
# Help : lukaszciesluk@gmail.com
######################################
#
# Run :
# chmod +x HSRPCheck.pl
# ./HSRPCheck.pl -h (for help)
#

use strict;
use warnings;
use SNMP;
use Net::SNMP qw(snmp_dispatcher oid_lex_sort);
use Getopt::Long;
use Net::Ping;
use lib "/opt/nagios/libexec";

use vars qw(%ERRORS $default_timeout);
my $default_timeout = 15;
my $default_ping_timeout = 5;
my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

######### Cisco OIDs
my $cisco_hsrp_oid = "1.3.6.1.4.1.9.9.106.1.2.1.1.15";   # hsrp operational status
my %hsrp_array = ("cisco",$cisco_hsrp_oid);

######### Globals
my $help = undef;
my $username = undef;					  	  # SNMP Username e.g. test_user
my $auth_protocol = undef;					  # Auth protocol e.g. SHA
my $auth_password = undef;					  # Password for auth protocol
my $priv_protocol = undef;					  # Priv protocol e.g. DES
my $priv_password = undef;					  # Priv password for priv protocol
my $host = undef;  							  # hostnames
my $switch = undef;							  # switch behind them
my $result = undef;
my $HSRP_status = undef;
my @hosts;
my $session;
my $error;
my $error_level = 0;
my $output_message;

sub usage {
    print "./HSRPCheck.pl -u <user> -a <authProtocol> -A <authPassword> -x <privProtocl> -X <privPass> -H <host> -S <switch>\n";
}

######### Check host using icmp => return 1 - alive, return 0 - down
sub ping($) {
	my $switchping = "@_";
	my $p = Net::Ping->new("icmp");
	$p->port_number("80");
	if( $p->ping($switchping, $default_ping_timeout)) 
	{
		#print "Switch ".$switchping." is alive\n";
		$p->close();
		return 1;
	} else {
		#print "Warning: Switch ".$switchping." appears to be down\n";
		$p->close();
		return 0;
	}	
}

sub help {
   print "\nCisco 2800 Series HSRP Status\n";
   usage();
   print <<EOT;
-h --help
   print this help message
-u --username=USERNAME
   username e.g. test_user
-a --authprotocol=PROTOCOL
   protocol for auth e.g. SHA
-A --authpassword=PASSWORD
   password for auth
-x --privprotocol=PROTOCOL
   protocol for auth e.g. DES
-X --privpassword=PASSWORD
   password for auth
-H --hostname=HOST(s)
   name or IP address of host(s)
-S --switch=SWITCH
   name or IP address of switch
EOT
}

$SIG{'ALRM'} = sub {
     print ("Nagios time-out\n");
     exit $ERRORS{"UNKNOWN"};
};

sub check_input {
    Getopt::Long::Configure ("bundling");
    GetOptions(
        'h'     => \$help,            	'help'          	=> \$help,
		'u:s'	=> \$username,			'username:s'		=> \$username,
		'a:s'	=> \$auth_protocol,		'authprotocol:s'	=> \$auth_protocol,
		'A:s'	=> \$auth_password,		'authpassword:s'	=> \$auth_password,
		'x:s'	=> \$priv_protocol,		'privprotocol:s'	=> \$priv_protocol,
		'X:s'	=> \$priv_password,		'privpassword:s'	=> \$priv_password,
		'H:s'	=> \$host,				'hostname:s'		=> \$host,
		'S:s'	=> \$switch,			'switch:s'			=> \$switch
	);
		
if ($help) { help(); exit $ERRORS{'OK'}; }
if (!defined($host)) { print "Unknown known host(s)\n"; usage(); exit $ERRORS{"UNKNOWN"}} else 
{
	@hosts=split(/,/,$host);
	if ( scalar(@hosts) == 0) {print "Empty hosts lists"; usage(); exit $ERRORS{"UNKNOWN"}}
}
if (!defined($switch)) { print "Unknown switch!\n"; usage(); exit $ERRORS{"UNKNOWN"}}
if ((!defined($username) || !defined($auth_password)) )
    { print "Put SNMP login info! (-h for help)\n"; usage(); exit $ERRORS{"UNKNOWN"}}
if (!defined($auth_protocol) || !defined($auth_password))
    { print "Put auth login info! (-h for help)\n"; usage(); exit $ERRORS{"UNKNOWN"}}
if (!defined($priv_protocol) || !defined($priv_password))
	{ print "Put priv login info! (-h for help)\n"; usage(); exit $ERRORS{"UNKNOWN"}}
}

######### MAIN PROGRAM

check_input();

if (defined($default_timeout)) {
  alarm($default_timeout);
}

######### Connect to specified host(s) and collect HSRP information
foreach (@hosts) {
	#print "Host : $_\n";
	my $onehost = $_;
	if ( defined($username) && defined($auth_password)) {
		($session, $error) = Net::SNMP->session(
		  -hostname         => $_,
		  -version          => 'snmpv3',
		  -username         => $username,
		  -authpassword     => $auth_password,
		  -authprotocol     => $auth_protocol,
		  -privpassword  	=> $priv_password,
		  -privprotocol 	=> $priv_protocol
		);
		
		######### Check session
		if (!defined $session) {
			printf ("Probably wrong SNMP login information %s.\n", $error);
			exit $ERRORS{"UNKNOWN"};
		} else {
			######### Get value from router using SNMP if session is present
			my $result = $session->get_table(
				Baseoid	=>	$hsrp_array{'cisco'}
			);
		
			if (!defined($result)) { ######### No result found in MIB using SNMP
				printf("Cannot fetch result from MIB (machine %s is down?): %s.\n", $_, $session->error);
				$session->close;
				exit $ERRORS{"UNKNOWN"};
			} else {
				foreach (oid_lex_sort(keys(%{$result}))) {
					$HSRP_status = $result->{$_};
					if ($HSRP_status == 1) { ######### initial - CRITICAL
						$output_message = $output_message."$onehost is in initial mode, ";
						$error_level = 2;
					}
					if ($HSRP_status == 2) { ######### learn = CRITICAL
						$output_message = $output_message."$onehost is in learn mode, ";
						$error_level = 2;
					}
					if ($HSRP_status == 3) { ######### listen = WARNING
						$output_message = $output_message."$onehost is in listen mode, ";
						$error_level = 3;
					}
					if ($HSRP_status == 4) { ######### speak = OK
						$output_message = $output_message."$onehost is in speak mode, ";
						$error_level = 6;
					}
					if ($HSRP_status == 5) { ######### standby = OK
						$output_message = $output_message."$onehost is in standby mode, ";
						$error_level = 6;
					}
					if ($HSRP_status == 6) { ######### active = OK
						$output_message = $output_message."$onehost is in initial mode, ";
						$error_level = 6;
					}
				}
				#1: initial
				#2: learn
				#3: listen
				#4: speak
				#5: standby
				#6: active
			}
		}
	}
}

######### Checking if switch is alive or not

my $ping_status = ping($switch);			
if ($ping_status == 1) {
	$output_message = $output_message."Switch $switch is OK => ";
} elsif ($ping_status == 0) {
	$output_message = $output_message."Switch $switch is DOWN => ";
	$error_level = 2;
}

######### Handling warnings and errors

if ($error_level == 6) { #OK
	$output_message = $output_message."Error level : OK\n";
	printf ($output_message);
	exit $ERRORS{"OK"};
} elsif (($error_level >= 3) and ($error_level <= 5)) { #WARNING
	$output_message = $output_message."Error level : WARNING\n";
	printf ($output_message);
	exit $ERRORS{"WARNING"};
} elsif (($error_level >= 1) and ($error_level) <= 2) { #CRITICAL
	$output_message = $output_message."Error level : CRITICAL\n";
	printf ($output_message);
	exit $ERRORS{"CRITICAL"};
}
