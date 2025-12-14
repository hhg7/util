use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
package Util;
use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Cwd 'getcwd';
use Scalar::Util 'looks_like_number';
use File::Find 'find';
use Cwd 'getcwd';
use File::Temp 'tempfile';
use FindBin '$RealScript';
use List::Util qw(min max sum);
use Capture::Tiny 'capture';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use JSON qw(encode_json decode_json);
use autodie ':default';
use Exporter 'import';
use File::Copy 'cp';
use POSIX 'lgamma';
use Term::ANSIColor;
# density_scatterplot
our @EXPORT = qw(average_pre_rec_plot average_roc_plot dir execute file2string format_commas get_sample_ID json_file_to_ref list_regex_files num_arrays_equal pvalue plot p_adjust rand_between random_key random_value read_table ref_to_json_file venn venn_proportional_area workbook_to_hash worksheet_to_hash);

sub make_colormap {
=example

returns an image filename that has a range of values, and the RGB colors that match those values

my $colormap = make_colormap({
	min						=> -1,
	max						=> 1,
	colorbar_image_file	=> $colorbar_svg,
	units						=> 'ϕ',
});
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'colormap',				# JSON file or hash
		'min', 'max', 'step'	# like a C-style for loop
	);
	my @defined_args = ( @reqd_args,
		'colorbar_image_file',	# an image to show the scale
		'units'						# what unit is this colorbar representing?
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args, array_max => scalar @defined_args;
		die 'The above args are accepted.'
	}
	my $map;
	if (defined $args->{colorbar_image_file}) {
# https://matplotlib.org/stable/users/explain/colors/colorbar_only.html
		my $unlink = 0;
		my ($py, $tmp_file) = tempfile(DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink);
		say $tmp_file if $unlink == 0;
		say $py 'import matplotlib.pyplot as plt';
		say $py 'import matplotlib as mpl';
		say $py 'fig, ax = plt.subplots(figsize=(6, 1), layout="constrained")';
		say $py 'cmap = mpl.cm.gist_rainbow';
		say $py "norm = mpl.colors.Normalize(vmin=$args->{min}, vmax=$args->{max})";
		say $py "fig.colorbar(mpl.cm.ScalarMappable(norm=norm, cmap=cmap), cax=ax, orientation='horizontal', label='$args->{units}')";
		say $py "plt.savefig('$args->{colorbar_image_file}', bbox_inches='tight', pad_inches = 0.1, metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
		my ($stdout, $stderr, $exit) = capture {
			system( "python3 $tmp_file" );
		};
		if ($exit != 0) {
			say "exit = $exit";
			say "STDOUT = $stdout";
			say "STDERR = $stderr";
			die 'failed'
		}
		say 'wrote ' . colored(['black on_bright_yellow'], $args->{colorbar_image_file});
	}
	return $args->{colorbar_image_file};
}

sub average_pre_rec_plot {
# https://stats.stackexchange.com/questions/186337/average-roc-for-repeated-10-fold-cross-validation-with-probability-estimates
# this subroutine takes lists of TPR and FPR
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ filename => 'blah.xlsx' })\"";
	}
	my @reqd_args = ('data', 'filename');
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ('color', 'figwidth', 'labelright', 'legend', 'output_type', 'title', 'xlabel', 'ylabel', @reqd_args);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
#---------
	my $unlink = 1;
	my ($fh, $filename) = tempfile (UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say $filename if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'import numpy as np';
	say $fh 'base_y = np.linspace(1, 0, 101)';
	say $fh 'plt.figure()';
	foreach my $group (keys %{ $args->{data} }) {
		my $color = $args->{color}{$group} // 'b';
		say $fh 'ys = []';
		foreach my $run (keys %{ $args->{data}{$group} }) {
			say $fh 'x = [' . join (',', reverse @{ $args->{data}{$group}{$run}[0] }) . ']';
			say $fh 'y = [' . join (',', reverse @{ $args->{data}{$group}{$run}[1] }) . ']';
			say $fh "plt.plot(x, y, '$color', alpha=0.15)";
			say $fh 'y = np.interp(base_y, x, y)';
			say $fh 'ys.append(y)';
		}
		say $fh 'ys = np.array(ys)';
		say $fh 'mean_ys = ys.mean(axis=0)';
		say $fh 'std = ys.std(axis=0)';
		say $fh 'ys_upper = np.minimum(mean_ys + std, 1)';
		say $fh 'ys_lower = mean_ys - std';
		say $fh "plt.plot(base_y, mean_ys, '$color', label = '$group')";
		say $fh "plt.fill_between(base_y, ys_lower, ys_upper, color='$color', alpha=0.3)";
	}
	$args->{output_type} = $args->{output_type} // 'svg';
	say $fh "plt.title('$args->{title}')" if defined $args->{title};
	$args->{xlabel} = $args->{xlabel} // 'Recall = TP/P';
	$args->{ylabel} = $args->{ylabel} // 'Precision = TP / (TP + FP)';
	say $fh "plt.xlabel('$args->{xlabel}')";
	say $fh "plt.ylabel('$args->{ylabel}')";
	$args->{labelright} = $args->{labelright} // 0; # by default, labels on the right side are off
	if ($args->{labelright} > 0) {
		say $fh 'plt.tick_params(labelright = True, right = True, axis = "both", which = "both")';
	}
	my $output_image = "$args->{filename}.$args->{output_type}";
	$args->{legend} = $args->{legend} // 1;
#	say $fh 'fig, ax = plt.subplots()' if $n_group > 0;
#	say $fh 'ax.get_legend().remove()' if $args->{legend} == 0;
	say $fh 'plt.legend()' if $args->{legend} == 1;
	foreach my $arg ('figwidth', 'figheight') {# default figheight = 4.8, figwidth = 6.4 
		say $fh "f.set_$arg($args->{$arg})" if defined $args->{$arg};
	}
	say $fh "plt.savefig('$output_image', bbox_inches='tight', pad_inches = 0.1)";
	close $fh;
	
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die 'failed'
	}
	say "wrote $output_image";
	return $output_image
}

