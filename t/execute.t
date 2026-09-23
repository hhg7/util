#!/usr/bin/env perl
# execute(): run a shell command, returning exit code, stdout, stderr, or all.
use 5.044;
use warnings FATAL => 'all';
use FindBin;
use lib "$FindBin::Bin/..";
use Test::More;
use Test::Exception;
use Capture::Tiny 'capture';
use Util;

is( execute('true'),                0,       'exit code of a passing command' );
is( execute('echo hello', 'stdout'), 'hello', 'stdout is captured and chomped' );
is( execute('echo oops 1>&2', 'stderr'), 'oops', 'stderr is captured and chomped' );

my $all = execute('echo out; echo err 1>&2', 'all');
is( ref $all, 'HASH', 'return => all yields a hashref' );
is( $all->{stdout}, 'out', 'all: stdout field' );
is( $all->{stderr}, 'err', 'all: stderr field' );
is( $all->{exit},   0,     'all: exit field' );

# A failing command with $die disabled returns the raw wait-status ($?),
# which for exit(1) is 256 (1 << 8).
my $code;
capture { $code = execute('false', 'exit', 0) };
is( $code, 256, 'non-zero command with die disabled returns raw wait status' );

# $die defaults to 1: a failing command is fatal.
throws_ok { capture { execute('false') } } qr/failed/,
	'failing command dies by default';

# Invalid $return value is rejected up front.
throws_ok { execute('true', 'nonsense') }
	qr/only accepts/, 'rejects an unknown return mode';

done_testing;
