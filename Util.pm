use 5.044;
no source::encoding;
use warnings FATAL => 'all';
use Devel::Confess;
# Startup cost.  Everything below the pragmas is loaded on first use, not at
# `use Util`.  Loading DDP + Devel::Confess + autodie + Capture::Tiny +
# JSON::MaybeXS eagerly cost ~40 ms of interpreter startup on every script
# that touched this module, even ones that only called format_commas().
#
# The rules that decide what can be deferred:
#   - PRAGMAS (autodie, warnings, feature/`use 5.044`) act on the *compiler*
#     for the enclosing lexical scope, so they can never be deferred.  autodie
#     was the single most expensive line here (~15 ms); it is gone, and the
#     two bare open()s it was covering now carry explicit `or die`.
#   - Exporter must exist at compile time (it supplies import()), but it is
#     free -- it is already in memory as part of the core.
#   - Everything else is a plain module, so `require` inside the sub that
#     needs it works.  `require` is idempotent and a repeat call is one %INC
#     hash lookup, so putting it in the hot sub costs nothing measurable.
#   - A runtime `require` does NOT run import(), so the imported short names
#     (find, capture, decode_json, colored, blessed) are gone.  Each call site
#     below is therefore fully qualified.  Calling a not-yet-loaded sub with a
#     block prototype is also unparseable at compile time, which is why
#     Capture::Tiny::capture is handed an explicit sub{} instead of a bare {}.
#

package main;

# `use Util` has always leaked DDP's p()/np() into main::, and scripts rely on
# that (list.pl calls `p @files` without ever loading DDP).  These stubs keep
# that convenience without paying DDP's ~16 ms unless something actually
# prints.  They must be declared with DDP's own prototype at compile time,
# because that is what makes `p @files` pass \@files rather than a flat list.
# On first call, DDP->import() overwrites these globs with the real thing --
# `caller` is main:: here, which is exactly what makes it install into main::.
my $DDP_LOADED = 0;
sub _load_ddp {
	return if $DDP_LOADED++;
	require DDP;
	local $SIG{__WARN__} = sub {
		warn @_ unless $_[0] =~ m{\ASubroutine main::n?p redefined};
	};
	DDP->import({output => 'STDOUT', array_max => 10, show_memsize => 1, show_dualvar => 'off'});
	return;
}
sub p  :prototype(\[@$%&];%) { _load_ddp(); goto &{ \&main::p  } }
sub np :prototype(\[@$%&];%) { _load_ddp(); goto &{ \&main::np } }

package Util;
use 5.044;
no source::encoding;
use warnings FATAL => 'all';
require Exporter;
our @ISA = ('Exporter');
# Scalar::Util is require'd by structure() below -- it drags in List::Util's XS
# bootstrap (~4 ms) and only the structure()/st() family ever touches it.
# density_scatterplot
our @EXPORT = qw(dir execute file2string format_commas json_file_to_ref random_key random_value ref_to_json_file st structure);

