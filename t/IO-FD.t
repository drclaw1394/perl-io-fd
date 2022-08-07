# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl IO-FD.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('IO::FD') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use IO::FD;
use Socket qw":all";

my $fd=6;

my $res=IO::FD::socket($fd, AF_INET, SOCK_STREAM, 0);

print STDERR "FD is: ".$fd."\n";
print STDERR "res is: $res\n";
ok $fd==3, "Created socket";


