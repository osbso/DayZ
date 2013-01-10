#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Getopt::Long;

use Data::Dumper;

my ($help, $dbname, $dbhost, $dbport, $dbuser, $dbpass);

GetOptions(
            'help'    => \$help,
            'n=s'     => \$dbname,    
            'name=s'  => \$dbname,    
            'ip=s'    => \$dbhost,
            'po=i'    => \$dbport,
            'port=i'  => \$dbport,
            'user=s'  => \$dbuser,
            'pw=s'    => \$dbpass,
            'pass=s'  => \$dbpass,
          );

if( $help || @ARGV < 5 && ! ($dbname || $dbhost || $dbport || $dbuser|| $dbpass ) ) {
    print "usage: $0 <db name> <db hostname or ip> <db port> <db username> <db password>\n";
    print "  -n,  --name\n"; 
    print "         Database name\n";
    print "  -ip, --ip\n";
    print "         Database Host or IP\n";
    print "  -po, --port\n";
    print "         Database Port\n";
    print "  -u,  --user\n";
    print "         Database Username\n";
    print "  -pw, --pass\n";
    print "         Database Password\n";
    exit;
}

my %player_data;

print "Attempting to connect to $dbhost:$dbport..\n";

my $dsn = "DBI:mysql:database=$dbname;host=$dbhost;port=$dbport";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass);

my $p_table = $dbh->prepare("SELECT name, unique_id, humanity, survival_attempts, total_survivor_kills, total_zombie_kills, total_headshots FROM profile ORDER BY  `profile`.`total_zombie_kills`");
$p_table->execute();

while( my $row = $p_table->fetchrow_hashref() ) {
    my $name;
    for my $pdata(sort keys %$row) { 
        if($pdata =~ /^name/ ) {
            $name = $row->{$pdata};
        } elsif( $pdata =~ /zombie_kills/ ) {
            $player_data{$name}{"ZOMBIE KILLS"} = $row->{$pdata};
        } elsif( $pdata =~ /total_headshots/ ) {
            $player_data{$name}{"HEADSHOTS"} = $row->{$pdata};
        } elsif( $pdata =~ /unique_id/ ) {
            $player_data{$name}{"UID"} = $row->{$pdata};
        }
    }
}

for my $player ( sort keys %player_data ) {
    print "STATS For $player: \n";
    my $pref = $player_data{$player};
    for my $stats ( sort keys %$pref ) {
        if($stats =~ /UID/ ) { 
            my $itable = exec_query("SELECT inventory FROM `survivor` WHERE unique_id='$pref->{$stats}' AND is_dead=0");
            while( my $inventory = $itable->fetchrow_arrayref() ) {
                print " INVENTORY: ";
                for( @$inventory ) {
                    $_ =~ s/\[|\]|\"|\s+|Item//g;
                    my $item = join(" ", split(/,/, $_) );
                    print "$item\n";
                }
            }
            my $btable = exec_query("SELECT backpack FROM `survivor` WHERE unique_id='$pref->{$stats}' AND is_dead=0");
            while( my $bpack = $btable->fetchrow_arrayref() ) {
                print " BACKPACK: ";
                for( @$bpack ) {
                    $_ =~ s/\[|\]|\"|\s+|Item//g;
                    my $item = join(" ", split(/,/, $_) );
                    print "$item\n";
                }

            }
            next;
        }
        print " $stats=$pref->{$stats}\n";
    }
    print "\n"
}

sub exec_query {
    my ($details) = $_[0];
    my $query = $dbh->prepare($details);
    $query->execute();
    return $query;
}
