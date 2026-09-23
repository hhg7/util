#!/usr/bin/env perl
# Compile-load the module and confirm every advertised symbol is exported.
use 5.044;
use warnings FATAL => 'all';
use FindBin;
use lib "$FindBin::Bin/..";
use Test::More;

BEGIN { use_ok('Util') or BAIL_OUT('Util.pm failed to compile') }

my @exported = qw(
	dir execute file2string format_commas
	json_file_to_ref random_key random_value ref_to_json_file
	st structure
);

for my $sym (@exported) {
	ok( main->can($sym), "exported: $sym" );
}

# @EXPORT and this list must not drift apart in either direction.
is_deeply( [sort @Util::EXPORT], [sort @exported],
	'@EXPORT matches the list checked above' );

# p() and np() are installed into main:: by Util.pm as lazy stubs that pull in
# DDP on first call, so scripts get them without a `use DDP` of their own.
ok( main->can('p'),  'p() is available in main::' );
ok( main->can('np'), 'np() is available in main::' );
ok( !$INC{'DDP.pm'}, 'DDP is not loaded until p()/np() is actually called' );

done_testing;
