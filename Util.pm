# Compatibility shim: `use Util` loads Util::Con, for the scripts written
# before the module was renamed.  It is not part of the distribution -- the
# tarball is built from lib/, and dist.ini's [PruneFiles] keeps everything in
# the repository root out of it -- and exists because this file has been
# symlinked into perl-5.44.0's site_perl as Util.pm, and 55 scripts under
# ~/Scripts say `use Util`.
#
# abs_path() resolves that symlink, so lib/ is found next to the real file
# rather than next to the link.  Once Util::Con is installed with `make
# install` or from CPAN, scripts can say `use Util::Con` and this file and its
# symlink can go.
package Util;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec;
use lib File::Spec->catdir(dirname(abs_path(__FILE__)), 'lib');
require Util::Con;
our @EXPORT = @Util::Con::EXPORT;

# goto keeps the caller's frame, so Util::Con::import sees the script as its
# caller and puts the subs, p() and np(), and autodie there, as it would for
# `use Util::Con`.  The class is swapped so that Exporter reads Util::Con's
# @EXPORT.
sub import {
	shift;
	unshift @_, 'Util::Con';
	goto &Util::Con::import;
}

1;
