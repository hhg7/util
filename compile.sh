# Build, test and install Cn::Util from this working copy into whichever perl
# is first on PATH, as ~/Scripts/stats/compile.sh does for Stats::LikeR.
# Arguments go to Makefile.PL:
#
#	sh compile.sh
#	sh compile.sh INSTALL_BASE=~/perl5/local
#
# It builds in the repository root.  That is safe only because Makefile.PL
# drops root-level *.pm and *.pl from the install through MY::libscan (see
# [MakeMaker::Awesome] in dist.ini); without it, the shim Util.pm and the
# author scripts went into site_perl too, the shim over its symlink.
#
# Makefile.PL is the one the last "sh dzil.sh" copied back, so a change to
# dist.ini since then, a new prerequisite included, is not seen here until
# the next release.
#
# The first run has no Makefile to clean.  The first run after Makefile.PL
# changes has one older than it, and EUMM then rewrites the Makefile and exits
# 1 from "make clean" on purpose, asking for make to be run again -- which the
# next line does -- so its output and status are not worth showing.
if [ -f Makefile ]; then make clean >/dev/null 2>&1; fi
perl Makefile.PL "$@" && make && make test && make install
