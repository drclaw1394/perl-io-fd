use Test::More;
use lib "lib";
use lib "blib/lib";
use lib "blib/arch";

use IO::FD;
use IO::FD::Constants;

use feature ":all";
#say @IO::FD::Constants::names;

use Fcntl;

use strict;
use warnings;

plan skip_all => "kqueue not supported on  $^O" if $^O !~ /darwin|bsd/i;

my $kq=IO::FD::kqueue();
ok defined( $kq), "Create a queue";

     #############################################################################
     # struct kevent {                                                           #
     #         uintptr_t       ident;          /* identifier for this event */   #
     #         int16_t         filter;         /* filter for event */            #
     #         uint16_t        flags;          /* general flags */               #
     #         uint32_t        fflags;         /* filter-specific flags */       #
     #         intptr_t        data;           /* filter-specific data */        #
     #         void            *udata;         /* opaque user data identifier */ #
     # };                                                                        #
     #############################################################################

     #use constant KPACK64=>"(QsSLqq)*";
     #say STDERR unpack "H*", 
     my $struct=pack(KEVENT_PACKER, fileno(STDOUT), EVFILT_WRITE,EV_ADD|EV_ENABLE,0,0,0); 

     #say STDERR length $struct;
my $results=IO::FD::SV(32*10);

my $ret=IO::FD::kevent($kq, $struct, $results, 1);
$struct="";
for(1..5){
	my $ret=IO::FD::kevent($kq, $struct, $results, 1);
	#say STDERR "kevent return : $ret  length of event list: ". length $results;
	#say STDERR join ", ", my @r=unpack KEVENT_PACKER, $results;
	#syswrite STDOUT,"x" x $r[4];
}


IO::FD::close $kq;
done_testing;
