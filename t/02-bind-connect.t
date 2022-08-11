use Test::More tests=>2;

use IO::FD;
use Fcntl;

use Socket ":all";

my $sock_file="test.sock";
unlink($sock_file);
my $addr=pack_sockaddr_un($sock_file);


#Server
ok defined(IO::FD::socket my $listener_fd,AF_UNIX, SOCK_STREAM, 0), "Socket creation";


ok defined(IO::FD::bind($listener_fd, $addr));

my $flags=IO::FD::fcntl $listener_fd, F_GETFL, 0;

say STDERR "Flags on listener: $flags";
say STDERR "REad write enabled" if O_RDWR & $flags;
say STDERR "REad only enabled" if O_RDONLY & $flags;

IO::FD::fcntl $listener_fd, F_SETFL, $flags|O_NONBLOCK;
$flags=IO::FD::fcntl $listener_fd, F_GETFL, 0;
say STDERR "Flags on listener: $flags";
say STDERR "NONBLOCKING" if $flags& O_NONBLOCK;

my $path="x" x 1024;
my $fd=IO::FD::mkstemp("/tmp/anotherXXXXXXXX");
die "FD NOT VALID" unless defined $fd;
my $result=IO::FD::fcntl $fd, F_GETPATH, $path;
say STDERR "path get result: $result: $!";
say STDERR "RESULTING PATH: $path";


my $buffer;#=h"asdfasdf";
my $ret=IO::FD::getsockopt($listener_fd, SOL_SOCKET, SO_TYPE, $buffer);
say STDERR "getsockopt status: $!" unless $ret;
say STDERR "Socket type ". unpack "I", $buffer;

my $ret=IO::FD::getsockopt($listener_fd, SOL_SOCKET, SO_SNDBUF, $buffer);
say STDERR "getsockopt status: $!" unless $ret;
say STDERR "send buffer size". unpack "I", $buffer;


my $ret=IO::FD::setsockopt($listener_fd, SOL_SOCKET, SO_SNDBUF, pack "I", 512);
say STDERR "setsockopt status: $!" unless $ret;


my $ret=IO::FD::getsockopt($listener_fd, SOL_SOCKET, SO_SNDBUF, $buffer);
say STDERR "getsockopt status: $!" unless $ret;
say STDERR "send buffer size". unpack "I", $buffer;
