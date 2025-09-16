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

our @EXPORT = qw(average_pre_rec_plot average_roc_plot barplot colored_table combined_plots_in_rows density_scatterplot dir execute file2string format_commas get_sample_ID heatmaps_in_rows hist2d_in_rows histogram json_file_to_ref list_regex_files multiline_plot num_arrays_equal plots_in_rows pvalue plot p_adjust rand_between random_key random_value read_table ref_to_json_file scatterplot scatterplot_2d_color scatterplot_2d_groups_color venn venn_proportional_area violin_plot workbook_to_hash worksheet_to_hash make_colormap violin_subplots wide_plot);
my @ax_methods = (
'ArtistList', 'add_child_axes', 'add_collection', 'add_container', 'add_image', 'add_line', 'add_patch', 'add_table', 'apply_aspect', 'autoscale_view', 'axison', 'bxp', 'callbacks', 'can_pan', 'can_zoom', 'child_axes', 'collections', 'containers', 'contains_point', 'dataLim', 'drag_pan', 'end_pan', 'fmt_xdata', 'fmt_ydata', 'format_coord', 'format_xdata', 'format_ydata', #'get_adjustable', 'get_anchor', 'get_aspect', 'get_autoscale_on', 'get_autoscalex_on', 'get_autoscaley_on', 'get_axes_locator', 'get_axisbelow', 'get_box_aspect', 'get_data_ratio', 'get_fc', 'get_forward_navigation_events', 'get_frame_on', 'get_gridspec', 'get_images', 'get_legend', 'get_legend_handles_labels', 'get_lines', 'get_navigate', 'get_navigate_mode', 'get_position', 'get_rasterization_zorder', 'get_shared_x_axes', 'get_shared_y_axes', 'get_subplotspec', 'get_title', 'get_xaxis', 'get_xaxis_text1_transform', 'get_xaxis_text2_transform', 'get_xaxis_transform', 'get_xbound', 'get_xgridlines', 'get_xlabel', 'get_xlim', 'get_xmajorticklabels', 'get_xmargin', 'get_xminorticklabels', 'get_xscale', 'get_xticklabels', 'get_xticklines', 'get_xticks', 'get_yaxis', 'get_yaxis_text1_transform', 'get_yaxis_text2_transform', 'get_yaxis_transform', 'get_ybound', 'get_ygridlines', 'get_ylabel', 'get_ylim', 'get_ymajorticklabels', 'get_ymargin', 'get_yminorticklabels', 'get_yscale', 'get_yticklabels', 'get_yticklines', 'get_yticks','has_data',
'ignore_existing_data_limits', 'in_axes', 'indicate_inset', 'indicate_inset_zoom', 'inset_axes', 'invert_xaxis', 'invert_yaxis', 'label_outer', 'legend_', 'name', 'pcolorfast', 'redraw_in_frame', 'relim', 'reset_position', 'secondary_xaxis', 'secondary_yaxis', 'set_adjustable', 'set_anchor', 'set_aspect', 'set_autoscale_on', 'set_autoscalex_on', 'set_autoscaley_on', 'set_axes_locator', 'set_axis_off', 'set_axis_on', 'set_axisbelow', 'set_box_aspect', 'set_fc', 'set_forward_navigation_events', 'set_frame_on', 'set_mouseover( ', 'set_navigate', 'set_navigate_mode', 'set_position', 'set_prop_cycle', 'set_rasterization_zorder', 'set_subplotspec', 'set_title', 'set_xbound', 'set_xlabel',
'set_xlim', # ax.set_xlim(left, right), or ax.set_xlim(right = 180)
'set_xmargin', 'set_xscale', 'set_xticklabels', 'set_xticks', 'set_ybound', 'set_ylabel', 'set_ylim', 'set_ymargin', 'set_yscale', 'set_yticklabels', 'set_yticks', 'sharex', 'sharey', 'spines', 'start_pan', 'tables', 'titleOffsetTrans', 'transAxes', 'transData', 'transLimits', 'transScale', 'update_datalim', 'use_sticky_edges', 'viewLim', 'violin', 'xaxis', 'xaxis_date', 'xaxis_inverted', 'yaxis', 'yaxis_date', 'yaxis_inverted');
my @fig_methods =  ('add_artist','add_axes','add_axobserver','add_callback','add_gridspec', 'add_subfigure', 'add_subplot','align_labels','align_titles','align_xlabels','align_ylabels','artists',  'autofmt_xdate',
	#'axes', # same as plt
'bbox','bbox_inches','canvas','clear','clf','clipbox',
'colorbar', # same name as in plt, have to use on case-by-case
'contains','convert_xunits','convert_yunits','delaxes','dpi','dpi_scale_trans','draw', 'draw_artist','draw_without_rendering','figbbox','figimage',
#	'figure',	'findobj',
'format_cursor_data', 'frameon',
#'gca','get_agg_filter','get_alpha','get_animated','get_axes','get_children', 'get_clip_box','get_clip_on','get_clip_path','get_constrained_layout','get_constrained_layout_pads', 'get_cursor_data','get_default_bbox_extra_artists','get_dpi','get_edgecolor','get_facecolor', #'get_figheight',
#'get_figure',
#'get_figwidth', 
#'get_frameon','get_gid','get_in_layout','get_label', 'get_layout_engine','get_linewidth','get_mouseover','get_path_effects','get_picker', 'get_rasterized','get_size_inches','get_sketch_params','get_snap', 'get_suptitle',
#'get_supxlabel', 'get_supylabel','get_tight_layout','get_tightbbox','get_transform', 'get_transformed_clip_path_and_affine',
	#'get_url',	'get_visible','get_window_extent','get_zorder',
#	'ginput',, keeping plt instead
	'have_units','images','is_transform_set',
#	'legend',	'legends',
	'lines','mouseover', 'number','patch','patches','pchanged','pick','pickable','properties','remove', 'remove_callback',
	#'savefig', keeping plt instead
	'sca','set','set_agg_filter','set_alpha','set_animated','set_canvas', 'set_clip_box','set_clip_on','set_clip_path','set_constrained_layout' ,'set_constrained_layout_pads', 'set_dpi','set_edgecolor','set_facecolor',
	'set_figheight', # default 4.8
#	'set_figure', # deprecated as of matplotlib 3.10.0
	'set_figwidth',# default 6.4
	'set_frameon','set_gid','set_in_layout','set_label','set_layout_engine','set_linewidth', 'set_mouseover','set_path_effects','set_picker','set_rasterized','set_size_inches', 'set_sketch_params','set_snap','set_tight_layout','set_transform','set_url','set_visible', 'set_zorder',
#	'show', # keeping plt instead
	'stale','stale_callback','sticky_edges','subfigs','subfigures',
#	'subplot_mosaic',
	'subplotpars',
#	'subplots',	'subplots_adjust',
	'suppressComposite',
#	'suptitle', # keeping plt instead
	'supxlabel','supylabel',
	#'text',
	'texts',
	#'tight_layout',
	'transFigure','transSubfigure', 'update','update_from',
	#'waitforbuttonpress',
	'zorder'
);
my @plt_methods = ('AbstractContextManager','Annotation','Arrow','Artist','AutoLocator','AxLine','Axes', 'BackendFilter','Button','Circle','Colorizer','ColorizingArtist','Colormap','Enum', 'ExitStack','Figure','FigureBase','FigureCanvasBase','FigureManagerBase',' FixedFormatter','FixedLocator','FormatStrFormatter','Formatter','FuncFormatter','GridSpec', 'IndexLocator','Line2D','LinearLocator','Locator','LogFormatter','LogFormatterExponent', 'LogFormatterMathtext','LogLocator','MaxNLocator','MouseButton','MultipleLocator','Normalize', 'NullFormatter','NullLocator','PolarAxes','Polygon','Rectangle','ScalarFormatter', 'Slider','Subplot','SubplotSpec','TYPE_CHECKING','Text','TickHelper','Widget','acorr', 'angle_spectrum','annotate','annotations','arrow','autoscale','autumn','axes','axhline', 'axhspan','axis','axline','axvline','axvspan','backend_registry','bar','bar_label','barbs', 'barh','bone','box','boxplot','broken_barh','cast','cbook','cla','clabel',
	#'clf', # I don't think you'd ever do that, also redundant with fig
	'clim', 'close','cm','cohere','color_sequences','colorbar','colormaps','connect','contour', 'contourf','cool','copper','csd','cycler','delaxes','disconnect','draw','draw_all', 'draw_if_interactive','ecdf','errorbar','eventplot','figaspect','figimage','figlegend', 'fignum_exists','figtext','figure','fill','fill_between','fill_betweenx','findobj', 'flag','functools','gca','gcf','gci','get','get_backend','get_cmap', 'get_current_fig_manager','get_figlabels','get_fignums','get_plot_commands', 'get_scale_names','getp','ginput','gray','grid','hexbin','hist','hist2d','hlines', 'hot','hsv','importlib','imread','imsave','imshow','inferno','inspect', 'install_repl_displayhook','interactive','ioff','ion','isinteractive', 'jet','legend','locator_params','logging','loglog','magma','magnitude_spectrum', 'margins','matplotlib','matshow','minorticks_off','minorticks_on','mlab', 'new_figure_manager','nipy_spectral','np','overload','pause','pcolor','pcolormesh', 'phase_spectrum','pie','pink','plasma','plot','plot_date','polar','prism','psd', 'quiver','quiverkey','rc','rcParams','rcParamsDefault','rcParamsOrig','rc_context', 'rcdefaults','rcsetup','rgrids','savefig','sca','scatter','sci','semilogx', 'semilogy','set_cmap','set_loglevel','setp','show','specgram','spring','spy', 'stackplot','stairs','stem','step','streamplot','style',
'subplot', # nrows, ncols : int, default: 1
'subplot2grid', 'subplot_mosaic','subplot_tool','subplots','subplots_adjust','summer','suptitle', 'switch_backend','sys','table',
	'text',# text(x: 'float', y: 'float', s: 'str', fontdict: 'dict[str, Any] | None' = None, **kwargs) -> 'Text'
	'thetagrids','threading','tick_params', 'ticklabel_format','tight_layout','time', 'title', 'tricontour','tricontourf', 'tripcolor','triplot','twinx','twiny','uninstall_repl_displayhook','violinplot', 'viridis','vlines','waitforbuttonpress','winter','xcorr','xkcd','xlabel','xlim', 'xscale','xticks','ylabel','ylim','yscale','yticks');

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

sub function { # this is a helper function to other matplotlib subroutines
=example
	this is called *inside* other subroutines to shorten code

	function => {
		min	=> 0,
		max	=> $xint,
		func	=> "-(10.0/($xint*$xint))*(x+$xint)*(x-$xint)",
		step	=> 1
	},
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'fh',						# e.g. $py, $fh, which will be passed by the subroutine
		'func',					# a function, like "-9x**2", but must be readable by python3
		'min', 'max', 'step'	# like a C-style for loop
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		'plot_params'
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args, array_max => scalar @defined_args;
		die 'The above args are accepted.'
	}
	say {$args->{fh}} 'import numpy as np';
	say {$args->{fh}} "xs = np.arange($args->{min}, $args->{max}, $args->{step}).tolist()";
	say {$args->{fh}} "ys = [$args->{func} for x in xs]";
	if (defined $args->{plot_params}) {
		my @params;
		while (my ($key, $value) = each %{ $args->{plot_params} }) {
			push @params, "$key = $value";
		}
		say {$args->{fh}} 'plt.plot(xs, ys, ' . join (',', @params) . ')';
	} else {
		say {$args->{fh}} 'plt.plot(xs, ys)';
	}
}

sub plot_args { # this is a helper function to other matplotlib subroutines
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'fh',		# e.g. $py, $fh, which will be passed by the subroutine
		'args',	# args to original function
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		@ax_methods, @fig_methods, @plt_methods
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args, array_max => scalar @defined_args;
		die 'The above args are accepted.'
	}
	my @args = (\@ax_methods, \@fig_methods, \@plt_methods);
	my @obj  = ('ax', 'fig', 'plt');
	foreach my $item (grep {defined $args->{args}{$_}} ('xlabel', 'ylabel', 'title')) {
		if ($args->{args}{$item} =~ m/^(\w+)$/) {
			$args->{args}{$item} = "'$args->{args}{$item}'";
		}
	}
	while (my ($i, $obj) = each @args) {
		foreach my $method (grep {defined $args->{args}{$_}} @{ $args[$i] }) {
			my $ref = ref $args->{args}{$method};
			if ($ref eq '') {
				say {$args->{fh}} "$obj[$i].$method($args->{args}{$method})";
			} elsif ($ref eq 'ARRAY') {
				foreach my $j (@{ $args->{args}{$method} }) { # say $fh "plt.$method($plt)";
					say {$args->{fh}} "$obj[$i].$method($j)";
				}
			} else {
				p $args;
				die "$ref only accepts scalar or array types";
			}
		}
	}
}

sub line_segments { # this is a helper function to other matplotlib subroutines
=example
	this is called *inside* other subroutines to shorten code
	line_segments({
		fh						=> $py,
		object				=> "ax$r",
		'line.segments'	=> $args->{data}[$r]{line_segments},
		ylim					=> [$ymin-1, $ymax+1]
	});
	where "line_segments" looks like:
	line_segments	=> [
		[ # 1st line segment
			[100, 0],# left pt
			[400, 0] # right pt
		],
		[# 2nd line segment
			[450, 1],
			[650, 1]
		],
		[
			[0,   2],
			[993, 2]
		]
	],
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'fh',					# e.g. $py, $fh, which will be passed by the subroutine
		'line.segments',	# data, array of arrays [[x0,y0],[x1,y1]]
		'object',			# e.g. "ax2"
		'ylim'				# e.g. [0,1]
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		'colors',
		'plot_params'
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args, array_max => scalar @defined_args;
		die 'The above args are accepted.'
	}
	say {$args->{fh}} 'from matplotlib.collections import LineCollection';
	my @data;
	my ($min_y, $max_y) = ('inf', '-inf');
	foreach my $segment (@{ $args->{'line.segments'} }) {
		$max_y = max($max_y, $segment->[0][1], $segment->[1][1]);
		$min_y = min($min_y, $segment->[0][0], $segment->[1][0]);
		push @data, "[($segment->[0][0], $segment->[0][1]),($segment->[1][0], $segment->[1][1])]";
	}
	my $lw = $args->{linewidths} // '5';
	if (defined $args->{colors}) {
		say {$args->{fh}} 'from colour import Color';
		say {$args->{fh}} 'chroma = [Color(c) for c in ("' . join ('","', @{ $args->{colors} }) . '")]';
		say {$args->{fh}} 'rgb = [c.get_rgb() for c in chroma]';
		say {$args->{fh}} 'lines = LineCollection([' . join (',', @data) . '], linewidths=5, colors = rgb)';
	} else {
		say {$args->{fh}} 'lines = LineCollection([' . join (',', @data) . '], linewidths=5)';
	}
	say {$args->{fh}} "$args->{object}.add_collection(lines)";
	if (defined $args->{ylim}) {
		$min_y = $args->{ylim}[0];
		$max_y = $args->{ylim}[1];
	} else {
		my $height = $max_y - $min_y;
		$max_y = $max_y + .2*$height;
		$min_y = $min_y - .2*$height;
	}
	say {$args->{fh}} "$args->{object}.set_ylim($min_y, $max_y)";
}