# ---------------------------------------------------------------------------
# `use Util` hands the calling file autodie and Devel::Confess as well as the
# subs, so scripts do not have to repeat those two lines.
#
# The two need completely different treatment, because they are different
# kinds of thing:
#
#   Devel::Confess is GLOBAL.  It installs $SIG{__DIE__}/{__WARN__} for the
#   whole process, so merely loading it anywhere -- the `use` at the top of
#   this file -- already reaches every caller.  Nothing to re-export.
#
#   autodie is LEXICAL, and that is the hard case.  It is Fatal underneath,
#   and Fatal::import does a bare `caller()` with no $Level support: calling
#   autodie->import() directly from in here makes Fatal believe the importing
#   file is Util.pm.  Its runtime leak-guard then sees calls arriving from a
#   different file and correctly declines to apply -- open() in the caller
#   just returns undef again, silently.  Verified: the naive version does
#   nothing at all.
#
# So the import has to be performed in a context where caller() reports the
# caller's package and file.  A string eval carrying a #line directive does
# exactly that, and is the same trick Import::Into uses (not depended on here
# because it is not a core module).  $line/$file come from our own caller, so
# autodie's scope starts at the `use Util` line, which is where a hand-written
# `use autodie` would have started it too.
#
# NB: `use Util ();` skips import() entirely, per normal Perl semantics, so
# that is the escape hatch for a caller that wants the subs but not autodie.
# ---------------------------------------------------------------------------
sub import {
	my $class = shift;
	$class->export_to_level(1, $class, @_);   # the @EXPORT subs, one level up

	my ($pkg, $file, $line) = caller;
	require autodie;
	my $ok = eval qq{package $pkg;\n#line $line "$file"\nautodie->import(':default'); 1};
	die "Util: could not propagate autodie to $file: $@" unless $ok;
	return;
}

sub dir {
	my %args = (
	  tests     => 'f',
	  dir       => '.',
	  regex     => '.',
	  recursive => 0,
	  on_match  => undef,   # optional callback: streams results, keeps RAM flat
	  cpu       => 1,       # worker processes for a recursive walk; 1 = no forking
	  @_,
	);

	my %allowed = map { $_ => 1 } qw(tests dir regex recursive on_match cpu);
	if (my @bad = grep { !$allowed{$_} } keys %args) {
	  die "Unrecognized arguments: @bad\nAccepted args: "
		 . join(', ', sort keys %allowed);
	}
	# Added 's' (non-zero size), removed 't' (tty test - meaningless on a path)
	die "Unrecognized characters in tests: $args{tests}"
	  if $args{tests} =~ /[^rwxoRWXOezsfdlpSbcugkTB]/;
	die "cpu must be a positive integer, got '$args{cpu}'"
	  unless $args{cpu} =~ /\A[1-9][0-9]*\z/;
	my $re = eval { qr/$args{regex}/ }
	  or die "Invalid regex '$args{regex}': $@";
# Compile the tests once. The first test stats the path; every later test
# reuses the stat buffer via the special '_' filehandle, so N tests cost
# one stat(2) syscall instead of N (~2.4x faster for 4 tests).
# -l needs lstat, so it is hoisted to the front, and the test after it
# must re-stat the real path (otherwise '_' holds lstat data, or -l _
# would be a fatal error).
	my @t = split //, $args{tests};
	@t = ((grep { $_ eq 'l' } @t), (grep { $_ ne 'l' } @t));
	my (@parts, $fresh);
	$fresh = 1;
	for my $t (@t) {
	  if    ($t eq 'l') { push @parts, '-l $_[0]';   $fresh = 1 }
	  elsif ($fresh)    { push @parts, "-$t \$_[0]"; $fresh = 0 }
	  else              { push @parts, "-$t _" }
	}
	my $tester = @parts
	  ? (eval 'sub { ' . join(' && ', @parts) . ' }'
		   or die "Failed to compile tests: $@")
	  : sub { 1 };   # empty tests string now means "no filtering", not "nothing matches"

	my $target_dir = $args{dir};
	$target_dir =~ s{(?<=[^/])/+\z}{};   # strip trailing slashes, but keep "/" intact
	# "." is left off the front of results; "/" must not become "//etc".
	my $join = sub ($d, $item) {
		$d eq '.' ? $item : $d eq '/' ? "/$item" : "$d/$item"
	};

	my $cb = $args{on_match};
	my @items;
	my $emit = $cb // sub { push @items, $_[0] };

	if ($args{recursive}) {
		require File::Find; # ~1.6 ms, and only the recursive branch needs it
		# Walk everything strictly below $start, handing each match to $sink.
		my $find = sub ($start, $sink) {
			my $strip = $start eq '.';
			File::Find::find({
				no_chdir => 1,
				wanted   => sub {
					 return if $_ eq $start;             # $start itself is not "below" it
					 my ($file) = m{([^/]+)\z}s;         # basename, much cheaper than File::Spec
					 if ($file =~ $re && $tester->($_)) {
					     my $path = $_;
					     $path =~ s{^\./}{} if $strip;
					     $sink->($path);
					 }
				},
			}, $start);
		};
		if ($args{cpu} == 1) {
			$find->($target_dir, $emit);
		} else {
			_dir_parallel($target_dir, $args{cpu}, $re, $tester, $join, $find, $emit);
		}
	} else {
		# cpu is ignored here on purpose: one readdir plus one stat per entry
		# is ~6 us warm, far below the cost of forking and shipping results back.
		opendir my $dh, $target_dir
			or die "Cannot open directory $target_dir: $!";
		while (defined(my $item = readdir $dh)) {   # defined(): a file named "0" is falsy
			next if $item =~ /\A\.\.?\z/;           # \A..\z: "$" would match before a trailing \n
			next if $item !~ $re;
			my $path = $join->($target_dir, $item);
			$emit->($path) if $tester->($path);
		}
		closedir $dh;
	}
	return $cb ? () : @items;
}

# Jobs handed out per worker.  Parallel::ForkManager starts a new job whenever
# a worker finishes, so more jobs than workers is what evens out a tree whose
# subdirectories differ wildly in size; each job costs one fork plus one
# Storable round-trip through a temp file, so too many jobs loses again.
# Measured 2026-09-23, 20-core NVMe box, warm cache, best of 3, seconds:
#
#   tree (files)                 serial   k=1    k=2    k=4    k=8    k=16
#   ~/perl5 (150k), cpu=8         1.23    0.95   0.25   0.29   0.36   0.47
#   ~/perl5 (150k), cpu=4         1.23    1.03   0.82   0.39   0.45   0.61
#   perlbrew/build (120k), cpu=8  0.75    0.19   0.24   0.25   0.33   0.44
#
# k=1 and k=2 collapse on the skewed tree; 4 is the smallest value that does
# not.  Re-run: edit the value below, then time
#   perl -I. -MUtil -e 'dir(dir => $ARGV[0], recursive => 1, cpu => 8)' TREE
my $DIR_JOBS_PER_CPU = 4;

# Recursive dir() across $cpu worker processes.  Results come back to this
# process and go through $emit here, so an on_match closure still sees and
# mutates the caller's variables -- it just runs after a whole job's batch
# arrives rather than per file, and match order differs from the serial walk.
sub _dir_parallel ($root, $cpu, $re, $tester, $join, $find, $emit) {
	require Parallel::ForkManager; # not core, and only cpu > 1 needs it

	# One subtree per job would starve the pool whenever a single directory
	# holds most of the tree (~/perl5: one of 3 top-level dirs has 99% of the
	# files, and a top-level split gave no speedup at any cpu).  So walk
	# breadth-first here until a level is wide enough to share out, testing
	# the entries of every level walked; the final level's directories are
	# already tested and become the jobs.
	my $want  = $cpu * $DIR_JOBS_PER_CPU;
	my @level = ($root);
	while (@level && @level < $want) {
		my @next;
		for my $d (@level) {
			opendir my $dh, $d or die "Cannot open directory $d: $!";
			while (defined(my $item = readdir $dh)) {
				next if $item =~ /\A\.\.?\z/;
				my $path = $join->($d, $item);
				$emit->($path) if $item =~ $re && $tester->($path);
				push @next, $path if !-l $path && -d _; # lstat: File::Find does not follow symlinks either
			}
			closedir $dh;
		}
		@level = @next;
	}
	return unless @level;

	my @jobs;
	push @{ $jobs[$_ % $want] }, $level[$_] for 0 .. $#level;

	my @errors;
	my $pm = Parallel::ForkManager->new($cpu);
	# The default 1 s poll in wait_all_children added a flat 1.01 s to every
	# call, measured; 0 makes it block in waitpid instead.
	$pm->set_waitpid_blocking_sleep(0);
	$pm->run_on_finish(sub ($pid, $exit, $id, $signal, $core, $data) {
		if ($signal || $exit || !$data) {
			push @errors, "dir: worker $pid died (exit $exit, signal $signal)";
			return;
		}
		push @errors, $data->{error} if defined $data->{error};
		$emit->($_) for @{ $data->{paths} };
	});
	for my $job (@jobs) {
		$pm->start and next;
		my @found;
		my $ok = eval { $find->($_, sub { push @found, $_[0] }) for @$job; 1 };
		$pm->finish(0, { paths => \@found, error => $ok ? undef : "$@" });
	}
	$pm->wait_all_children;
	die join "\n", @errors if @errors;
	return;
}

sub execute ($cmd, $return = 'exit', $die = 1) {
	if ($return !~ m/^(exit|stdout|stderr|all)$/) {
		die "you gave \$return = \"$return\", while this subroutine only accepts ^(exit|stdout|stderr)\$";
	}
	require Capture::Tiny; # ~7.5 ms
	# Capture::Tiny redirects fd 1 and fd 2 and nothing else, so the child still
	# inherits the parent's fd 0.  A child that prompts -- rm on a
	# write-protected file, cp -i, apt -- prompts only when fd 0 is a tty, then
	# writes its question into the captured stderr where nobody can see it and
	# blocks on the terminal for an answer the user does not know is wanted.
	# (Observed 2026-09-13: `rm -r` on read-only cl.tex hung jobsearch/tex/tar.pl
	# indefinitely.)  Pointing fd 0 at /dev/null turns the prompt into an instant
	# EOF, so such a child declines and exits instead of hanging.
	# Reopening STDIN is the point, not `local *STDIN`: the child inherits the
	# descriptor, and only reopening the handle perl holds on fd 0 -- which frees
	# fd 0 and so reclaims it as the lowest available -- puts /dev/null there.
	require File::Spec;
	my $saved_stdin;
	open $saved_stdin, '<&', \*STDIN or die "cannot save STDIN: $!"
		if defined fileno STDIN;   # a caller may legitimately have closed it
	open STDIN, '<', File::Spec->devnull or die "cannot reopen STDIN on devnull: $!";
	# An explicit sub{} rather than capture { ... }: the prototype that makes
	# the block form legal is not visible at compile time under a runtime
	# require, so perl would try to parse the block as an anonymous hash.
	my ($stdout, $stderr, $exit) = Capture::Tiny::capture(sub {
		system( $cmd )
	});
	if (defined $saved_stdin) {
		open STDIN, '<&', $saved_stdin or die "cannot restore STDIN: $!";
	} else {
		close STDIN;
	}
	if (($die == 1) && ($exit != 0)) {
		say STDERR "exit = $exit";
		say STDERR "STDOUT = $stdout";
		say STDERR "STDERR = $stderr";
		die "$cmd\n failed";
	}
	if ($return eq 'exit') {
		return $exit
	} elsif ($return eq 'stderr') {
		chomp $stderr;
		return $stderr
	} elsif ($return eq 'stdout') {
		chomp $stdout;
		return $stdout
	} elsif ($return eq 'all') {
		chomp $stdout;
		chomp $stderr;
		return {
			exit   => $exit,
			stdout => $stdout,
			stderr => $stderr
		}
	} else {
		die "$return broke pigeonholes"
	}
	return $stdout
}

sub file2string ($file) {
	open my $fh, '<', $file or die "can't read $file: $!"; # was autodie
	return do { local $/; <$fh> };
}

sub format_commas ($n, $format = '.%02d') { # https://stackoverflow.com/questions/33442240/perl-printf-to-use-commas-as-thousands-separator
# $format should be '%.0u' for integers
	my $neg = $n < 0;
	my $abs = abs $n;
	my $int = int $abs;
	# int(100 * (.005 + frac)) is the original expression, and is exactly
	# round-half-up to hundredths -- .005 * 100 is the +0.5 before truncation.
	# It is kept verbatim so no already-correct result shifts by a cent.
	my $cents = int(100 * (.005 + ($abs - $int)));
	# ...but it can land on 100 (.999 rounds up to 1.00), which used to be
	# printed straight into the fraction: 999999.999 came out "999,999.100".
	# The carry has to go into the integer part instead.
	if ($cents >= 100) {
		$int++;
		$cents -= 100;
	}
	# Split off the sign and work on the magnitude: the old code fed a negative
	# through int()/sprintf and produced "-1,234.-49" for -1234.5, and lost the
	# sign entirely for -0.5.  A value that rounds to zero stays unsigned, so
	# -0.001 is "0.00" rather than "-0.00".
	my $sign = ($neg && ($int || $cents)) ? '-' : '';
	# '%.0f' rather than interpolating $int: a large magnitude stringifies in
	# scientific notation, and the reverse/unpack grouping shredded that into
	# "1e,+20" for 1e20.
	my $digits = sprintf '%.0f', $int;
	return $sign . reverse(join(',', unpack('(A3)*', reverse $digits))) . sprintf($format, $cents);
}

sub json_file_to_ref ($json_filename) {
	die "$json_filename doesn't exist or isn't a file" unless -f $json_filename;
	die "$json_filename has 0 size" if -s $json_filename == 0;
	open my $fh, '<:raw', $json_filename or die "can't read $json_filename: $!";
	my $json = do { local $/; <$fh> }; # slurp; $/ restored immediately
	close $fh;
	# Python/NumPy emit bare NaN / Infinity / -Infinity, which are not valid
	# JSON. Rewrite them to null (-> undef) only when they sit in JSON value
	# position (after '[', ',' or ':'), so literal "NaN" inside strings is safe.
	$json =~ s/[\[,:]\s*\K-?(?:NaN|Infinity)(?=\s*[,\]}])/null/g;
	require JSON::MaybeXS; # ~4.3 ms
	return JSON::MaybeXS::decode_json($json);
}

