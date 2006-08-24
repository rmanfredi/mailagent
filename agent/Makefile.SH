: Makefile.SH generated from Jmake.tmpl and Jmakefile [jmake 3.0 PL70]
: $X-Id: Jmake.tmpl,v 3.0.1.3 1997/02/28 14:56:16 ram Exp ram $

case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
CURRENT=agent
DIR=`echo $CURRENT/ | sed -e 's/\.\///g'`
echo "Extracting ${DIR}Makefile (with variable substitutions)"

INSTALL=`echo $install | sed -e 's,\./i,\$(TOP)/i,'`
DATE=`date`

$spitshell >Makefile <<!GROK!THIS!
########################################################################
# Makefile generated from Makefile.SH on $DATE

SHELL = /bin/sh
JMAKE = jmake
TOP = ..
CURRENT = $CURRENT
DIR = $DIR
INSTALL = $INSTALL

########################################################################
# Parameters set by Configure -- edit config.sh if changes are needed

BINDIR = $installbin
CTAGS = ctags
L = $manext
MANSRC = $installmansrc
MAKE = make
MKDEP = $mkdep \$(DPFLAGS) --
MV = $mv
RM = $rm -f
SCRIPTDIR = $installscript
SED = $sed

########################################################################
# Automatically generated parameters -- do not edit

SUBDIRS = pl filter files man test examples
SCRIPTS =  \$(BIN)

!GROK!THIS!
$spitshell >>Makefile <<'!NO!SUBS!'
########################################################################
# Jmake rules for building libraries, programs, scripts, and data files
# $X-Id: Jmake.rules,v 3.0.1.6 1997/02/28 14:56:01 ram Exp ram $

########################################################################
# Force 'make depend' to be performed first -- do not edit

.FORCE_DEPEND::

all:: .FORCE_DEPEND

########################################################################
# Start of Jmakefile

# $X-Id: Jmakefile,v 3.0.1.3 1994/10/31 11:12:59 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $X-Log: Jmakefile,v $
# Revision 3.0.1.3  1994/10/31  11:12:59  ram
# patch23: file magent.sh now replaces magent.SH to avoid auto-extraction
#
# Revision 3.0.1.2  1994/10/29  17:37:48  ram
# patch20: directory pl added to subdirs and depend lists
#
# Revision 3.0.1.1  1994/09/22  13:39:09  ram
# patch12: new edusers script to edit users file
#
# Revision 3.0  1993/11/29  13:47:37  ram
# Baseline for mailagent 3.0 netwide release.
#

BIN = mailpatch mailhelp maillist maildist package edusers

all:: $(BIN)

local_realclean::
	$(RM) $(BIN)

mailpatch: mailpatch.SH
	/bin/sh mailpatch.SH

mailhelp: mailhelp.SH
	/bin/sh mailhelp.SH

maillist: maillist.SH
	/bin/sh maillist.SH

maildist: maildist.SH
	/bin/sh maildist.SH

package: package.SH
	/bin/sh package.SH

edusers: edusers.SH
	/bin/sh edusers.SH


install:: $(SCRIPTS) $(LSCRIPTS)
	@for file in $(SCRIPTS) $(LSCRIPTS); do \
	case '${MFLAGS}' in *[i]*) set +e;; esac; \
	(set -x; $(INSTALL) -c -m 555 $$file $(SCRIPTDIR)); \
	done

deinstall::
	@for file in $(SCRIPTS) $(LSCRIPTS); do \
	case '${MFLAGS}' in *[i]*) set +e;; esac; \
	(set -x; $(RM) $(SCRIPTDIR)/$$file); \
	done


all:: magent

local_realclean::
	$(RM) magent

magent: magent.sh
	/bin/sh magent.sh


all:: mailagent

local_realclean::
	$(RM) mailagent
mailagent: magent
	perl $(TOP)/bin/perload -o magent > $@
	chmod +rx $@

install:: mailagent
	$(INSTALL) -c -m 555  mailagent $(BINDIR)

deinstall::
	$(RM) $(BINDIR)/mailagent

depend::
	@case '${MFLAGS}' in *[ik]*) set +e;; esac; \
	for i in pl filter ;\
	do \
	(cd $$i ; echo "Depending" "in $(DIR)$$i..."; \
	$(MAKE) $(MFLAGS)  depend); \
	done

.FORCE:

pl/utmp/utmp.pl: .FORCE
	@echo "Checking "utmp.pl" in "pl/utmp"..."
	cd pl/utmp; $(MAKE) utmp.pl
	@echo "Continuing in $(CURRENT)..."

BINSH = \
	mailpatch.SH \
	mailhelp.SH \
	maillist.SH \
	maildist.SH \
	package.SH \
	edusers.SH \
	magent.sh

