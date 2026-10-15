#!/usr/bin/env perl
# Regenerate the POD at the end of lib/Util/Con.pm from README.md, then check
# that POD and the Changes file.  Run from the root of the repository, before
# anything is built (dzil.sh does this first):
#
#	perl md2pod.pl
#
# Everything after the "# from md2pod.pl" line of the module is replaced, so
# edit README.md, not the POD.  Taken from Matplotlib-Simple's md2pod.pl,
# without the part that copies examples into its test suite.  It is author
# tooling and is not shipped, so it uses modern perl and declares nothing.

use 5.044;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Devel::Confess 'color';
use Markdown::To::POD 'markdown_to_pod';
use HTML::Table;
use List::MoreUtils 'first_index';
use Test::More;
use Test::Pod;
use Test::CPAN::Changes;

sub file2string ($file) {
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}

# Markdown::To::POD's list-detection regex has no blank line requirement before
# a following heading, so a heading glued straight onto a list (no blank line
# between them) gets swallowed into the final list item: the "=headN" is then
# emitted *inside* the "=over", and the list's "=back" lands after it
# ("You forgot a '=back' before '=headN'", "=back without =over"). This is a
# parse-time failure, so it must be repaired in the Markdown before conversion.
#
# Guarantee a blank line before every heading (ATX "# X" and Setext "X" over a
# row of "=" or "-"). The "\S" mirrors the converter's own header regex (header
# text required, so a bare "###" is left alone). Fenced code regions are
# skipped so "# comment" lines inside them are untouched. GFM table separators
# never match the Setext underline test because they contain pipes.
sub ensure_blank_before_headings ($text) {
	my @lines = split /\n/, $text, -1;
	my @out;
	my $in_fence = 0;
	foreach my $j (0..$#lines) {
		my $ln = $lines[$j];
		$in_fence = !$in_fence if $ln =~ m/^[ \t]*(?:```|~~~)/;
		my $is_atx = !$in_fence && $ln =~ m/^\#{1,6}[ \t]*\S/;
		my $is_setext = !$in_fence && $ln =~ m/\S/
			&& $j < $#lines && $lines[$j+1] =~ m/^[ \t]*(?:=+|-+)[ \t]*$/;
		push @out, ''
			if ($is_atx || $is_setext) && scalar @out > 0 && $out[-1] ne '';
		push @out, $ln;
	}
	return join "\n", @out;
}

# Markdown::To::POD emits a nested list's "=over" directly after the parent
# "=item" line with no blank line between them. POD requires a blank line
# before every command paragraph, so without it the "=over" is absorbed into
# the item's text rather than opening a list; the matching inner "=back" then
# closes the *outer* list, orphaning later "=item"/"=back" directives
# ("'=item' outside of any '=over'", "=back without =over").
#
# Repair by guaranteeing a blank line before every POD command paragraph.
# "=begin X" / "=end X" data blocks are copied verbatim so their raw contents
# are never rewritten.
sub fix_pod_command_spacing ($pod) {
	my @in = split /\n/, $pod, -1;
	my @out;
	my $in_data = 0;
	foreach my $cmd_line (@in) {
		if ($in_data) {
			push @out, $cmd_line;
			$in_data = 0 if $cmd_line =~ m/^=end\b/;
			next;
		}
		if ($cmd_line =~ m/^=\w+/) {
			# a command paragraph must be preceded by a blank line
			push @out, '' if scalar @out > 0 && $out[-1] ne '';
			push @out, $cmd_line;
			$in_data = 1 if $cmd_line =~ m/^=begin\b/;
		} else {
			push @out, $cmd_line;
		}
	}
	return join "\n", @out;
}

# Guarantee balanced =over/=back. Even with the blank-line repairs above, the
# converter can emit a heading while a list is still open (e.g. a Setext-
# underlined heading, or any heading the pre-processor's normalization missed),
# leaving the matching =back stranded after the heading. Close any list still
# open when a heading / =cut / end-of-file is reached, and drop any =back that
# has no open =over. "=begin X" / "=end X" data blocks are passed through
# verbatim so their contents are never miscounted.
sub balance_pod_over_back ($pod) {
	my @in = split /\n/, $pod, -1;
	my @out;
	my $depth = 0;
	my $in_data = 0;
	foreach my $bal_line (@in) {
		if ($in_data) {
			push @out, $bal_line;
			$in_data = 0 if $bal_line =~ m/^=end\b/;
			next;
		}
		if ($bal_line =~ m/^=begin\b/) {
			push @out, $bal_line;
			$in_data = 1;
			next;
		}
		if ($bal_line =~ m/^=over\b/) {
			$depth++;
			push @out, $bal_line;
			next;
		}
		if ($bal_line =~ m/^=back\b/) {
			# drop a =back that has no matching open =over
			if ($depth > 0) {
				$depth--;
				push @out, $bal_line;
			}
			next;
		}
		if ($bal_line =~ m/^=(?:head\d+|cut|pod|encoding)\b/) {
			while ($depth > 0) {
				push @out, '', '=back';
				$depth--;
			}
			push @out, '' if scalar @out > 0 && $out[-1] ne '';
			push @out, $bal_line;
			next;
		}
		push @out, $bal_line;
	}
	while ($depth > 0) {
		push @out, '', '=back';
		$depth--;
	}
	return join "\n", @out;
}

my $md = file2string('README.md');
# Ensure headings are separated from preceding blocks so the converter's list
# detection terminates correctly before them
$md = ensure_blank_before_headings($md);
my @md = split /\n/, $md;
my @idx = grep {$md[$_] =~ m/\|.+\|/} 0..$#md; # indices with tables
my @table_end = grep {
	($idx[$_+1] - $idx[$_]) > 1
	} 0..$#idx-1; # get table ends
# README.md need not have a table at all: Util-Con's has none, because a table
# reaches the POD only as "=for html" and so vanishes from perldoc in a
# terminal.  With none, there is nothing to start or end.
my @table_start = @idx ? (0, map {$_ + 1} @table_end) : ();
push @table_end, $#idx if @idx; # assume that last index is the end of a table (it should be)
foreach my ($table_i, $table_start) (indexed reverse @table_start) {
	my @md_table = @md[@idx[$table_start..$table_end[$table_i]]];
	splice @md, $idx[$table_start], scalar @md_table; # remove the original MD code
	my @table;
	foreach my $line (@md_table) {
		# Only the empty cells outside the outer pipes are dropped.  Dropping
		# every empty cell moved every cell after an empty one a column left.
		( my $row = $line ) =~ s/^\h*\|//;
		$row =~ s/\|\h*$//;
		push @table, [ map { s/^\h+|\h+$//gr } split /\|/, $row, -1 ];
	}
	my $t =  HTML::Table->new(-data => \@table);
	my $table = $t->getTable;
	@table = grep {$_ ne ''} split /\n/, $table;
	foreach my $line (@table) {
		$line =~ s/`([^`]+)`/\<code\>$1\<\/code\>/g;
	}
	splice @md, $idx[$table_start], 0, @table; # insert the HTML code
}
$md = join ("\n", @md);
my $pod = markdown_to_pod($md);
my @pod = split /\n/, $pod;

# get table start and end indices
foreach my $i ( grep {$pod[$_] =~ /^<img\h/} reverse 0..$#pod) {
	next if $pod[$i-1] eq '<p>' eq $pod[$i+1]; # html paragraph
	splice @pod, $i+1, 0, '<p>', ''; # end
	splice @pod, $i, 0, '', '=for html', '<p>',; # start
}
foreach my $i (grep {$pod[$_] eq '<table>'} reverse 0..$#pod) {
	splice @pod, $i, 0, '=for html';
}
unshift @pod, "=encoding utf8\n";

# Repair command-paragraph spacing so nested lists stay balanced POD, then
# close any list left open across a heading and drop stray =back directives
$pod = fix_pod_command_spacing(join "\n", @pod);
$pod = balance_pod_over_back($pod);
@pod = split /\n/, $pod;

# An "=item" outside of any list is a POD error Test::Pod reports, and it can
# only come from the converter, so wrap any orphan in its own list
my $over_depth = 0;
my @fixed_pod;
foreach my $line (@pod) {
	if ($line =~ m/^=over\b/) {
		$over_depth++;
	} elsif ($line =~ m/^=back\b/) {
		$over_depth-- if $over_depth > 0;
	} elsif (($line =~ m/^=item\b/) && ($over_depth == 0)) {
		push @fixed_pod, '' if scalar @fixed_pod > 0 && $fixed_pod[-1] ne '';
		push @fixed_pod, '=over 4', '';
		$over_depth++;
	}
	push @fixed_pod, $line;
}
while ($over_depth > 0) { # close out any block that the wrapping above opened
	push @fixed_pod, '' if scalar @fixed_pod > 0 && $fixed_pod[-1] ne '';
	push @fixed_pod, '=back', '';
	$over_depth--;
}
@pod = @fixed_pod;

my $lib = file2string('lib/Util/Con.pm');
my @lib = split /\n/, $lib;
my $line = first_index {$_ eq '# from md2pod.pl πατερ ημων ο εν τοις ουρανοις, ἁγιασθήτω τὸ ὄνομά σου'} @lib;
if ($line == -1) {
	die 'Could not find correct line index';
}
# Keep everything up to and including the marker line, and drop what follows.
# Matplotlib-Simple's copy spliced at the negative offset 1-(@lib - $line),
# which is 0 -- everything -- when the marker is the last line, as it is
# before the first run; that run emptied lib/Util/Con.pm of its code.
splice @lib, $line + 1;
push @lib, @pod; # add properly formatted POD text
open my $fh, '>', 'lib/Util/Con.pm';
say $fh join ("\n", @lib);
close $fh;

pod_file_ok( 'lib/Util/Con.pm' );

changes_file_ok('Changes'); # hand-maintained; never generated from README.md
done_testing();
