# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl IO-FD.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use feature ":all";

use Test::More tests => 1;
BEGIN { use_ok('IO::FD') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
##############################################################################
# use IO::FD;                                                                #
# use Socket qw":all";                                                       #
#                                                                            #
# #use overload "<>"=> \&IO::FD::sysread;                                    #
#                                                                            #
# my $fd=6;                                                                  #
#                                                                            #
# my $res=IO::FD::socket($fd, AF_INET, SOCK_STREAM, 0);                      #
#                                                                            #
# print STDERR "FD is: ".$fd."\n";                                           #
# print STDERR "res is: $res\n";                                             #
#                                                                            #
# ok $fd==3, "Created socket";                                               #
#                                                                            #
#                                                                            #
#                                                                            #
# {                                                                          #
#         use File::Temp qw<tempfile>;                                       #
#         use POSIX;                                                         #
#         use FCNTL;                                                         #
#         `echo "test data">test.txt`;                                       #
#         my $dd=IO::FD::sysopen(my $fd, "test.txt", O_RDONLY,0);            #
#         say STDERR "DD IS: ",$dd;                                          #
#         say STDERR "fd IS: ",$fd;                                          #
#         say STDERR "DD is defined: ", defined $dd;                         #
#                                                                            #
#         ok defined($dd), "dd is defined";                                  #
#                                                                            #
#         my $buf="this is before: ";                                        #
#         IO::FD::sysread($fd,$buf,4,-1);                                    #
#         say STDERR "Buffer is: ",$buf;                                     #
#                                                                            #
#                                                                            #
#         my ($ret)=IO::FD::syswrite(fileno(STDERR), "OUTPUT BABY\n",10,10); #
#         say STDERR "RETURN is: $ret";                                      #
#                                                                            #
#         say STDERR "CLOSE RETURN: ",IO::FD::sysclose $fd;                  #
# }                                                                          #
#                                                                            #
# {                                                                          #
#         my $ret=IO::FD::pipe(my $rend, my $wend);                          #
#         if($ret){                                                          #
#                 IO::FD::syswrite($wend, "DATA VIA PIPE",4,0);              #
#                 my $buf="";                                                #
#                 IO::FD::sysread($rend, $buf, 4, 0);                        #
#                 say STDERR "read from pipe: $buf";                         #
#         }                                                                  #
# }                                                                          #
# my $count=5;                                                               #
# local $/=\$count;                                                          #
# #say STDERR join ", ",IO::FD::readline fileno STDIN                        #
#                                                                            #
#                                                                            #
##############################################################################