# These return *some* key/value from the hash, not a random one -- whichever
# pair the hash's internal iterator yields first.
#
# They used to be `foreach my $key (keys %{$hash}) { return $key }`, which is
# O(n): `keys` in list context materializes EVERY key into a temporary list,
# and then the loop throws all but the first away.  On a 50,000-key hash that
# was 1.48 ms per call; via each() it is 0.15 us, ~10,000x faster.
#
# The bare `keys` in void context resets the iterator, so repeated calls keep
# returning the first pair instead of walking off the end of the hash.  That
# is the same side effect the old `keys`-in-list-context version had, so a
# caller in the middle of its own each() loop is no worse off than before.
#
# Falling off a foreach also returned '' rather than undef in scalar context;
# each() on an empty hash returns an empty list, so these now yield a true
# undef, which is what t/random.t always asserted.
sub random_key ($hash) {
	keys %{ $hash };                 # reset the iterator
	my ($key) = each %{ $hash };
	return $key;
}

sub random_value ($hash) {
	keys %{ $hash };                 # reset the iterator
	my (undef, $value) = each %{ $hash };
	return $value;
}

sub ref_to_json_file ($ref, $json_filename) {
	my $ref_json_filename = ref $json_filename;
	unless ($ref_json_filename eq '') {
		die "$json_filename isn't a scalar/string";
	}
	require JSON::MaybeXS;
	require Term::ANSIColor;
	open my $fh, '>:raw', $json_filename   # Write it unmangled
		or die "can't write $json_filename: $!"; # was autodie
	say $fh JSON::MaybeXS::encode_json($ref);
	say 'Wrote ' . Term::ANSIColor::colored(['blue on_red'], $json_filename);
	return $json_filename;
}