depend::
	($(SED) '/^# DO NOT DELETE/q' Makefile && \
	grep '^\$$grep' $(BINSH) | \
	$(SED) -e "s/^.*' \([^ ]*\) >>\(.*\)/\2: \1/" \
	) > Makefile.new
	cp Makefile Makefile.bak
	cp Makefile.new Makefile
	$(RM) Makefile.new

########################################################################
# Common rules for all Makefiles -- do not edit

emptyrule::

clean: sub_clean local_clean
realclean: sub_realclean local_realclean
clobber: sub_clobber local_clobber

local_clean::
	$(RM) core *~ *.o

local_realclean:: local_clean

local_clobber:: local_realclean
	$(RM) Makefile config.sh

Makefile.SH: Jmakefile
	-@if test -f $(TOP)/.package; then \
	if test -f Makefile.SH; then \
	echo "	$(RM) Makefile.SH~; $(MV) Makefile.SH Makefile.SH~"; \
	$(RM) Makefile.SH~; $(MV) Makefile.SH Makefile.SH~; \
	fi; \
	echo "	$(JMAKE) -DTOPDIR=$(TOP) -DCURDIR=$(CURRENT)" ; \
	$(JMAKE) -DTOPDIR=$(TOP) -DCURDIR=$(CURRENT) ; \
	else touch $@; exit 0; fi

Makefile: Makefile.SH
	/bin/sh Makefile.SH

tags::
	$(CTAGS) -w *.[ch]
	$(CTAGS) -xw *.[ch] > tags

local_clobber::
	$(RM) tags

########################################################################
# Rules for building in sub-directories -- do not edit

subdirs:
	@case '${MFLAGS}' in *[ik]*) set +e;; esac; \
	for i in $(SUBDIRS) ;\
	do \
	(cd $$i ; echo $(VERB) "in $(DIR)$$i..."; \
	$(MAKE) $(MFLAGS) $(FLAGS) $(TARGET)); \
	done

install::
	@$(MAKE) subdirs TARGET=install VERB="Installing" FLAGS=

deinstall::
	@$(MAKE) subdirs TARGET=deinstall VERB="Deinstalling" FLAGS=

install.man::
	@$(MAKE) subdirs TARGET=install.man VERB="Installing man pages" FLAGS=

deinstall.man::
	@$(MAKE) subdirs TARGET=deinstall.man VERB="Deinstalling man pages" FLAGS=

sub_clean::
	@$(MAKE) subdirs TARGET=clean VERB="Cleaning" FLAGS=
	@echo "Back to $(CURRENT) for "clean...

sub_realclean::
	@$(MAKE) subdirs TARGET=realclean VERB="Real cleaning" FLAGS=
	@echo "Back to $(CURRENT) for "realclean...

sub_clobber::
	@$(MAKE) subdirs TARGET=clobber VERB="Clobbering" FLAGS=
	@echo "Back to $(CURRENT) for "clobber...

tag::
	@case '${MFLAGS}' in *[ik]*) set +e;; esac; \
	for i in $(SUBDIRS) ;\
	do \
	(cd $$i ; echo "Tagging" "in $(DIR)$$i..."; \
	$(MAKE) $(MFLAGS)  tag); \
	done

Makefiles::
	@case '${MFLAGS}' in *[ik]*) set +e;; esac; \
	for i in $(SUBDIRS);\
	do \
	echo "Making "Makefiles" in $(DIR)$$i..."; \
	(cd $$i || exit 1; \
	if test ! -f Makefile; then /bin/sh Makefile.SH; fi; \
	$(MAKE) $(MFLAGS) Makefiles) \
	done

Makefiles.SH:: Makefile.SH
	@case '${MFLAGS}' in *[ik]*) set +e;; esac; \
	for i in $(SUBDIRS);\
	do \
	case "$(DIR)$$i/" in \
	*/*/*/*/) newtop=../../../..;; \
	*/*/*/) newtop=../../..;; \
	*/*/) newtop=../..;; \
	*/) newtop=..;; \
	esac; \
	case "$(TOP)" in \
	/*) newtop="$(TOP)" ;; \
	esac; \
	echo "Making Makefiles.SH in $(DIR)$$i..."; \
	(cd $$i || exit 1; $(MAKE) $(MFLAGS) -f ../Makefile \
	Makefile TOP=$$newtop CURRENT=$(DIR)$$i;\
	$(MAKE) $(MFLAGS) Makefiles.SH) \
	done

all::
	@$(MAKE) subdirs TARGET=all VERB="Making all" FLAGS=

########################################################################
# Dependencies generated by make depend
# DO NOT DELETE THIS LINE -- make depend relies on it

# Put nothing here or make depend will gobble it up
.FORCE_DEPEND::
	@echo "You must run 'make depend' in $(TOP) first."; exit 1
!NO!SUBS!
chmod 644 Makefile
$eunicefix Makefile

