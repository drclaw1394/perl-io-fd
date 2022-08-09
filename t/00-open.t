use Test::More tests=>6;

use IO::FD;
use Fcntl;

#Test opening a file in different modes

{
	#Create a tempfile

	my $name=IO::FD::mktemp("/tmp/mytempXXXXXXXXX");
	ok defined($name), "Temp file name ok";
	ok IO::FD::sysopen(my $fd, $name, O_CREAT|O_RDONLY,0), "Opening $name: $!";

	ok IO::FD::close($fd), "Closing fd";

	ok !defined(IO::FD::close($fd)), "Double Closing fd";
}

{
	#Create a tempfile
	my $fd=IO::FD::mkstemp("/tmp/mytempXXXXXXXXX");
	ok defined($fd), "Temp fd ok";

	ok IO::FD::close($fd), "Closing fd";

}

{
	my $fd=IO::FD::mkstemp("tmp/mytemp/XXXXXXXXX");
	ok defined($fd), "Temp fd ok";
	
	my $buffer="Hello world";
	#write data to file
	IO::FD::syswrite($fd,$buffer);
}