# ----------------------------------------------------------------------------
# structure(): print the *shape* of a data structure instead of its values.
#
# p() from Data::Printer shows you every value; when a 50,000-element array
# holds the same kind of record over and over, that is the wrong tool.  This
# merges all elements of an array into ONE representative node, so you see the
# schema once.  Keys absent from some of the merged records are flagged '?';
# values that disagree about their type become a UNION.
#
# Two entry points, mirroring DDP's own p()/np() split:
#   st()        - prototyped, so `st %hash` works like `p %hash`.  Use this
#                 interactively.
#   structure() - plain sub, takes a reference: structure(\%hash), or the
#                 return value of another call.  Use this from other code.
#
# Scalar::Util and Term::ANSIColor are require'd in structure(), which st()
# also funnels through, so the per-value helpers below can call them fully
# qualified without re-checking %INC on every node.

my %STRUCTURE_COLOR = (
	key    => 'bold',            # hash key names
	opt    => 'red',             # the '?' optional marker
	HASH   => 'bold cyan',
	ARRAY  => 'bold yellow',
	UNION  => 'bold magenta',
	elem   => 'bright_black',    # the '[*]' / '<alt>' / '(empty)' markers
	class  => 'bold white',      # blessed package names
	number => 'green',
	string => 'bright_blue',
	bool   => 'bright_magenta',
	null   => 'bright_black',
	CODE   => 'yellow',
	other  => 'red',             # anything unexpected
);

