# NAME

IO::FD - I/O with less setup overhead

STILL A WORK IN PROGRESS

# SYNOPSIS

Create and bind a socket (server):

```perl
    use IO::FD
    use Socket ":all";

    die "Error creating socket"
            unless IO::FD::socket(my $listen_fd, AF_INET,SOCK_STREAM,0);

    my ($err,@sockaddr)=addrinfo "0.0.0.0", 80, {
            family=>AF_INET,
            socktype=>SOCK_STREAM,
            flags=>AI_NUMERICHOST|AI_PASSIVE
    };

    die "Error binding"
            unless FD::IO::bind($listen_fd,$sockaddr[0]{addr});     

    
    die "Error accepting" 
            unless IO::FD::accept(my $client_fd, $listen_fd);
    
    #read and write here
    
```

Create and connect a socket(client):

```perl
    use IO::FD;
    use Socket ":all";

    die "Error creating socket"
            unless IO::FD::socket(my $fd, AF_INET,SOCK_STREAM,0);

    my ($err,@sockaddr)=addrinfo "127.0.0.1", 80, {
            family=>AF_INET,
            socktype=>SOCK_STREAM,
            flags=>AI_NUMERICHOST
    };

    die "Error connecting";
            unless FD::IO::connect($fd, $sockaddr[0]{addr});

    #read and write here
```

Open a file

```perl
    use IO::FD;
    use Fcntl;
    die "could not open file" 
            unless IO::FD::sysopen(my $fd, "path.txt", O_RDONLY);
    
```

Read/Write/Close an fd

```perl
    use IO::FD;

    my $fd; #From FD::IO::Socket, FD::IO::sysopen, POSIX::open

    die "Error writing"
            unless IO::FD::syswrite $fd, "This is some data"; #Length and optional offset

    die "Error reading"
            unless IO::FD::sysread $fd, my $buffer, $length); 

    die "Error closing" 
            unless IO::FD::close $fd;
```

Advanced:

```
    fctrl...
    ioctl...
```

# DESCRIPTION

IO::FD implements core I/O operations on **file descriptors** instead of perl
**file handles**. Where it makes sense the interface to each routine matches
that of perl's filehandle routines, but uses the systems **file descriptor**
instead of Perl's **file handle**.

For example:

```perl
    #Perl:
    sysopen(my $file_handle, ...);
    sysread($file_handle, ...);

    #IO::FD
    IO::FD::sysopen(my $file_descriptor, ...);
    IO::FD::sysread($file_descriptor, ...);
```

It is relatively straight forward to substitute in `IO::FD` in places where
`socket`, `select`, `accept`, `bind`, `sysopen`, `sysread`,`syswrite`
and `close` are used.

The main reason you should consider using this module is the increased rate of
opening a file or creating a socket,

# SUPPORTED SYSTEMS

Currently focused on unix type systems, as this is the natural habitat of a file descriptor.

TODO:
	Attempt to work with winsock
	Additional advanced fd functions (send fds , sendfile...)

# GOAL

The main goal of this module is to **reduce the overhead in opening a file,
creating or accepting a socket** for server applications.

The secondary goal is to provide support functions to make using file
descriptors feasible without 'upgrading' to a perl filehandle. This means
implementing common routines such as bind, accept, sysread et. al.

Raw I/O throughput is not primary focus as buffered I/O via Perl's file handles
will most likely give higher throughput in most file access.

# MOTIVATION

Perl makes working with files pretty easy, thanks to the use of **file
handles**. Line splitting, UTF-8, EOL processing etc. are awesome and make your life easier.

However there are use cases where the awesomeness of a file handle isn't
appreciated and in fact can reduce overall performance. Once such case, is a
web server.

- No need to understand the file, just send it

    Web servers don't generally don't care about file contents. It just needs to
    send it quickly when requested. Opening a file via filehandle is quite slow
    compared to opening it via file descriptor due to the setup of the buffering
    and nice, but unneeded processing.

- Unkown and uneeded i/o buffering 

    Filehandles use  their own buffering to allow line splitting, etc. When lots of
    files are open, potentially this means more memory compared to a file
    descriptor.

    Also, sockets already have kernel level buffering and generally should be
    processed in an event loop as the data is available. Filehandle buffering isn't
    really useful in this case.

- Network data is not text

    While protocols such as HTTP look like text, they allow transmission of binary
    data. This makes automatic line conversions and text processing via a
    filehandle is impractical. As such setting up a file handle to achieve it is
    superfluous.

- Open and accept performance

    The above points culminate into the fact that `open/sysopen` and `accept`
    take a large proportion of setup time when servicing small files. This can be
    avoided by not using filehandles and simply using the underlying file
    descriptor directly.

# LIMITATIONS

Perl does a lot of nice things, which when using file descriptors directly you
will **loose**:

```
    Buffering for file read/write performance
    Automatic close when out of scope
    Close on exec
    
```

If you don't what these mean, it might be best to learn about how it will
impact your program before using this module.

The other main limitation is this module assumes you have file descriptors to
work with on your system.

# APIs

Each of the APIS mimic the perl counterpart as much as possible. Unless explicitly mentioned, they should operate like built in routines.
Any differences are listed.

## Perlish API

### getsockopt

### setsockopt

Note: Implements the integer shorthand as per perldoc -f setsockopt

### sysread

### syswrite

### pipe

### syspipe

A alias of pipe.

### close

### sysclose

An alias of close

### sysopen

### sysseek

Only the 4 argument version of select is supported.

### accept

### sysaccept

Alias to accept

### bind

### sysbind

Alias to bind

### send/sendto

TODO

### recv/recvfrom

TODO

### fctrl

### sysfctrl

Alias to fctrl

TODO

### ioctl

### sysioctl

Alias to ioctl

TODO

### readline

```perl
    #SLURP A FILE
    local $/=undef;
    my $slurp=IO::FD::readline;

            #or
    #SLURP ALL RECORDS
    local $/=\1234;
    my @records=IO::FD::readline;
```

A read line function is available, but is only operates in file slurp or
record slurp mode. As no buffering is used, It does not attempt to split
lines or read a line at a time like the normal perl readline or  <>
operator

## Extended API

### slurp

```perl
    my $data=IO::FD::slurp $path;
```

Open file at $path, read the contents into scalar and close the file.

### spew 

```
    IO::FD::spew $path, $data;
```

Open a file at $path, write $data, close file

# PERFORMANCE

## Open and close a file

## Create a and close a socket

## Accept and close socket

## Echo server connection rate

# SEE ALSO

The [POSIX](https://metacpan.org/pod/POSIX) module provides an `open`, `close`, `read` and `write`
routines which return/work with file descriptors. If you are only concerned
with working with files, this is a better option as it is a core module, and
will give you the purported benefits of this module.  However it does not
provide any networking/socket support.

Perl's built in `syscall` routine could implement most of this module. However
macos no longer has a syscall interface. That makes `syscall` a non starter
for me.

# AUTHOR

# REPOSITORTY

# LICENSE
