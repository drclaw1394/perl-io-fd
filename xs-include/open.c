
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
      if(SvREADONLY(fd)){
        Perl_croak(aTHX_ "%s", PL_no_modify);
      }
			if(items==4){
				permissions=SvIV(ST(3));
			}
			f=open(path, mode, permissions);
			if(f<0){
				RETVAL=&PL_sv_undef;
			}
			else{
        if(!(mode & O_CLOEXEC) && (f>PL_maxsysfd)){
          fcntl(f, F_SETFD, FD_CLOEXEC);
        }
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
 		SV *fd
    char *path
    int mode
    int permissions

		PREINIT:
			int f;

		CODE:
      if(SvREADONLY(fd)){
        Perl_croak(aTHX_ "%s", PL_no_modify);
      }
			f=open(path, mode, permissions);
			if(fd<0){
				RETVAL=&PL_sv_undef;
			}
			else{
        if(!(mode & O_CLOEXEC) && (f>PL_maxsysfd)){
          fcntl(f, F_SETFD, FD_CLOEXEC);
        }
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
