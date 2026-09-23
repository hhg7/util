#!/usr/bin/env perl
# file2string(): slurp a whole file into one scalar.
use 5.044;
use warnings FATAL => 'all';
use FindBin;
use lib "$FindBin::Bin/..";
use Test::More;
use Test::Exception;
use File::Temp 'tempfile';
use Util;

my ($fh, $path) = tempfile( UNLINK => 1 );
print $fh "line1\nline2\nno-final-newline-either";
close $fh;

my $content = file2string($path);
is( $content, "line1\nline2\nno-final-newline-either",
	'slurps the entire file including embedded newlines' );

# Empty file slurps to an empty string.
my ($efh, $epath) = tempfile( UNLINK => 1 );
close $efh;
is( file2string($epath), '', 'empty file yields empty string' );

# autodie makes a missing file fatal.
throws_ok { file2string('/no/such/file/at/all') }
	qr/(No such file|open)/i, 'missing file is fatal (autodie)';

done_testing;
