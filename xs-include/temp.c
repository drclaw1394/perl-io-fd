#NOTES:
#LINUX: use readlink on /proc/self/fd/NNN where NNN is the file
#BSD/DARINW use fcntl and F_GETPATH on the fd
#MKSTEMP
########

SV*
mkstemp(template)
	char *template

	INIT:
		int ret;
		SV *path_sv;
		char *path;
		int len=0;
		int min_ok=1;
    ssize_t bufsize,outsize;
    char proc[MAXPATHLEN];

	PPCODE:
		len=strlen(template);
		if(len<6){
			Perl_croak(aTHX_ "The template must end with at least 6 'X' characters");
		}

		for(int i=1; i<=6; i++){
			min_ok=min_ok&&(template[len-i]=='X');
		}
		if(!min_ok){
			Perl_croak(aTHX_ "The template must end with at least 6 'X' characters");
		}


		ret=mkstemp(template);
		if(ret<0){
			Perl_croak(aTHX_ "Error creating temp file");
			//mXPUSHs(&PL_sv_undef);
		}	
		else{

      if(ret>PL_maxsysfd){
        fcntl(ret, F_SETFD, FD_CLOEXEC);
      }
			switch(GIMME_V){
				case G_SCALAR:
					mXPUSHs(newSViv(ret));
					XSRETURN(1);
					break;
				case G_ARRAY:
          
          // Read the manual stupid... This was so simple
          // yet so hard !  LOL
					path_sv=newSVpv(template,0);
					path=SvPVX(path_sv);
<<<<<<< HEAD
=======
					fcntl(ret, F_GETPATH, path);
					SvCUR_set(path_sv, strlen(path));
          SvPOK_on(path_sv);
#endif
#if defined(IO_FD_OS_LINUX)
          //ssize_t bufsize=MAXPATHLEN;
          bufsize=MAXPATHLEN;
          //ssize_t outsize;
          //char * buf;

          path_sv=newSV(MAXPATHLEN);
          path=SvPVX(path_sv);
          sprintf(proc,"/proc/self/fd/%d",ret);
          //readlink on /proc/self/fd/NNN where NNN is the file
          //
          outsize=readlink(proc, path, bufsize);
          if(outsize<0){
			      Perl_croak(aTHX_ "Cannot access fd info in /proc");
          }

          path[outsize]='\0'; //Needs a manual null
          SvCUR_set(path_sv, outsize);
          SvPOK_on(path_sv);
#endif
>>>>>>> 195df30d7da6d97635f6380fa0317c01f5204205

					EXTEND(SP,2);
					mPUSHs(newSViv(ret));
					//mPUSHs(newSVpv(path,0));
					mPUSHs(path_sv);
					XSRETURN(2);
					break;

				default:
					XSRETURN_EMPTY;
					break;
					
			}
		}

#MKTEMP
#######

SV*
mktemp(template)
	char *template

	INIT:
		char *ret;
		char *buf;
		int len=0;
		int min_ok=1;
	PPCODE:
		len=strlen(template);
		if(len<6){
			Perl_croak(aTHX_ "The template must end with at least 6 'X' characters");
		}

		for(int i=1; i<=6; i++){
			min_ok=min_ok&&(template[len-i]=='X');
		}

		if(!min_ok){
			Perl_croak(aTHX_ "The template must end with at least 6 'X' characters");
		}

		ret=mktemp(template);
		if(ret==NULL){
			Perl_croak(aTHX_ "Error creating temp file");
		}
		else{
			mXPUSHs(newSVpv(ret, 0));
			XSRETURN(1);
		}

