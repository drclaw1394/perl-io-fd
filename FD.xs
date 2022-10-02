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

#include <sys/time.h>
#include <sys/event.h>

#include <sys/stat.h>

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

#LISTEN
#######


SV *
listen(listener,backlog)
	int listener;
	int backlog;


	INIT:
		int ret;

	CODE:

		ret=listen(listener, backlog);

		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret+1);
		}

	OUTPUT:
		RETVAL

#ACCEPT
#######

SV*
accept(new_fd, listen_fd)
		SV* new_fd
                int listen_fd

                PREINIT:
                        struct sockaddr *packed_addr;
                        int ret;
			SV *addr=newSV(sizeof(struct sockaddr));
			struct sockaddr *buf=(struct sockaddr *)SvPVX(addr);
			unsigned int len=sizeof(struct sockaddr);

			

                CODE:
                ret=accept(listen_fd, buf, &len);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else {
			SvPOK_on(addr);
			SvCUR_set(addr,sizeof(struct sockaddr));
			RETVAL=addr;
			if(SvOK(new_fd)){
				sv_setiv(new_fd, ret);		
			}
			else{
				new_fd=newSViv(ret);
			}
		}
	
	
                OUTPUT:
			RETVAL
			new_fd
#CONNECT
########

SV*
connect(fd, address)
	SV* fd
	SV *address

	PREINIT:
		int ret;
		int len=SvOK(address)?SvCUR(address):0;
		struct sockaddr *addr=(struct sockaddr *)SvPVX(address);

	CODE:

		ret=connect(SvIVX(fd),addr,len);
		//fprintf(stderr,"CONNECT: %d\n",ret);
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
sysread(fd, data, len, ...)
                int fd;
                SV* data
		int len
		INIT:
			int ret;
			char *buf;
			int offset=0;

                CODE:
			//TODO: allow unspecified len and offset

			//grow scalar to fit potental read

			if(items >=4 ){
				//len=SvIOK(ST(2))?SvIV(ST(2)):0;
				offset=SvIOK(ST(3))?SvIV(ST(3)):0;
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
			int data_len=SvCUR(data);

			#fprintf(stderr, "Length of buffer is: %d\n", data_len);
			#fprintf(stderr, "Length of request is: %d\n",len);

			buf = SvPOK(data) ? SvGROW(data,len+1) : 0;

			//data_len=SvPVX(data);
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
		
		buf=SvPVX(data);
		buf+=offset;
		ret=write(fd, buf, len);
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
		int len;
	CODE:

		len=SvPOK(data)?SvCUR(data):0;
		#TODO: fix negative offset processing
		#TODO: allow unspecified len and offset

		#fprintf(stderr,"Input size: %zu\n",SvCUR(data));

		
		buf=SvPVX(data);
		ret=write(fd, buf, len);
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
		
		buf=SvPVX(data);
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
		
		buf=SvPVX(data);
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

	ALIAS: syspipe=1

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
bind(fd, address)
	int fd
	SV*address
	
	ALIAS: sysbind=1

	INIT:
		int ret;
		int len=SvOK(address)?SvCUR(address):0;
		struct sockaddr *addr=(struct sockaddr *)SvPVX(address);
	CODE:
		//fprintf(stderr, "bind fd: %d\n",fd);
		//fprintf(stderr, "bind len: %d\n",len);
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

	ALIAS: sysfctrl=1
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

	ALIAS: sysioctl=1
	INIT:

	CODE:
		RETVAL=&PL_sv_undef;

	OUTPUT:
		RETVAL

#GETSOCKOPT
############
SV*
getsockopt(fd, level, option) 
	int fd
	int level
	int option

	INIT:
		int ret;
		char * buf;
		unsigned int  len;
		SV *buffer;

	CODE:
		buffer=newSV(257);
		SvPOK_on(buffer);
		buf=SvPVX(buffer);
		len=256;

		ret=getsockopt(fd,level, option, buf, &len);	

		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else {
			SvCUR_set(buffer, len);
			*SvEND(buffer)='\0';
			RETVAL=buffer;
		}


	OUTPUT:
		RETVAL


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

		SV *_buffer;


	CODE:
		if(SvOK(buffer)){
			if(SvIOK(buffer)){
				#fprintf(stderr, "SET SOCKOPT as integer\n");
				//Do what perl does and convert integers
				_buffer=newSV(sizeof(int));
				len=sizeof(int);
				
				SvPOK_on(_buffer);
				SvCUR_set(_buffer, len);
				//*SvEND(_buffer)='\0';
				buf=SvPVX(_buffer);
				*((int *)buf)=SvIVX(buffer);

			}
			else if(SvPOK(buffer)){
				#fprintf(stderr, "SET SOCKOPT as NON integer\n");
				_buffer=buffer;

			}

			len=SvCUR(_buffer);
			buf=SvPVX(_buffer);
			ret=setsockopt(fd,level,option,buf, len);
			if(ret<0){
				//fprintf(stderr, "call failed\n");
				RETVAL=&PL_sv_undef;
			}
			else{
				//fprintf(stderr, "call succeeded\n");
				RETVAL=newSViv(ret+1);
			}
			
		}
		else{
			//fprintf(stderr, "no buffer");
			RETVAL=&PL_sv_undef;
		}	


		

	OUTPUT:
		RETVAL

        ##########################################################
        # #FILENO                                                #
        # #######                                                #
        #                                                        #
        # SV *                                                   #
        # fileno (fd_fh)                                         #
        #         SV *fd_fh;                                     #
        #                                                        #
        #         INIT:                                          #
        #                 int ret;                               #
        #                                                        #
        #         CODE:                                          #
        #                 if(!SvOK(fd_fh)){                      #
        #                         RETVAL=&PL_sv_undef;           #
        #                 }                                      #
        #                 else{                                  #
        #                         if(SvIOK(fd_fh)){              #
        #                                 //treat as integer fd  #
        #                                 RETVAL=newSVsv(fd_fh); #
        #                         }                              #
        #                         else{                          #
        #                                 //assume glob          #
        #                                 REVAL=GvIO             #
        #                         }                              #
        #                 }                                      #
        #                                                        #
        #                                                        #
        #         OUTPUT:                                        #
        #                 RETVAL                                 #
        #                                                        #
        ##########################################################


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
		int bit_string_size=129;
		int tmp;

	CODE:
		//Ensure the vector can fit a fd_set
		//TODO: Need to make sure its null filled too
		//
		if(SvOK(readvec)){
			r=(fd_set *)SvGROW(readvec,bit_string_size);
			tmp=SvCUR(readvec);
			Zero(((char *)r)+tmp,bit_string_size-tmp,1);
			nfds=tmp;
		}
		else {
			r=NULL;
		}

		if(SvOK(writevec)){
			w=(fd_set *)SvGROW(writevec,bit_string_size);
			tmp=SvCUR(writevec);
			Zero(((char *)w)+tmp,bit_string_size-tmp,1);
			nfds=tmp>nfds?tmp:nfds;
		}
		else {
			w=NULL;
		}

		if(SvOK(errorvec)){
			e=(fd_set *)SvGROW(errorvec,bit_string_size);
			tmp=SvCUR(errorvec);
			Zero(((char *)e)+tmp, bit_string_size-tmp,1);
			nfds=tmp>nfds?tmp:nfds;
		}
		else {
			e=NULL;
		}

		nfds*=8;        //convert string (byte) length to bit length
				//This length has an implicit +1 for select call

		//Clamp the nfds to 1024
		if(nfds>1024){
			//TODO: Need to show an error here?
			nfds=1024;
		}
		//TODO: handle EAGAIN and EINT
		//nfds++;
		//fprintf(stderr, "Number of fds for select: %d\n", nfds);
		if(SvOK(tout) && (SvNOK(tout) || SvIOK(tout))){
			//Timeout value provided in fractional seconds
			tval=SvNV(tout);
			timeout.tv_sec=(unsigned int ) tval;
			tval-=timeout.tv_sec;
			tval*=1000000;
			timeout.tv_usec=(unsigned int) tval;

			//fprintf(stderr, "select with %fs timeout....\n", tval);
			ret=select(nfds,r,w,e,&timeout);
			//fprintf(stderr, "Returned number of fds %d\n", ret);
		}

		else{
			//Timeout is not a number
			//printf(stderr, "select with null timeout....\n");
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
			//Used for timeout only
			ret=poll(NULL,0,(int)s_timeout*1000);
		}
		//TODO: need to process EAGAIN and INT somehow
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
			//fprintf(stderr, "temp file creation failed\n");
		}
		else{
			RETVAL=newSV(0);

			sv_setpv(RETVAL,ret);
			buf=SvPVX(RETVAL);
			//fprintf(stderr, "File name generated %s\n", buf);
		}


	OUTPUT:
		RETVAL

