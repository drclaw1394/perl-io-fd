#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

MODULE = IO::FD		PACKAGE = IO::FD		

INCLUDE: const-xs.inc


int
socket(sock,af,type,proto)
		int sock;
		int af
		int type
		int proto

		PREINIT:
			int fd;
		CODE:
			fd=socket(af, type, proto);
			sock=fd;
                        ##############################
                        # if(SvOK(sock)){            #
                        #         sv_setiv(sock,fd); #
                        # }                          #
                        # else {                     #
                        #         sock=newSViv(fd);  #
                        # }                          #
                        ##############################
			//Set error variable...
			if(fd<0){
				RETVAL=-1;
				#set the error variable
			}
			else{
				RETVAL=0;

			}

		OUTPUT:
			RETVAL
			sock

########################################################################################
# int                                                                                  #
#         accept                                                                       #
#                 int listener;                                                        #
#                 INIT:                                                                #
#                         struct sockaddr *packed_addr;                                #
#                         socklen_t       len;                                         #
#                         int ret;                                                     #
#                                                                                      #
#                 CODE:                                                                #
#                 ret=accept(listener, &packed_addr, &len);                            #
#                 //Set error variable...                                              #
#                 RETVAL:                                                              #
#                         //Make SV from packed addr                                   #
#                         //return the new socket fd and the packed address  as a list #
#                                                                                      #
# int     open                                                                         #
#                 char * path;                                                         #
#                 int mode;                                                            #
#                 int permission;                                                      #
#                                                                                      #
#                 INIT:                                                                #
#                         int ret;                                                     #
#                 CODE:                                                                #
#                         ret=open(path, mode, permission);                            #
#                         //Set error variable...                                      #
#                 RETVAL:                                                              #
#                         ret;                                                         #
# int read                                                                             #
#                 int fd;                                                              #
#                 char *data;                                                          #
#                 int len;                                                             #
#                                                                                      #
#                 INIT:                                                                #
#                         int ret;                                                     #
#                                                                                      #
#                 CODE:                                                                #
#                         ret=read(fd,data,len);                                       #
#                                                                                      #
#                         //Set error var                                              #
#                 RETVAL:                                                              #
#                                                                                      #
#                         ret;                                                         #
#                                                                                      #
# int write                                                                            #
#                 int fd;                                                              #
#                 char *data;                                                          #
#                 int len;                                                             #
#                                                                                      #
#                 INIT:                                                                #
#                         ret;                                                         #
#                                                                                      #
#                 CODE:                                                                #
#                         ret=write(fd, data, len);                                    #
#                         //set error var                                              #
#                 RETVAL:                                                              #
#                         ret;                                                         #
#                                                                                      #
# //TODO:                                                                              #
# //      bind                                                                         #
# //      sendto                                                                       #
# //      recv                                                                         #
#                                                                                      #
########################################################################################
