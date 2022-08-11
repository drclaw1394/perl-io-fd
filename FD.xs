#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"
#include <fcntl.h>
#include <sys/socket.h>
#include <stdio.h>
#include <unistd.h>
#include <poll.h>


//Read from an fd until eof or error condition
//Returns SV containing all the data
// AKA "slurp";
SV * slurp(int fd, int read_size){
	SV* buffer;
	char *buf;
	int ret;
	int len=0;
	buffer=newSV(read_size);
	
	do {
		SvGROW(buffer, len+read_size);	//Grow the buffer if required
		buf=SvPVX(buffer);		//Get pointer to memory.. 
		ret=read(fd, buf+len, read_size);	//Do the read,offset to current traked len

		if(ret>0){
			len+=ret;		//track total length
			buf=SvPVX(buffer);
			buf[len]='\0';		//Add null for shits and giggles
		}
		else{
			break;
		}

	}
	while(ret>0);

	SvPOK_on(buffer);	//Make it a string
	SvCUR_set(buffer,len);	//Set the length
	sv_2mortal(buffer);	//Decrement ref count
	return buffer;
}




MODULE = IO::FD		PACKAGE = IO::FD		

INCLUDE: const-xs.inc

#SOCKET
#######

SV* 
socket(sock,af,type,proto)
		SV* sock;
		int af
		int type
		int proto

		PREINIT:
			int fd;
			int s;
		CODE:
			s=socket(af, type, proto);

			//Set error variable...
			if(s<0){
				
				RETVAL=&PL_sv_undef;
				#need to set error code here
			}
			else{
				RETVAL=newSViv(s);
				if(SvOK(sock)){
					sv_setiv(sock,s);
				}
				else {
					sock=newSViv(s);
				}
			}

		OUTPUT:
			RETVAL
			sock

#ACCEPT
#######

int
accept(new_fd, listen_fd)
		int new_fd
                int listen_fd

                PREINIT:
                        struct sockaddr packed_addr;
                        socklen_t       len;
                        int ret;
			SV *addr;	

                CODE:
                RETVAL=accept(listen_fd, &packed_addr, &len);

                //Set error variable...
	
                OUTPUT:
			RETVAL
			new_fd
#CONNECT
########

SV*
connect(fd,address)
	int fd
	SV *address

	PREINIT:
		int ret;
		int len=SvOK(address)?SvLEN(address):0;
		struct sockaddr *addr=(struct sockaddr *)sv_pv(address);

	CODE:
		ret=connect(fd,addr,len);
		if(ret<0){
			RETVAL=&PL_sv_undef;	
		}
		else{
			RETVAL=newSViv(ret+1);
		}
	OUTPUT:
		RETVAL
		
#SYSOPEN
########

SV*
sysopen(fd, path, mode, ... )
 		SV* fd
                char *path
                int mode

		PREINIT:
			int f;
                	int permissions=0666;	//Default if not provided

		CODE:
			if(items==4){
				permissions=SvIV(ST(3));
			}
			f=open(path, mode, permissions);
			if(f<0){
				RETVAL=&PL_sv_undef;
			}
			else{
				RETVAL=newSViv(f);
				if(SvOK(fd)){
					sv_setiv(fd,f);
				}
				else {
					fd= newSViv(f);
				}
			}

		OUTPUT:
			RETVAL
			fd


SV*
sysopen4(fd, path, mode, permissions)
 		int fd
                char *path
                int mode
                int permissions

		PREINIT:
			int f;

		CODE:
			fd=open(path, mode, permissions);
			if(fd<0){
				RETVAL=&PL_sv_undef;
			}
			else{
				RETVAL=newSViv(fd);
			}

		OUTPUT:
			RETVAL
			fd
#CLOSE
######

SV*
close(fd)
	int fd;

	INIT:
		int ret;

	CODE:
		ret=close(fd);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			#close returns 0 on success.. which is false in perl 
			#so increment
			RETVAL=newSViv(ret+1);
		}
	OUTPUT:
		RETVAL



#SYSREAD
########