SV*
recv(fd,data,len,flags)
	int fd
	SV *data
	int len
	int flags

	INIT:
		int ret;
		SV* peer;	//Return addr like perl
		struct sockaddr *peer_buf; 
		unsigned int addr_len;
		char *buf;

	CODE:
		//Makesure the buffer exists and is large enough to recv
		if(!SvOK(data)){
			data=newSV(len+1);
		}
		buf = SvPOK(data) ? SvGROW(data,len+1) : NULL;

		peer=newSV(sizeof(struct sockaddr)+1);
		peer_buf=(struct sockaddr *)SvPVX(peer);

		addr_len=sizeof(struct sockaddr);
		ret=recvfrom(fd,buf,len,flags,peer_buf, &addr_len);

		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			SvPOK_on(peer);
			SvCUR_set(peer, addr_len);
			RETVAL=peer;
		}
	OUTPUT:
		RETVAL
		data

SV*
send(fd,data,flags, ...)
	int fd
	SV* data
	int flags

	INIT:

		char *buf;
		int len;

		struct sockaddr *dest;
		int ret;

		
	CODE:
		if(SvOK(data) && SvPOK(data)){
			if((items == 4) && SvOK(ST(3)) && SvPOK(ST(3))){
				//Do sendto
				len=SvCUR(data);
				buf=SvPVX(data);

				dest=(struct sockaddr *)SvPVX(ST(3));

				ret=sendto(fd, buf, len, flags, dest, SvCUR(ST(3)));
			}
			else {
				//Regular send
				len=SvCUR(data);
				buf=SvPVX(data);
				ret=send(fd, buf, len, flags);
			}
		}
		if(ret<0){

			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret);
		}
	OUTPUT:
		RETVAL


