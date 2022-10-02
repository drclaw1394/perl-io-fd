use Test::More tests=>1;
use lib "lib";
use lib "blib/lib";
use lib "blib/arch";

use IO::FD;
use IO::FD::Constants;

use feature ":all";
#say @IO::FD::Constants::EXPORT;

use Fcntl;
use strict;
use warnings;
################################
# use constant {               #
#         POLLIN=>0x0001,      #
#         POLLPRI=>0x0002,     #
#         POLLOUT=>0x0004,     #
#         POLLRDNORM=>0x0040,  #
#         POLLWRNORM=>POLLOUT, #
#         POLLRDBAND=>0x0080,  #
#         POLLWRBAND=>0x0100,  #
#         POLLERR=>0x0008,     #
#         POLLHUP=>0x0010,     #
#         POLLNVAL=>0x0020     #
# };                           #
################################

ok defined IO::FD::pipe(my $read, my $write);

for($read,$write){
	my $flags=IO::FD::fcntl( $_, F_GETFL,0);
	IO::FD::fcntl($_, F_SETFL, $flags|O_NONBLOCK);
}

#Poll
#pack "iss"; #int=> fd short=>flags to watch,  short=>result flags;
my %position;
for(0..10){
	my $list="";
	$list.=pack "(iss)*", $read, POLLIN, 0, $write, POLLOUT, 0;
	#$list.=pack "iss",$write,POLLOUT,0;

	#say STDERR join ", ",unpack "(iss)*", $list;
	my $res=IO::FD::poll($list,1);

	#say STDERR "Poll result: $res";
	#say STDERR join ", ",unpack "(iss)*", $list;
}
