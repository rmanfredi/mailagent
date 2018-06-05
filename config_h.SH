case "$CONFIG_SH" in
'') CONFIG_SH=config.sh;;
esac
case "$CONFIG_H" in
'') CONFIG_H=config.h;;
esac
case $CONFIG in
'')
	if test -f $CONFIG_SH; then TOP=.;
	elif test -f ../$CONFIG_SH; then TOP=..;
	elif test -f ../../$CONFIG_SH; then TOP=../..;
	elif test -f ../../../$CONFIG_SH; then TOP=../../..;
	elif test -f ../../../../$CONFIG_SH; then TOP=../../../..;
	else
		echo "Can't find $CONFIG_SH."; exit 1
	fi
	. $TOP/$CONFIG_SH
	;;
esac
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting $CONFIG_H (with variable substitutions)"
sed <<!GROK!THIS! >$CONFIG_H -e 's!^#undef\(.*/\)\*!/\*#define\1 \*!' -e 's!^#un-def!#undef!'
/*
 * This file was produced by running the config_h.SH script, which
 * gets its values from $CONFIG_SH, which is generally produced by
 * running Configure.
 *
 * Feel free to modify any of this as the need arises.  Note, however,
 * that running config_h.SH again will wipe out any changes you've made.
 * For a more permanent change edit $CONFIG_SH and rerun config_h.SH.
 *
 * \$Id$
 */

/*
 * Package name      : $package
 * Source directory  : $src
 * Configuration time: $cf_time
 * Configured by     : $cf_by
 * Target system     : $myuname
 */

#ifndef _config_h_
#define _config_h_

/* STRINGIFY:
 *	This macro surrounds its token with double quotes.
 */
#if $cpp_stuff == 1
#define STRINGIFY(a)"a"
#define SQuoTe(a)${cpp_quote}a
#define EQuoTe(a)a${cpp_quote}
#endif
#if $cpp_stuff == 42
#define CaTiFy(a,b) a ## b
#define CAT2(a,b) CaTiFy(a,b)
#define StGiFy(a)# a
#define STRINGIFY(a)StGiFy(a)
#endif
#if $cpp_stuff != 1 && $cpp_stuff != 42
#include "Bletch: How does this C preprocessor catenate tokens?"
#endif

/* HAS_BCOPY:
 *	This symbol is defined if the bcopy() routine is available to
 *	copy blocks of memory.
 */
#$d_bcopy HAS_BCOPY	/**/

/* HAS_DUP2:
 *	This symbol, if defined, indicates that the dup2 routine is
 *	available to duplicate file descriptors.
 */
#$d_dup2 HAS_DUP2	/**/

/* HAS_FCNTL:
 *	This symbol, if defined, indicates to the C program that
 *	the fcntl() function exists.
 */
#$d_fcntl HAS_FCNTL		/**/

/* FLEXFILENAMES:
 *	This symbol, if defined, indicates that the system supports filenames
 *	longer than 14 characters.
 */
#$d_flexfnam	FLEXFILENAMES		/**/

/* HAS_GETHOSTNAME:
 *	This symbol, if defined, indicates that the C program may use the
 *	gethostname() routine to derive the host name.  See also HAS_UNAME
 *	and PHOSTNAME.
 */
/* HAS_UNAME:
 *	This symbol, if defined, indicates that the C program may use the
 *	uname() routine to derive the host name.  See also HAS_GETHOSTNAME
 *	and PHOSTNAME.
 */
/* PHOSTNAME:
 *	This symbol, if defined, indicates that the C program may use the
 *	contents of PHOSTNAME as a command to feed to the popen() routine
 *	to derive the host name.  See also HAS_GETHOSTNAME and HAS_UNAME.
 *	Note that the command uses a fully qualified path, so that it is safe
 *	even if used by a process with super-user privileges.
 */
#$d_gethname HAS_GETHOSTNAME	/**/
#$d_uname HAS_UNAME		/**/
#$d_phostname PHOSTNAME "$aphostname"	/* How to get the host name */