SV*
getpeername(fd)
	int fd;
	
	INIT:
		int ret;
		SV *addr=newSV(sizeof(struct sockaddr)+1);
		struct sockaddr *buf=(struct sockaddr *)SvPVX(addr);
		unsigned int len=sizeof(struct sockaddr);

	CODE:
		
		ret=getpeername(fd,buf,&len);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else {
			SvCUR_set(addr,len);
			SvPOK_on(addr);

			RETVAL=addr;
		}
	
	OUTPUT:
		RETVAL

SV*
getsockname(fd)
	int fd;
	
	INIT:
		int ret;
		SV *addr=newSV(sizeof(struct sockaddr)+1);
		struct sockaddr *buf=(struct sockaddr *)SvPVX(addr);
		unsigned int len=sizeof(struct sockaddr);

	CODE:
		
		ret=getsockname(fd,buf,&len);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else {
			SvCUR_set(addr,len);
			SvPOK_on(addr);

			RETVAL=addr;
		}
	
	OUTPUT:
		RETVAL



void
stat(target)
	SV *target;

	ALIAS:
		IO::FD::stat = 1
		IO::FD::lstat = 2
	INIT:

		int ret=-1;
		char *path;
		struct stat buf;
		int len;
		IV atime;
		IV mtime;
		IV ctime;
	PPCODE:

		if(SvOK(target) && SvIOK(target)){
			//Integer => always an fstat
			ret=fstat(SvIV(target), &buf);
		}
		else if(SvOK(target)&& SvPOK(target)){
			//String => stat OR lstat
			
			len=SvCUR(target);
			Newx(path, len+1, char); 	//Allocate plus null
			Copy(SvPV_nolen(target), path, len, char);	//Copy
			*(path+len)='\0';	//set null	
			switch(ix){
				case 1:
					ret=stat(path, &buf);
					break;
				case 2:
					ret=lstat(path, &buf);
					break;

				default:
					break;
			}
			Safefree(path);

			
		}
		else {
			//Unkown
		}

		if(ret>=0){
			switch(GIMME_V){
				case G_ARRAY:
					//fprintf(stderr , "ARRAY CONTEXT. no error\n");
					atime=buf.st_atimespec.tv_sec+buf.st_atimespec.tv_nsec*1e-9;
					mtime=buf.st_mtimespec.tv_sec+buf.st_mtimespec.tv_nsec*1e-9;
					ctime=buf.st_ctimespec.tv_sec+buf.st_ctimespec.tv_nsec*1e-9;

					//Work through the items in the struct
					//dSP;
					EXTEND(SP, 13);
					mPUSHs(newSViv(buf.st_dev));
					mPUSHs(newSVuv(buf.st_ino));
					mPUSHs(newSVuv(buf.st_mode));
					mPUSHs(newSViv(buf.st_nlink));
					mPUSHs(newSViv(buf.st_uid));
					mPUSHs(newSViv(buf.st_gid));
					mPUSHs(newSViv(buf.st_rdev));
					mPUSHs(newSViv(buf.st_size));
					mPUSHs(newSViv(atime));
					mPUSHs(newSViv(mtime));
					mPUSHs(newSViv(ctime));
					mPUSHs(newSViv(buf.st_blksize));
					mPUSHs(newSViv(buf.st_blocks));
					XSRETURN(13);
					break;
				case G_VOID:
					XSRETURN_EMPTY;
					break;
				case G_SCALAR:
				default:
					//fprintf(stderr , "SCALAR CONTEXT. no error\n");
					mXPUSHs(newSViv(1));
					XSRETURN(1);
					break;
			}



		}
		switch(GIMME_V){
			case G_SCALAR:
				mXPUSHs(&PL_sv_undef);
				break;
			case G_VOID:
			case G_ARRAY:
			default:
				XSRETURN_EMPTY;
				break;
		}