SV*
sysread(fd, data, ...)
                int fd;
                SV* data

		INIT:
			int ret;
			char *buf;
			int len;
			int offset;

                CODE:
			//TODO: allow unspecified len and offset

			//grow scalar to fit potental read

			if(items >=4 ){
				len=SvIOK(ST(2))?SvIV(ST(2)):0;
				offset=SvIOK(ST(3))?SvIV(ST(3)):0;
			}
			else if(items ==3){
				len=SvIOK(ST(2))?SvIV(ST(2)):0;
				offset=0;
			}
			else {
				len=SvOK(data)?SvCUR(data):0;
				offset=0;
			}
				
			int data_len=sv_len(data);
			int request_len;
			if(offset<0){
				offset=data_len-offset;
			}
			else{

			}
			request_len=len+offset;

			#fprintf(stderr, "Length of buffer is: %d\n", data_len);
			#fprintf(stderr, "Length of request is: %d\n", request_len);

			buf = SvPOK(data) ? SvGROW(data, request_len+1) : 0;

			data_len=sv_len(data);
			#fprintf(stderr, "Length of buffer is: %d\n", data_len);
			#TODO: fill with nulls if offset past end of original data
					
			buf+=offset;

                        ret=read(fd, buf, len);
			if(ret<0){

				RETVAL=&PL_sv_undef;
			}
			else {
				buf[ret]='\0';
				SvCUR_set(data,ret+offset);
				RETVAL=newSViv(ret);
			}

		OUTPUT:
			RETVAL

SV*
sysread3(fd, data, len)
                int fd;
                SV* data
                int len

		INIT:
			int ret;
			char *buf;
			int offset;

                CODE:
			int data_len=sv_len(data);

			#fprintf(stderr, "Length of buffer is: %d\n", data_len);
			#fprintf(stderr, "Length of request is: %d\n",len);

			buf = SvPOK(data) ? SvGROW(data,len+1) : 0;

			data_len=sv_len(data);
			#fprintf(stderr, "Length of buffer is: %d\n", data_len);
					

                        ret=read(fd, buf, len);
			if(ret<0){

				RETVAL=&PL_sv_undef;
			}
			else {
				buf[ret]='\0';
				SvCUR_set(data,ret);
				RETVAL=newSViv(ret);
			}

		OUTPUT:
			RETVAL

SV*
sysread4(fd, data, len, offset)
                int fd;
                SV* data
                int len
		int offset

		INIT:
			int ret;
			char *buf;

                CODE:
			#TODO: allow unspecified len and offset

			#grow scalar to fit potental read
			int data_len=sv_len(data);
			int request_len;
			if(offset<0){
				offset=data_len-offset;
			}
			else{

			}
			request_len=len+offset;

			#fprintf(stderr, "Length of buffer is: %d\n", data_len);
			#fprintf(stderr, "Length of request is: %d\n", request_len);

			buf = SvPOK(data) ? SvGROW(data, request_len+1) : 0;

			data_len=sv_len(data);
			#fprintf(stderr, "Length of buffer is: %d\n", data_len);
			#TODO: fill with nulls if offset past end of original data
					
			buf+=offset;

                        ret=read(fd, buf, len);
			if(ret<0){

				RETVAL=&PL_sv_undef;
			}
			else {
				buf[ret]='\0';
				SvCUR_set(data,ret+offset);
				RETVAL=newSViv(ret);
			}

		OUTPUT:
			RETVAL

#SYSWRITE 
##########

