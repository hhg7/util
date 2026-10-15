# Release Util-Con.  Bump $VERSION in lib/Util/Con.pm and write the Changes
# entry under it first (see CLAUDE.md), then:
#
#	sh dzil.sh
#
# This is Matplotlib-Simple's dzil.sh with the names changed.  The root
# Makefile.PL is not written by hand and is not gathered into the tarball --
# dist.ini has [Git::GatherDir] exclude it and [MakeMaker] generate its own --
# so a current one exists only inside Util-Con-$VERSION/, which "dzil build"
# writes at the end of this script.  It is copied back to the root afterwards,
# so that "perl Makefile.PL && make test" in a clone tests against the
# prerequisites dist.ini declares now, not those of an earlier release.
set -e

# Regenerates the module's POD from README.md and checks Changes, so it has to
# run before anything is built out of those files.
perl md2pod.pl

# Builds, runs the test suite (TestRelease), asks for confirmation, uploads.
dzil release

# Again, without uploading: this is what leaves Util-Con-$VERSION/ and its
# tarball in the working directory.  It overwrites an existing directory of
# the same name, so a re-run of this script is harmless.
dzil build

# dist.ini takes the distribution version from the module ([VersionFromModule]),
# so read it from the same place rather than from anything dzil leaves behind.
version=$(perl -ne 'if (/^our \$VERSION\s*=\s*["\x27]?([0-9._]+)["\x27]?\s*;/) { print $1; exit }' lib/Util/Con.pm)
if [ -z "$version" ]; then
	echo "dzil.sh: no \$VERSION found in lib/Util/Con.pm" >&2
	exit 1
fi
if [ ! -f "Util-Con-$version/Makefile.PL" ]; then
	echo "dzil.sh: dzil build wrote no Util-Con-$version/Makefile.PL" >&2
	exit 1
fi

# The root Makefile.PL is what someone cloning from GitHub runs, so it is the
# one just shipped rather than one from an earlier release.  Commit it with the
# rest of the release.
cp "Util-Con-$version/Makefile.PL" Makefile.PL
perl Makefile.PL