/* HAS_GETOPT:
 *	This symbol, if defined, indicates that the getopt() routine exists.
 */
#$d_getopt HAS_GETOPT		/**/

/* HAS_GNULIBC:
 *	This symbol, if defined, indicates to the C program that
 *	the GNU C library is being used.  A better check is to use
 *	the __GLIBC__ and __GLIBC_MINOR__ symbols supplied with glibc.
 */
#$d_gnulibc HAS_GNULIBC  	/**/
#if defined(HAS_GNULIBC) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE
#endif

/* HAS_RENAME:
 *	This symbol, if defined, indicates that the rename routine is available
 *	to rename files.  Otherwise you should do the unlink(), link(), unlink()
 *	trick.
 */
#$d_rename HAS_RENAME	/**/

/* HAS_SETPGID:
 *	This symbol, if defined, indicates that the setpgid(pid, gpid)
 *	routine is available to set process group ID.
 */
#$d_setpgid HAS_SETPGID	/**/

/* HAS_SETPGRP:
 *	This symbol, if defined, indicates that the setpgrp routine is
 *	available to set the current process group.
 */
/* USE_BSD_SETPGRP:
 *	This symbol, if defined, indicates that setpgrp needs two
 *	arguments whereas USG one needs none.  See also HAS_SETPGID
 *	for a POSIX interface.
 */
#$d_setpgrp HAS_SETPGRP		/**/
#$d_bsdsetpgrp USE_BSD_SETPGRP	/**/

/* HAS_SETRGID:
 *	This symbol, if defined, indicates that the setrgid routine is available
 *	to change the real gid of the current program.
 */
#$d_setrgid HAS_SETRGID		/**/

/* HAS_SETRUID:
 *	This symbol, if defined, indicates that the setruid routine is available
 *	to change the real uid of the current program.
 */
#$d_setruid HAS_SETRUID		/**/

/* HAS_SETSID:
 *	This symbol, if defined, indicates that the setsid routine is
 *	available to set the process group ID.
 */
#$d_setsid HAS_SETSID	/**/

/* HAS_STRCASECMP:
 *	This symbol, if defined, indicates that the strcasecmp() routine is
 *	available for case-insensitive string compares.
 */
#$d_strccmp HAS_STRCASECMP	/**/

/* HAS_INDEX:
 *	This symbol is defined to indicate that the index()/rindex()
 *	functions are available for string searching.
 */
#$d_index HAS_INDEX	/**/

/* HAS_STRERROR:
 *	This symbol, if defined, indicates that the strerror routine is
 *	available to translate error numbers to strings. See the writeup
 *	of Strerror() in this file before you try to define your own.
 */
/* HAS_SYS_ERRLIST:
 *	This symbol, if defined, indicates that the sys_errlist array is
 *	available to translate error numbers to strings. The extern int
 *	sys_nerr gives the size of that table.
 */
/* HAS_SYS_ERRNOLIST:
 *	This symbol, if defined, indicates that the sys_errnolist array is
 *	available to translate an errno code into its symbolic name (e.g.
 * ENOENT). The extern int sys_nerrno gives the size of that table.
 */
/* Strerror:
 *	This preprocessor symbol is defined as a macro if strerror() is
 *	not available to translate error numbers to strings but sys_errlist[]
 *	array is there.
 */
#$d_strerror HAS_STRERROR		/**/
#$d_syserrlst HAS_SYS_ERRLIST	/**/
#$d_sysernlst HAS_SYS_ERRNOLIST	/**/
#define Strerror(e) $d_strerrm

/* Time_t:
 *	This symbol holds the type returned by time(). It can be long,
 *	or time_t on BSD sites (in which case <sys/types.h> should be
 *	included).
 */
#define Time_t $timetype		/* Time type */

/* UNION_WAIT:
 *	This symbol if defined indicates to the C program that the argument
 *	for the wait() system call should be declared as 'union wait status'
 *	instead of 'int status'. You probably need to include <sys/wait.h>
 *	in the former case (see I_SYSWAIT).
 */