SV*
syswrite(fd,data,...)
	int fd
	SV* data

	INIT:
		int ret;
		char *buf;
		STRLEN max=SvCUR(data);
		int len;
		int offset;
	CODE:
		if(items >=4 ){
			//length and  Offset provided
			len=SvIOK(ST(2))?SvIV(ST(2)):0;
			offset=SvIOK(ST(3))?SvIV(ST(3)):0;
			
		}
		else if(items == 3){
			//length provided	
			len=SvIOK(ST(2))?SvIV(ST(2)):0;
			offset=0;
		}
		else{
			//no length or offset
			len=SvCUR(data);
			offset=0;
		}

		#TODO: fix negative offset processing
		#TODO: allow unspecified len and offset

		#fprintf(stderr,"Input size: %zu\n",SvCUR(data));
		offset=
			offset>max
				?max
				:offset;

		if((offset+len)>max){
			len=max-offset;
		}
		
		buf=sv_pv(data);
		buf+=offset;
		ret=write(fd,buf,len);
		#fprintf(stderr, "write consumed %d bytes\n", ret);	
		if(ret<0){
			RETVAL=&PL_sv_undef;	
		}
		else{
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL

SV*
syswrite2(fd,data)
	int fd
	SV* data

	INIT:
		int ret;
		char *buf;
		STRLEN max=SvCUR(data);
		int offset=0;
		int len;
	CODE:

		len=SvIOK(data)?SvIV(data):0;
		#TODO: fix negative offset processing
		#TODO: allow unspecified len and offset

		#fprintf(stderr,"Input size: %zu\n",SvCUR(data));

		if(len>max){
			len=max;
		}
		
		buf=sv_pv(data);
		ret=write(fd,buf,len);
		#fprintf(stderr, "write consumed %d bytes\n", ret);	
		if(ret<0){
			RETVAL=&PL_sv_undef;	
		}
		else{
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL

SV*
syswrite3(fd,data,len)
	int fd
	SV* data
	int len

	INIT:
		int ret;
		char *buf;
		STRLEN max=SvCUR(data);
		int offset=0;
	CODE:

		#TODO: fix negative offset processing
		#TODO: allow unspecified len and offset

		#fprintf(stderr,"Input size: %zu\n",SvCUR(data));

		if(len>max){
			len=max;
		}
		
		buf=sv_pv(data);
		ret=write(fd,buf,len);
		#fprintf(stderr, "write consumed %d bytes\n", ret);	
		if(ret<0){
			RETVAL=&PL_sv_undef;	
		}
		else{
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL


SV*
syswrite4(fd,data,len,offset)
	int fd
	SV* data
	int len
	int offset

	INIT:
		int ret;
		char *buf;
		STRLEN max=SvCUR(data);
	CODE:

		#TODO: fix negative offset processing
		#TODO: allow unspecified len and offset

		#fprintf(stderr,"Input size: %zu\n",SvCUR(data));
		offset=
			offset>max
				?max
				:offset;

		if((offset+len)>max){
			len=max-offset;
		}
		
		buf=sv_pv(data);
		buf+=offset;
		ret=write(fd,buf,len);
		#fprintf(stderr, "write consumed %d bytes\n", ret);	
		if(ret<0){
			RETVAL=&PL_sv_undef;	
		}
		else{
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL


#PIPE
######

SV*
pipe(read_end,write_end)
	SV* read_end
	SV* write_end

	INIT:
		int ret;
		int fds[2];

	CODE:
		ret=pipe(fds);

		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			#pipe returns 0 on success...
			RETVAL=newSViv(ret+1);
			if(SvOK(read_end)){
				sv_setiv(read_end, fds[0]);
			}
			else {
				read_end=newSViv(fds[0]);
			}

			if(SvOK(write_end)){
				sv_setiv(write_end,fds[1]);
			}
			else {
				write_end=newSViv(fds[1]);
			}
		}
	OUTPUT:
		RETVAL
		read_end
		write_end

#BIND
#####

SV*
bind(fd,address)
	int fd
	SV*address
	
	INIT:
		int ret;
		int len=SvOK(address)?SvLEN(address):0;
		struct sockaddr *addr=(struct sockaddr *)sv_pv(address);
	CODE:
		ret=bind(fd, addr, len);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret+1);
		}
	
	OUTPUT:
		RETVAL
#SOCKETPAIR
###########
# TODO: 
# How to through an exception like perl when syscall not implemented?

SV*
socketpair(fd1,fd2, domain, type, protocol)
	int fd1
	int fd2
	int domain
	int type
	int protocol

	INIT:

		int ret;
		int fds[2];

	CODE:
		#TODO need to emulate via tcp to localhost for non unix
		ret=socketpair(domain, type, protocol, fds);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret+1);
			fd1=fds[0];
			fd2=fds[1];
		}
	OUTPUT:
		RETVAL
		fd1
		fd2

#SYSSEEK
########

SV*
sysseek(fd,offset,whence)
	int fd;
	int offset;
	int whence;

	INIT:
		int ret;

	CODE:

		ret=lseek(fd, offset,whence);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL

#DUP
####

SV*
dup(fd)
	int fd;

	INIT:
		int ret;

	CODE:
		ret=dup(fd);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL


#DUP2
#####

SV*
dup2(fd1,fd2)
	int fd1
	int fd2

	INIT: 
		int ret;

	CODE:
		ret=dup2(fd1,fd2);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret);
		}

	OUTPUT:

		RETVAL
#FCNTL
######

SV*
fcntl(fd, cmd, arg)
	int fd
	int cmd
	SV* arg

	#TODO: everything
	INIT:
		int ret;
	CODE:
		#if arg is numeric, call with iv
		#otherwise we pass pointers and hope for the best
		if(SvOK(arg)){
			if(SvIOK(arg)){
				#fprintf(stderr, "PROCESSING ARG AS NUMBER\n");
				ret=fcntl(fd,cmd, SvIV(arg));
			}else if(SvPOK(arg)){
				#fprintf(stderr, "PROCESSING ARG AS STRING\n");
				ret=fcntl(fd,cmd,SvPVX(arg));
			}
			else {
				#error
				#fprintf(stderr, "PROCESSING ARG AS UNKOWN\n");
				ret=-1;
			}
			if(ret==-1){
				RETVAL=&PL_sv_undef;
			}
			else {
				RETVAL=newSViv(ret);
			}
		}

	OUTPUT:
		RETVAL


#IOCTL
######

SV*
ioctl(fd, request, arg)
	int fd
	int request
	int arg

	INIT:

	CODE:
		RETVAL=&PL_sv_undef;

	OUTPUT:
		RETVAL

#GETSOCKOPT
############
SV*
getsockopt(fd, level, option, buffer) 
	int fd
	int level
	int option
	SV *buffer

	INIT:
		int ret;
		char * buf;
		unsigned int  len;

	CODE:
		if(!SvOK(buffer)){
			buffer=newSV(257);
			SvPOK_on(buffer);
			buf=SvPVX(buffer);
		}
		else{
			buf=SvGROW(buffer,257);
		}	


		len=256;
		ret=getsockopt(fd,level, option, buf, &len);	
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else {
			SvCUR_set(buffer, len);
			*SvEND(buffer)='\0';
			RETVAL=newSVsv(buffer);
		}
		


	OUTPUT:
		RETVAL
		buffer


#SETSOCKOPT
###########
SV*
setsockopt(fd, level, option, buffer)
	int fd
	int level
	int option
	SV* buffer;

	INIT:
		int ret;
		char  *buf;
		unsigned int len;


	CODE:
		if(SvOK(buffer)&&SvPOK(buffer)){
			len=SvCUR(buffer);
			buf=SvPVX(buffer);
			ret=setsockopt(fd,level,option,buf, len);
			RETVAL=newSViv(ret+1);
		}
		else{
			RETVAL=&PL_sv_undef;
		}	


		

	OUTPUT:
		RETVAL


#SELECT
#######

SV*
select(readvec, writevec, errorvec, tout)
	SV* readvec
	SV* writevec
	SV* errorvec
	#Perl timeout is in fractional seconds
	SV* tout	


	INIT:
		fd_set *r;
		fd_set *w;
		fd_set *e;
		struct timeval timeout;
		int size=sizeof(fd_set)+1;
		double tval;
		int ret;
		int nfds=0;

	CODE:
		//Ensure the vector can fit a fd_set	
		//TODO: Need to make sure its null filled too
		//
		if(SvOK(readvec)){
			r=(fd_set *)SvGROW(readvec,size);
			nfds=SvCUR(readvec)>nfds?SvCUR(readvec) : nfds;
		}
		else {
			r=NULL;
		}

		if(SvOK(writevec)){
			w=(fd_set *)SvGROW(writevec,size);
			nfds=SvCUR(writevec)>nfds?SvCUR(writevec) : nfds;
		}
		else {
			w=NULL;
		}

		if(SvOK(errorvec)){
			e=(fd_set *)SvGROW(errorvec,size);
			nfds=SvCUR(errorvec)>nfds?SvCUR(errorvec) : nfds;
		}
		else {
			e=NULL;
		}

		nfds*=8;	//convert string (byte) length to bit length
		if(SvOK(tout) && SvNOK(tout)){
			//Timeout value provided in fractional seconds
			tval=SvNV(tout);
			timeout.tv_sec=(int) tval;
			tval-=timeout.tv_sec;
			tval*=1000000;
			timeout.tv_usec=(int) tval;
			
			ret=select(nfds,r,w,e,&timeout);
		}

		else{
			//Timeout is non a number
			ret=select(nfds,r,w,e, NULL);
		}
		if(ret<0){
			//Undef on error
			RETVAL=&PL_sv_undef;
		}
		else{
			//0 on timeout expired
			//>0 number of found fds to test
			RETVAL=newSViv(ret);
		}


	OUTPUT:

		RETVAL
		readvec
		writevec
		errorvec

