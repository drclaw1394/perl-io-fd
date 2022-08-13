package IO::FD::DWIM;
use strict;
use warnings;

use IO::FD;
use Exporter "import";

our %EXPORT_TAGS = ( 'all' => [ qw(
	accept
	listen
	socket
	socketpair
	bind
	connect
	getsockopt
	setsockopt

	sysopen
	close
	sysread
	syswrite

	pipe
	sysseek

	dup
	dup2

	fcntl
	ioctl

	readline
	fileno
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#wrapper around IO::FD function which allow for filehandles or filedescriptors
#Makes it very easy to change existing code to use file descriptors 


sub socket :prototype($$$$) 
	{ref($_[0]) ? &CORE::socket : &IO::FD::socket; }

sub listen:prototype($$) 
	{ref($_[0]) ? &CORE::listen : &IO::FD::listen; }

sub accept:prototype($$) 
	{ref($_[0]) ? &CORE::accept : &IO::FD::accept; }

sub connect:prototype($$) 
	{ref($_[0]) ? &CORE::connect : &IO::FD::connect; }

sub sysopen:prototype($$$@) 
	{ref($_[0]) ? &CORE::sysopen : &IO::FD::sysopen; }

sub close($) 
	{ref($_[0]) ? &CORE::close : &IO::FD::close; }

sub sysread:prototype($$$@) 
	{ref($_[0]) ? &CORE::sysread : &IO::FD::sysread; }

sub syswrite:prototype($$@) 
	{ref($_[0]) ? &CORE::syswrite : &IO::FD::syswrite; }

sub send:prototype($$$@) 
	{ref($_[0]) ? &CORE::send : &IO::FD::send; }

sub recv:prototype($$$$) 
	{ref($_[0]) ? &CORE::recv : &IO::FD::recv; }

sub pipe:prototype($$) 
	{ref($_[0]) ? &CORE::pipe : &IO::FD::pipe; }

sub bind:prototype($$) 
	{ref($_[0]) ? &CORE::bind : &IO::FD::bind; }

sub socketpair:prototype($$$$$) 
	{ref($_[0]) ? &CORE::socketpair : &IO::FD::socketpair; }

sub sysseek:prototype($$$) 
	{ref($_[0]) ? &CORE::sysseek : &IO::FD::sysseek; }

sub dup:prototype($) 
	{ref($_[0]) ? &CORE::dup : &IO::FD::dup; }

sub dup2:prototype($$) 
	{ref($_[0]) ? &CORE::dup2 : &IO::FD::dup2; }

sub fcntl:prototype($$$) 
	{ref($_[0]) ? &CORE::fcntl : &IO::FD::fcntl; }

sub ioctl:prototype($$$) 
	{ref($_[0]) ? &CORE::ioctl : &IO::FD::ioctl; }

sub getsockopt:prototype($$$) 
	{ref($_[0]) ? &CORE::getsockopt : &IO::FD::getsockopt; }

sub setsockopt:prototype($$$$) 
	{ref($_[0]) ? &CORE::setsockopt : &IO::FD::setsockopt; }

sub fileno :prototype($) {
	ref($_[0])
		?fileno $_[0]
		: $_[0];
}

#sub select
	#{ref($_[0]) ? &CORE::select : &IO::FD::setsockopt; }