sub average_roc_plot {
# https://stats.stackexchange.com/questions/186337/average-roc-for-repeated-10-fold-cross-validation-with-probability-estimates
# this subroutine takes lists of TPR and FPR

=example data:
	$roc{$key}{$run}[0] = $ml_output->{'FPR points'}; # hash of hash of hash of array (HoHoHoA)
	$roc{$key}{$run}[1] = $ml_output->{'TPR points'};
	
	if multiple graphs are being merged, then "roc" should be set to 0
=cut
	my ($args) = @_;
	my @reqd_args = ('data', 'filename');
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ('color', 'diagonal', 'figwidth', 'labelright', 'legend', 'output_type', 'roc', 'title', 'xlabel', 'xlim', 'ylabel', 'ylim', @reqd_args);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	@undef_args = grep { !defined $args->{$_} } keys %{ $args };
	if (scalar @undef_args > 1) {
		p @undef_args;
		die 'the above args were not defined.';
	}
#---------
	$args->{roc} = $args->{roc} // 1;
	my $unlink = 1;
	my ($fh, $filename) = tempfile(UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say $filename if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	say $fh "import numpy as np\n";
	my $ymax = 1;
	if ($args->{roc} > 0) {
		say $fh "base_fpr = np.linspace(0, 1, 101)\n";
	} else {
# get min & max
		my ($xmin, $xmax) = ('inf', '-inf');
		foreach my $group (keys %{ $args->{data} }) {
			foreach my $run (keys %{ $args->{data}{$group} }) {
				$xmin = min(@{ $args->{data}{$group}{$run}[0] }, $xmin);
				$xmax = max(@{ $args->{data}{$group}{$run}[0] }, $xmax);
				if (scalar @{ $args->{data}{$group}{$run} } != 2) {
					say "\$args->{data}{$group}{$run}";
					p $args->{data}{$group}{$run};
					die 'there should be two arrays of data (x & y)';
				}
				if (grep {not defined} @{ $args->{data}{$group}{$run}[1] }) {
					say "\$args->{data}{$group}{$run}";
					p $args->{data}{$group}{$run};
					die 'undefined values found'
				}
				$ymax  = max($ymax, @{ $args->{data}{$group}{$run}[1] });
			}
		}
		say $fh "base_fpr = np.linspace($xmin, $xmax, 101)";
	}
	say $fh 'plt.figure()';
	foreach my $group (keys %{ $args->{data} }) {
		my $color = $args->{color}{$group} // 'b';
		say $fh 'tprs = []';
		foreach my $run (keys %{ $args->{data}{$group} }) {
			my $nx = scalar @{ $args->{data}{$group}{$run}[0] };
			my $ny = scalar @{ $args->{data}{$group}{$run}[1] };
			if ($nx != $ny) {
				die "there are $nx x points, but $ny y points.  They must be equal."
			}
			say $fh 'fpr = [' . join (',', @{ $args->{data}{$group}{$run}[0] }) . ']';
			say $fh 'tpr = [' . join (',', @{ $args->{data}{$group}{$run}[1] }) . ']';
			say $fh "plt.plot(fpr, tpr, '$color', alpha=0.15)";
			my $n = scalar @{ $args->{data}{$group}{$run}[1] };
			say $fh 'tpr = np.interp(base_fpr, fpr, tpr)';
			say $fh 'tpr[0] = 0.0';
			say $fh 'tprs.append(tpr)';
		}
		say $fh 'tprs = np.array(tprs)';
		say $fh 'mean_tprs = tprs.mean(axis=0)';
		say $fh 'std = tprs.std(axis=0)';
		say $fh "tprs_upper = np.minimum(mean_tprs + std, $ymax)";
		say $fh 'tprs_lower = mean_tprs - std';
		say $fh "plt.plot(base_fpr, mean_tprs, '$color', label = '$group')";
		say $fh "plt.fill_between(base_fpr, tprs_lower, tprs_upper, color='$color', alpha=0.3)";
	}
	$args->{diagonal} = $args->{diagonal} // 1;
	say $fh 'plt.plot([0, 1], [0, 1],"r--")' if $args->{diagonal} > 0; # x = y diagonal line
	$args->{output_type} = $args->{output_type} // 'svg';
	say $fh "plt.title('$args->{title}')" if defined $args->{title};
	$args->{xlabel} = $args->{xlabel} // 'False Positive Rate';
	$args->{ylabel} = $args->{ylabel} // 'True Positive Rate';
	say $fh "plt.xlabel('$args->{xlabel}')";
	say $fh "plt.ylabel('$args->{ylabel}')";
	$args->{labelright} = $args->{labelright} // 0; # by default, labels on the right side are off
	if ($args->{labelright} > 0) {
		say $fh 'plt.tick_params(labelright = True, right = True, axis = "both", which = "both")';
	}
	my $output_image = "$args->{filename}.$args->{output_type}";
	$args->{legend} = $args->{legend} // 1;
#	say $fh 'fig, ax = plt.subplots()' if $n_group > 0;
#	say $fh 'ax.get_legend().remove()' if $args->{legend} == 0;
	say $fh 'plt.legend()' if $args->{legend} == 1;
	foreach my $arg ( grep { defined $args->{$_} } ('figwidth', 'figheight')) {
		say $fh "f.set_$arg($args->{$arg})";
	}
	foreach my $arg (grep { defined $args->{$_} } ('xlim', 'ylim')) {
		say $fh "plt.$arg(" . join (',', @{ $args->{$arg} }) . ')';
	}
	say $fh "plt.savefig('$output_image', bbox_inches='tight', pad_inches = 0.1)";
	close $fh;
	
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die 'failed'
	}
	say "wrote $output_image";
	return $output_image
}