#POLL
#####
SV*
poll (poll_list, s_timeout)
	SV* poll_list;
	double s_timeout;
	INIT:

		int sz=sizeof(struct pollfd);
		int count;	
		int ret;
	CODE:
		if(SvOK(poll_list) && SvPOK(poll_list)){
			count=SvCUR(poll_list)/sz;	 //Number of items in array
			//TODO: croak if not fully divisible
			ret=poll((struct pollfd *)SvPVX(poll_list), count, (int)s_timeout*1000);
		}
		else {
			ret=poll(NULL,0,(int)s_timeout*1000);
		}
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret);

		}
	
	
		//No length of list is required as we use the smallest multiple of sizeof(struct pollfd) which will fit in  the poll list

	OUTPUT:

		RETVAL
		poll_list




#MKSTEMP
########

SV*
mkstemp(template)
	char *template

	INIT:
		int ret;
	CODE:
		ret=mkstemp(template);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}	
		else{
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL
#MKTEMP
#######

SV*
mktemp(template)
	char *template

	INIT:
		char *ret;
		char *buf;
	CODE:
		ret=mktemp(template);
		if(ret==NULL){
			RETVAL=&PL_sv_undef;
			fprintf(stderr, "temp file creation failed\n");
		}
		else{
			RETVAL=newSV(0);

			sv_setpv(RETVAL,ret);
			buf=SvPVX(RETVAL);
			fprintf(stderr, "File name generated %s\n", buf);
		}


	OUTPUT:
		RETVAL


#readline
#readinput based on $\ seperator. use get_sv function??
#in list or scalar context

void
readline(fd)
	int fd
	
	INIT:
		SV *irs;
		int ret;
		int count;
		SV* buffer;
		char *buf;
		int do_loop=1;

		int tmp;
	PPCODE:
		irs=get_sv("/",0);
		if(irs){
			#Found variable. Read records
			if(SvOK(irs)){
				if(SvROK(irs)){
					##SLURP RECORDS

					SV* v=SvRV(irs);	//Dereference to get SV
					tmp=SvIV(v);		//The integer value of the sv
					do{
						buffer=newSV(tmp);	//Allocate buffer at record size
						buf=SvPVX(buffer);	//Get the pointer we  need
						ret=read(fd, buf, tmp);	//Do the read into buffer

						sv_2mortal(buffer);	//Decrement ref count
						if(ret<=0){
							break;		//Finish on error or eof 
						}

						SvPOK_on(buffer);	//Make a string
						buf[ret]='\0';		//Set null just in case
						SvCUR_set(buffer, tmp);	//Set the length of the string
						EXTEND(SP,1);		//Extend stack
						PUSHs(buffer);		//Push record
					} while(ret>0 && do_loop);

				}
				else {
					#EOL split
					#Requrires buffering so not supported?
				}
			}
			else{
				##SLURP entire file
				EXTEND(SP,1);
				PUSHs(slurp(fd, 4096));
			}
		}
		else {
			#not found.. this isn't good

		}


#Naming
# IO::FD::sysread for example mimics the perl sysread
# IO::FD::read for example is a direct API mapping to the os read function	

#TODO:
# DONE socketpair	=> perl uses tcp if unix sockets not supported?
# DONE seek
# DONE dup and dup2
# TODO fcntl
# TODO ioctl
# poll
# select ... perl compatiable version
# dir ... not normally on FDs?
# readline?

# Add IPC::Open2 and IPC::Open3 emulations

