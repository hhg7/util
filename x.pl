#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Util 'file2string';
use List::MoreUtils 'first_index';

sub insert_file_into_another {
#
# this sub inserts some lines from a donating file into a receiving file
#
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ filename => 'blah.xlsx' })\"";
	}
	my @reqd_args = (
		'donating.file',      # file that donates text
		'receiving.file',     # file that receives text
		'donate.start.str',   # line in donating file that starts text
		'receiving.start.str' # 
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		'destination.file',  # by default, $args->{'receiving.file'}
		'donate.end.str',    # the string in the donating  file indicating end of saving lines
		'receiving.end.str', # the string in the receiving file indicating end of saving lines
		'substitute'         # an array of text substitutions to do
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my @missing_files = grep {not -f $args->{$_}} ('donating.file', 'receiving.file');
	if (scalar @missing_files > 0) {
		p $args;
		say STDERR 'the above args have these files missing:';
		p @missing_files;
		die 'the above files are missing';
	}
	my $file = file2string($args->{'donating.file'});
	my @donating_file = split /\n/, $file;
	my $start_idx = first_index {$_ eq $args->{'donate.start.str'}} @donating_file;
	if ($start_idx == -1) {
		die "Couldn't find start line in $args->{'donating.file'}";
	}
	my $end_idx = scalar @donating_file - 1; # 'donate.end.str' gets priority
	if (defined $args->{'donate.end.str'}) {
		$end_idx = first_index {$_ eq $args->{'donate.end.str'}} @donating_file;
	}
	die "Couldn't get end string = \"$args->{'donate.end.str'}\"" if $end_idx == -1;
	if ($end_idx <= $start_idx) {
		die "$args->{'donating.file'}: \$end_idx = $end_idx <= \$start_idx = $start_idx";
	}
	@donating_file = @donating_file[$start_idx+1..$end_idx-1]; # take the lines that are needed
	foreach my $sub (@{ $args->{substitute} }) {
		foreach my $line (@donating_file) {
			$line =~ s/$sub->[0]/$sub->[1]/;
		}
	}
	if (scalar @donating_file == 0) {
		p $args;
		die "there were 0 lines to save from $args->{'donating.file'}";
	}
	$file = file2string($args->{'receiving.file'});
	my @receiving_file = split /\n/, $file;
	$start_idx = first_index {$_ eq $args->{'receiving.start.str'}} @receiving_file;
	if ($start_idx == -1) {
		die "Couldn't find start line in $args->{'receiving.start.str'}";
	}
	$end_idx = scalar @receiving_file - 1;
	if (defined $args->{'receiving.end.str'}) {
		$end_idx = first_index {$_ eq $args->{'receiving.end.str'}} @receiving_file;
	}
	if ($end_idx == -1) {
		die "\"$args->{'donate.end.str'}\" wasn't found in \"$args->{'receiving.file'}\"";
	}
	if ($end_idx <= $start_idx) {
		die "$args->{'receiving.file'}: \$end_idx = $end_idx <= \$start_idx = $start_idx";
	}
	# remove the lines that are supposed to be removed; insert @donating_file
	splice @receiving_file, $start_idx + 1, $end_idx - $start_idx - 1, @donating_file;
	$args->{'destination.file'} = 
	open my $fh, '>', $args->{'receiving.file'};
	say $fh join ("\n", @receiving_file);
	return 1;
}
insert_file_into_another({ # pathfinder
	'donating.file'       => 'donate.file.txt',
	'donate.start.str'    => '# πατερ ημων ο εν τοις ουρανοις, ἁγιασθήτω τὸ ὄνομά σου',
	'donate.end.str'      => '# Λέγω οὖν, μὴ ἀπώσατο ὁ θεὸς',
	'receiving.file'      => 'receiving.file.txt',
	'receiving.start.str' => '# Λέγω οὖν, μὴ ἀπώσατο ὁ θεὸς',
	'receiving.end.str'   => '# σὺ δὲ τῇ πίστει ἕστηκας. μὴ ὑψηλὰ φρόνει, ἀλλὰ φοβοῦ'
});