SV *
kqueue()

	INIT:
		int ret;
	CODE:
		ret=kqueue();
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret);
		}
	OUTPUT:
		RETVAL

SV *
kevent(kq, change_list, event_list, timeout)
	int kq;
	SV * change_list;
	SV * event_list;
	SV * timeout;
	
	INIT:
		int ret;
		int ncl, nel;
		struct kevent *cl, *el;
		struct timespec tspec;
		double tout;

	CODE:
		//Calcuate from current length
		ncl=SvCUR(change_list)/sizeof(struct kevent);

		//Calculate from available length
		nel=SvLEN(event_list)/sizeof(struct kevent);

		cl=(struct kevent *)SvPVX(change_list);
		el=(struct kevent *)SvPVX(event_list);

		//fprintf(stderr, "change list len: %d, event list available: %d\n", ncl, nel);
		if(SvOK(timeout)&& SvNOK(timeout)){
			tout=SvNV(timeout);
			tspec.tv_sec=tout;
			tspec.tv_nsec=1e9*(tout-tspec.tv_sec);
			ret=kevent(kq,cl,ncl, el, nel, &tspec);
		}
		else {
			ret=kevent(kq,cl,ncl, el, nel, NULL);
		}

		if(ret<0){
			SvCUR_set(event_list,0);
			RETVAL=&PL_sv_undef;
		}
		else {
			SvCUR_set(event_list,sizeof(struct kevent)*ret);
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL
		event_list

	
SV *
pack_kevent(ident,filter,flags,fflags,data,udata)
	unsigned long ident;
	I16 filter;
	U16 flags;
	U32 fflags;
	long data;
	SV *udata;

	INIT:
		struct kevent *e;

	CODE:
		RETVAL=newSV(sizeof(struct kevent));	
		e=(struct kevent *)SvPVX(RETVAL);
		e->ident=ident;
		e->filter=filter;
		e->flags=flags;
		e->fflags=fflags;
		e->data=data;
		e->udata=SvRV(udata);
		SvCUR_set(RETVAL,sizeof(struct kevent));
		SvPOK_on(RETVAL);
		//Pack

	OUTPUT:
		RETVAL


SV * 
clock_gettime_monotonic()

	INIT:
		struct timespec tp;
		int ret;

	CODE:
		ret=clock_gettime(CLOCK_MONOTONIC, &tp);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSVnv(tp.tv_sec + tp.tv_nsec * 1e-9);
		}


	OUTPUT:
		RETVAL

long
sv_to_pointer(sv)
	SV *sv

	INIT:

	CODE:
		//TODO: Increase the ref count	of input sv
		RETVAL=(long)SvRV(sv);
	OUTPUT:

		RETVAL

SV *
pointer_to_sv(pointer)
	long pointer;

	INIT:
	CODE:
		//TODO: check valid. decrement ref count;
		RETVAL=newRV((SV*)pointer);

	OUTPUT:
		RETVAL


SV *
SV(size)
	int size

	CODE:
		RETVAL=newSV(size);
		
		//SvPOK_on(RETVAL);
		SvPVCLEAR(RETVAL);
	OUTPUT:
		RETVAL

#TODO

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

#TODO:
# TODO ioctl
# poll
# select ... perl compatiable version
# dir ... not normally on FDs?
# readline?

# Add IPC::Open2 and IPC::Open3 emulations

