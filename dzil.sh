# Release Cn-Util.  Bump $VERSION in lib/Cn/Util.pm and write the Changes
# entry under it first (see CLAUDE.md), then:
#
#	sh dzil.sh
#
# This is Matplotlib-Simple's dzil.sh with the names changed, plus the git
# steps: it stages the release, uploads it, then commits it as "$VERSION" and
# pushes.  The root Makefile.PL is not written by hand and is not gathered
# into the tarball -- dist.ini has [Git::GatherDir] exclude it and [MakeMaker]
# generate its own -- so a current one exists only inside Cn-Util-$VERSION/,
# which "dzil build" writes.  It is copied back to the root and committed with
# the release, so that "perl Makefile.PL && make test" in a clone tests against
# the prerequisites dist.ini declares now, not those of an earlier release.
set -e

# dist.ini takes the distribution version from the module ([VersionFromModule]),
# so read it from the same place rather than from anything dzil leaves behind.
version=$(perl -ne 'if (/^our \$VERSION\s*=\s*["\x27]?([0-9._]+)["\x27]?\s*;/) { print $1; exit }' lib/Cn/Util.pm)
if [ -z "$version" ]; then
	echo "dzil.sh: no \$VERSION found in lib/Cn/Util.pm" >&2
	exit 1
fi

# Regenerates the module's POD from README.md and checks Changes, so it has to
# run before anything is built out of those files.
perl md2pod.pl

# [Git::GatherDir] builds from git's index, not the working tree, so a file
# that is not staged is not shipped -- which is how the 0.021 tarball came to
# lack t/windows-names.t.  -u stages every change to a tracked file (the POD
# md2pod.pl just rewrote among them); new files are staged only under lib/ and
# t/, where everything belongs in the distribution, so that a stray script in
# the root is not committed and pushed unseen.  Any such file is listed instead.
git add -u
git add -A lib t
untracked=$(git ls-files --others --exclude-standard)
if [ -n "$untracked" ]; then
	echo "dzil.sh: not staged, so neither shipped nor committed:" >&2
	echo "$untracked" | sed 's/^/	/' >&2
fi

# Without uploading: this is what leaves Cn-Util-$VERSION/ and its tarball in
# the working directory.  It overwrites an existing directory of the same
# name, so a re-run of this script is harmless.
dzil build
if [ ! -f "Cn-Util-$version/Makefile.PL" ]; then
	echo "dzil.sh: dzil build wrote no Cn-Util-$version/Makefile.PL" >&2
	exit 1
fi
cp "Cn-Util-$version/Makefile.PL" Makefile.PL
git add Makefile.PL

# Builds, runs the test suite (TestRelease), asks for confirmation, uploads.
# Nothing is committed before this succeeds, so a failing test or a "no" at
# the prompt leaves only staged changes, and the next run stages over them
# rather than adding a second commit for the same version.
dzil release

# The commit is named after the version, as earlier releases were.  An empty
# index means the release was committed by hand already, and there is nothing
# to add.
if ! git diff --cached --quiet; then
	git commit -m "$version"
fi
git push

# Writes the root Makefile that "make test" uses; the Makefile is in .gitignore.
perl Makefile.PL
