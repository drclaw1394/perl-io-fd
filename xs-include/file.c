#SYSSEEK
########

SV*
sysseek(fd,offset,whence)
	SV *fd;
	int offset;
	int whence;

	INIT:
		int ret;

	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      ret=lseek(SvIV(fd), offset, whence);
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
        RETVAL=newSViv(ret);
      }
    }
    else{
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::bind called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL

#DUP
####

SV*
dup(fd)
	SV *fd;

	INIT:
		int ret;

	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      ret=dup(SvIV(fd));
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
        RETVAL=newSViv(ret);
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::dup called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL


#DUP2
#####

SV*
dup2(fd1,fd2)
	SV *fd1
	SV *fd2

	INIT: 
		int ret;

	CODE:
    if(SvOK(fd1) && SvIOK(fd1) && SvOK(fd2) && SvIOK(fd2)){
      ret=dup2(SvIV(fd1),SvIV(fd2));
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
        if(ret>PL_maxsysfd){
          fcntl(ret, F_SETFD, FD_CLOEXEC);
        }
        RETVAL=newSViv(ret);
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::dup2 called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL
    
#FCNTL
######

SV*
fcntl(fd, cmd, arg)
	SV *fd
	int cmd
	SV* arg

	#TODO: everything

	ALIAS: sysfctrl=1
	INIT:
		int ret;
	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      //if arg is numeric, call with iv
      //otherwise we pass pointers and hope for the best
      if(SvOK(arg)){
        if(SvIOK(arg)){
          //fprintf(stderr, "PROCESSING ARG AS NUMBER\n");
          ret=fcntl(SvIV(fd),cmd, SvIV(arg));
        }else if(SvPOK(arg)){
          //fprintf(stderr, "PROCESSING ARG AS STRING\n");
          ret=fcntl(SvIV(fd),cmd,SvPVX(arg));
        }
        else {
          //error
          //fprintf(stderr, "PROCESSING ARG AS UNKOWN\n");
          ret=-1;
        }
        if(ret==-1){
          RETVAL=&PL_sv_undef;
        }
        else {
          RETVAL=newSViv(ret);
        }
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::fcntl called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL


#IOCTL
######

SV*
ioctl(fd, request, arg)
	SV *fd
	int request
	int arg

	ALIAS: sysioctl=1
	INIT:

	CODE:
		RETVAL=&PL_sv_undef;
    //NOTE: Remember to add 1 to no error return
	OUTPUT:
		RETVAL


#if defined(IO_FD_OS_DARWIN)|| defined(IO_FD_OS_BSD)
#define IO_FD_ATIME atime=buf.st_atimespec.tv_sec+buf.st_atimespec.tv_nsec*1e-9;
#define IO_FD_MTIME mtime=buf.st_mtimespec.tv_sec+buf.st_mtimespec.tv_nsec*1e-9;
#define IO_FD_CTIME ctime=buf.st_ctimespec.tv_sec+buf.st_ctimespec.tv_nsec*1e-9;
#endif

#if defined(IO_FD_OS_LINUX)
#define IO_FD_ATIME atime=buf.st_atim.tv_sec+buf.st_atim.tv_nsec*1e-9;
#define IO_FD_MTIME mtime=buf.st_mtim.tv_sec+buf.st_mtim.tv_nsec*1e-9;
#define IO_FD_CTIME ctime=buf.st_ctim.tv_sec+buf.st_ctim.tv_nsec*1e-9;
#endif

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
			Copy(SvPVbyte_nolen(target), path, len, char);	//Copy
			path[len]='\0';	//set null	
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

					IO_FD_ATIME
					IO_FD_MTIME
					IO_FD_CTIME


					//Work through the items in the struct
					//dSP;
					EXTEND(SP, 13);               //macos     bsd       linux
					mPUSHs(newSVuv(buf.st_dev));  //int32     uint64    uint64
					mPUSHs(newSVuv(buf.st_ino));  //uint32/64 uint64    uint32/uint64
					mPUSHs(newSVuv(buf.st_mode)); //uint16    uint16    uint32
					mPUSHs(newSVuv(buf.st_nlink));//uint16    uint64    uint32
					mPUSHs(newSVuv(buf.st_uid));  //uint32    uint32    uint32
					mPUSHs(newSVuv(buf.st_gid));  //uint32    uint32    uint32
					mPUSHs(newSVuv(buf.st_rdev)); //As per st_dev
					mPUSHs(newSViv(buf.st_size)); //int64     int64     uint64 
					mPUSHs(newSViv(atime));
					mPUSHs(newSViv(mtime));
					mPUSHs(newSViv(ctime));
					mPUSHs(newSViv(buf.st_blksize));//int32   int32     int32 
					mPUSHs(newSViv(buf.st_blocks));//int64    int64     int32
					XSRETURN(13);
					break;
				case G_VOID:
					XSRETURN_EMPTY;
					break;
				case G_SCALAR:
				default:
					mXPUSHs(newSViv(1));
					XSRETURN(1);
					break;
			}



		}
		switch(GIMME_V){
			case G_SCALAR:
				mXPUSHs(&PL_sv_undef);
				XSRETURN(1);
				break;
			case G_VOID:
			case G_ARRAY:
			default:
				XSRETURN_EMPTY;
				break;
		}