#$d_uwait UNION_WAIT		/**/

/* HAS_VFORK:
 *	This symbol, if defined, indicates that vfork() exists.
 */
#$d_vfork HAS_VFORK	/**/

/* Signal_t:
 *	This symbol's value is either "void" or "int", corresponding to the
 *	appropriate return type of a signal handler.  Thus, you can declare
 *	a signal handler using "Signal_t (*handler)()", and define the
 *	handler using "Signal_t handler(sig)".
 */
#define Signal_t $signal_t	/* Signal handler's return type */

/* USE_WIFSTAT:
 *	This symbol, if defined, indicates to the C program that the argument
 *	for the WIFxxx set of macros such as WIFSIGNALED or WIFEXITED can
 *	be of the same kind as the one used to hold the wait() status. Should
 *	only matter on HP-UX, where the macros are incorrectly written and
 *	therefore cause programs using them with an 'union wait' variable
 *	to not compile properly. See also UNION_WAIT.
 */
#$d_wifstat USE_WIFSTAT		/**/

/* I_FCNTL:
 *	This manifest constant tells the C program to include <fcntl.h>.
 */
#$i_fcntl I_FCNTL	/**/

/* I_MALLOC:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <malloc.h>.
 */
#$i_malloc I_MALLOC		/**/

/* I_STDLIB:
 *	This symbol, if defined, indicates that <stdlib.h> exists and should
 *	be included.
 */
#$i_stdlib I_STDLIB		/**/

/* I_STRING:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <string.h> (USG systems) instead of <strings.h> (BSD systems).
 */
#$i_string I_STRING		/**/

/* I_SYS_FILE:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/file.h> to get definition of R_OK and friends.
 */
#$i_sysfile I_SYS_FILE		/**/

/* I_SYS_IOCTL:
 *	This symbol, if defined, indicates that <sys/ioctl.h> exists and should
 *	be included. Otherwise, include <sgtty.h> or <termio.h>.
 */
/* USE_TIOCNOTTY:
 *	This symbol, if defined indicate to the C program that the ioctl()
 *	call with TIOCNOTTY should be used to void tty association.
 *	Otherwise (on USG probably), it is enough to close the standard file
 *	decriptors and do a setpgrp().
 */
#$i_sysioctl	I_SYS_IOCTL		/**/
#$d_voidtty USE_TIOCNOTTY	/**/

/* I_SYS_PARAM:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/param.h>.
 */
#$i_sysparam I_SYS_PARAM		/**/

/* I_SYS_TYPES:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/types.h>.
 */
#$i_systypes	I_SYS_TYPES		/**/

/* I_SYS_WAIT:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/wait.h>.
 */
#$i_syswait I_SYS_WAIT	/**/

/* I_TERMIOS:
 *	This symbol, if defined, indicates that the program should include
 *	the POSIX termios.h rather than sgtty.h or termio.h.
 *	There are also differences in the ioctl() calls that depend on the
 *	value of this symbol.
 */
#$i_termios I_TERMIOS		/**/

/* I_TIME:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <time.h>.
 */
/* I_SYS_TIME:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/time.h>.
 */
/* I_SYS_TIME_KERNEL:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/time.h> with KERNEL defined.
 */
#$i_time I_TIME		/**/
#$i_systime I_SYS_TIME		/**/
#$i_systimek I_SYS_TIME_KERNEL		/**/

/* I_UNISTD:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <unistd.h>.
 */
#$i_unistd I_UNISTD		/**/

/* INTSIZE:
 *	This symbol contains the value of sizeof(int) so that the C
 *	preprocessor can make decisions based on it.
 */
#define INTSIZE $intsize