sub _structure_color ($name, $text, $use_color) {
	return $text unless $use_color;
	return Term::ANSIColor::colored([$STRUCTURE_COLOR{$name} // $STRUCTURE_COLOR{other}], $text);
}

# Classify one value.  Blessed containers keep their package name so that
# Foo=HASH and a plain HASH don't get merged into the same node.
sub _structure_kind ($v) {
	return 'null' unless defined $v;
	my $r = ref $v;
	return (Scalar::Util::looks_like_number($v) ? 'number' : 'string') if $r eq '';
	if (my $class = Scalar::Util::blessed($v)) {
		return 'bool' if $class eq 'JSON::PP::Boolean' || $class eq 'Types::Serialiser::Boolean';
		return 'Regexp' if $class eq 'Regexp';
		my $rt = Scalar::Util::reftype($v) // '';
		return "$class=$rt" if $rt eq 'HASH' || $rt eq 'ARRAY' || $rt eq 'SCALAR' || $rt eq 'REF';
		return $class;
	}
	return $r; # HASH ARRAY SCALAR REF CODE GLOB
}

# Merge a list of same-position values into a single structural node:
#   { kind => 'hash',  keys => { k => { node => .., optional => 0|1 } }, n, class }
#   { kind => 'array', node => .., n => #instances, lens => [lengths], class }
#   { kind => 'sref',  node => .. }                       # \$x and \\$x
#   { kind => 'leaf',  types => { typename => 1, ... } }
#   { kind => 'union', alts => { kindname => node } }
# $stack holds the refaddrs of the containers we are currently inside, so a
# self-referential structure terminates instead of recursing forever.
sub _structure_describe ($values, $opt, $depth, $stack) {
	my %by_kind;
	push @{ $by_kind{ _structure_kind($_) } }, $_ for @{ $values };
	my @kinds = sort keys %by_kind;

	if (@kinds > 1) {
		return {
			kind => 'union',
			alts => { map { $_ => _structure_describe($by_kind{$_}, $opt, $depth, $stack) } @kinds },
		};
	}
	my $k = $kinds[0] // 'null';
	my ($class, $reftype) = $k =~ /\A(.+)=(HASH|ARRAY|SCALAR|REF)\z/;
	$reftype //= $k;

	if ($reftype eq 'HASH' || $reftype eq 'ARRAY' || $reftype eq 'SCALAR' || $reftype eq 'REF') {
		# Drop anything we're already inside: its shape is an ancestor's shape.
		my @fresh = grep { !$stack->{ Scalar::Util::refaddr($_) } } @{ $values };
		return { kind => 'leaf', types => { '(cycle)' => 1 } } unless @fresh;
		if ($opt->{max_depth} && $depth >= $opt->{max_depth}) {
			return { kind => 'leaf', types => { '(...)' => 1 } };
		}
		local @{ $stack }{ map { Scalar::Util::refaddr($_) } @fresh } = (1) x @fresh;

		if ($reftype eq 'HASH') {
			my %keys; # key => { vals => [...], seen => n }
			for my $h (@fresh) {
				for my $key (keys %{ $h }) {
					push @{ $keys{$key}{vals} }, $h->{$key};
					$keys{$key}{seen}++;
				}
			}
			# A wide hash used as a dictionary has no interesting key names:
			# merge every value into one representative entry instead.
			if ($opt->{hash_max} && keys %keys > $opt->{hash_max}) {
				my @all = map { @{ $keys{$_}{vals} } } keys %keys;
				return {
					kind  => 'hash',
					class => $class,
					n     => scalar @fresh,
					wide  => scalar keys %keys,
					keys  => { '*' => {
						node     => _structure_describe(\@all, $opt, $depth + 1, $stack),
						optional => 0,
					}},
				};
			}
			my %out;
			for my $key (keys %keys) {
				$out{$key} = {
					node     => _structure_describe($keys{$key}{vals}, $opt, $depth + 1, $stack),
					optional => ($keys{$key}{seen} < @fresh ? 1 : 0),
				};
			}
			return { kind => 'hash', class => $class, n => scalar @fresh, keys => \%out };
		}
		elsif ($reftype eq 'ARRAY') {
			my (@elems, @lens);
			for my $a (@fresh) {
				push @lens,  scalar @{ $a };
				push @elems, @{ $a };
			}
			return {
				kind  => 'array',
				class => $class,
				node  => (@elems ? _structure_describe(\@elems, $opt, $depth + 1, $stack) : undef),
				n     => scalar @fresh,
				lens  => \@lens,
			};
		}
		return { # SCALAR / REF
			kind  => 'sref',
			class => $class,
			node  => _structure_describe([map { ${ $_ } } @fresh], $opt, $depth + 1, $stack),
		};
	}
	return { kind => 'leaf', types => { $k => 1 } };
}

sub _structure_array_desc ($node, $c) {
	my @lens = @{ $node->{lens} };
	my ($min, $max) = ($lens[0], $lens[0]);
	for (@lens) { $min = $_ if $_ < $min; $max = $_ if $_ > $max }
	my $range = $min == $max ? $min : "$min-$max";
	my $out = $c->('ARRAY', "ARRAY[$range]");
	$out .= " (from $node->{n} instances)" if $node->{n} > 1;
	return $out;
}

sub _structure_render ($label, $node, $indent, $opt, $c, $lines) {
	my $pad = ('    ' x $indent) . ($label // '');
	my $class = defined $node->{class} ? $c->('class', "$node->{class}=") : '';

	if ($node->{kind} eq 'hash') {
		my @k = sort keys %{ $node->{keys} };
		my $count = $node->{wide} // scalar @k;
		push @{ $lines }, $pad . $class . $c->('HASH', "HASH{$count}")
			. ($node->{n} > 1 ? " (from $node->{n} instances)" : '')
			. ($node->{wide} ? ' ' . $c->('elem', '(keys merged)') : '');
		for my $key (@k) {
			my $entry = $node->{keys}{$key};
			my $name  = ($key eq '*' && $node->{wide})
				? $c->('elem', '<*>') . ': '
				: $c->('key', $key) . ($entry->{optional} ? $c->('opt', '?') : '') . ': ';
			_structure_render($name, $entry->{node}, $indent + 1, $opt, $c, $lines);
		}
	}
	elsif ($node->{kind} eq 'array') {
		push @{ $lines }, $pad . $class . _structure_array_desc($node, $c);
		if ($node->{node}) {
			_structure_render($c->('elem', '[*]') . ': ', $node->{node}, $indent + 1, $opt, $c, $lines);
		} else {
			push @{ $lines }, ('    ' x ($indent + 1)) . $c->('elem', '(empty)');
		}
	}
	elsif ($node->{kind} eq 'sref') { # \$x: stay on the same line, no extra indent level
		_structure_render($pad . $class . $c->('elem', '\\') . ' ', $node->{node}, 0, $opt, $c, $lines);
	}
	elsif ($node->{kind} eq 'union') {
		push @{ $lines }, $pad . $c->('UNION', 'UNION');
		for my $alt (sort keys %{ $node->{alts} }) {
			_structure_render($c->('elem', "<$alt>") . ' ', $node->{alts}{$alt}, $indent + 1, $opt, $c, $lines);
		}
	}
	else { # leaf
		push @{ $lines }, $pad . join($c->('elem', '|'),
			map { $c->($_, $_) } sort keys %{ $node->{types} });
	}
	return;
}

sub structure ($ref, %args) {
	my %opt = (
		output    => 'stdout', # 'stdout' | 'stderr' | 'string' (string: return it, print nothing)
		color     => 'auto',   # 'auto' | 1 | 0
		max_depth => 0,        # 0 = unlimited
		hash_max  => 32,       # hashes wider than this collapse to one '<*>' entry; 0 = never
		as        => undef,    # optional header line, like DDP's "as"
		%args,
	);
	my %allowed = map { $_ => 1 } qw(output color max_depth hash_max as);
	if (my @bad = grep { !$allowed{$_} } keys %opt) {
		die "Unrecognized arguments: @bad\nAccepted args: " . join(', ', sort keys %allowed);
	}
	die "output must be one of stdout, stderr, string" if $opt{output} !~ m/\A(stdout|stderr|string)\z/;

	require Scalar::Util; # ~4 ms (List::Util XS bootstrap); see header note

	my $fh = $opt{output} eq 'stderr' ? \*STDERR : \*STDOUT;
	my $use_color = $opt{color} eq 'auto'
		? ((($ENV{CLICOLOR_FORCE} || ($opt{output} ne 'string' && -t $fh)) && !$ENV{NO_COLOR}) ? 1 : 0)
		: $opt{color};
	require Term::ANSIColor if $use_color; # ~0.8 ms, skipped entirely when piping
	my $c = sub ($name, $text) { _structure_color($name, $text, $use_color) };

	my @lines;
	push @lines, $c->('key', $opt{as}) if defined $opt{as};
	_structure_render(undef, _structure_describe([$ref], \%opt, 0, {}), 0, \%opt, $c, \@lines);
	my $out = join("\n", @lines) . "\n";
	print {$fh} $out unless $opt{output} eq 'string';
	return $out;
}

# st(): structure() with DDP's calling convention, so you can write
#
#   st %hash;   st @array;   st $ref;   st %hash, max_depth => 2;
#
# instead of backslashing by hand.  The \[@$%&] prototype makes perl pass a
# reference to the caller's variable, which is the whole trick -- but it also
# means the argument must BE a variable: st(\%h), st({...}) and
# st(func()) are compile-time errors, exactly as they are for DDP's p().
# Call structure() directly in those cases.
#
# NOTE: the obvious short name 's' is impossible.  perl's tokenizer resolves a
# bare 's' to the substitution operator before it ever looks for a sub of that
# name, so `s $ref` dies with "Substitution pattern not terminated" and even
# `s($ref)` is parsed as s(pat)(repl).  Only `&s($ref)` would work, which
# defeats the point.  Hence 'st'.
#
# :prototype() attribute rather than a bare (\[@$%&];%) signature-position
# prototype: under `use 5.044` signatures are enabled, so that slot is a
# signature and the prototype has to move into an attribute.
sub st :prototype(\[@$%&];%) ($item, @args) {
	# `st %h` / `st @a` / `st &c` hand us the HASH/ARRAY/CODE ref directly, but
	# `st $x` hands us a ref to the scalar $x -- one layer more than we want.
	# The prototype rejects everything except a plain variable, so a SCALAR/REF
	# here is always that added layer: peel exactly one.  `st $hashref` then
	# describes the hash, and `my $x = 42; st $x` prints 'number', not '\ number'.
	my $ref = (ref($item) eq 'SCALAR' || ref($item) eq 'REF') ? ${ $item } : $item;
	return structure($ref, @args);
}

1;