sub text { # this is a helper function to other matplotlib subroutines
=example
	this is called *inside* other subroutines to shorten code
	"text" should be a 2D array wherein each element looks like:
	
	[x coord, y coord, "txt"]
	OR
	[x coord, y coord, text, xtext, ytext] if text location is specified for arrows
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'text',	# a 2D array
		'fh',		# e.g. $py, $fh, which will be passed by the subroutine
		'object'	# e.g. "plt"
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		'annotate',		# label using plt.annotate instead; 0 or 1; cf. text
		'adjust_text',	# use the adjust_text https://adjusttext.readthedocs.io/en/latest/Examples.html
		'xshift'	# if using "annotate" option; how far to shift right/left as a % of x axis
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args, array_max => scalar @defined_args;
		die 'The above args are accepted.'
	}
	$args->{adjust_text} = $args->{adjust_text} // 0;
	$args->{annotate}		= $args->{annotate}    // 0;
	if ($args->{adjust_text} > 0) { # can't handle bold font
# make the strings all 1 array
		my $str = 'txt = [(' . join ('),(', @{ $args->{text} }) . ')]';
		say {$args->{fh}} 'data = [';
		foreach my $text (@{ $args->{text} }) {
			my @t = @{ $text }[0..2];
			$t[2] = "'$t[2]'";
			say {$args->{fh}} '	(' . join (',', @t) . '),';
		}
		say {$args->{fh}} ']';
		say {$args->{fh}} 'from adjustText import adjust_text';
		say {$args->{fh}} 'texts = [plt.text(x, y, l) for x, y, l in data]';
		say {$args->{fh}} 'adjust_text(texts)';
	} elsif ($args->{annotate} > 0) { # use lines to point from text label
		if ((defined $args->{xshift}) && (($args->{xshift} < 0) || ($args->{xshift} > 100))) {
			p $args;
			die 'xshift must be within [0,100]';
		}
		say {$args->{fh}} 'xmin, xmax, ymin, ymax = plt.axis()';
		$args->{xshift} = $args->{xshift} // 15;
		say {$args->{fh}} 'xshift = (xmax - xmin) * 0.01 * ' . $args->{xshift};
		while (my ($i, $text) = each @{ $args->{text} }) {
			my $xytext_coords;
			if (scalar @{ $text } == 5) { # xy coords of point, then xy coords of text
				$xytext_coords = join (',', @{ $text }[3,4]);
			} else { #3f (scalar @{ $text } == 3) { # no defined shift location
				$xytext_coords = "$text->[0] + xshift, $text->[1]";#join (',', @{ $text }[0,1]);
#			} else {
#				p $text;
#				die "at text index $i (above), there can only be 3 or 5 elements.";
			}
			say {$args->{fh}} "$args->{object}.annotate(text = '$text->[2]', xy = [$text->[0],$text->[1]], xytext = [$xytext_coords], arrowprops = dict(arrowstyle = 'simple', facecolor = 'red', mutation_scale = 0.5))";
		}
	} else {
		foreach my $text (@{ $args->{text} }) {
			my @t = @{ $text };
			$t[2] = "'$t[2]'";
			say {$args->{fh}} "$args->{object}.text(" . join (',', @t) . ')';
		}
	}
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