sub dir { # a Perl5 mimic of Perl6/Raku's "dir"
	my %args = ( # default arguments listed below
		tests => 'f', dir => '.', regex   => '.', recursive => 0, @_, # argument pair list goes here
	);
	if ($args{tests} =~ m/[^rwxoRWXOezfdlpSbctugkTB]/){# sMAC returns are non-boolean, and are excluded
		die "There are some unrecognized characters in $args{tests}";
	}
	my @defined_args = ('tests', 'dir', 'regex', 'recursive');
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %args;
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my @items = split '', $args{tests};
	my $tests = '-' . join (' -', @items);
	undef @items;
	$args{regex} = qr/$args{regex}/;
	opendir my $dh, $args{dir};
	while (my $item = readdir $dh) {
		if (($item !~ $args{regex}) or ($item =~ m/^\.{1,2}$/)) { next }
		my $i = "$args{dir}/$item";
		die "\$i isn't defined." if not defined $i;
		my $rv = eval "${tests} \$i" || 0;
		if ($rv == 0) { next }
		if ($args{dir} eq '.') {
			push @items, $item
		} else {
			push @items, $i
		}
	}
	if ($args{recursive} == 1) {
		find({
			wanted => sub {
				if ((eval "${tests} \$_") && ($_ =~ /$args{regex}/)) {
					push @items, $_;
				}
			},
			no_chdir => 1
	 		},
			$args{dir}
		);
		foreach my $item (@items) {
			$item =~ s/^\.\///;
		}
	}
	return @items
}

sub execute ($cmd, $return = 'exit', $die = 1) {
	if ($return !~ m/^(exit|stdout|stderr|all)$/) {
		die "you gave \$return = \"$return\", while this subroutine only accepts ^(exit|stdout|stderr)\$";
	}
	my ($stdout, $stderr, $exit) = capture {
		system( $cmd )
	};
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
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}

sub format_commas ($n, $format = '.%02d') { # https://stackoverflow.com/questions/33442240/perl-printf-to-use-commas-as-thousands-separator
# $format should be '%.0u' for integers
	return reverse(join(",",unpack("(A3)*", reverse int($n)))) . sprintf($format,int(100*(.005+($n - int($n)))));
}

