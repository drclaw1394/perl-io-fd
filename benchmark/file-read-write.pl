use v5.36;
use lib "lib";
use lib "blib/lib";
use lib "blib/arch";
use IO::FD;
use POSIX;
use Benchmark qw<cmpthese>;

my $max_po2=4;
use Fcntl;
{

	say "Read performance:";
	#read performance
	die "Open failed" unless sysopen my $fh, "/dev/zero", O_RDONLY;
	die "Open failed" unless my $pfd=POSIX::open "/dev/zero", O_RDONLY;
	die "Open failed" unless IO::FD::sysopen my $fd, "/dev/zero", O_RDONLY;

	for(0..$max_po2){
		say "Read 4096 x 2^$_";
		my $size=4096*2**$_;
		cmpthese -1, {
			file_handle=>sub {sysread $fh,my $buffer="", $size},
			file_desc_posix=>sub {POSIX::read $pfd, my $buffer="", $size},
			io_fd=>sub {IO::FD::sysread3 $fd, my $buffer="", $size}
		};
	}

	close $fh;
	POSIX::close $pfd;
	IO::FD::close $fd;

}

{
	say "";
	say "Write performance:";
	#write performance
	die "Open failed" unless sysopen my $fh, "/dev/null", O_WRONLY;
	die "Open failed" unless my $pfd=POSIX::open "/dev/null", O_WRONLY;
	die "Open failed" unless IO::FD::sysopen my $fd, "/dev/null", O_WRONLY;
	for (0..$max_po2){
		say "4096x 2^$_";
		my $data="x" x (4096*2**$_);
		cmpthese -1, {
			file_handle=>sub {syswrite $fh,$data},
			file_desc_posix=>sub {POSIX::write $pfd, $data, length $data},
			io_fd=>sub {IO::FD::syswrite2 $fd, $data}
		};
	}

	close $fh;
	POSIX::close $pfd;
	IO::FD::close $fd;

}