sub barplot { # not intended for stacked plots
=barplot({
	'bar.type'			=> 'bar',
#	bottom				=> \@bottom,
	color					=> ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'fuchsia'],
	edgecolor			=> 'black',
	execute				=> 0,
	'output.filename'	=> '/tmp/barplot.svg',
	data					=> {
		Fri	=> 76,
		Mon	=> 73,
		Sat	=> 26,
		Sun	=> 11,
		Thu	=> 94,
		Tue	=> 93,
		Wed	=> 77
	},
	'input.file'		=> $tmp_filename,
	'key.order'			=> ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
	title					=> '"title"',
	text					=> [
									'1, 50, "text1"',
									'2, 55, "text2"',
								],
	suptitle				=> '"suptitle2"',
	xlabel				=> '"Day of the Week"',
	ylabel				=> '"# of Rejections"',
});
barplot({
	'bar.type'				=> 'barh',
	data => {
		'United States'	=> 5277, # FAS Estimate
		'Russia'				=> 5449, # FAS Estimate
		'United Kingdom'	=> 225,  # Consistent estimate
		'France'				=> 290,  # Consistent estimate
		'China'				=> 600,  # FAS Estimate
		'India'				=> 180,  # FAS Estimate
		'Pakistan'			=> 130,  # FAS Estimate
		'Israel'				=> 90,   # FAS Estimate
		'North Korea'		=> 50,   # FAS Estimate
	},
	'output.filename'		=> '/tmp/nuclear.warheads.svg',
	set_figwidth			=> 13,
	'input.file'			=> $tmp_filename,
	xerr						=> {
		'United States'	=> [15,29],
		'Russia'				=> [199,1000],
		'United Kingdom'	=> [15,19],
		'France'				=> [19,29],
		'China'				=> [200,159],
		'India'				=> [15,25],
		'Pakistan'			=> [15,49],
		'Israel'				=> [90,50],
		'North Korea'		=> [10,20],
	},
	'log'						=> 'True',
#	linewidth				=> 1,
});
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	# required arguments
	my @reqd_args = (
		'data',				# a simple hash, key => value
		'output.filename'	# an output file; returns string otherwise
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = (@reqd_args, # all possible options
		'bar.type',		# default "bar" or "barh"
		'bottom',		# bottoms of bars; float or array-like, default: 0
		'color',			# :mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar faces. This is an alias for *facecolor*. If both are given, *facecolor* takes precedence
# if entering multiple colors, quoting isn't needed
		'edgecolor',	#:mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar edges.
		'execute',		# execute the python file or not; default 1 = yes
		'input.file',	# instead of lots of files, run all plots together in this file
		'key.order',	# define the keys in an order (an array reference)
		'linewidth',	# float or array, optional; Width of the bar edge(s). If 0, don't draw edges
		'log',			# bool, default: False; If *True*, set the y-axis to be log scale.
		'width',			# float or array, default: 0.8; The width(s) of the bars.
		'xerr',			# float or array-like of shape(N,) or shape(2, N), optional. If not *None*, add horizontal / vertical errorbars to the bar tips. The values are +/- sizes relative to the data:        - scalar: symmetric +/- values for all bars
#        - shape(N,): symmetric +/- values for each bar
#        - shape(2, N): Separate - and + values for each bar. First row
#          contains the lower errors, the second row contains the upper
#          errors.
#        - *None*: No errorbar. (Default)
		'yerr', # same as xerr, but better with bar
		@ax_methods, @plt_methods, @fig_methods
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my @key_order;
	if (defined $args->{'key.order'}) {
		@key_order = @{ $args->{'key.order'} };
	} else {
		@key_order = sort keys %{ $args->{data} };
	}
	$args->{'bar.type'} = $args->{'bar.type'} // 'bar'; # use "bar" by default
	if ( # xerr doesn't work with barh
		($args->{'bar.type'} eq 'barh')
		&&
		(defined $args->{'xerr'})
		&&
		(not defined $args->{'yerr'})
	) {
		$args->{xerr} = $args->{yerr};
	}
	my $unlink = 0;
	my ($fh, $temp_py);
	if (defined $args->{'input.file'}) {
		$temp_py = $args->{'input.file'};
		open $fh, '>>', $args->{'input.file'};
	} else {
		($fh, $temp_py) = tempfile(DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink);
	}
	say $temp_py if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'labels = ["' . join ('","', @key_order) . '"]';
	say $fh 'vals = [' . join (',', @{ $args->{data} }{@key_order}) . ']';
	my $fig_present = 0;
	if (grep {defined $args->{$_}} (@ax_methods, @fig_methods)) {
		$fig_present = 1;
		say $fh 'fig, ax = plt.subplots()';
	}
	my $options = '';# these args go to the plt.bar call
	if (defined $args->{'log'}) {
		$options .= ", log = $args->{log}";
	}
	# args that can be either arrays or strings below; STRINGS:
	foreach my $c (grep {defined $args->{$_}} ('color', 'edgecolor')) {
		my $ref = ref $args->{$c};
		if ($ref eq '') { # single color
			$options .= ", $c = '$args->{$c}'";
		} elsif ($ref eq 'ARRAY') {
			$options .= ", $c = [\"" . join ('","', @{ $args->{$c} }) . '"]';
		} else {
			p $args;
			die "$ref for $c isn't acceptable";
		}
	}
	# args that can be either arrays or strings below; NUMERIC:
	foreach my $c (grep {defined $args->{$_}} ('linewidth')) {
		my $ref = ref $args->{$c};
		if ($ref eq '') { # single color
			$options .= ", $c = $args->{$c}";
		} elsif ($ref eq 'ARRAY') {
			$options .= ", $c = [" . join (',', @{ $args->{$c} }) . ']';
		} else {
			p $args;
			die "$ref for $c isn't acceptable";
		}
	}
	foreach my $err (grep {defined $args->{$_}} ('xerr', 'yerr')) {
		my $ref = ref $args->{$err};
		if ($ref eq '') {
			$options .= ", $err = $args->{$err}";
		} elsif ($ref eq 'HASH') { # I assume that it's all defined
			my (@low, @high);
			foreach my $i (@key_order) {
				if (scalar @{ $args->{$err}{$i} } != 2) {
					p $args->{$err}{$i};
					die "$err/$i should have exactly 2 items: low and high error bars";
				}
				push @low,	$args->{$err}{$i}[0];
				push @high,	$args->{$err}{$i}[1];
			}
			$options .= ", $err = [[" . join (',', @low) . '],[' . join (',', @high) . ']]';
		} else {
			p $args;
			die "$ref for $err isn't acceptable";
		}
	}
	say $fh "plt.$args->{'bar.type'}(labels, vals $options)";
	plot_args({
		fh		=> $fh,
		args	=> $args
	});
	say $fh "plt.savefig('$args->{'output.filename'}', bbox_inches = 'tight', metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	$args->{execute} = $args->{execute} // 1;
	if ($args->{execute} == 0) {
		say $fh 'plt.close()';
		if ($fig_present == 0) {
			say $fh 'del labels, vals';
		} else {
			say $fh 'del fig, ax, labels, vals';
		}
	}
	close $fh;
	if ($args->{execute} > 0) {
		execute("python3 $temp_py");
		say 'wrote ' . colored(['cyan on_bright_yellow'], "$args->{'output.filename'}");
	} else { # not running yet
		say 'will write ' . colored(['cyan on_bright_yellow'], "$args->{'output.filename'}");
	}
	return $args->{'output.filename'};
}

sub colored_table {
=purpose
	this subroutine prints out a colored table, kind of like a heat map

data should look like:
[
    [0] [
            [0] 2029,
            [1] 938,
                (...skipping 6 items...)
        ],
    [1] [
            [0] 975,
            [1] 2136,
    ....
example execution:
------------------
colored_table({
	'col.labels'	=> \@col_labels,
	filename 		=> '/home/con/identify.target/who.critical/svg/msa.qc/DEG20010729_msa_quality.svg',
	data				=> \@data,
	'row.labels'	=> \@row_labels,
	cb_label			=> 'Score',
	title				=> 'Multiple Sequence Alignment Score'
});
------------------
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'col.labels',	# column labels
		'data',			# input data, should be an 2D array
		'filename', 	# output file name, a simple string
	);
	my @undef_args = grep {!defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die "The arguments above are necessary for proper function of $current_sub and weren't defined.";
	}
	unless (
		(scalar @{ $args->{'col.labels'} } == scalar @{ $args->{'row.labels'} })
		&&
		(scalar @{ $args->{'col.labels'} } == scalar @{ $args->{data} })
	) {
		p $args;
		die '"col.labels", "data", and "row.labels" must all be the same length';
	}
#	optional args are below
	my @defined_args = (@reqd_args,
		'cb_label',	# colorbar label
		'cb_max',	# #maximum value for color bar; default is the data's maximum value
		'cb_min',	# minimum value for color bar; default is the data's minimum value
		'cblogscale',	# color bar in log scale
		'cmap',		# the cmap used for coloring
		'default_undefined',	# what value should undefined values be assigned to?
		'row.labels',	# row labels
		'show.numbers',# show the numbers or not, by default off.  0 = "off"; "show.numbers" > 0 => "on"
		'title',		# title
#		'xlabel',	# xlabel prints in a bad position, so I removed this as a possible option
#		'ylabel',	# ylabel prints under the row labels
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my ($min, $max) = ('inf', '-inf');
	$args->{default_undefined} = $args->{default_undefined} // 0;
	while (my ($i, $row) = each (@{ $args->{data} })) {
		if (scalar @{ $row } != scalar @{ $args->{data} }) {
			p $args->{data}, array_max => $i+1;
			die "row $i of data has a # of elements != to the number of labels";
		} # best to check for errors as early as possible
		foreach my $u (grep {not defined $row->[$_]} 0..$#$row) {
			$row->[$u] = $args->{default_undefined};
		}
		$min = min($min, @{ $row });
		$max = max($max, @{ $row });
	}
	$min = $args->{cb_min} // $min;
	$max = $args->{cb_max} // $max;
	$args->{cmap} = $args->{cmap} // 'gist_rainbow';
	$args->{cblogscale} = $args->{cblogscale} // 0;
	my $unlink = 0;
	my ($py, $tempfile) = tempfile(DIR => '/tmp', UNLINK => $unlink, SUFFIX => '.py');
	say $tempfile if $unlink == 0;
	say $py 'from matplotlib import pyplot as plt';
	say $py 'from matplotlib import colors' if $args->{cblogscale} > 0;
	say $py 'data = ' . encode_json($args->{data});
	say $py "norm = plt.Normalize($min, $max)";
	say $py 'datacolors = plt.cm.gist_rainbow(norm(data))';
	say $py 'fig = plt.figure()';
	say $py 'ax = fig.add_subplot(111, frameon=False, xticks=[], yticks=[])';
	if ($args->{cblogscale} > 0) {
		say $py "img = plt.imshow(data, cmap='$args->{cmap}', norm=colors.LogNorm())";
	} else {
		say $py "img = plt.imshow(data, cmap='$args->{cmap}')";
	}
	if (defined $args->{cb_label}) {
		say $py "plt.colorbar(label = '$args->{cb_label}')";
	} else {
		say $py 'plt.colorbar()';
	}
	say $py 'img.set_visible(False)';
	$args->{'show.numbers'} = $args->{'show.numbers'} // 0;
	if ($args->{'show.numbers'} > 0) {
		say $py 'table = plt.table(cellText=data, rowLabels=["' . join ('","', @{ $args->{'row.labels'} }) . '"], colLabels = ["' . join ('","', @{ $args->{'col.labels'} }) . '"], cellColours = datacolors, loc = "center", bbox=[0,0,1,1])';
	} else {
		say $py 'table = plt.table(rowLabels=["' . join ('","', @{ $args->{'row.labels'} }) . '"], colLabels = ["' . join ('","', @{ $args->{'col.labels'} }) . '"], cellColours = datacolors, loc = "center", bbox=[0,0,1,1])';
	}
	foreach my $arg (grep {defined $args->{$_}} ('title')) {#, 'xlabel', 'ylabel')) {
		say $py "plt.$arg('$args->{$arg}')";
	}
	if (defined $args->{logscale}) {
		foreach my $axis (@{ $args->{logscale} }) { # x, y 
			say $py "plt.$axis" . 'scale("log")';
		}
	}
	say $py "plt.clim(vmin = $args->{cb_min})" if defined $args->{cb_min};
	say $py "plt.clim(vmax = $args->{cb_max})" if defined $args->{cb_max};
	say $py "plt.savefig('$args->{filename}', bbox_inches='tight', pad_inches = 0.1, metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	close $py;
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $tempfile" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die "\"python3 $tempfile\" failed";
	}
	say 'wrote ' . colored(['black on_yellow'], "$args->{filename}");
	return $args->{filename};
}

sub combined_plots_in_rows {
=example

	combined_plots_in_rows({
	data	=> [
		{	# first panel
			China		=> [
				[1992..2022],
				$plot_data{'Area harvested'}{China},
			],
			India		=> [
				[1992..2022],
				$plot_data{'Area harvested'}{India},
			],
			Russia	=> [
				[1992..2022],
				$plot_data{'Area harvested'}{'Russian Federation'},
			],
			Ukraine	=> [
				[1992..2022],
				$plot_data{'Area harvested'}{Ukraine},
			],
			'USA' => [
				[1992..2022],
				$plot_data{'Area harvested'}{'United States of America'}
			]
		},
		{
			China		=> [
				[1992..2022],
				$plot_data{Production}{China},
			],
			India		=> [
				[1992..2022],
				$plot_data{Production}{India},
			],
			Russia	=> [
				[1992..2022],
				$plot_data{Production}{'Russian Federation'},
			],
			Ukraine	=> [
				[1992..2022],
				$plot_data{Production}{Ukraine},
			],
			'USA' => [
				[1992..2022],
				$plot_data{Production}{'United States of America'}
			]
		}
	],
	legend	=> [1],
	xlabel	=> 'Year',
	figwidth	=> 12,
	ax_methods => [
		{
			set_xlim		=> 'left = 1992, right = 2022',
			set_ylabel	=> 'Area Harvested (x 10$^{6}$Ha)'
		},
		{
			set_ylabel	=> 'Production (x 10$^{7}$tons)'
		}
	],
	filename	=> 'svg/potato.data.svg',
	title		=> 'Potato Land Use and Production'
});

	combined_plots_in_rows({
		filename	=> $similarity_svg,
		figwidth	=> 12,
		title		=> "$deg_annotation->{$deg}{'Gene Name'} ($caption{$dir})",
		data		=> [
				{	# 1st panel
					hosts			=> [					# 1st data set, 1st panel
						[0..$max_n],
						$group_similarity->{hosts}
					],
					pathogens	=> [					# 2nd data set, 2nd panel
						[0..$max_n],
						$group_similarity->{pathogens}
					]
				},
				{	# 2nd panel
					%{ $domains }
				}
		],
		xlim			=> [0, $max_n],	# common to all sub-plots, so just [min, max]
		subtitles	=> [
			'Host/Pathogen Similarity', 'Domains'
		],
		ylabel		=> ['Φ'],# 2nd is undefined
		yaxis_off	=> [undef, 1],
		plot_params	=> [
			{	# 1st pane/row
				hosts			=> {
					color => 'red',
				},
				pathogens	=> {
					color => 'blue'
				}
			}
		],
		legend		=> [1,undef]
	});
=cut
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	my ($args) = @_;
	my @reqd_args = (
		'data',		# array of hashes
		'filename'	# include file type extension, e.g. ".svg"
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = (
		'ax_methods',	# a list/array of hashes https://matplotlib.org/stable/api/axes_api.html
		'cblabel',		# label for colorbar, accepts string
		'figheight', 'figwidth',
		'hist2d_bins',	# no. of bins for hist2d, by default 10
		'legend',
		'ncols',			# default 1
		'plot_params',	# array of hashes
		'plot_type',	# an array: e.g. "hist2d", by default "plot"
		'sharex',		# sharex according to plt.subplots, by default true
		'subtitles',	# each of the plot's titles, lesser in significance than title
		'title',			# this is sent to suptitle; "title" won't work here
		'xlabel',		# overall xlabel for all plots
		'xlim', 			# e.g. [0,1]. They're shared
		'yaxis_off', 	# deactivate the y-axis for these groups, an array
		'ylabel',		# an array for each data group
		'ylim', 			# e.g. [0,1]
	@reqd_args);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
# https://stackoverflow.com/questions/45841786/creating-a-1d-heat-map-from-a-line-graph
	$args->{figheight} = $args->{figheight} // 4.8;
	$args->{figwidth}  = $args->{figwidth}  // 6.4;
	my $unlink = 0;
	my ($py, $temp_py) = tempfile(DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink);
	say 'temp file is ' . colored(['white on_blue'], $temp_py) . ' from ' . __FILE__ . " in $current_sub" if $unlink == 0;
	say $py 'import matplotlib.pyplot as plt';
	my @hist2d_plot_indices;
	if (defined $args->{plot_type}) { # avoids an error
		@hist2d_plot_indices = grep {$args->{plot_type}[$_] eq 'hist2d'} 0..scalar @{ $args->{plot_type} }-1;
	}
	if (scalar @hist2d_plot_indices > 0) {# plot the 2d histogram so that counts can be determined
#https://stackoverflow.com/questions/78020884/hist2d-plots-with-vmin-vax-unknown-until-plotting-with-combined-colorbar-previo/78022097#78022097
		say $py 'import matplotlib';
		say $py 'import matplotlib.pyplot as plt';
		say $py 'from matplotlib.ticker import MaxNLocator';
		say $py 'import numpy as np';
		say $py 'xmax = float("-inf")';
		say $py 'xmin = float("inf")';
		foreach my $r (@hist2d_plot_indices) {
			say $py "x$r = [" . join (',',  @{ $args->{data}[$r][0] }) . ']';
			say $py "y$r = np.array([" . join (',',  @{ $args->{data}[$r][1] }) . '])';
			say $py "xmax = max(xmax,max(x$r))";
			say $py "xmin = min(xmin,min(x$r))";
		}
		$args->{hist2d_bins} = int $args->{hist2d_bins} // 10;
		my $bins1 = $args->{hist2d_bins} + 1;
		say $py "bins = (np.linspace(xmin,xmax,$bins1), $args->{hist2d_bins})";
		foreach my $r (@hist2d_plot_indices) {
			say $py "h$r, _, _ = np.histogram2d(x$r, y$r, bins=bins)";
		}
		my @h = map {"h$_"} @hist2d_plot_indices;
		say $py 'h = [' . join (',', @h) . ']';
		say $py 'colormin = min(hi.min() for hi in h)';
		say $py 'colormax = max(hi.max() for hi in h)';
	}
	my $nrows = scalar @{ $args->{data} };
	my @ax = map {"axes$_"} 0..$nrows-1;
	$args->{sharex} = $args->{sharex} // 'True';
	$args->{ncols} = $args->{ncols} // 1;
	say $py 'fig, (' . join (',', @ax) . ") = plt.subplots(nrows = $nrows, ncols = $args->{ncols}, sharex = $args->{sharex}, figsize = ($args->{figwidth}, $args->{figheight}))";
	foreach my $r (0..scalar @{ $args->{data} } - 1) { # for each plot/row $r
#		say $py "axes[$r].set_ylabel('$args->{ylabel}[$r]')" if defined $args->{ylabel}[$r];
#		say $py "axes[$r].set_title('$args->{subtitles}[$r]')" if defined $args->{subtitles}[$r];
		if (defined $args->{yaxis_off}[$r]) {
			say $py "axes$r.get_yaxis().set_visible(False)";
		}
		my $plot_type = $args->{plot_type}[$r] // 'plot';
		next if $plot_type eq 'hist2d'; # because of normalization, these are later
		foreach my $s (keys %{ $args->{data}[$r] }) { # $s for "set"
			my @plot_params = "label = '$s'";
			while (my ($param, $value) = each %{ $args->{plot_params}[$r]{$s} }) {
				if (looks_like_number($value)) {
					push @plot_params, "$param = $value";
				} elsif ($value =~ m/^\d+,\s*\d+\.\d+$/) {
					push @plot_params, "$param = $value";
				} else {
					push @plot_params, "$param = '$value'";
				}
			}
			if (scalar @{ $args->{data}[$r]{$s} } == 2) { # conventional plotting; hist2d uses this
				say $py "h$r = axes$r.$plot_type([" . join (',', @{ $args->{data}[$r]{$s}[0] }) .' ], [' . join (',', @{ $args->{data}[$r]{$s}[1] }) . '],' . join (',', @plot_params) . ')';
#				say $py "h$r = axes[$r].$plot_type([" . join (',', @{ $args->{data}[$r][0] }) .' ], [' . join (',', @{ $args->{data}[$r][1] }) . '],' . join (',', @plot_params) . ')';
#			} elsif (scalar @{ $args->{data}[$r]{$s} } == 2) { # conventional plotting
			} else #if (
#					(ref $args->{data}[$r]{$s} eq 'HASH') # line_segments or text
				{
	# plotting with helper functions
				if (defined $args->{data}[$r]{line_segments}) {
					my ($ymin, $ymax) = ('inf', '-inf');
					foreach my $segm (@{ $args->{data}[$r]{line_segments} }) {
						foreach my $pt (0,1) {
							$ymin = min($ymin, $segm->[$pt][1]);
							$ymax = max($ymax, $segm->[$pt][1]);
						}
					}
					my %args = (
						fh						=> $py,
						object				=> "axes$r",
						'line.segments'	=> $args->{data}[$r]{line_segments},
						ylim					=> [$ymin-1, $ymax+1]
					);
					if (defined $args->{data}[$r]{colors}) {
						$args{colors} =  $args->{data}[$r]{colors};
					}
					line_segments({%args});
				}
				if (defined $args->{data}[$r]{text}) {
					text({
						fh			=> $py,
						text		=> $args->{data}[$r]{text},
						object	=> "axes$r",
					});
				}
			}
			say $py "axes$r.legend()" if defined $args->{legend}[$r]; # must be *after* plot
		}
		if (defined $args->{ax_methods}[$r]) { # are there methods defined for refining this plot?
			while (my ($method, $value) = each %{ $args->{ax_methods}[$r] }) {
				if (
						(looks_like_number($value))
						||
						($value =~ m/^\d+,\s*\d+\.?\d*$/)# like ax0.set_xlim(0, 99)
						||
						($value =~ m/^[A-Za-z]+.+\d+$/) # left = 1992, right = 2022
					) {
					say $py "axes$r.$method($value)";
				} elsif ($value eq '') {
					say $py "axes$r.$method()";
				} else {
					say $py "axes$r.$method('$value')";
				}
			}
		}
#		if ($args->{plot_type}[$r] eq 'hist2d') {	# colorbars for individual subplots
#			say $py "fig.colorbar(h$r\[3], ax = ax$r)";
#		}
	}
	if (scalar @hist2d_plot_indices > 0) { # if there are hist2d plots
		my @y = map {"y$_"} @hist2d_plot_indices;
		say $py 'for ax, hi, yi in zip(axes.flat, h, [' . join (',', @y) . ']):';
    	say $py '	im = ax.imshow(hi.T, vmin=colormin, vmax=colormax, origin="lower", aspect="auto",   extent=[xmin, xmax, yi.min(), yi.max()], cmap="turbo")';
    	$args->{cblabel} = ", label = '$args->{cblabel}'" // '';
    	say $py "cbar = fig.colorbar(im, ax=axes.ravel().tolist() $args->{cblabel})";
		say $py 'cbar.ax.yaxis.set_major_locator(MaxNLocator(integer=True))';# force integer ticks
		foreach my $r (0..scalar @{ $args->{ax_methods} } - 1) {
			while (my ($method, $value) = each %{ $args->{ax_methods}[$r] }) {
				if (
						(looks_like_number($value))
						||
						($value =~ m/^\d+,\s*\d+\.?\d*$/)# like ax0.set_xlim(0, 99)
					) {
					say $py "axes[$r].$method($value)";
				} elsif ($value eq '') {
					say $py "axes[$r].$method()";
				} else {
					say $py "axes[$r].$method('$value')";
				}
			}
		}
	}
	$args->{xlabel} = $args->{xlabel} // 'Amino Acid Residue (MSA Coordinate)';
	if (defined $args->{title}) {
		$args->{suptitle} = $args->{title};
	}
	foreach my $arg (grep {defined $args->{$_}} ('xlabel', 'suptitle', 'ylabel')) {
		say $py "plt.$arg('$args->{$arg}')";
	}
	say $py 'fig.tight_layout(pad = 0.5)' if scalar @hist2d_plot_indices == 0;
	if (defined $args->{xlim}) {
		say $py 'plt.xlim(' . join (',', @{ $args->{xlim} }) . ')';
	}
	say $py "plt.savefig('$args->{filename}', bbox_inches = 'tight', metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	close $py;
	execute("python3 $temp_py");
	say 'wrote ' . colored(['cyan on_bright_yellow'], "$args->{filename}");
	return $args->{filename};
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

sub density_scatterplot {
=example
data should be a hash of arrays.  Density plots cannot handle multiple sets
{
    cousin       [		# x-axis
        [0] 132,
        [1] 145,
        [2] 370,
            (...skipping 1016 items...)
    ],
    sambucinum   [		# y-axis
        [0] 32,
        [1] 148,
            (...skipping 1016 items...)
    ]
}
=cut
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	my ($args) = @_;
	my @reqd_args = (
		'output.filename',	# include suffix like ".svg"
		'data'					# hash of array
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'The above arguments are necessary, but are not defined.';
	}
	my @defined_args = ('cblabel',
	'cb_logscale',		# put the colorbar/colors in logarithmic scale. "on" is if $args->{cb_logscale} > 0
	'execute',			# execute the python file or not; default 1 = yes
	'input.file',		# instead of lots of files, run all plots together in this file
	@reqd_args, 'keys', 'legend', 'line_segment',
	'logscale',			# an array of axes, e.g. logscale => ['x', 'y']
	'xbins',				# default 15
	'ybins',				# default 15
	@ax_methods, @plt_methods, @fig_methods
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	$args->{xbins} = $args->{xbins} // 15;
	$args->{ybins} = $args->{ybins} // 15;
	$args->{xbins} = int $args->{xbins};
	$args->{ybins} = int $args->{ybins};
	
	if (($args->{xbins} == 0) || ($args->{ybins} == 0)) {
		p $args;
		die '# of bins cannot be 0';
	}
	my @keys;
	if (defined $args->{keys}) {
		@keys = @{ $args->{keys} };
	} else {
		@keys = sort keys %{ $args->{data} };
	}
	if (scalar @keys != 2) {
		p @keys;
		die 'There must be exactly 2 keys';
	}
	my $n_points = scalar @{ $args->{data}{$keys[0]} };
	if ( scalar @{ $args->{data}{$keys[1]} } != $n_points) {
		say "$keys[0] has $n_points points.";
		say "$keys[1] has " . scalar @{ $args->{data}{$keys[1]} } . ' points.';
		die 'The length of both keys must be equal.';
	}
	if (defined $args->{title}) {
		if ($args->{title} =~ m/([\'\"])$/) {
			my $str_terminus = $1;
			$args->{title} =~ s/[\'\"]$//;
			$args->{title} .= " ($n_points points)$str_terminus";
		} else {
			$args->{title} .= " ($n_points points)";
		}
	} else {
		$args->{title} = " ($n_points points)";
	}
# https://izziswift.com/how-can-i-make-a-scatter-plot-colored-by-density-in-matplotlib/
	my $unlink = 0;
	my ($fh, $temp_py);
	if (defined $args->{'input.file'}) {
		$temp_py = $args->{'input.file'};
		open $fh, '>>', $args->{'input.file'};
	} else {
		($fh, $temp_py) = tempfile(DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink);
	}
	say $temp_py if $unlink == 0;
	say $fh 'import numpy as np';
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'x = np.array([' . join (',', @{ $args->{data}{$keys[0]} }) . '])';
	my $xlogscale = false;
	if ((defined $args->{logscale}) && (grep {$_ eq 'x'} @{ $args->{logscale} })) {
		say $fh 'import numpy as np';
		say $fh "xbins = np.logspace(np.log10(min(x)), np.log10(max(x)), $args->{nbins})";
		$xlogscale = true;
	}
	my $fig_present = 0;
	if (grep {defined $args->{$_}} (@ax_methods, @fig_methods)) {
		$fig_present = 1;
		say $fh 'fig, ax = plt.subplots()';
	}
	say $fh 'y = np.array([' . join (',', @{ $args->{data}{$keys[1]} }) . '])';
	$args->{cb_logscale} = $args->{cb_logscale} // 0; # default is off
	if ($args->{cb_logscale} > 0) {
		say $fh 'from matplotlib.colors import LogNorm';
		say $fh "plt.hist2d(x, y, ($args->{xbins}, $args->{ybins}), cmap = plt.cm.turbo, norm = LogNorm())";#.jet)";
	} else { # default
		say $fh "plt.hist2d(x, y, ($args->{xbins}, $args->{ybins}), cmap = plt.cm.turbo)";
	}
	$args->{xlabel} = $args->{xlabel} // $keys[0];
	$args->{ylabel} = $args->{ylabel} // $keys[1];
	plot_args({
		fh		=> $fh,
		args	=> $args
	});
#	foreach my $arg ('title', 'xlabel', 'ylabel') {
#		if (defined $args->{$arg}) {
#			$args->{$arg} =~ s/'/\\'/g;
#			say $fh "plt.$arg('$args->{$arg}')";
#		}
#	}
	if (defined $args->{cblabel}) {
		say $fh "plt.colorbar(label = '$args->{cblabel}')";
	} else {
		say $fh 'plt.colorbar(label = "Density")';
	}
	if (defined $args->{line_segment}) {
=example
	line_segment => [ # array of anonymous hashes
		{
			'x0' => 0, 'x1' => 1, # 1st point
			'y0' => 0, 'y1' => 1, # 2nd point
			linestyle => 'dashed', color => 'red', label => "D' = R^2"
		}
	],
=cut
		foreach my $ls (@{ $args->{line_segment} }) { # hash ref
			my @reqd_coords = ('x0', 'x1', 'y0', 'y1');
			my @undef_args = grep {!defined $ls->{$_}} @reqd_coords;
			if (scalar @undef_args > 0) {
				p @undef_args;
				say STDERR 'the above args are not defined.';
				say STDERR 'the below args are defined:';
				p $ls;
				p @reqd_coords;
				die 'the above coordinates must be defined.'
			}
			my $x = join (',', @{ $ls }{'x0', 'x1'});
			my $y = join (',', @{ $ls }{'y0', 'y1'});
			my $linestyle = $ls->{linestyle} // 'dashed';
			my $color = $ls->{color} // 'red';
			my $options = "linestyle = '$linestyle', color = '$color'";
			if (defined $ls->{label}) {
				$ls->{label} =~ s/'/\\'/g;
				$options .= ", label = '$ls->{label}'";
			}
			say $fh "plt.plot([$x], [$y], $options)";
		}
	}
	if (defined $args->{logscale}) {
		if (ref $args->{logscale} ne 'ARRAY') {
			die 'logscale should be an array of axes like ["x", "y"]' # this error message is more meaningful
		}
		foreach my $axis (@{ $args->{logscale} }) { # x, y 
			say $fh "plt.$axis" . 'scale("log")';
		}
	}
	$args->{legend} = $args->{legend} // 0;
	if ((looks_like_number($args->{legend})) && ($args->{legend} > 0)) {
		say $fh 'plt.legend()';
	} elsif ((looks_like_number($args->{legend})) && ($args->{legend} == 0)) {
	} else {
		say $fh "plt.legend($args->{legend})"; # e.g. "loc = 8" for location code https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.legend.html
	}
	say $fh "plt.savefig('$args->{'output.filename'}', bbox_inches = 'tight', metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	$args->{execute} = $args->{execute} // 1;
	if ($args->{execute} == 0) {
		say $fh 'plt.close()';
		if ($fig_present == 0) {
			say $fh 'del x, y';
		} else {
			say $fh 'del fig, ax, x';
		}
	}
	close $fh;
	if ($args->{execute} > 0) {
		execute("python3 $temp_py");
		say 'wrote ' . colored(['cyan on_bright_green'], "$args->{'output.filename'}");
	} else { # not running yet
		say 'will write ' . colored(['cyan on_green'], "$args->{'output.filename'}");
	}
	return $args->{'output.filename'};
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

sub hist2d_in_rows {
=example
@d looks like

[
 [0] [
         [0] [	# x axis
                 [0] 801.5,
                 [1] 802.5,
                 [2] 803.5,
             ],
         [1] [	# y axis
                 [0] 33.4982,
                 [1] 32.7278,
                 [2] 33.4982,
             ]
     ],
 [1] [
         [0] [
                 [0] 268.5,
                 [1] 269.5,
                 [2] 270.5,
                     (...skipping 97 items...)
             ],
         [1] [
                 [0] 33.8834,
                 [1] 33.8834,
                 [2] 35.039,
                     (...skipping 97 items...)
             ]
     ],

	hist2d_in_rows({
		cblabel		=> 'Hit Density (# of Proteins)',
		filename		=>	$svg_output,
		figheight	=> 3*$scale,
		figwidth		=> 4*$scale,
		data			=> \@d,
		plot_type	=> \@plot_type,
		ax_methods	=> \@ax_methods,
		plot_params	=> \@plot_params,
		xlabel		=> 'Amino Acid Residue',
		hist2d_bins	=> $length/20,
		xlim			=> [0, $length],
		title			=> $title,
		yaxis_off	=> [undef,undef,undef,undef,1]
	});
=cut
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	my ($args) = @_;
	my @reqd_args = (
		'data',		# array of hashes
		'filename'	# include file type extension, e.g. ".svg"
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die "the above args are necessary for $current_sub, but were not defined.";
	}
	my @defined_args = (
		'ax_methods',	# a list/array of hashes https://matplotlib.org/stable/api/axes_api.html
		'cblabel',		# label for colorbar, accepts string
#		'cb_logscale',	# default off
		'figheight', 'figwidth',
		'hist2d_bins',	# no. of bins for hist2d, by default 10
		'legend',
		'ncols',			# default 1
		'plot_params',	# array of hashes
		'plot_type',	# an array: e.g. "hist2d", by default "plot"
		'sharex',		# sharex according to plt.subplots, by default true
		'yaxis_off', 	# deactivate the y-axis for these groups, an array
#		'ylabel',		# an array for each data group
		'ylim', 			# e.g. [0,1]
	@reqd_args);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
# https://stackoverflow.com/questions/45841786/creating-a-1d-heat-map-from-a-line-graph
	$args->{figheight} = $args->{figheight} // 4.8;
	$args->{figwidth}  = $args->{figwidth}  // 6.4;
	my $unlink = 0;
	my ($py, $temp_py) = tempfile(DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink);
	say 'temp file is ' . colored(['white on_blue'], $temp_py) . ' from ' . __FILE__ . " in $current_sub" if $unlink == 0;
	say $py 'import matplotlib.pyplot as plt';
	
	$args->{cb_logscale} = $args->{cb_logscale} // 0; # default is off
#	if ($args->{cb_logscale} > 0) {
#		say $py 'from matplotlib.colors import LogNorm';
#	}
	my @hist2d_plot_indices;
	if (defined $args->{plot_type}) { # avoids an error
		@hist2d_plot_indices = grep {$args->{plot_type}[$_] eq 'hist2d'} 0..scalar @{ $args->{plot_type} }-1;
	}
	if (scalar @hist2d_plot_indices > 0) {# plot the 2d histogram so that counts can be determined
#https://stackoverflow.com/questions/78020884/hist2d-plots-with-vmin-vax-unknown-until-plotting-with-combined-colorbar-previo/78022097#78022097
		say $py 'import matplotlib.pyplot as plt';
		say $py 'from matplotlib.ticker import MaxNLocator';
		say $py 'import numpy as np';
		say $py 'xmax = float("-inf")';
		say $py 'xmin = float("inf")';
		foreach my $r (@hist2d_plot_indices) {
			say $py "x$r = [" . join (',',  @{ $args->{data}[$r][0] }) . ']';
			say $py "y$r = np.array([" . join (',',  @{ $args->{data}[$r][1] }) . '])';
			say $py "xmax = max(xmax,max(x$r))";
			say $py "xmin = min(xmin,min(x$r))";
		}
		$args->{hist2d_bins} = int $args->{hist2d_bins} // 10;
		my $bins1 = $args->{hist2d_bins} + 1;
		say $py "bins = (np.linspace(xmin,xmax,$bins1), $args->{hist2d_bins})";
		foreach my $r (@hist2d_plot_indices) {
			say $py "h$r, _, _ = np.histogram2d(x$r, y$r, bins=bins)";
		}
		my @h = map {"h$_"} @hist2d_plot_indices;
		say $py 'h = [' . join (',', @h) . ']';
		say $py 'colormin = min(hi.min() for hi in h)';
		say $py 'colormax = max(hi.max() for hi in h)';
	}
	my $nrows = scalar @{ $args->{data} };
#	my @ax = map {"axes$_"} 0..$nrows-1;
	$args->{sharex} = $args->{sharex} // 'True';
	$args->{ncols} = $args->{ncols} // 1;
	say $py "fig, axes = plt.subplots(nrows = $nrows, ncols = $args->{ncols}, sharex = $args->{sharex}, figsize = ($args->{figwidth}, $args->{figheight}))";
	foreach my $r (0..scalar @{ $args->{data} } - 1) { # for each plot/row $r
#		say $py "axes[$r].set_ylabel('$args->{ylabel}[$r]')" if defined $args->{ylabel}[$r];
#		say $py "axes[$r].set_title('$args->{subtitles}[$r]')" if defined $args->{subtitles}[$r];
		if (defined $args->{yaxis_off}[$r]) {
			say $py "axes[$r].get_yaxis().set_visible(False)";
		}
		my $plot_type = $args->{plot_type}[$r] // 'plot';
		next if $plot_type eq 'hist2d'; # because of normalization, these are later
		foreach my $s (keys %{ $args->{data}[$r] }) { # $s for "set"
			my @plot_params = "label = '$s'";
			while (my ($param, $value) = each %{ $args->{plot_params}[$r]{$s} }) {
				if (looks_like_number($value)) {
					push @plot_params, "$param = $value";
				} elsif ($value =~ m/^\d+,\s*\d+\.\d+$/) {
					push @plot_params, "$param = $value";
				} else {
					push @plot_params, "$param = '$value'";
				}
			}
#			if ($args->{cb_logscale} > 0) {
#				push @plot_params, 'norm = LogNorm()';
#			}
			if (scalar @{ $args->{data}[$r]{$s} } == 2) { # conventional plotting; hist2d uses this
				say $py "h$r = axes[$r].$plot_type([" . join (',', @{ $args->{data}[$r]{$s}[0] }) .' ], [' . join (',', @{ $args->{data}[$r]{$s}[1] }) . '],' . join (',', @plot_params) . ')';
#				say $py "h$r = axes[$r].$plot_type([" . join (',', @{ $args->{data}[$r][0] }) .' ], [' . join (',', @{ $args->{data}[$r][1] }) . '],' . join (',', @plot_params) . ')';
#			} elsif (scalar @{ $args->{data}[$r]{$s} } == 2) { # conventional plotting
			} else #if (
#					(ref $args->{data}[$r]{$s} eq 'HASH') # line_segments or text
				{
	# plotting with helper functions
				if (defined $args->{data}[$r]{line_segments}) {
					my ($ymin, $ymax) = ('inf', '-inf');
					foreach my $segm (@{ $args->{data}[$r]{line_segments} }) {
						foreach my $pt (0,1) {
							$ymin = min($ymin, $segm->[$pt][1]);
							$ymax = max($ymax, $segm->[$pt][1]);
						}
					}
					my %args = (
						fh						=> $py,
						object				=> "axes[$r]",
						'line.segments'	=> $args->{data}[$r]{line_segments},
						ylim					=> [$ymin-1, $ymax+1]
					);
					if (defined $args->{data}[$r]{colors}) {
						$args{colors} =  $args->{data}[$r]{colors};
					}
					line_segments({%args});
				}
				if (defined $args->{data}[$r]{text}) {
					text({
						fh			=> $py,
						text		=> $args->{data}[$r]{text},
						object	=> "axes[$r]",
					});
				}
			}
			say $py "axes[$r].legend()" if defined $args->{legend}[$r]; # must be *after* plot
		}
		if (defined $args->{ax_methods}[$r]) {
			while (my ($method, $value) = each %{ $args->{ax_methods}[$r] }) {
				if (
						(looks_like_number($value))
						||
						($value =~ m/^\d+,\s*\d+\.?\d*$/)# like ax0.set_xlim(0, 99)
					) {
					say $py "axes[$r].$method($value)";
				} elsif ($value eq '') {
					say $py "axes[$r].$method()";
				} else {
					say $py "axes[$r].$method('$value')";
				}
			}
		}
#		if ($args->{plot_type}[$r] eq 'hist2d') {	# colorbars for individual subplots
#			say $py "fig.colorbar(h$r\[3], ax = ax$r)";
#		}
	}
	if (scalar @hist2d_plot_indices > 0) { # if there are hist2d plots
		my @y = map {"y$_"} @hist2d_plot_indices;
		say $py 'for ax, hi, yi in zip(axes.flat, h, [' . join (',', @y) . ']):';
    	say $py '	im = ax.imshow(hi.T, vmin=colormin, vmax=colormax, origin="lower", aspect="auto",   extent=[xmin, xmax, yi.min(), yi.max()], cmap="turbo")';
    	$args->{cblabel} = ", label = '$args->{cblabel}'" // '';
    	say $py "cbar = fig.colorbar(im, ax=axes.ravel().tolist() $args->{cblabel})";
		say $py 'cbar.ax.yaxis.set_major_locator(MaxNLocator(integer=True))';# force integer ticks
		foreach my $r (0..scalar @{ $args->{ax_methods} } - 1) {
			while (my ($method, $value) = each %{ $args->{ax_methods}[$r] }) {
				if (
						(looks_like_number($value))
						||
						($value =~ m/^\d+,\s*\d+\.?\d*$/)# like ax0.set_xlim(0, 99)
					) {
					say $py "axes[$r].$method($value)";
				} elsif ($value eq '') {
					say $py "axes[$r].$method()";
				} else {
					say $py "axes[$r].$method('$value')";
				}
			}
		}
	}
	$args->{xlabel} = $args->{xlabel} // 'Amino Acid Residue (MSA Coordinate)';
	if (defined $args->{title}) {
		$args->{suptitle} = $args->{title};
	}
	foreach my $arg (grep {defined $args->{$_}} ('xlabel', 'suptitle')) {
		say $py "plt.$arg('$args->{$arg}')";
	}
	say $py 'fig.tight_layout(pad = 0.5)' if scalar @hist2d_plot_indices == 0;
	if (defined $args->{xlim}) {
		say $py 'plt.xlim(' . join (',', @{ $args->{xlim} }) . ')';
	}
	say $py "plt.savefig('$args->{filename}', bbox_inches = 'tight', metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	close $py;
	execute("python3 $temp_py");
	say 'wrote ' . colored(['cyan on_bright_yellow'], "$args->{filename}");
	return $args->{filename};
}
sub histogram {
=histogram({
	data	=> {
		W	=> generate_normal_dist(100, 15, 210*100),
		B	=> generate_normal_dist(85, 15, 41*100)
	},
	'output.filename' => '/tmp/overlapping.histogram.svg',
	bins	=> {
		W	=> 100,
		B	=> 100
	},
	legend	=> 'loc="upper right"',
	title		=> '"IQ Distribution"',
	xlabel	=> '"IQ"',
	ylabel	=> '"# of People in the USA"'
});
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'data',					# hash of arrays
		'output.filename',	# output, "file.svg" or whatever; otherwise file returns string
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = (
		'bins',					# a hash for each group in data
		'execute',		# execute the python file or not; default 1 = yes
		'input.file',		# instead of lots of files, run all plots together in this file
		@ax_methods, @plt_methods,	@fig_methods,
	@reqd_args);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my $data_ref = ref $args->{data};
	unless ($data_ref eq 'HASH') {
		die "$current_sub data should be a HASH, but $data_ref was entered";
	}
	my $unlink = 0;
	my ($fh, $temp_py);
	if (defined $args->{'input.file'}) {
		$temp_py = $args->{'input.file'};
		open $fh, '>>', $args->{'input.file'};
	} else {
		($fh, $temp_py) = tempfile(DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink);
	}
	say $temp_py if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'plt.figure()';
	my ($ax_present, $fig_present) = (0,0);
	if (grep {defined $args->{$_}} (@ax_methods, @fig_methods)) {
		$fig_present = 1;
		say $fh 'fig, ax = plt.subplots()';
	}
	foreach my $set (sort keys %{ $args->{data} }) {
		my $bins = '';
		if (defined $args->{bins}{$set}) {
			$bins = ", bins = $args->{bins}{$set}";
		}
		say $fh 'plt.hist([' . join (',', @{ $args->{data}{$set} }) . "] $bins, alpha = 0.5, label = '$set')";
	}
	foreach my $method (grep {defined $args->{$_}} @ax_methods) {
		my $ref = ref $args->{$method};
		if ($ref eq '') {
			say $fh "ax.$method($args->{$method})";
		} elsif ($ref eq 'ARRAY') {
			foreach my $ax (@{ $args->{$method} }) {
				say $fh "ax.$method($ax)";
			}
		} else {
			p $args;
			die "$ref only accepts scalar or array types";
		}
	}
	foreach my $method (grep {defined $args->{$_}} @plt_methods) {
		my $ref = ref $args->{$method};
		if ($ref eq '') {
			say $fh "plt.$method($args->{$method})";
		} elsif ($ref eq 'ARRAY') {
			foreach my $plt (@{ $args->{$method} }) {
				say $fh "plt.$method($plt)";
			}
		} else {
			p $args;
			die "$ref only accepts scalar or array types";
		}
	}
	say $fh "plt.savefig('$args->{'output.filename'}', bbox_inches = 'tight', metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	$args->{execute} = $args->{execute} // 1;
	if ($args->{execute} == 0) {
		if ($fig_present == 0) {
			say $fh 'del labels, vals';
		} else {
			say $fh 'del fig, ax, labels, vals';
		}
	}
	close $fh;
	if ($args->{execute} > 0) {
		execute("python3 $temp_py");
		say 'wrote ' . colored(['cyan on_bright_yellow'], "$args->{'output.filename'}");
	} else { # not running yet
		say 'will write ' . colored(['cyan on_bright_yellow'], "$args->{'output.filename'}");
	}
}
#sub histogram {
=example
	histogram({
		plt_methods => {
			title		=> "'$density_data->[1] queries without hits', fontsize = 12",
			suptitle	=> "'$title', fontsize = 24",
			xlabel	=> '"Expectation Value"',
			ylabel	=> '"Count"'
		},
		data		=> $density_data->[0],
		filename	=> "svg/$species.histogram.svg",
		logscale	=> ['x','y'],
		nbins		=> 60,
	#	xlim		=> [-0.01,0.12]
	});
#=cut
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	my ($args) = @_;
	my @reqd_args = (
	'data',
	'filename');
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	die 'data must be an array' unless ref $args->{data} eq 'ARRAY';
	die 'data is empty' if scalar @{ $args->{data} } == 0;
	my @defined_args = ('color', 'edge.color', 'figheight', 'figwidth', 'labelright', 'legend',
	'logscale',
	'nbins',
	'plt_methods',
	'suptitle',
	'title', 'xlabel', 'xlim', 'ylabel', @reqd_args);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	if (defined $args->{logscale}) {
		if (ref $args->{logscale} ne 'ARRAY') {
			die 'logscale should be an array of axes like ["x", "y"]' # this error message is more meaningful
		}
	}
#---------
	my $unlink = 1;
	my ($fh, $filename) = tempfile (UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say $filename if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'from matplotlib.ticker import PercentFormatter';
	$args->{nbins} = $args->{nbins} // 20;
# Creating histogram
	say $fh 'x = [' . join (',', @{ $args->{data} }) . ']';
	$args->{figheight} = $args->{figheight} // 6.4;
	$args->{figwidth}  = $args->{figwidth}  // 4.8;
	say $fh "fig, axs = plt.subplots(1, 1, figsize =($args->{figheight}, $args->{figwidth}), tight_layout = True)";
	my $xlogscale = false;
	if ((defined $args->{logscale}) && (grep {$_ eq 'x'} @{ $args->{logscale} })) {
		say $fh 'import numpy as np';
		say $fh "bins = np.logspace(np.log10(min(x)), np.log10(max(x)), $args->{nbins})";
		$xlogscale = true;
	}
 	if (grep { defined $args->{$_} } ('color', 'edge.color')) {
 		my @color;
 		push @color, "color = '$args->{color}'"     if defined $args->{color};
 		push @color, "ec = '$args->{'edge.color'}'" if defined $args->{'edge.color'};
 		my $color = ', ' . join (',', @color);
 		if ($xlogscale == true) {
 			say $fh "axs.hist(x, bins = bins $color)";
 		} else { # non-logarithmic/regular
	 		say $fh "axs.hist(x, bins = $args->{nbins} $color)";
	 	}
 	} else {
 		if ($xlogscale == true) {
 			say $fh 'axs.hist(x, bins = bins)';
 		} else {
			say $fh "axs.hist(x, bins = $args->{nbins})";
		}
	}
	$args->{labelright} = $args->{labelright} // 0; # by default, labels on the right side are off
	if ($args->{labelright} > 0) {
		say $fh 'plt.tick_params(labelright = True, right = True, axis = "both", which = "both")';
	}
	if (defined $args->{logscale}) {
		foreach my $axis (@{ $args->{logscale} }) { # x, y 
			say $fh "plt.$axis" . 'scale("log")';
		}
	}
	if (defined $args->{xlim}) {
		say $fh 'plt.xlim(' . join (',', @{ $args->{xlim} }) . ')';
	}
	foreach my $method (keys %{ $args->{plt_methods} }) {
		say $fh "plt.$method( $args->{plt_methods}{$method} )";
	}
	say $fh "plt.savefig('$args->{filename}', bbox_inches = 'tight', metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
#	say $fh "plt.savefig('$args->{filename}', bbox_inches='tight', pad_inches = 0.1, metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript'})";
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
	say 'wrote ' . colored(['black on_bright_red'], $args->{filename});
	return $args->{filename}
}
=cut
=example histogram
my @x;
foreach (0..99) {
	push @x, rand(10);
}
histogram({
	filename   => 'images/histogram',
	data       => \@x,
	xlabel     => 'x',
	labelright => 1,
	title      => 'title',
	color      => 'red',
	'edge.color' => 'yellow'
});
=cut

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
		if (-f $f) {
			if ($directory eq '.') {
				push @files, $file
			} else {
				push @files, $f
			}
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

=example use
my %d;

each graph/line is its own hash key with an x and y key each

$d{flatline}{x} = [1..5];
$d{flatline}{y} = [map {3} 1..5];
$d{'sin(x)'}{x} = [1..5];
$d{'sin(x)'}{y} = [map {sin($_)} 1..5];
$d{flatline}{linestyle} = ':';

multiline_plot({
	filename => 'images/potential.roc',
	data     => \%d,
	title    => 'potential ROC',
	ylabel   => 'TPR',
	xlabel   => 'FPR',
});
=cut

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

sub plot { # minimal plotting function
	my ($args) = @_;
	my @reqd_args = ('data.file', 'output.image');
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = (@reqd_args, 'figwidth', 'shaded.regions', 'title', 'xlabel',
	'xlim', # e.g. [0,4]
	'ylabel',
	'ylim', # e.g. [0,4]
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	if (grep {not defined $args->{$_}} keys %{ $args }) {
		p $args;
		my $current_sub = (split(/::/,(caller(0))[3]))[-1];
		die "undefined arguments were given to $current_sub";
	}
	my ($py, $py_filename) = tempfile(DIR => '/tmp', UNLINK => 1, SUFFIX => '.py');
	say $py 'import matplotlib.pyplot as plt';
	say $py 'from pandas import read_csv';
	say $py "data = read_csv('$args->{'data.file'}', comment = '#', delimiter = '\\t', names = ['x', 'y'])";
	$args->{figwidth} = $args->{figwidth} // 6.4;
	say $py "plt.plot(data['x'], data['y'])";
#	say $py "plt.figure().set_figwidth($args->{figwidth})";
	foreach my $item (grep {defined $args->{$_}} ('title', 'xlabel', 'ylabel')) {
		if ($args->{$item} =~ m/"/) {
			say $py "plt.$item('$args->{$item}')";
		} elsif ($args->{$item} =~ m/'/) {
			say $py "plt.$item(\"$args->{$item}\")";
		} else {
			say $py "plt.$item('$args->{$item}')";
		}
	}
	# shade regions if so desired
	foreach my $region ( @{ $args->{'shaded.regions'} } ) {
		say $py "plt.axvspan($region->[0], $region->[1], color='green', alpha = 0.5)";
	}
	foreach my $arg (grep { defined $args->{$_} } ('xlim', 'ylim')) {
		say $py "plt.$arg(" . join (',', @{ $args->{$arg} }) . ')';
	}
	say $py "plt.savefig('$args->{'output.image'}', metadata={'Creator': 'made/written by" . getcwd() . "/$RealScript'})";
	close $py;
	# now execute the file
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $py_filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die "python3 failed";
	}
	say colored(['bright_magenta on_black'], "wrote $args->{'output.image'}");
}
sub plots_in_rows {
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

or another example:
	plots_in_rows({
		filename	=> $similarity_svg,
		figwidth	=> 12,
		data		=> {
			hosts			=> [
				[0..$max_n],
				$group_similarity->{hosts}
			],
			pathogens	=> [
				[0..$max_n],
				$group_similarity->{pathogens}
			],
			domains		=> $domains
		},
		xlabel		=> 'MSA amino acid index',
		yaxis_off	=> ['domains'],
		ylabel		=> { # no ylabel for domains
			hosts			=> 'Φ',
			pathogens	=> 'Φ',
		},
		order			=> ['hosts', 'pathogens', 'domains'],
		xlim			=> [0,$max_n],
		ylim			=> [-0.05,1.05],
		title			=> $gene
	});
=cut
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
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
	my @undef_grps = grep {not defined $args->{data}{$_}} (sort keys %{ $args->{data} });
	if (scalar @undef_grps > 0) {
		p $args->{data};
		p @undef_grps;
		die "the above groups are not defined in \"$current_sub\"";
	}
	my @defined_args = (
		'figheight', 'figwidth',
		'line.segments',	# call the helper function
		'order',
		'title',	# this is sent to suptitle; "title" won't work here
		'xlabel',# overall xlabel for all plots
		'xlim', 	# e.g. [0,1]
		'yaxis_off', # deactivate the y-axis for these groups, an array
		'ylabel',# a hash for each data group
		'ylim', 	# e.g. [0,1]
	@reqd_args);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
# https://stackoverflow.com/questions/45841786/creating-a-1d-heat-map-from-a-line-graph
	if (defined $args->{ylabel}) {
		my $ref = ref $args->{ylabel};
		unless ($ref eq 'HASH') {
			die "ylabel arg is a \"$ref\", while it must be a hash for each group in \"data\" for $current_sub";
		}
	}
	my @order;
	if (defined $args->{order}) {
		@order = @{ $args->{order} };
	} else {
		@order = sort {lc $a cmp lc $b} keys %{ $args->{data} };
	}
	$args->{figheight} = $args->{figheight} // 4.8;
	$args->{figwidth}  = $args->{figwidth}  // 6.4;
	my $unlink = 0;
	my ($py, $temp_py) = tempfile(DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink);
	say "temp file is $temp_py from " . __FILE__ . " in $current_sub" if $unlink == 0;
	say $py 'import matplotlib.pyplot as plt';
	my $nrows = scalar @order;
	my @ax = map {"ax$_"} 0..$#order;
	say $py 'fig, (' . join (',', @ax) . ") = plt.subplots(nrows = $nrows, sharex = True, figsize = ($args->{figwidth}, $args->{figheight}))";
	while (my ($n, $group) = each @order) {
#		say $py "ax$n.set_ylabel('$args->{ylabel}{$group}') " if defined $args->{ylabel}{$group};
		say $py "ax$n.set_title('$group')";
		if ((defined $args->{yaxis_off}) && (grep {$_ eq $group} @{ $args->{yaxis_off} })) {
			say $py "ax$n.get_yaxis().set_visible(False)";
		}
		if (ref $args->{data}{$group} eq 'ARRAY') { # simple 1 group plot
 # plotting conventionally
			say $py "ax$n.plot([" . join (',', @{ $args->{data}{$group}[0] }) .' ], [' . join (',', @{ $args->{data}{$group}[1] }) . '])';
			foreach my $arg (grep { defined $args->{$_} } ('xlim', 'ylim')) {
				say $py "ax$n.set_$arg(" . join (',', @{ $args->{$arg} }) . ')';
			}
		} elsif (
				(ref $args->{data}{$group} eq 'HASH') # line_segments or text
			) {
# plotting with helper functions
			if (defined $args->{data}{$group}{line_segments}) {
				my ($ymin, $ymax) = ('inf', '-inf');
				foreach my $segm (@{ $args->{data}{$group}{line_segments} }) {
					foreach my $pt (0,1) {
						$ymin = min($ymin, $segm->[$pt][1]);
						$ymax = max($ymax, $segm->[$pt][1]);
					}
				}
				line_segments({
					fh						=> $py,
					object				=> "axes$n",
					'line.segments'	=> $args->{data}{$group}{line_segments},
					ylim					=> [$ymin-1, $ymax+1]
				});
			}
			if (defined $args->{data}{$group}{text}) {
				text({
					fh			=> $py,
					text		=> $args->{data}{$group}{text},
					object	=> "axes$n",
				});
			}
		}
	}
	if (defined $args->{xlim}) {
		say $py "plt.xlim($args->{xlim}[0], $args->{xlim}[1])";
	}
	$args->{xlabel} = $args->{xlabel} // 'Amino Acid Residue (MSA Coordinate)';
	if (defined $args->{title}) {
		$args->{suptitle} = $args->{title};
	}
	foreach my $arg (grep {defined $args->{$_}} ('xlabel', 'suptitle')) {
		say $py "plt.$arg('$args->{$arg}')";
	}
	say $py 'fig.tight_layout(pad = 1.0)';
	say $py "plt.savefig('$args->{filename}', metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	close $py;
	execute("python3 $temp_py");
	say 'wrote ' . colored(['cyan on_bright_yellow'], "$args->{filename}");
	return $args->{filename};
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

sub scatterplot {
=data should look like
{
    F.solani      {		# this is a set, indicated on the legend
        cousin       [	# one axis, x or y
            [0] 406,
            [1] 1222,
                (...skipping 1016 items...)
        ],
        sambucinum   [	# the other axis, y or x
            [0] 49,
            [1] 154,
                (...skipping 1016 items...)
        ]
    },
    F.venenatum   {		# this is a set, indicated on the legend
        cousin       [	# one axis, x or y
            [0] 483,
            [1] 1242,
                (...skipping 1009 items...)
        ],
        sambucinum   [	# one axis, x or y
            [0] 49,
            [1] 154,
                (...skipping 1009 items...)
        ]
    }
}
----------------------
an example calling looks like:
----------------------
scatterplot({
	filename => "svg/$metric" . '_compare',
	data		=> \%scatter_data,
	title		=> $metric,
	axes		=> ['sambucinum', 'cousin'],
	line_segment => [
		{
			x0 => 0, y0 => 0,
			x1 => $max, y1 => $max
		},
	]
});
	
	or
	
scatterplot({
	filename => "sort/$q" . '_scatter',
	data		=> {
		hosts => {
			'Alignment length (a.a.)' => $stat{$q}{hosts}{align_len},
			'Evalue' => $stat{$q}{hosts}{evalue}
		},
		pathogens => {
			'Alignment length (a.a.)' => $stat{$q}{pathogens}{align_len},
			'Evalue' => $stat{$q}{pathogens}{evalue}
		},
	},
	logscale		=> ['y'],
	plot_params	=> {
		hosts			=> {
			facecolors => '"none"', edgecolors => '"blue"',		label => '"hosts"'
		},
		pathogens	=> {
			facecolors => '"none"', edgecolors => '"orange"',	label => '"pathogens"'
		},
	},
	title			=> '$\it{S. cerevisiae}$ ' . "$q: $deg_annotation->{$q}{'Gene Name'}",
	ylabel		=> 'log(Evalue+10⁻¹⁸⁰)' # https://lingojam.com/SuperscriptGenerator
});
	
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = ('data', 'filename');
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	if (scalar keys %{ $args->{data} } == 0) {
		p $args;
		die "$current_sub was given an empty dataset.";
	}
	my @defined_args = ( @reqd_args,
	'axes',	# define the order of the axes, must match the second hash indices
	'custom_legend', 'figwidth', 'grid',
	'labelright', 'labels', 'legend',
	'legend.position',# possible values are 'outside upper left', 'outside upper center', 'outside upper right','outside center right', 'upper center left','outside lower right', 'outside lower center', 'outside lower left', or just "default"
	'line_segment',	# draw line segments, specify as array of hash
	'logscale',			# specify which axes should be logscale, e.g. logscale => ['x', 'y']
	'labelsize', 'minor_gridlines',
	'plot_params',		# plot details for each group in "data": marker type, facecolors, edgecolors, etc.
	'output_type',
	'title',
	'title_params', # hash of parameter and value https://matplotlib.org/stable/users/explain/text/text_props.html
	'xlabel',		# string
	'ylabel',		# string
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args, array_max => scalar @defined_args;
		die 'The above args are accepted.'
	}
	my %axes;
	foreach my $set (keys %{ $args->{data} }) {
		foreach my $axis (keys %{ $args->{data}{$set} }) {
			$axes{$axis}++;
		}
	}
	if (scalar keys %axes != 2) {
		p $args->{data};
		say STDERR 'the above data set has the following axes (keys) and their number of appearances (values):';
		p %axes;
		die 'there must be exactly two axes';
	}
	my @axes;
	if (defined $args->{axes}) {
		@axes = @{ $args->{axes} };
	} else {
		@axes = sort {lc $a cmp lc $b} keys %axes;
	}
	my $unlink = 0;
	my ($fh, $tempfile) = tempfile (UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say colored(['blue on_yellow'], $tempfile) if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'fig, ax = plt.subplots(layout = "constrained")';
	foreach my $set (sort {lc $a cmp lc $b} keys %{ $args->{data} }) {
#		my $options = '';
#		if ((defined $args->{colors}) && (defined $args->{colors}{$set})) {
#			$options = ", color = '$args->{colors}{$set}'";
#		}
#		if (defined $args->{marker}{$set}) {
#			$options .= ", marker = '$args->{marker}{$set}'"
#		}
		if (defined $args->{plot_params}{$set}) {
			my @params = ("label = '$set'");
			foreach my $param (grep {ref $args->{plot_params}{$set}{$_} eq ''} keys %{ $args->{plot_params}{$set} }) { # skip arrays and hashes
				if (looks_like_number($args->{plot_params}{$set}{$param})) {
					push @params, "$param = $args->{plot_params}{$set}{$param}";
				} else {
					push @params, "$param = '$args->{plot_params}{$set}{$param}'";
				}
			}
			foreach my $param (grep {ref $args->{plot_params}{$set}{$_} eq 'ARRAY'} keys %{ $args->{plot_params}{$set} }) { # skip arrays and hashes
				push @params, 's = [' . join (',', @{ $args->{plot_params}{$set}{$param} }) . ']'
			}
			say $fh 'plt.scatter([' . join (',', @{ $args->{data}{$set}{$axes[0]} }) . '], [' . join (',', @{ $args->{data}{$set}{$axes[1]} }) . '], ' . join (',', @params) . ')';
		} else {
			say $fh 'plt.scatter([' . join (',', @{ $args->{data}{$set}{$axes[0]} }) . '], [' . join (',', @{ $args->{data}{$set}{$axes[1]} }) . "], label = '$set')";
		}
	}
	$args->{xlabel} = $args->{xlabel} // $axes[0];
	$args->{ylabel} = $args->{ylabel} // $axes[1];
	foreach my $arg ('title', 'xlabel', 'ylabel') {
		if (defined $args->{$arg}) {
			$args->{$arg} =~ s/'/\\'/g;
			my $param_key = $arg . '_params';
			my $params = '';
			if (defined $args->{$param_key}) {
				my @params;
				while (my ($key, $value) = each %{ $args->{$param_key} }) {
					if (looks_like_number($value)) {
						push @params, "$key = $value";
					} else {
						push @params, "$key = '$value'";
					}
				}
				$params = ',' . join (',', @params);
			}
			say $fh "plt.$arg('$args->{$arg}' $params)";
		}
	}
	if (defined $args->{logscale}) {
		if (ref $args->{logscale} ne 'ARRAY') {
			die 'logscale should be an array of axes like ["x", "y"]' # this error message is more meaningful
		}
		foreach my $axis (@{ $args->{logscale} }) { # x, y 
			say $fh "plt.$axis" . 'scale("log")';
		}
	}
	if (defined $args->{line_segment}) {
=example
	line_segment => {
		'x0' => 0, 'x1' => 1, # 1st point
		'y0' => 0, 'y1' => 1, # 2nd point
		linestyle => 'dashed', color => 'red', label => "D' = R^2"
	},
		my $x = join (',', @{ $args->{line_segment} }{'x0', 'x1'});
		my $y = join (',', @{ $args->{line_segment} }{'y0', 'y1'});
		my $linestyle = $args->{line_segment}{linestyle} // 'dashed';
		my $color = $args->{line_segment}{color} // 'red';
		my $options = "linestyle = '$linestyle', color = '$color'";
		if (defined $args->{line_segment}{label}) {
			$args->{line_segment}{label} =~ s/'/\\'/g;
			$options .= ", label = '$args->{line_segment}{label}'";
		}
		say $fh "plt.plot([$x], [$y], $options)";
		printf $fh ("plt.xlim([%lf,%lf])\n", $xmin - ($xmax - $xmin) / 10, $xmax + ($xmax - $xmin) / 10 );
		printf $fh ("plt.ylim([%lf,%lf])\n", $ymin - ($ymax - $ymin) / 10, $ymax + ($ymax - $ymin) / 10 );

#	if (defined $args->{line_segment}) 
=example
	line_segment => [ # array of anonymous hashes
		{
			'x0' => 0, 'x1' => 1, # 1st point
			'y0' => 0, 'y1' => 1, # 2nd point
			linestyle => 'dashed', color => 'red', label => "D' = R^2"
		}
	],
=cut
		foreach my $ls (@{ $args->{line_segment} }) { # hash ref
			my @reqd_coords = ('x0', 'x1', 'y0', 'y1');
			my @undef_args = grep {!defined $ls->{$_}} @reqd_coords;
			if (scalar @undef_args > 0) {
				p @undef_args;
				say STDERR 'the above args are not defined.';
				say STDERR 'the below args are defined:';
				p $ls;
				p @reqd_coords;
				die 'the above coordinates must be defined.'
			}
			my $x = join (',', @{ $ls }{'x0', 'x1'});
			my $y = join (',', @{ $ls }{'y0', 'y1'});
			my $linestyle = $ls->{linestyle} // 'dashed';
			my $color = $ls->{color} // 'red';
			my $options = "linestyle = '$linestyle', color = '$color'";
			if (defined $ls->{label}) {
				$ls->{label} =~ s/'/\\'/g;
				$options .= ", label = '$ls->{label}'";
			}
			say $fh "plt.plot([$x], [$y], $options)";
		}
	}
	$args->{legend} = $args->{legend} // 1;
	if (defined $args->{custom_legend}) {
# https://matplotlib.org/stable/gallery/text_labels_and_annotations/custom_legends.html
		say $fh 'legend_elements = [' . join (',', @{ $args->{custom_legend} }) . ']';
		say $fh 'plt.legend(handles = legend_elements)';
	} elsif ($args->{legend} eq 'default') {
		say $fh 'plt.legend()';
	} elsif ($args->{legend} > 0) { # 0 turns legend off
#		say $fh 'plt.legend()';
		$args->{'legend.position'} = $args->{'legend.position'} // 'outside center right';
		say $fh "fig.legend(loc = '$args->{'legend.position'}')"; # essential when multiple groups are present
	}
	say $fh "plt.savefig('$args->{filename}', bbox_inches='tight', pad_inches = 0.1, metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript'})";
	close $fh;
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $tempfile" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die "python3 failed";
	}
	say 'wrote ' . colored(['black on_bright_green'], $args->{filename});
	return $args->{filename};
}

sub scatterplot_2d_color {
=example:
---------
scatterplot_2d_color({
	filename	=> $svg_name,
	title		=> $title,
	data		=> {
		'Alignment length (a.a.)'	=> [@length],
		'Mean # of Pathogens'	=> [@mean_pathogens],
		'Mean Similarity'			=> [@mean_similarity]
	},
	color_key=>	'Mean Similarity',
	plot_params => {
		alpha => 0.5
	}
});
	----------------
	Req'd options:
	----------------
	data:
input data should look like this:
{
    align_len   [
        [0] 59,
        [1] 59,
            (...skipping 16 items...)
    ],
    evalue      [
        [0] 0.291346,
        [1] 0.33064,
            (...skipping 16 items...)
    ],
    score       [
        [0] 81,
        [1] 81,
            (...skipping 16 items...)
    ]
} (3K)
	the 3rd key (sorted case-insensitive alphabetically) will be the color key if "color_key" isn't specified
	the xlabel, ylabel, and color label are the key names themselves.  "xlabel", "ylabel", etc. aren't accepted
	another example:
		scatterplot_2d_color({
#		adjust_text	=> 1,
		annotate		=> 1, # use the arrow annotation
#		function => { # plot this function within the scatterplot
#			min	=> 0,
#			max	=> $xint,
#			func	=> "-(10.0/($xint*$xint))*(x+$xint)*(x-$xint)",
#			step	=> 1
#		},
		cb_min		=> 0,
		cb_max		=> 1,
		filename		=> $args->{svg_name},
		title			=> $args->{title},
		data			=> {
			'Alignment length (a.a.)'			=> [@length],
#			'Total Protein Length (a.a.)'		=> [@full_protein_length],
			'Mean Pathogen Column Occupancy'	=> [@mean_pathogens],
			'Mean Pathogen ϕ'						=> [@mean_similarity]
		},
		color_key	=>	'Mean Pathogen ϕ',#'Total Protein Length (a.a.)',
		plot_params => {
			alpha => 0.5
		},
		text			=> [@text],
		xmin			=> 0,
#		xlim			=> [0, 2290],
		ylim			=> [1,10.2]
	});
	where @text is [x, y, text, xtext, ytext] for arrowed annotation
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @undef_args = grep { !defined $args->{$_}} ('data', 'filename');
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = (
	'annotate',		# use annotate function to use arrows for scatterplots
	'adjust_text',	# adjust the text with the "text" helper subroutine.  Set to 1 for "on"
	'cb_min','cb_max', # minimum/maximum color values
	'color_key', 'custom_legend', 'data', 'figwidth', 'filename',
	'function', # hash which takes min, max, func, and step (using "function" helper subroutine)
	'grid',
	'keys', # specify the order, otherwise alphabetical
	'line_segment',
#example
#	line_segment	=> [{
#		'x0'	=> $min,	'x1'	=> $max,
#		'y0'	=> $min,	'y1'	=> $max,
#	}],
	'logscale',			# specify which axes should be logscale, e.g. logscale => ['x', 'y']
	'plot_params',
	'plt_methods', 	# a hash; write *EXACTLY* what goes into the method; e.g. title, etc.
	'text',				# an array of text items to add, each text addition should look like [x, y, text]
	'title',
	'xlabel',
	'ylabel',
	'xlim',				# array of min,max for each
	'xmin', 				# 1 number
	'xshift',			# 1 number, for annotate; how much % of the xaxis is shifted for default arrows
	'ylim',				# array of min,max for each
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die "The above args are accepted by $current_sub"
	}
	my @keys;
	if (defined $args->{'keys'}) {
		@keys = @{ $args->{keys} };
	} else {
		@keys = sort {lc $a cmp lc $b} keys %{ $args->{data} };
	}
	if (scalar @keys != 3) {
		p $args->{data};
		die 'There must be exactly 3 data keys for a 2D scatterplot with color as a 3rd dimension';
	}
	if (defined $args->{color_key}) {
		while (my ($i, $key) = each @keys) {
			next unless $key eq $args->{color_key};
			splice @keys, $i, 1; # remove the color key from @keys
		}
	} else {
		$args->{color_key} = pop @keys;
	}
	if (not defined $args->{data}{$args->{color_key}}) {
		p $args->{data};
		die "\"$args->{color_key}\" isn't defined as a key in \"data\"";
	}
	my %lengths = map { $_ => scalar @{ $args->{data}{$_} }} (@keys, $args->{color_key});
	my %unique_lengths = map { $_ => 1 } values %lengths;
	if (scalar keys %unique_lengths != 1) {
		p %lengths;
		die 'There is some mismatch in entry data, all keys should have the same length';
	}
	my $unlink = 1;
	my ($fh, $tempfile) = tempfile (UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say $tempfile if $unlink == 0;
	say $fh "# originally written by $current_sub in " . __FILE__ if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'x = [' . join (',', @{ $args->{data}{$keys[0]} }) . ']';
	say $fh 'y = [' . join (',', @{ $args->{data}{$keys[1]} }) . ']';
	say $fh 'z = [' . join (',', @{ $args->{data}{$args->{color_key}} }) . ']';
	$args->{xlabel} = $args->{xlabel} // $keys[0];
	$args->{ylabel} = $args->{ylabel} // $keys[1];
	say $fh "plt.xlabel('$args->{xlabel}')";
	say $fh "plt.ylabel('$args->{ylabel}')";
	say $fh "plt.title('$args->{title}')" if defined $args->{title};
	if (defined $args->{plot_params}) {
		my @params;
		while (my ($key, $value) = each %{ $args->{plot_params} }) {
			if (looks_like_number($value)) {
				push @params, "$key = $value";
			} else {
				push @params, "$key = '$value'";
			}
		}
		say $fh 'im = plt.scatter(x, y, c = z, cmap = "gist_rainbow", ' . join (',', @params) . ')';
	} else {
		say $fh 'im = plt.scatter(x, y, c = z, cmap = "gist_rainbow")';
	}
	say $fh "plt.colorbar(im, label = '$args->{color_key}')";
	if (defined $args->{logscale}) {
		if (ref $args->{logscale} ne 'ARRAY') {
			p $args->{logscale};
			die 'logscale should be an array of axes like ["x", "y"]' # this error message is more meaningful
		}
		foreach my $axis (@{ $args->{logscale} }) { # x, y 
			say $fh "plt.$axis" . 'scale("log")';
		}
	}
	if (defined $args->{line_segment}) {
		foreach my $ls (@{ $args->{line_segment} }) { # hash ref
			my @reqd_coords = ('x0', 'x1', 'y0', 'y1');
			my @undef_args = grep {!defined $ls->{$_}} @reqd_coords;
			if (scalar @undef_args > 0) {
				p @undef_args;
				say STDERR 'the above args are not defined.';
				say STDERR 'the below args are defined:';
				p $ls;
				p @reqd_coords;
				die 'the above coordinates must be defined.'
			}
			my $x = join (',', @{ $ls }{'x0', 'x1'});
			my $y = join (',', @{ $ls }{'y0', 'y1'});
			my $linestyle = $ls->{linestyle} // 'dashed';
			my $color = $ls->{color} // 'red';
			my $options = "linestyle = '$linestyle', color = '$color'";
			if (defined $ls->{label}) {
				$ls->{label} =~ s/'/\\'/g;
				$options .= ", label = '$ls->{label}'";
			}
			say $fh "plt.plot([$x], [$y], $options)";
		}
	}
	$args->{legend} = $args->{legend} // 0;
	if (defined $args->{custom_legend}) {
# https://matplotlib.org/stable/gallery/text_labels_and_annotations/custom_legends.html
		say $fh 'legend_elements = [' . join (',', @{ $args->{custom_legend} }) . ']';
		say $fh 'plt.legend(handles = legend_elements)';
	} elsif ($args->{legend} > 0) { # 0 turns legend off
		say $fh 'plt.legend()';
	}
	say $fh "plt.clim(vmin = $args->{cb_min})" if defined $args->{cb_min};
	say $fh "plt.clim(vmax = $args->{cb_max})" if defined $args->{cb_max};
	foreach my $arg (grep { defined $args->{$_} } ('xlim', 'ylim')) {
		say $fh "plt.$arg(" . join (',', @{ $args->{$arg} }) . ')';
	}
	if (defined $args->{text}) {
		my %args = (
			object	=> 'plt',
			fh			=> $fh,
			text		=> $args->{text}
		);
		foreach my $arg (grep {defined $args->{$_}} ('adjust_text', 'annotate', 'xshift')) {
			$args{$arg} = $args->{$arg};
		}
		text({%args});
	}
	if (defined $args->{function}) {
		$args->{function}{fh} = $fh;
		function( $args->{function} );
	}
	if (defined $args->{xmin}) {
		say $fh "plt.xlim(left = $args->{xmin})";
	}
	if (defined $args->{xmax}) {
		say $fh "plt.xlim(right = $args->{xmax})";
	}
	foreach my $method (keys %{ $args->{plt_methods} }) {
		say $fh "plt.$method( $args->{plt_methods}{$method} )";
	}
	say $fh "plt.savefig('$args->{filename}', bbox_inches='tight', pad_inches = 0.1, metadata={'Creator': 'made/written by Util.pm\\'s $current_sub " . getcwd() . "/$RealScript'})";
	close $fh;
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $tempfile" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die "\"python3 $tempfile\" failed";
	}
	say 'wrote ', colored(['blue on_bright_yellow'], $args->{filename});
	return $args->{filename}
}
=example scatterplot_2d_color
my %data;
$data{x} = [map {rand($n)} 0..$n];
$data{y} = [map {rand($n)} 0..$n];
$data{z} = [map {rand($n)} 0..$n];

scatterplot_2d_color({
	data        => \%data,
	filename    => 'scatterplot.2d.color',
	xlabel      => 'xlabel',
	ylabel      => 'ylabel',
	color_key   => 'z',
	title       => 'title',
	pointtype   => 7,
});
=cut

sub scatterplot_2d_groups_color {
=subroutine instructions
	data should look like:
	{
    glycine.max         {	# group
        align_len   [		# axis
            [0] 75,
            [1] 75,...
        ],
        evalue      [
            [0] 0.979687,
            [1] 1.07782,
            ...
        ],
        score       [
            [0] 75,
            [1] 75,
            ....
        ]
    },
    oryza.sativa        {
        align_len   [
            [0] 173,
            [1] 65
        ],
        evalue      [
            [0] 0.263218,
            [1] 3.12112
        ],
        score       [
            [0] 77,
            [1] 68
        ]
    },
   ----------------
	Req'd arguments:
	----------------
	color_key:
		which one of the sub-keys/axes should be used for color,
		e.g. "align_len", "evalue", or "score" in the sample data above

	data:
		a hash of hash of arrays, like above
	
	filename:
		the filename, without the file type suffix, ".svg" by default

	x.axis.key
		which one of the axes should be used for the x-axis,
		e.g. "align_len", "evalue", or "score" in the sample data above

	y.axis.key
		which one of the axes should be used for the y-axis,
		e.g. "align_len", "evalue", or "score" in the sample data above

	----------------
	Optional arguments:
	----------------
	legend.position
		where to put the legend. Default 'outside center right',
		but other possible values:
		  'outside left upper',
        'outside right upper',
        'outside left lower',
        'outside center right',
        'outside center left',
        'outside lower center',
        'outside upper center',
        'outside right lower'

	title:
		the plot title

	xlabel:
		by deafult, x.axis.key, but if something better can be used for xlabel, use this

	xmin, xmax
		self-explanatory

	ylabel:
		by deafult, y.axis.key, but if something better can be used for ylabel, use this

	ymin, ymax:
		self-explanaory
=cut
	my ($args) = @_;
	unless (ref $args eq 'HASH') {
		my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = ('data', 'filename');#, 'x.axis.key', 'y.axis.key');
	my @undef_args = grep {!defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'The arguments above are necessary for proper function and weren\'t defined.';
	}
	my @defined_args = (@reqd_args,'color_key', 'color.max', 'color.min', 'figwidth', 'filename', 'legend.position', 'logscale', 'output_type', 'title', 'xlabel', 'xmin', 'xmax', 'ylabel', 'ymin', 'ymax');
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	if (defined $args->{logscale}) {
		die 'logscale should be an array of axes like ["x", "y"]' if ref $args->{logscale} ne 'ARRAY';
	}
	# data check
	my (@axes_check, %axes);
	my ($color_min, $color_max) = ('inf', '-inf');
	if (defined $args->{color_key}) {
		@axes_check = ($args->{'color_key'}, $args->{'x.axis.key'}, $args->{'y.axis.key'});
	} else {
		@axes_check = ($args->{'x.axis.key'}, $args->{'y.axis.key'});
	}
	foreach my $group (keys %{ $args->{data} }) {
		my @axes = keys %{ $args->{data}{$group} };
		my @missing_axes = grep {!defined $args->{data}{$group}{$_}} @axes_check;
		if (scalar @missing_axes > 0) {
			say STDERR "the group \"$group\":";
			p $args->{data}{$group};
			say STDERR 'is missing the following group(s):';
			p @missing_axes;
			die ">= 1 of the above axes are not defined for $group";
		}
		foreach my $axis (keys %{ $args->{data}{$group} }) {
			my @non_numeric_vals = grep {!looks_like_number($_)} @{ $args->{data}{$group}{$axis} };
			if (scalar @non_numeric_vals > 0) {
				p $args->{data}{$group}{$axis};
				say STDERR 'has the following non-numeric values:';
				p @non_numeric_vals;
				die "non-numeric values found in \$args->{data}{$group}{$axis}";
			}
			$axes{$axis}++;
			next unless ((defined $args->{color_key}) && ($axis eq $args->{'color_key'}));
			$color_min = min( $color_min, @{ $args->{data}{$group}{$axis} });
			$color_max = max( $color_max, @{ $args->{data}{$group}{$axis} });
		}
	}
	if (scalar keys %axes != 3) {
		p $args->{data};
		say STDERR 'there are not exactly 3 unique axes in the data set';
		p %axes;
		die 'there must be 3 axes (keys) for each group';
	}
	undef %axes;
	$color_min = $args->{'color.min'} // $color_min;
	$color_max = $args->{'color.max'} // $color_max;
	my $unlink = 0;
	my ($fh, $tempfile) = tempfile (UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say $tempfile if $unlink == 0;
	my @markers = ('o', 'v', '^', '<', '>', '1', '2', '3', '4', '8', 's', 'p', 'P', '*', 'h', 'H', '+', 'x', 'D', 'd', '|', '_');
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'fig, ax = plt.subplots(layout = "constrained")';
	say $fh "norm = plt.Normalize($color_min,$color_max)";
	my $marker_index = 0;
	foreach my $group (sort {lc $a cmp lc $b} keys %{ $args->{data} }) {
		my $mark = $markers[$marker_index % scalar @markers]; # cycle through if groups > markers
		say $fh 'plt.scatter([' . join (',', @{ $args->{data}{$group}{$args->{'x.axis.key'}} }) . '],[' . join (',', @{ $args->{data}{$group}{$args->{'y.axis.key'}} }) . '], c = [' .  join (',', @{ $args->{data}{$group}{$args->{'color_key'}} }) . "], norm = norm, label = '$group', cmap = 'gist_rainbow', marker = '$mark')";
		$marker_index++;
	}
	say $fh "plt.title('$args->{title}')" if defined $args->{title};
	$args->{xlabel} = $args->{xlabel} // $args->{'x.axis.key'};
	say $fh "plt.xlabel('$args->{xlabel}')";
	$args->{ylabel} = $args->{ylabel} // $args->{'y.axis.key'};
	say $fh "plt.ylabel('$args->{ylabel}')";
	say $fh "plt.colorbar().set_label('$args->{color_key}')";
	if (defined $args->{xmax}) {
		say $fh "ax.set_xlim(right = $args->{xmax})";
	}
	if (defined $args->{xmin}) {
		say $fh "ax.set_xlim(left = $args->{xmin})";
	}
	if (defined $args->{ymax}) {
		say $fh "ax.set_ylim(top = $args->{ymax})";
	}
	if (defined $args->{ymin}) {
		say $fh "ax.set_ylim(bottom = $args->{ymin})";
	}
	foreach my $axis (@{ $args->{logscale} }) { # x, y
		say $fh "plt.$axis" . 'scale("log")';
	}
	$args->{'legend.position'} = $args->{'legend.position'} // 'outside center right';
	say $fh "fig.legend(loc = '$args->{'legend.position'}')"; # essential when multiple groups are present
	$args->{output_type} = $args->{output_type} // 'svg';
	my $image_file = "$args->{filename}.$args->{output_type}";
	say $fh "plt.savefig('$image_file', bbox_inches='tight', pad_inches = 0.1)";
	close $fh;
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $tempfile" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die "\"python3 $tempfile\" failed";
	}
	say "wrote $image_file";
	return $image_file
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

sub violin_plot {
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'data',		# a hash of array
		'filename'	# do not include suffix
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	if (scalar keys %{ $args->{data} } == 0) {
		p $args;
		die "\"$current_sub\" got empty data.";
	}
	my @non_array_keys = grep {ref $args->{data}{$_} ne 'ARRAY'} sort keys %{ $args->{data} };
	if (scalar @non_array_keys > 0) {
		p $args->{data};
		p @non_array_keys;
		die 'the above keys are not arrays. Data must be entered in as a hash of arrays';
	}
	my @defined_args = (@reqd_args, 'color', 'colors', 'figheight', 'figwidth', 'flip', 'grid', 'keys', 'labelsize', 'legend', 'line_segment', 'logscale', 'medians', 'major_gridlines', 'minor_gridlines', 'tick_params', 'title', 'totals in labels', 'skip total label', 'whiskers', 'xlabel', 'ylabel');
=options defined
colors             => hash of keys and their colors
'keys'             => define the order of keys to be shown in the violin plot
logscale           => list/array of axes that should be in logscale
	minor_gridlines => {
		x => '%.1f'
	}
'skip total label' => skip these keys total number; defined as a hash
=cut
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	$args->{medians} = $args->{medians} // 1;
	foreach my $key (keys %{ $args->{data} }) {
		$args->{data}{$key} = [grep {defined} @{ $args->{data}{$key} }];
	}
	my @keys;
	if (defined $args->{keys}) {
		my @undef_keys = grep { not defined $args->{data}{$_} } @{ $args->{keys} };
		if (scalar @undef_keys > 0) {
			say STDERR 'the following keys are not defined in data:';
			p @undef_keys;
			say STDERR 'the keys that were sent are:';
			my @defined_keys = sort @{ $args->{keys} };
			p @defined_keys, array_max => scalar @defined_keys;
			die 'the above keys, which were defined in "keys", are not defined in args->{data}.'
		}
		@keys = @{ $args->{keys} };
	} else {
		@keys = sort keys %{ $args->{data} };
	}
	if (
		(defined $args->{'skip total label'}) &&
		(ref $args->{'skip total label'} ne 'ARRAY')
		) {
		die "'skip total label' should be an array reference, but was " . ref $args->{'skip total label'}
	}
	if (defined $args->{logscale}) {
		die 'logscale should be an array of axes like ["x", "y"]' if ref $args->{logscale} ne 'ARRAY';
	}
	my $unlink = 1;
	my ($fh, $filename) = tempfile (UNLINK => $unlink, SUFFIX => '.py', DIR => '/tmp');
	say $filename if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'data = []';
	my $min_n_points = 'inf';
	foreach my $key (@keys) {
		say $fh 'data.append([' . join (',', @{ $args->{data}{$key} }) . '])';
		$min_n_points = min( scalar @{ $args->{data}{$key} }, $min_n_points);
	}
	say $fh 'f = plt.figure()';
	foreach my $arg (grep {defined $args->{$_}} ('figwidth', 'figheight')) { # default figheight = 4.8, figwidth = 6.4
		say $fh "f.set_$arg($args->{$arg})";
	}
	$args->{labelsize} = $args->{labelsize} // 6;
	say $fh "plt.rc('xtick', labelsize = $args->{labelsize})"; # has to be set *before* calling plot
	$args->{flip} = $args->{flip} // 0; # non-zero $args->{flip} is considered "on"
	$args->{whiskers} = $args->{whiskers} // 1; # default is to make whiskers
	my $showmedians = 'True';
	$showmedians = 'False' if $args->{whiskers} > 0;
	$min_n_points = int max( $min_n_points/100, 100); # matplotlib's default is 100
	if ($args->{flip} > 0) {
		say $fh "violin_plot = plt.violinplot(data, showmeans=False, vert = False, showmedians=$showmedians, points = $min_n_points)";
		my $tmp = $args->{xlabel}; # switch x and y labels
		$args->{xlabel} = $args->{ylabel};
		$args->{ylabel} = $tmp;
	} else {
		say $fh "violin_plot = plt.violinplot(data, showmeans=False, showmedians=$showmedians, points = $min_n_points)";
	}
	if (defined $args->{colors}) { # every hash key should have its own color defined
# the below code helps to provide better error messages in case I make an error in calling the sub
		my @wrong_keys = grep { not defined $args->{colors}{$_} } keys %{ $args->{data} };
		if (scalar @wrong_keys > 0) {
			p @wrong_keys;
			die 'the above data keys have no defined color'
		}
# list of pre-defined colors: https://matplotlib.org/stable/gallery/color/named_colors.html
		say $fh 'colors = ["' . join ('","', @{ $args->{colors} }{@keys} ) . '"]';
# the above color list will have the same order, via the above hash slice
		say $fh 'for i, pc in enumerate(violin_plot["bodies"], 1):';
		say $fh "\tpc.set_facecolor(colors[i-1])";
		say $fh "\tpc.set_edgecolor('black')";
	} else {
	  	say $fh 'for pc in violin_plot["bodies"]:';
		if (defined $args->{color}) {
			say $fh "\tpc.set_facecolor('$args->{color}')";
		}
		say $fh "\tpc.set_edgecolor('black')";
	}
	foreach my $arg ('title', 'xlabel', 'ylabel') {
		say $fh "plt.$arg('$args->{$arg}')" if defined $args->{$arg}
	}
	foreach my $axis (@{ $args->{logscale} }) { # x, y
		say $fh "plt.$axis" . 'scale("log")';
	}
	$args->{'totals in labels'} = $args->{'totals in labels'} // 1; # print group size by default
	if ($args->{whiskers} > 0) {
# https://matplotlib.org/devdocs/gallery/statistics/customized_violin.html
		say $fh 'import numpy as np';
		say $fh 'def adjacent_values(vals, q1, q3):';
		say $fh '	upper_adjacent_value = q3 + (q3 - q1) * 1.5';
		say $fh '	upper_adjacent_value = np.clip(upper_adjacent_value, q3, vals[-1])';
		say $fh '	lower_adjacent_value = q1 - (q3 - q1) * 1.5';
		say $fh '	lower_adjacent_value = np.clip(lower_adjacent_value, vals[0], q1)';
		say $fh '	return lower_adjacent_value, upper_adjacent_value';
		say $fh 'np_data = np.array(data, dtype = object)';
		say $fh 'quartile1 = []';
		say $fh 'medians   = []';
		say $fh 'quartile3 = []';
		say $fh 'for subset in list(range(0, len(np_data))):';
		say $fh '	local_quartile1, local_medians, local_quartile3 = np.percentile(data[subset], [25, 50, 75])';
		say $fh '	quartile1.append(local_quartile1)';
		say $fh '	medians.append(local_medians)';
		say $fh '	quartile3.append(local_quartile3)';
		say $fh 'whiskers = np.array([';
		say $fh '    adjacent_values(sorted_array, q1, q3)';
    	say $fh '    for sorted_array, q1, q3 in zip(data, quartile1, quartile3)])';
    	say $fh 'whiskers_min, whiskers_max = whiskers[:, 0], whiskers[:, 1]';
    	say $fh 'inds = np.arange(1, len(medians) + 1)';
    	if ($args->{flip} == 0) {
    		if ($args->{medians} > 0) {
				say $fh 'plt.scatter(inds, medians, marker="o", color="green", s=30, zorder=3)';
			}
			say $fh 'plt.vlines(inds, quartile1, quartile3, color="k", linestyle="-", lw=5)';
			say $fh 'plt.vlines(inds, whiskers_min, whiskers_max, color="k", linestyle="-", lw=1)';
		} else {
			if ($args->{medians} > 0) {
				say $fh 'plt.scatter(medians, inds, marker="o", color="green", zorder=3)';
			}
			say $fh 'plt.hlines(inds, quartile1, quartile3, color="k", linestyle="-", lw=3)';
			say $fh 'plt.hlines(inds, whiskers_min, whiskers_max, color="k", linestyle="-", lw=3)';
		}
	}
	my @xticks;
	foreach my $key (@keys) {
		if (
				($args->{'totals in labels'} == 0) ||
				( # was this key's total meant to be omitted?
					(defined $args->{'skip total label'}) &&
					(grep {$_ eq $key} @{ $args->{'skip total label'} })
				)
			)
			 {
			push @xticks, $key;
		} else {
			push @xticks, "$key (" . format_commas(scalar @{ $args->{data}{$key} }, '%.0u') . ')';
		}
		if ($args->{flip} == 0) {
			say $fh 'plt.plot(' . scalar @xticks . ', ' . (sum (@{ $args->{data}{$key} } ) / scalar @{ $args->{data}{$key} }) . ', "ro")'; # plot mean point, which is red
		} else {
			say $fh 'plt.plot(' . (sum (@{ $args->{data}{$key} } ) / scalar @{ $args->{data}{$key} }) . ', ' .  scalar @xticks . ', "ro")'; # plot mean point, which is red
		}
	}
	if ($args->{flip} == 0) {
		say $fh 'plt.xticks([' . join (',', 1..scalar @keys) . '], ["' . join ('","', @xticks) . '"])';
	} else {
		say $fh 'plt.yticks([' . join (',', 1..scalar @keys) . '], ["' . join ('","', @xticks) . '"])';
	}
	my $ax_set = 0;
	if (defined $args->{grid}) {
# https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.grid.html
		say $fh 'ax = plt.gca()';
		$ax_set = 1;
		say $fh "ax.grid($args->{grid})";
	}
	if (defined $args->{minor_gridlines}) {
# https://www.tutorialspoint.com/how-to-show-minor-tick-labels-on-a-log-scale-with-matplotlib
		say $fh 'from matplotlib.ticker import FormatStrFormatter';
		if ($ax_set == 0) { # "ax" has already been written if grid is present
			say $fh 'ax = plt.gca()';
			$ax_set = 1;
		}
		foreach my $axis (keys %{ $args->{minor_gridlines} }) {
			say $fh "ax.$axis" . "axis.set_minor_formatter(FormatStrFormatter('$args->{minor_gridlines}{$axis}'))";
		}
	}
	if (defined $args->{major_gridlines}) {
# https://www.tutorialspoint.com/how-to-show-minor-tick-labels-on-a-log-scale-with-matplotlib
		say $fh 'from matplotlib.ticker import FormatStrFormatter';
		if ($ax_set == 0) { # "ax" has already been written if grid is present
			say $fh 'ax = plt.gca()';
			$ax_set = 1;
		}
		foreach my $axis (keys %{ $args->{major_gridlines} }) {
			say $fh "ax.$axis" . "axis.set_major_formatter(FormatStrFormatter('$args->{major_gridlines}{$axis}'))";
		}
	}
	if (defined $args->{tick_params}) {
# https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.tick_params.html
		if ($ax_set == 0) { # "ax" has already been written if grid is present
			say $fh 'ax = plt.gca()';
			$ax_set = 1;
		}
		say $fh "ax.tick_params($args->{tick_params})";
# e.g. 'axis = "x", labelbottom = True, labeltop = True, bottom = True, top = True'
	}
	if (defined $args->{line_segment}) {
=example
	line_segment => [ # array of anonymous hashes
		{
			'x0' => 0, 'x1' => 1, # 1st point
			'y0' => 0, 'y1' => 1, # 2nd point
			linestyle => 'dashed', color => 'red', label => "D' = R^2"
		}
	],
=cut
		foreach my $ls (@{ $args->{line_segment} }) { # hash ref
			my $x = join (',', @{ $ls }{'x0', 'x1'});
			my $y = join (',', @{ $ls }{'y0', 'y1'});
			my $linestyle = $ls->{linestyle} // 'dashed';
			my $color = $ls->{color} // 'red';
			my $options = "linestyle = '$linestyle', color = '$color'";
			if (defined $ls->{label}) {
				$ls->{label} =~ s/'/\\'/g;
				$options .= ", label = '$ls->{label}'";
			}
			say $fh "plt.plot([$x], [$y], $options)";
		}
	}
	$args->{legend} = $args->{legend} // 0;
	if ((looks_like_number($args->{legend})) && ($args->{legend} > 0)) {
		say $fh 'plt.legend()';
	} elsif ((looks_like_number($args->{legend})) && ($args->{legend} == 0)) {
	} else {
		say $fh "plt.legend($args->{legend})"; # e.g. "loc = 8" for location code https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.legend.html
	}
	say $fh "plt.savefig('$args->{filename}', bbox_inches='tight', pad_inches = 0.05, metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript'})";
	close $fh;
	
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		my ($cp_fh, $copy_filename) = tempfile (UNLINK => 0, SUFFIX => '.py');
		close $cp_fh; #just need to make the file
		cp($filename, $copy_filename);
		die "violin-plot failed, and the file is $copy_filename for debugging";
	}
	say 'wrote ' . colored(['black on_yellow'], $args->{filename});
	return $args->{filename}
}
=example execution
violin_plot({
	filename => 'images/violin_adverse_event_var',
	data     => \%metrics,
	title    => 'Adverse Event',
	figwidth => 9,
	flip     => 1,
	ylabel   => 'Metric',
	xlabel   => 'Metric Value',
	colors   => \%colors
	line_segment => [
		{
			'x0' => 1, 'x1' => scalar keys %data, # 1st point
			'y0' => 76.3, 'y1' => 76.3, # 2nd point https://usa.mortality.org/
			linestyle => 'dashed', color => 'blue', label => 'Male SD L.E.'
		},
		{
			'x0' => 1, 'x1' => scalar keys %data, # 1st point
			'y0' => 81.4, 'y1' => 81.4, # 2nd point https://usa.mortality.org/
			linestyle => 'dashed', color => 'pink', label => 'Female SD L.E.'
		},
	],
	legend => 1
});
=cut

sub violin_subplots {
=example
violin_subplots({
	ax_methods	=> \@ax_methods,
#	color			=> 'red',
	data			=> \@d,
	figheight	=> 9,
	figwidth		=> 16,
	filename		=> 'nr.violin.subplots.svg',
	nrows			=> 2,
	ncols			=> 3,
	plt_methods => {
		suptitle	 => '"Hits with Non-Redundant Protein Database", fontsize = 24'
	},
	flip			=> 1,
});
violin_subplots({
	data	=> [
		{
			White	=> generate_normal_dist(100, 15, 210*100),
			Black	=> generate_normal_dist(85, 15, 41*100)
		},
	],
	ncols		=> 1,
	nrows		=> 1,
	flip		=> 1,
	filename	=> '/tmp/violin.subplot.svg'
});
=cut
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'data',		# array of hash
		'filename',	# include suffix
		'ncols',	# number of cols, an unsigned integer > 0
		'nrows',	# number of rows, an unsigned integer > 0
	);
	my @undef_args = grep { !defined $args->{$_}} (@reqd_args);
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my $data_ref = ref $args->{data};
	if ($data_ref ne 'ARRAY') {
		p $args;
		die "\"$current_sub\" needs data as an array, but \"$data_ref\" ref was given.";
	}
	my @defined_args = (@reqd_args,
		'ax_methods',	# a list/array of hashes https://matplotlib.org/stable/api/axes_api.html
		'color',			# a single color all violin plots
		'colors',		# different colors for different plots
		'figheight', 'figwidth',
		'flip',			# default 0
		'plt_methods', # a hash; write *EXACTLY* what goes into the method; e.g. title, etc.
		'sharex',		# default false
#		'title',			# actually suptitle
		'whiskers',		# quartiles
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.';
	}
	$args->{sharex}		= $args->{sharex} // 'False';
	$args->{figheight}	= $args->{figheight} // 4.8;
	$args->{figwidth}		= $args->{figwidth}  // 6.4;
	$args->{flip}	 		= $args->{flip}   // 0; # default is to not flip
	$args->{medians}		= $args->{medians} // 1;
	$args->{whiskers}		= $args->{whiskers} // 1; # default is "on"
	my $unlink = 0;
	my ($py, $temp_py_filename) = tempfile(DIR => '/tmp', UNLINK => $unlink, SUFFIX => '.py');
	say "temp file is $temp_py_filename" if $unlink == 0;
	say $py 'import matplotlib.pyplot as plt';
	if ($args->{whiskers} > 0) {
# https://matplotlib.org/stable/gallery/statistics/customized_violin.html
		say $py 'import numpy as np' if $args->{whiskers} > 0;
		say $py 'def adjacent_values(vals, q1, q3):';
		say $py '	upper_adjacent_value = q3 + (q3 - q1) * 1.5';
		say $py '	upper_adjacent_value = np.clip(upper_adjacent_value, q3, vals[-1])';
		say $py '	lower_adjacent_value = q1 - (q3 - q1) * 1.5';
		say $py '	lower_adjacent_value = np.clip(lower_adjacent_value, vals[0], q1)';
		say $py '	return lower_adjacent_value, upper_adjacent_value';
	}
	my @ax = map {"ax$_"} 0..$args->{nrows}*$args->{ncols}-1;
	my (@py, @y);
	while (my ($i, $ax) = each @ax) {
		my $a1i = int $i / $args->{ncols};	# 1st index
		my $a2i = $i % $args->{ncols};		# 2nd index
		$y[$a1i][$a2i] = $ax;
	}
	foreach my $y (@y) {
		push @py, '(' . join (',', @{ $y }) . ')';
	}
	say $py 'fig, (' . join (',', @py) . ") = plt.subplots($args->{nrows}, $args->{ncols}, sharex = $args->{sharex})";
	foreach my $arg (grep {defined $args->{$_}} ('figwidth', 'figheight')) { # default figheight = 4.8, figwidth = 6.4
		say $py "fig.set_$arg($args->{$arg})";
	}
	say $py "plt.suptitle('$args->{title}')" if defined $args->{title};
	foreach my $method (keys %{ $args->{plt_methods} }) {
		say $py "plt.$method( $args->{plt_methods}{$method} )";
	}
	while (my ($ax, $plot) = each @{ $args->{data} }) { # for each plot $ax (hash is $plot)
		next if scalar keys %{ $plot } == 0;
		say $py 'd = []';
		my $min_n_points = 'inf';
		my @xticks;
		foreach my $set (sort keys %{ $plot }) { # each individual violin point
			my $ref = ref $plot->{$set};
			unless ($ref eq 'ARRAY') {
				die "$set must be an array, but a $ref was entered.";
			}
			say $py 'd.append([' . join (',', @{ $plot->{$set} }) . '])';
			my $n_points = scalar @{ $plot->{$set} };
			$min_n_points = min( $n_points , $min_n_points);
			push @xticks, "$set (" . format_commas($n_points, '%.0u') . ')';
		}
		my $flip = '';
		if ($args->{flip} > 0) {
			$flip = ', vert = False';
#			my $tmp = $args->{xlabel}; # switch x and y labels
#			$args->{xlabel} = $args->{ylabel};
#			$args->{ylabel} = $tmp;
		}
		$min_n_points = max(100, $min_n_points);
		say $py "vp = ax$ax.violinplot(d, showmeans=True, points = $min_n_points $flip)";
		if (not defined $args->{colors}) {
		  	say $py 'for pc in vp["bodies"]:';
			if (defined $args->{color}) {
				say $py "\tpc.set_facecolor('$args->{color}')";
			}
			say $py "\tpc.set_edgecolor('black')";
		}
		if (defined $args->{ax_methods}[$ax]) {
			while (my ($method, $value) = each %{ $args->{ax_methods}[$ax] }) {
				if (
						(looks_like_number($value))
						||
						($value =~ m/^\d+\.?\d*,\s*\d+\.?\d*$/)		# like ax0.set_xlim(0, 99)
					) {
					say $py "ax$ax.$method($value)";
				} else {
					say $py "ax$ax.$method('$value')";
				}
			}
		}
		
		my $nkeys = scalar keys %{ $plot };
		if ($args->{flip} == 0) {
			say $py "ax$ax" . '.set_xticks([' . join (',', 1..$nkeys) . '], ["' . join ('","', @xticks) . '"])';
		} else {
			say $py "ax$ax" . '.set_yticks([' . join (',', 1..$nkeys) . '], ["' . join ('","', @xticks) . '"])';
		}
		
		say $py 'np_data = np.array(d, dtype = object)';
		say $py 'quartile1 = []';
		say $py 'medians   = []';
		say $py 'quartile3 = []';
		say $py 'for subset in list(range(0, len(np_data))):';
		say $py '	local_quartile1, local_medians, local_quartile3 = np.percentile(d[subset], [25, 50, 75])';
		say $py '	quartile1.append(local_quartile1)';
		say $py '	medians.append(local_medians)';
		say $py '	quartile3.append(local_quartile3)';
		say $py 'whiskers = np.array([';
		say $py '    adjacent_values(sorted_array, q1, q3)';
    	say $py '    for sorted_array, q1, q3 in zip(d, quartile1, quartile3)])';
    	say $py 'whiskers_min, whiskers_max = whiskers[:, 0], whiskers[:, 1]';
    	say $py 'inds = np.arange(1, len(medians) + 1)';
    	if ($args->{flip} == 0) {
    		if ($args->{medians} > 0) {
				say $py "ax$ax.scatter(inds, medians, marker='o', color='blue', s=30, zorder=3)";
			}
			say $py "ax$ax" . '.vlines(inds, quartile1, quartile3, color="k", linestyle="-", lw=5)';
			say $py "ax$ax" . '.vlines(inds, whiskers_min, whiskers_max, color="k", linestyle="-", lw=1)';
		} else {
			if ($args->{medians} > 0) {
				say $py "ax$ax" . '.scatter(medians, inds, marker="o", color="blue", zorder=3)';
			}
			say $py "ax$ax" . '.hlines(inds, quartile1, quartile3, color="k", linestyle="-", lw=3)';
			say $py "ax$ax" . '.hlines(inds, whiskers_min, whiskers_max, color="k", linestyle="-", lw=3)';
		}
	}
	say $py 'fig.tight_layout(pad=0.9)';
	say $py "plt.savefig('$args->{filename}', bbox_inches='tight', pad_inches = 0.05)";#, metadata={'Creator': 'made/written by " . getcwd() . "/$RealScript'})";
	close $py;
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $temp_py_filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		my ($cp_fh, $copy_filename) = tempfile (UNLINK => 0, SUFFIX => '.py');
		close $cp_fh; #just need to make the file
		cp($temp_py_filename, $copy_filename);
		p $args;
		die "violin-plot failed, and the file is $copy_filename for debugging";
	}
	say 'wrote ' . colored(['black on_yellow'], $args->{filename});
	return $args->{filename}
}

sub wide_plot {
=example
wide_plot({
	filename	=> 'svg/wide.plots.svg',
	data		=> {
		inflammatory	=> [
			[	# 1st run
				[0..26],
				[map {rand 1} 0..26],
			],
			[	# 2nd run
				[0..26],
				[map {rand 1} 0..26],
			],
			[	# 3rd run
				[0..26],
				[map {rand 1} 0..26],
			],
			[	# 4th run
				[0..26],
				[map {rand 1} 0..26],
			],
		]
	},
	xlabel	=> 'Weeks after birth'
});
=cut
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
	my @defined_args = (
	'color',		# a hash, e.g. color => {set1 => 'red', set2 => 'blue'}
	'figwidth', 'labelright', 'legend', 'output_type', 'title', 'xlabel', 'ylabel', @reqd_args);
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
	say $fh 'plt.figure()';
	foreach my $group (keys %{ $args->{data} }) {
		my $color = $args->{color}{$group} // 'b';
		say $fh 'ys = []';
		my ($min_x, $max_x) = ('inf', '-inf');
		foreach my $run (0.. scalar @{ $args->{data}{$group} }-1) {
			$min_x = min($min_x, @{ $args->{data}{$group}[$run][0] });
			$max_x = max($max_x, @{ $args->{data}{$group}[$run][0] });
		}
		say $fh "base_y = np.linspace($max_x, $min_x, 101)";
		foreach my $run (0.. scalar @{ $args->{data}{$group} }-1) {
			say $fh 'x = [' . join (',', @{ $args->{data}{$group}[$run][0] }) . ']';
			say $fh 'y = [' . join (',', @{ $args->{data}{$group}[$run][1] }) . ']';
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
	$args->{xlabel} = $args->{xlabel} // 'xlabel';
	$args->{ylabel} = $args->{ylabel} // 'ylabel';
	say $fh "plt.xlabel('$args->{xlabel}')";
	say $fh "plt.ylabel('$args->{ylabel}')";
	$args->{labelright} = $args->{labelright} // 0; # by default, labels on the right side are off
	if ($args->{labelright} > 0) {
		say $fh 'plt.tick_params(labelright = True, right = True, axis = "both", which = "both")';
	}
	$args->{legend} = $args->{legend} // 1;
#	say $fh 'fig, ax = plt.subplots()' if $n_group > 0;
#	say $fh 'ax.get_legend().remove()' if $args->{legend} == 0;
	say $fh 'plt.legend()' if $args->{legend} == 1;
	foreach my $arg ('figwidth', 'figheight') {# default figheight = 4.8, figwidth = 6.4 
		say $fh "f.set_$arg($args->{$arg})" if defined $args->{$arg};
	}
	say $fh "plt.savefig('$args->{filename}', bbox_inches='tight', pad_inches = 0.1, metadata={'Creator': 'made/written by Util.pm\\'s $current_sub " . getcwd() . "/$RealScript'})";
	close $fh;
	
	my ($stdout, $stderr, $exit) = capture {
		system( "python3 $filename" );
	};
	if ($exit != 0) {
		say "exit = $exit";
		say "STDOUT = $stdout";
		say "STDERR = $stderr";
		die "python3 $filename failed";
	}
	say 'wrote ' . colored(['yellow on_blue'], $args->{filename});
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