sub get_sample_ID ($vcf_file) {
	if ($vcf_file =~ m/\.gz$/) {
		open my $vcf, "zcat < $vcf_file |"; # "<" is necessary for Macs
		while (<$vcf>) {
	      unless (/^#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t/) {
	         next
	      }
	      chomp;
	      my @line = split /\t/;
	      return @line[9..$#line]
		}
	} elsif ($vcf_file =~ m/\.vcf$/) {
		open my $vcf, '<', $vcf_file;
		while (<$vcf>) {
			unless (/^#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t/) {
				next
			}
			chomp;
			my @line = split /\t/;
			return @line[9..$#line]
		}
	} else {
		die "$vcf_file failed my pigeonholes.";
	}
	die "Couldn't get a sample ID from $vcf_file";
}

sub heatmaps_in_rows {
# this subroutine plots rows of 1D heatmaps
=example
each one of the sets "all", "hosts", and "pathogens" will become a row in the final figure
x axis is indicated by [0]
y axis is indicated by [1]
{
 data       {
     all         [
         [0] [
                 [0] 0,
                 [1] 1,
                 [2] 2,
                     (...skipping 1256 items...)
             ],
         [1] [
                 [0] 0,
                 [1] 0,
                 [2] 0,
                     (...skipping 1256 items...)
             ]
     ],
     hosts       [
         [0] [
                 [0] 0,
                 [1] 1,
                 [2] 2,
                     (...skipping 1256 items...)
             ],
         [1] [
                 [0] 0,
                 [1] 0,
                 [2] 0,
                     (...skipping 1256 items...)
             ]
     ],
 },
 filename   "svg/sneath.0729.colobar.heatmap.svg",
 title      "YEF3",
 xlabel     "MSA amino acid index",
}
=cut
	my ($args) = @_;
	my @reqd_args = (
		'data',		# hash of arrays of arrays
		'filename'	# include file type extension, e.g. ".svg"
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = (
		'figheight', # default 4.8
		'figwidth',	 # default 6.4
		'title',	# this is sent to suptitle; "title" won't work here
		'xlabel', # overall xlabel for all plots; do not put ylabels here
		@reqd_args);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my @order;
	if (defined $args->{order}) {
		@order = @{ $args->{order} };
	} else {
		@order = sort {lc $a cmp lc $b} keys %{ $args->{data} };
	}
	$args->{figheight} = $args->{figheight} // 4.8;
	$args->{figwidth}  = $args->{figwidth}  // 6.4;
# https://stackoverflow.com/questions/45841786/creating-a-1d-heat-map-from-a-line-graph
	my $unlink = 1;
	my ($py, $temp_py) = tempfile(DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink);
	say $temp_py if $unlink == 0;
	say $py 'import matplotlib.pyplot as plt';
	say $py 'import numpy as np';
	my @ax = map {"ax$_"} 0..$#order;
	my $nrows = scalar @order;
	say $py 'fig, (' . join (',', @ax) . ") = plt.subplots(layout = 'constrained', nrows = $nrows, sharex = True, figsize = ($args->{figwidth}, $args->{figheight}))";
	while (my ($n, $group) = each @order) {
		say $py 'x = np.array([' . join (',', @{ $args->{data}{$group}[0] }) . '])';
		say $py 'y = np.array([' . join (',', @{ $args->{data}{$group}[1] }) . '])';
		say $py 'extent = [x[0]-(x[1]-x[0])/2., x[-1]+(x[1]-x[0])/2.,0,1]';
		say $py "im = ax$n.imshow(y[np.newaxis,:], cmap='gist_rainbow', aspect='auto', extent=extent)";
		say $py "ax$n.set_yticks([])";
		say $py "ax$n.set_title('$group')";
		say $py "cbar = ax$n.figure.colorbar(im, ax = ax$n, label = 'Similarity')";
	}
	$args->{xlabel} = $args->{xlabel} // 'Amino Acid Residue (MSA Coordinate)';
	if (defined $args->{title}) {
		$args->{suptitle} = $args->{title};
	}
	foreach my $arg (grep {defined $args->{$_}} ('xlabel', 'ylabel', 'suptitle')) {
		say $py "plt.$arg('$args->{$arg}')";
	}
#	say $py 'fig.tight_layout(pad = 1.0)';
	say $py "plt.savefig('$args->{filename}', metadata={'Creator': 'made/written by" . getcwd() . "/$RealScript'})";
	close $py;
	execute("python3 $temp_py");
	say 'wrote ' . colored(['cyan on_bright_yellow'], "$args->{filename}");
}

sub json_file_to_ref ($json_filename) {
	die "$json_filename doesn't exist or isn't a file" unless -f $json_filename;
	die "$json_filename has 0 size" if (-s $json_filename == 0);
#	say "Reading $json_filename" if defined $_[0];
	open my $fh, '<:raw', $json_filename; # Read it unmangled
	local $/;                     # Read whole file
	my $json = <$fh>;             # This is UTF-8
#	$json =~ s/NaN/"NaN"/g;
	return decode_json($json); # This produces decoded text
}

sub list_regex_files ($regex, $directory = '.', $case_sensitive = 'yes') {
	die "\"$directory\" doesn't exist" unless -d $directory;
	my @files;
	opendir (my $dh, $directory);
	if ($case_sensitive eq 'yes') {
		$regex = qr/$regex/;
	} else {
		$regex = qr/$regex/i;
	}
	while (my $file = readdir $dh) {
		next if $file !~ $regex;
		next if $file =~ m/^\.{1,2}$/;
		my $f = "$directory/$file";
		next unless -f $f;
		if ($directory eq '.') {
			push @files, $file
		} else {
			push @files, $f
		}
	}
	@files
}

sub multiline_plot {
=data
	flatline   {# name of the graph
	     linestyle   ":", 
	     x           [
	         [0] 1,
	         [1] 2,
	         [2] 3,
	     ],
	     y           [
	         [0] 3,
	         [1] 3,
	         [2] 3,
	     ]
	 },
	 sin(x)     {# name of the graph
	     x   [
	         [0] 1,
	         [1] 2,
	         [2] 3,
	     ],
	     y   [
	         [0] 0.841470984807897,
	         [1] 0.909297426825682,
	         [2] 0.141120008059867,
	     ]
	 }
=cut
	my ($args) = @_;
	my @undef_keys = grep {!defined $args->{$_}} ('data', 'filename');
	if (scalar @undef_keys > 0) {
		p @undef_keys;
		die 'the above keys are required for line_plot'
	}
	my @defined_args = (#'custom_legend',
	'data',			# hash of hash of array, as shown above
	'filename',
	'figwidth',		# default 4.8
	'figheight',	# default 6.4
	'fill_between',
	'labelright','legend','linestyle','logscale','output_type',
	'title', # string
	'xlabel',# string
	'xlim',	# an array of [min, max]
	'ylabel',
	'ylim'	# an array of [min, max]
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args, array_max => scalar @defined_args;
		die 'The above args are accepted.'
	}
	my $unlink = 0;
	$args->{figheight} = $args->{figheight} // 4.8;
	$args->{figwidth}  = $args->{figwidth}  // 6.4;
	my ($fh, $filename) = tempfile (UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say $filename if $unlink == 0;
# https://www.geeksforgeeks.org/plot-multiple-lines-in-matplotlib/
	say $fh 'from matplotlib import pyplot as plt';
	if (defined $args->{custom_legend}) {
		say $fh 'from matplotlib.lines import Line2D';
	}
	say $fh "fig, ax = plt.subplots(layout = 'constrained', figsize = ($args->{figwidth}, $args->{figheight}))";
#	foreach my $arg ('figwidth', 'figheight') {# default figheight = 4.8, figwidth = 6.4 
#		say $fh "plt.figure().set_$arg($args->{$arg})" if defined $args->{$arg};
#	}
	$args->{output_type} = $args->{output_type} // 'svg';
	foreach my $arg (grep {defined $args->{$_}} ('title', 'xlabel', 'ylabel')) {
		say $fh "plt.$arg('$args->{$arg}')";
	}
	if (defined $args->{logscale}) {
		if (ref $args->{logscale} ne 'ARRAY') {
			die 'logscale should be an array of axes like ["x", "y"]' # this error message is more meaningful
		}
		foreach my $axis (@{ $args->{logscale} }) { # x, y 
			say $fh "plt.$axis" . 'scale("log")';
		}
	}
	foreach my $arg (grep { defined $args->{$_} } ('xlim', 'ylim')) {
		say $fh "plt.$arg(" . join (',', @{ $args->{$arg} }) . ')';
	}
# add labels and ticks to the right for the y-axis
	$args->{labelright} = $args->{labelright} // 0;
	if ($args->{labelright} > 0) {
		say $fh 'plt.tick_params(labelright = True, right = True, axis = "both", which = "both")';
	}
	foreach my $line ( sort keys %{ $args->{data} }) {
		if (
				(scalar @{ $args->{data}{$line}{x} })
				!=
				(scalar @{ $args->{data}{$line}{y} })
			) {
			p $args->{data}{$line};
			die "$line has an unequal number of elements in x and y";
		}
		say $fh 'x = [' . join (',', @{ $args->{data}{$line}{x} }) . ']';
		say $fh 'y = [' . join (',', @{ $args->{data}{$line}{y} }) . ']';
		my @plot = ('x', 'y', "label = '$line'");
		if (defined $args->{data}{$line}{linestyle}) {
			push @plot, "linestyle = '$args->{data}{$line}{linestyle}'";
		}
		if (defined $args->{data}{$line}{color}) {
			push @plot, "color = '$args->{data}{$line}{color}'";
		}
		say $fh 'ax.plot(' . join (',', @plot) . ')';
# plt.plot(x, y, label = "curve 2", linestyle=":")
	}
	$args->{legend} = $args->{legend} // 1;
#	if (defined $args->{custom_legend}) {
# https://matplotlib.org/stable/gallery/text_labels_and_annotations/custom_legends.html
#		say $fh 'legend_elements = [' . join (',', @{ $args->{custom_legend} }) . ']';
#		say $fh 'plt.legend(handles = legend_elements)';
#	} elsif ($args->{legend} > 0) { # 0 turns legend off
#		say $fh 'plt.legend()';
#	}
	if (scalar keys %{ $args->{data} } > 1) { # only place a legend if there are > 1 groups
		$args->{'legend.position'} = $args->{'legend.position'} // 'outside center right';
		say $fh "fig.legend(loc = '$args->{'legend.position'}')"; # essential when multiple groups are present
	}
	my $output_image = "$args->{filename}.$args->{output_type}";
	if ($output_image =~ m/$args->{output_type}\.$args->{output_type}$/) {
		$output_image =~ s/\.$args->{output_type}$//; # ".svg.svg" -> ".svg"
	}
	say $fh 'ax.legend()' if $args->{legend} == 1;
	say $fh "plt.savefig('$output_image', bbox_inches='tight', pad_inches = 0.1, metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript'})";
	close $fh;
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die 'failed';
	}
	say 'wrote ' . colored(['white on_green'], $output_image);
	return $output_image
}

sub num_arrays_equal ($arr1, $arr2) {
	my $n = scalar @{ $arr1 };
	return 'no' if $n != scalar @{ $arr2 };
	foreach my $i (0..$n-1) {
		return 'no' if $arr2->[$i] != $arr1->[$i];
	}
	return 'yes';
}

sub pmin {
	my $array = shift;
	my $x = 1;
	my @pmin_array;
	my $n = scalar @$array;
	for (my $index = 0; $index < $n; $index++) {
		$pmin_array[$index] = min(@$array[$index], $x);
	}
	@pmin_array
}

sub cummin {
	my $array_ref = shift;
	my @cummin;
	my $cumulative_min = @$array_ref[0];
	foreach my $p (@$array_ref) {
		if ($p < $cumulative_min) {
			$cumulative_min = $p;
		}
		push @cummin, $cumulative_min;
	}
	@cummin
}

sub cummax {
	my $array_ref = shift;
	my @cummax;
	my $cumulative_max = @$array_ref[0];
	foreach my $p (@$array_ref) {
		if ($p > $cumulative_max) {
			$cumulative_max = $p;
		}
		push @cummax, $cumulative_max;
	}
	@cummax
}

sub order {#made to match R's "order"
	my $array_ref = shift;
	my $decreasing = 'false';
	if (defined $_[0]) {
		my $option = shift;
		if ($option =~ m/true/i) {
			$decreasing = 'true';
		} elsif ($option =~ m/false/i) {
			#do nothing, it's already set to false
		} else {
			die "2nd option should only be case-insensitive 'true' or 'false'";
		}
	}
	my @array;
	my $max_index = scalar @$array_ref-1;
	if ($decreasing eq 'false') {
		@array = sort { @$array_ref[$a] <=> @$array_ref[$b] } 0..$max_index;
	} elsif ($decreasing eq 'true') {
		@array = sort { @$array_ref[$b] <=> @$array_ref[$a] } 0..$max_index;
	}
	@array
}

sub pvalue ($array1, $array2) {
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if (grep {!defined} @$array1) {
		p $array1, array_max => scalar @{ $array1 };
		die "undefined values found in $current_sub"
	}
	if (grep {!defined} @$array2) {
		p $array2;
		die "undefined values found in $current_sub";
	}
	return 1.0 if scalar @$array1 <= 1;
	return 1.0 if scalar @$array2 <= 1;
	my $mean1 = sum(@{ $array1 });
	$mean1 /= scalar @$array1;
	my $mean2 = sum(@{ $array2 });
	$mean2 /= scalar @$array2;
	return 1.0 if $mean1 == $mean2;
	my ($variance1, $variance2) = (0, 0);
	foreach my $x (@$array1) {
		$variance1 += ($x-$mean1)*($x-$mean1);
	}
	foreach my $x (@$array2) {
		$variance2 += ($x-$mean2)*($x-$mean2);
	}
	if (($variance1 == 0.0) && ($variance2 == 0.0)) {
		return 1.0
	}
	$variance1 = $variance1/(scalar @$array1-1);
	$variance2 = $variance2/(scalar @$array2-1);
	my $array1_size = scalar @$array1;
	my $array2_size = scalar @$array2;
	my $WELCH_T_STATISTIC = ($mean1-$mean2)/sqrt($variance1/$array1_size+$variance2/$array2_size);
	my $DEGREES_OF_FREEDOM = (($variance1/$array1_size+$variance2/(scalar @$array2))**2)
	/
	(
	($variance1*$variance1)/($array1_size*$array1_size*($array1_size-1))+
	($variance2*$variance2)/($array2_size*$array2_size*($array2_size-1))
	);
	my $A = $DEGREES_OF_FREEDOM/2;
	my $value = $DEGREES_OF_FREEDOM/($WELCH_T_STATISTIC*$WELCH_T_STATISTIC+$DEGREES_OF_FREEDOM);
#from here, translation of John Burkhardt's C
	my $beta = lgamma($A)+0.57236494292470009-lgamma($A+0.5);
	my $acu = 10**(-15);
	my($ai,$cx,$indx,$ns,$pp,$psq,$qq,$rx,$temp,$term,$xx);
# Check the input arguments.
	return $value if $A <= 0.0;# || $q <= 0.0;
	return $value if $value < 0.0 || 1.0 < $value;
# Special cases
	return $value if $value == 0.0 || $value == 1.0;
	$psq = $A + 0.5;
	$cx = 1.0 - $value;
	if ($A < $psq * $value) {
		($xx, $cx, $pp, $qq, $indx) = ($cx, $value, 0.5, $A, 1);
	} else {
		($xx, $pp, $qq, $indx) = ($value, $A, 0.5, 0);
	}
	$term = 1.0;
	$ai = 1.0;
	$value = 1.0;
	$ns = int($qq + $cx * $psq);
#Soper reduction formula.
	$rx = $xx / $cx;
	$temp = $qq - $ai;
	$rx = $xx if $ns == 0;
	while (1) {
		#print "\$value = $value\n";
		$term = $term * $temp * $rx / ( $pp + $ai );
		#print "\$term = $term";
		$value = $value + $term;
		$temp = abs ($term);
		if ($temp <= $acu && $temp <= $acu * $value) {
#			print "pp = $pp";
#			print "xx = $xx";
#			print "qq = $qq";
#			print "cx = $cx";
#			print "beta = $beta";
	   	$value = $value * exp ($pp * log($xx)
	                          + ($qq - 1.0) * log($cx) - $beta) / $pp;
#	      print "the value = $value";
	   	$value = 1.0 - $value if $indx;# == 0;
#	   	if ($indx == 0) {
#	   		$value = 1.0 - $value
#	   	}
#	   	print "\$indx = $indx";
	   	last;
		}
	 	$ai = $ai + 1.0;
		$ns = $ns - 1;
		#print "ai = $ai";
		#print "ns = $ns";
		if (0 <= $ns) {
			$temp = $qq - $ai;
			$rx = $xx if $ns == 0;
		} else {
			$temp = $psq;
			$psq = $psq + 1.0;
		}
	}
	$value
}

sub p_adjust ($pvalues_ref, $method = 'Holm') {
	my %methods = (
		'bh'       => 1, 'fdr'     => 1,	'by'         => 1,
		'holm'     => 1, 'hommel'  => 1,	'bonferroni' => 1,
		'hochberg' => 1
	);
	my $method_found = 'no';
	foreach my $key (keys %methods) {
		if ((uc $method) eq (uc $key)) {
			$method = $key;
			$method_found = 'yes';
			last
		}
	}
	if ($method_found eq 'no') {
		if ($method =~ m/benjamini-?\s*hochberg/i) {
			$method = 'bh';
			$method_found = 'yes';
		} elsif ($method =~ m/benjamini-?\s*yekutieli/i) {
			$method = 'by';
			$method_found = 'yes';
		}
	}
	if ($method_found eq 'no') {
		die "No method could be determined from $method.\n";
	}
	my $lp = scalar @$pvalues_ref;
	my $n  = $lp;
	my @qvalues;
	if ($method eq 'hochberg') {
		my @o = order($pvalues_ref, 'TRUE');
		my @cummin_input; 
		for (my $index = 0; $index < $n; $index++) {
			$cummin_input[$index] = ($index+1)* @$pvalues_ref[$o[$index]];#PVALUES[$o[$index]] is p[o]
		}
		my @cummin = cummin(\@cummin_input);
		my @pmin   = pmin(\@cummin);
		my @ro = order(\@o);
		@qvalues = @pmin[@ro];
	} elsif ($method eq 'bh') {
		my @o = order($pvalues_ref, 'TRUE');
		my @cummin_input;
		for (my $index = 0; $index < $n; $index++) {
			$cummin_input[$index] = ($n/($n-$index))* @$pvalues_ref[$o[$index]];#PVALUES[$o[$index]] is p[o]
		}
		my @ro = order(\@o);
		my @cummin = cummin(\@cummin_input);
		my @pmin   = pmin(\@cummin);
		@qvalues = @pmin[@ro];
	} elsif ($method eq 'by') {
		my $q = 0.0;
		my @o = order($pvalues_ref, 'TRUE');
		my @ro = order(\@o);
		for (my $index = 1; $index < ($n+1); $index++) {
			$q += 1.0 / $index;
		}
		my @cummin_input;
		for (my $index = 0; $index < $n; $index++) {
			$cummin_input[$index] = $q * ($n/($n-$index)) * @$pvalues_ref[$o[$index]];#PVALUES[$o[$index]] is p[o]
		}
#		say join (',', @cummin_input);
#		say '@cummin_input # of elements = ' . scalar @cummin_input;
		my @cummin = cummin(\@cummin_input);
		undef @cummin_input;
		my @pmin   = pmin(\@cummin);
		@qvalues = @pmin[@ro];
	} elsif ($method eq 'bonferroni') {
		for (my $index = 0; $index < $n; $index++) {
			my $q = @$pvalues_ref[$index]*$n;
			if ((0 <= $q) && ($q < 1)) {
				$qvalues[$index] = $q;
			} elsif ($q >= 1) {
				$qvalues[$index] = 1.0;
			} else {
				die 'Failed to get Bonferroni adjusted p.'
			}
		}
	} elsif ($method eq 'holm') {
		my @o = order($pvalues_ref);
		my @cummax_input;
		for (my $index = 0; $index < $n; $index++) {
			$cummax_input[$index] = ($n - $index) * @$pvalues_ref[$o[$index]];
		}
		my @ro = order(\@o);
		undef @o;
		my @cummax = cummax(\@cummax_input);
		undef @cummax_input;
		my @pmin = pmin(\@cummax);
		undef @cummax;
		@qvalues = @pmin[@ro];
	} elsif ($method eq 'hommel') {
		my @o = order($pvalues_ref);
		my @p = @$pvalues_ref[@o];
		my @ro = order(\@o);
		undef @o;
		my (@q, @pa);
		my $min = $n*$p[0];
		for (my $index = 0; $index < $n; $index++) {
			my $temp = $n*$p[$index] / ($index + 1);
			$min = min($min, $temp);
		}
		for (my $index = 0; $index < $n; $index++) {
			$pa[$index] = $min;#q <- pa <- rep.int(min(n * p/i), n)
			 $q[$index] = $min;#q <- pa <- rep.int(min(n * p/i), n)
		}
		for (my $j = ($n-1); $j >= 2; $j--) {
			my @ij = 0..($n - $j);#ij <- seq_len(n - j + 1)
			my $I2_LENGTH = $j - 1;
			my @i2;
			for (my $i = 0; $i < $I2_LENGTH; $i++) {
				$i2[$i] = $n-$j+2+$i-1;
#R's indices are 1-based, C's are 0-based, I added the -1
			}

			my $q1 = $j * $p[$i2[0]] / 2.0;
			for (my $i = 1; $i < $I2_LENGTH; $i++) {#loop through 2:j
				my $TEMP_Q1 = $j * $p[$i2[$i]] / (2 + $i);
				$q1 = min($TEMP_Q1, $q1);
			}
			for (my $i = 0; $i < ($n - $j + 1); $i++) {#q[ij] <- pmin(j * p[ij], q1)
				$q[$ij[$i]] = min( $j*$p[$ij[$i]], $q1);
			}

			for (my $i = 0; $i < $I2_LENGTH; $i++) {#q[i2] <- q[n - j + 1]
				$q[$i2[$i]] = $q[$n - $j];
			}

			for (my $i = 0; $i < $n; $i++) {#pa <- pmax(pa, q)
				if ($pa[$i] < $q[$i]) {
					$pa[$i] = $q[$i];
				}
			}
#			printf("j = %zu, pa = \n", j);
#				double_say(pa, N);
		}#end j loop
		@qvalues = @pa[@ro];
	} else {
		die "$method doesn't fit my types.\n"
	}
	@qvalues
}

sub rand_between ($min, $max) {
	return $min + rand($max - $min)
}

sub random_key ($hash) {
	foreach my $key (keys %{ $hash }) {
		return $key
	}#this subroutine only returns one key of possibly many and then exits
}

sub random_value ($hash) {
	foreach my $value (values %{ $hash }) {
		return $value
	}
}
sub read_table { # mimics R's read.table; returns array of hash
	my ($args) = @_;
	my $args_ref = ref $args;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ($args_ref eq 'HASH') {
		die "\"$args_ref\" was entered, but a \"HASH\" is needed by $current_sub";
	}
	my @req_args = ('filename');#, 'row name');
	my @undef_args = grep { !defined $args->{$_}} @req_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = (@req_args,
	'sep', # by default ","
	'substitutions',
	'output.type'
	);
	my @bad_args = grep { # which args aren't defined?
								my $key = $_;
								not grep {$_ eq $key} @defined_args
							  } keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	$args->{sep} = $args->{sep} // ',';
	$args->{'output.type'} = $args->{'output.type'} // 'aoh';
	my (@data, @header, %data);
	open my $txt, '<', $args->{filename};
	while (<$txt>) {
		chomp;
# CSV will often have commas inside the fields, which incorrectly splits some cells
		foreach my $sub (@{ $args->{substitutions} }) {
			$_ =~ s/$sub->[0]/$sub->[1]/g;
		}
		my @line = split /$args->{sep}/;
		if ($. == 1) { # header
#			if ((defined $args->{'row name'}) && (!grep { $_ eq $args->{'row name'}} @line)) {
#				p @line;
#				die "the above line is missing $args->{'row name'}"
#			}
			foreach my $cell (@line) {
				$cell =~ s/^#//;
				if ($cell =~ m/^"(.+)"$/) { # remove quotes
					$cell = $1;
				}
			}
			@header = @line;
			next;
		}
		if (scalar @line != scalar @header) {
			p @line;
			warn "the number of elements on $args->{filename} line $. != the header.";
			next;
		}
		my %line;
		@line{@header} = @line; # hash slice based on header
		if ($args->{'output.type'} eq 'aoh') {
			push @data, \%line;
		} elsif ($args->{'output.type'} eq 'hoa') {
			foreach my $col (@header) {
				push @{ $data{$col} }, $line{$col};
			}
		}
#		my $key = $line{$args->{'row name'}};
#		delete $line{$args->{'row name'}};
#		$data{$key} = \%line;
	}
	if ($args->{'output.type'} eq 'aoh') {
		return \@data;
	} elsif ($args->{'output.type'} eq 'hoa') {
		return \%data;
	}
}

sub ref_to_json_file ($ref, $json_filename) {
	my $ref_json_filename = ref $json_filename;
	unless ($ref_json_filename eq '') {
		die "$json_filename isn't a scalar/string";
	}
	open my $fh, '>:raw', $json_filename; # Write it unmangled
	say $fh encode_json($ref);
	say 'Wrote ' . colored(['blue on_red'], $json_filename);
	return $json_filename;
}

sub venn {
	my ($args) = @_;
	unless (ref $args eq 'HASH') {
		my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = ('data', 'filename');
	my @undef_args = grep {!defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'The arguments above are necessary for proper function and weren\'t defined.';
	}
	my @defined_args = (@reqd_args, 'output_type', 'title', );
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my $input_string = 'data = ' . encode_json($args->{data});
	$input_string =~ s/\[/\{/g;
	$input_string =~ s/\]/\}/g;
	my ($fh, $filename) = tempfile (UNLINK => 1, SUFFIX => '.py', DIR => '/tmp');
	say $fh 'from venn import venn';
# https://github.com/LankyCyril/pyvenn/blob/master/pyvenn-demo.ipynb
	say $fh 'from matplotlib import pyplot as plt';
	say $fh $input_string;
	say $fh 'venn(data)';
	$args->{output_type} = $args->{output_type} // 'svg' ;
	my $output_image = "$args->{filename}.$args->{output_type}";
	if ($output_image =~ m/$args->{output_type}\.$args->{output_type}$/) {
		$output_image =~ s/\.$args->{output_type}$//; # ".svg.svg" -> ".svg"
	}
	foreach my $arg ('title') {
		if (defined $args->{$arg}) {
			say $fh "plt.$arg('$args->{$arg}')";
		}
	}
	say $fh "plt.savefig('$output_image', bbox_inches='tight', pad_inches = 0.1)";
	close $fh;
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die 'venn failed';
	}

	say "Wrote $output_image";
	return $output_image
}
=venn({
	filename => 'Images/venn_patient_status',
	data     => \%patient_status,
	title    => 'Patient Status'
});
=cut

sub venn_proportional_area {
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'data',		# a hash of array
		'filename'	# do not include suffix
	);
	my @undef_args = grep {!defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die "The arguments above are necessary for proper function with $current_sub and weren't defined.";
	}
	my $n_keys = scalar keys %{ $args->{data} };
	if (($n_keys != 2) && ($n_keys != 3)) {
		p $args->{data};
		die "$current_sub only takes 2 or 3 sets of data."; 
	}
	foreach my $key (keys %{ $args->{data} }) {
		if (grep {!defined} @{ $args->{data}{$key} }) {
			p $args->{data}{$key}, array_max => scalar @{ $args->{data}{$key} };
			die "$key has undefined values in $current_sub, there may be undefined values in other keys";
		}
	}
	my @defined_args = (@reqd_args, 'title');
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my $unlink = 0;
	my ($fh, $filename) = tempfile (UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say $filename if $unlink == 0;
	say $fh "from matplotlib_venn import venn$n_keys";
	say $fh 'from matplotlib import pyplot as plt';
	my @keys = sort keys %{ $args->{data} };
	my @n;
	while (my ($i, $key) = each @keys) {
		say $fh "set$i = set([\"" . join ('","', @{ $args->{data}{$key} }) . '"])';
		push @n, "set$i";
	}
	say $fh "venn$n_keys([" . join (',', @n) . '],("' . join ('","', @keys) . '"))';
	say $fh "plt.title('$args->{title}')" if defined $args->{title};
	say $fh "plt.savefig('$args->{filename}', bbox_inches='tight', pad_inches = 0.1, metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	close $fh;
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die "$current_sub failed";
	}
	say 'Wrote ' . colored(['blue on_red'], $args->{filename});
	return $args->{filename}
}

sub workbook_to_hash {
	my ($args) = @_;
	unless (ref $args eq 'HASH') {
		my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
		die "args must be given as a hash ref, e.g. \"$current_sub({ filename => 'blah.xlsx' })\"";
	}
	my @req_args = ('filename');
	my @undef_args = grep { !defined $args->{$_}} @req_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = (@req_args, 'output_type', 'sheet.names.to.save');
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	$args->{output_type} = $args->{output_type} // 'hoa';
	if ($args->{output_type} !~ m/^(hoa|hoh)$/i) {
		die "$args->{output_type} isn't one of the accepted output types";
	}
#	die if $args->{output_type} ne 'aoa';
#	if ($args->{type} !~ m/^(?:aoh|hoh)$/) {
#		die "$args->{type} should be either aoh or hoh."
#s	}
	my $excel = Spreadsheet::XLSX -> new ($args->{filename}) or die "Can't read $args->{filename}: $!";
	my %table;
	foreach my $sheet (@{$excel -> {Worksheet}}) { # will only do the 1st sheet
		if (
				(defined $args->{'sheet.names.to.save'})
				&&
				(!grep { $_ eq $sheet->{Name} } @{ $args->{'sheet.names.to.save'}})
			) {
			say "skipping $sheet->{Name}";
			next;
		}
		my (@header, @table);
		$sheet -> {MaxRow} ||= $sheet -> {MinRow};
#		$table{'n.rows'} = $sheet -> {MaxRow} - $sheet -> {MinRow};
		foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {
			$sheet -> {MaxCol} ||= $sheet -> {MinCol};
	# is this row blank?
			my @row;
			foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
				my $cell = $sheet -> {Cells} [$row] [$col];
				push @row, $cell->{Val};# if $cell;
			}
			if (!grep {defined} @row) { # skip empty rows
				next
			}
			foreach my $i (@row) {
				next unless defined $i;
				$i =~ s/\s+$//;
				$i =~ s/^\s+//;
			}
			unless ($header[0]) { # if the header isn't defined
				@header = @row;
#				@{ $table[0] } = @row if $args->{output_type} eq 'hoa';
				next
			}
			if (scalar @row != scalar @header) {
				say "row $row, which has " . scalar @row . ' elements, is:';
				p @row;
				say 'but the header, which has ' . scalar @header . ' items, is:';
				p @header;
				die "\"$sheet->{Name}\" row $row has a different # of columns than the header."
			}
			my $key = $row[0];
			if (($args->{output_type} eq 'hoh') && (defined $table{$sheet->{Name}}{$key})) {
				say STDERR "The row $key, which is on sheet $sheet->{Name}";
				p $table{$sheet->{Name}}{$key};
				say STDERR 'is going to be overwritten by the following with the same key name:';
				p @row;
				die "$key cannot be overwritten";
			}
			foreach my $column (@header) {
				if ($args->{output_type} eq 'hoa') {
					push @{ $table{$sheet->{Name}}{$column} }, shift @row;
				} elsif ($args->{output_type} eq 'hoh') {
					$table{$sheet->{Name}}{$column}{$key} = shift @row;
				}
			}
			
		}
	}
	if (scalar keys %table == 0) {
		die "couldn't get any data from $args->{filename}";
	}
	return \%table;
}
#my $excel = Spreadsheet::XLSX -> new ('local_python.results/local_python.xlsx');
sub worksheet_to_hash ($sheet, $col_check = 'yes') {# $sheet is seen by Spreadsheet::XLSX
	my (@header, %table);
	$sheet -> {MaxRow} ||= $sheet -> {MinRow};
	foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {
		$sheet -> {MaxCol} ||= $sheet -> {MinCol};
# is this row blank?
		my @row;
		foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
			my $cell = $sheet -> {Cells} [$row] [$col];
			push @row, $cell->{Val}
		}
		if (!grep {defined} @row) { # skip empty rows
			next
		}
		foreach my $i (grep {defined} @row) {
			$i =~ s/\s+$//;
			$i =~ s/^\s+//;
		}
		unless ($header[0]) { # if the header isn't defined
			@header = @row;
			next
		}
		if (($col_check eq 'yes') && (scalar @row != scalar @header)) {
			say 'the row is:';
			p @row;
			say 'but the header is:';
			p @header;
			die "\"$sheet->{Name}\" row $row has a different # of columns than the header."
		}
		foreach my $column (@header) {
			if (defined $column) {
				push @{ $table{$column} }, shift @row;
			} else {
				push @{ $table{'undefined column'} }, shift @row;
			}
		}
	}
	return \%table
}
1;
