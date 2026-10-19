# Compatibility shim: `use Util` loads Cn::Util, for the scripts written
# before the module was renamed.  It is not part of the distribution -- the
# tarball is built from lib/, and dist.ini's [PruneFiles] keeps everything in
# the repository root out of it -- and exists because this file has been
# symlinked into perl-5.44.0's site_perl as Util.pm, and 55 scripts under
# ~/Scripts say `use Util`.
#
# abs_path() resolves that symlink, so lib/ is found next to the real file
# rather than next to the link.  Once Cn::Util is installed with `make
# install` or from CPAN, scripts can say `use Cn::Util` and this file and its
# symlink can go.
package Util;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec;
use lib File::Spec->catdir(dirname(abs_path(__FILE__)), 'lib');
require Cn::Util;
our @EXPORT = @Cn::Util::EXPORT;

# goto keeps the caller's frame, so Cn::Util::import sees the script as its
# caller and puts the subs, p() and np(), and autodie there, as it would for
# `use Cn::Util`.  The class is swapped so that Exporter reads Cn::Util's
# @EXPORT.
sub import {
	shift;
	unshift @_, 'Cn::Util';
	goto &Cn::Util::import;
}

1;