/* MYHOSTNAME:
 *	This symbol contains name of the host the program is going to run on.
 *	The domain is not kept with hostname, but must be gotten from MYDOMAIN.
 *	The dot comes with MYDOMAIN, and need not be supplied by the program.
 *	If gethostname() or uname() exist, MYHOSTNAME may be ignored. If MYDOMAIN
 *	is not used, MYHOSTNAME will hold the name derived from PHOSTNAME.
 */
#define MYHOSTNAME "$myhostname"		/**/

/* PERLPATH:
 *	This symbol contains the absolute location of the perl interpreter.
 */
#define PERLPATH "$perlpath"		/**/

/* Pid_t:
 *	This symbol holds the type used to declare process ids in the kernel.
 *	It can be int, uint, pid_t, etc... It may be necessary to include
 *	<sys/types.h> to get any typedef'ed information.
 */
#define Pid_t $pidtype		/* PID type */

/* CAN_PROTOTYPE:
 *	If defined, this macro indicates that the C compiler can handle
 *	function prototypes.
 */
/* NXT_ARG:
 *	This macro is used to separate arguments in the declared argument list.
 */
/* V_FUNC:
 *	This macro is used to declare "public" (non-static) functions.
 *	It takes three arguments: the function type and name, a parenthesized
 *	traditional (comma separated) argument list, and the declared argument
 *	list (in which arguments are separated with NXT_ARG, and additional
 *	arbitrary arguments are specified with DOTS).  For example:
 *
 *		V_FUNC(int main, (argc, argv), int argc NXT_ARG char *argv[])
 */
/* _:
 *	This macro is used to declare function parameters for folks who want
 *	to make declarations with prototypes using a different style than
 *	the above macros.  Use double parentheses.  For example:
 *
 *		int main _((int argc, char *argv[]));
 */
#$prototype	CAN_PROTOTYPE	/**/
#ifdef CAN_PROTOTYPE
#define	NXT_ARG ,
#define	V_FUNC(name, arglist, args)name(args)
#define	_(args) args
#else
#define	NXT_ARG ;
#define	V_FUNC(name, arglist, args)name arglist args;
#define	_(args) ()
#endif

/* register1:
 *	This symbol, along with register2, register3, etc. is either the word
 *	"register" or null, depending on whether the C compiler pays attention
 *	to this many register declarations.  The intent is that you don't have
 *	to order your register declarations in the order of importance, so you
 *	can freely declare register variables in sub-blocks of code and as
 *	function parameters.  Do not use register<n> more than once per routine.
 */
#define register1 $reg1		/**/
#define register2 $reg2		/**/
#define register3 $reg3		/**/
#define register4 $reg4		/**/
#define register5 $reg5		/**/
#define register6 $reg6		/**/

/* ROOTID:
 *	This symbol contains the uid of root, normally 0.
 */
#define ROOTID $rootid		/**/

/* Uid_t:
 *	This symbol holds the type used to declare user ids in the kernel.
 *	It can be int, ushort, uid_t, etc... It may be necessary to include
 *	<sys/types.h> to get any typedef'ed information.
 */
#define Uid_t $uidtype		/* UID type */

/* VOIDFLAGS:
 *	This symbol indicates how much support of the void type is given by this
 *	compiler.  What various bits mean:
 *
 *	    1 = supports declaration of void
 *	    2 = supports arrays of pointers to functions returning void
 *	    4 = supports comparisons between pointers to void functions and
 *		    addresses of void functions
 *	    8 = suports declaration of generic void pointers
 *
 *	The package designer should define VOIDUSED to indicate the requirements
 *	of the package.  This can be done either by #defining VOIDUSED before
 *	including config.h, or by defining defvoidused in Myinit.U.  If the
 *	latter approach is taken, only those flags will be tested.  If the
 *	level of void support necessary is not present, defines void to int.
 */
#ifndef VOIDUSED
#define VOIDUSED $defvoidused
#endif
#define VOIDFLAGS $voidflags
#if (VOIDFLAGS & VOIDUSED) != VOIDUSED
#define void int		/* is void to be avoided? */
#define M_VOID			/* Xenix strikes again */
#endif

#endif
!GROK!THIS!
