package Perl::Critic::Command;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use Getopt::Long qw< GetOptions >;
use List::Util qw< first max >;
use Pod::Usage qw< pod2usage >;

use Perl::Critic::Exception::Parse ();
use Perl::Critic::Utils qw<
    :characters :severities policy_short_name
    $DEFAULT_VERBOSITY $DEFAULT_VERBOSITY_WITH_FILE_NAME
>;
use Perl::Critic::Utils::Constants qw< $_MODULE_VERSION_TERM_ANSICOLOR >;
use Perl::Critic::Violation qw<>;

#-----------------------------------------------------------------------------

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

use Exporter 'import';

Readonly::Array our @EXPORT_OK => qw< run >;

Readonly::Hash our %EXPORT_TAGS => (
    all             => [ @EXPORT_OK ],
);

#-----------------------------------------------------------------------------

Readonly::Scalar my $DEFAULT_VIOLATIONS_FOR_TOP => 20;

Readonly::Scalar my $EXIT_SUCCESS           => 0;
Readonly::Scalar my $EXIT_NO_FILES          => 1;
Readonly::Scalar my $EXIT_HAD_VIOLATIONS    => 2;
Readonly::Scalar my $EXIT_HAD_FILE_PROBLEMS => 3;

#-----------------------------------------------------------------------------

my @files = ();
my $critic = undef;
my $output = \*STDOUT;

#-----------------------------------------------------------------------------

sub _out {
    my @lines = @_;
    return print {$output} @lines;
}

#-----------------------------------------------------------------------------

sub run {
    my %options    = _get_options();
    @files         = _get_input(@ARGV);

    my ($violations, $had_error_in_file) = _critique(\%options, @files);

    return $EXIT_HAD_FILE_PROBLEMS  if $had_error_in_file;
    return $EXIT_NO_FILES           if not defined $violations;
    return $EXIT_HAD_VIOLATIONS     if $violations;

    return $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _get_options {

    my %opts = _parse_command_line();
    _dispatch_special_requests( %opts );
    _validate_options( %opts );

    # Convert severity shortcut options.  If multiple shortcuts
    # are given, the lowest one wins.  If an explicit --severity
    # option has been given, then the shortcuts are ignored. The
    # @SEVERITY_NAMES variable is exported by Perl::Critic::Utils.
    $opts{-severity} ||= first { exists $opts{"-$_"} } @SEVERITY_NAMES;
    $opts{-severity} ||= first { exists $opts{"-$_"} } ($SEVERITY_LOWEST ..  $SEVERITY_HIGHEST);


    # If --top is specified, default the severity level to 1, unless an
    # explicit severity is defined.  This provides us flexibility to
    # report top-offenders across just some or all of the severity levels.
    # We also default the --top count to twenty if none is given
    if ( exists $opts{-top} ) {
        $opts{-severity} ||= 1;
        $opts{-top} ||= $DEFAULT_VIOLATIONS_FOR_TOP;
    }

    #Override profile, if --noprofile is specified
    if ( exists $opts{-noprofile} ) {
        $opts{-profile} = $EMPTY;
    }

    return %opts;
}

#-----------------------------------------------------------------------------

sub _parse_command_line {
    my %opts;
    my @opt_specs = _get_option_specification();
    Getopt::Long::Configure('no_ignore_case');
    GetOptions( \%opts, @opt_specs ) || pod2usage();           #Exits

    # I've adopted the convention of using key-value pairs for
    # arguments to most functions.  And to increase legibility,
    # I have also adopted the familiar command-line practice
    # of denoting argument names with a leading dash (-).
    my %dashed_opts = map { ( "-$_" => $opts{$_} ) } keys %opts;
    return %dashed_opts;
}

#-----------------------------------------------------------------------------

sub _dispatch_special_requests {
    my (%opts) = @_;
    if ( $opts{-help}            ) { pod2usage( -verbose => 0 )    }  # Exits
    if ( $opts{-options}         ) { pod2usage( -verbose => 1 )    }  # Exits
    if ( $opts{-man}             ) { pod2usage( -verbose => 2 )    }  # Exits
    if ( $opts{-version}         ) { _display_version()            }  # Exits
    if ( $opts{-list}            ) { _render_all_policy_listing()  }  # Exits
    if ( $opts{'-list-enabled'}  ) { _render_policy_listing(%opts) }  # Exits
    if ( $opts{'-list-themes'}   ) { _render_theme_listing()       }  # Exits
    if ( $opts{'-profile-proto'} ) { _render_profile_prototype()   }  # Exits
    if ( $opts{-doc}             ) { _render_policy_docs( %opts )  }  # Exits
    return 1;
}

#-----------------------------------------------------------------------------

sub _validate_options {
    my (%opts) = @_;
    my $msg = $EMPTY;


    if ( $opts{-noprofile} && $opts{-profile} ) {
        $msg .= qq{Warning: Cannot use -noprofile with -profile option.\n};
    }

    if ( $opts{-verbose} && $opts{-verbose} !~ m{(?: \d+ | %[mfFlcCedrpPs] )}xms) {
        $msg .= qq<Warning: --verbose arg "$opts{-verbose}" looks odd.  >;
        $msg .= qq<Perhaps you meant to say "--verbose 3 $opts{-verbose}."\n>;
    }

    if ( exists $opts{-top} && $opts{-top} < 0 ) {
        $msg .= qq<Warning: --top argument "$opts{-top}" is negative.  >;
        $msg .= qq<Perhaps you meant to say "$opts{-top} --top".\n>;
    }

    if (
            exists $opts{-severity}
        &&  (
                    $opts{-severity} < $SEVERITY_LOWEST
                ||  $opts{-severity} > $SEVERITY_HIGHEST
            )
    ) {
        $msg .= qq<Warning: --severity arg "$opts{-severity}" out of range.  >;
        $msg .= qq<Severities range from "$SEVERITY_LOWEST" (lowest) to >;
        $msg .= qq<"$SEVERITY_HIGHEST" (highest).\n>;
    }


    if ( $msg ) {
        pod2usage( -exitstatus => 1, -message => $msg, -verbose => 0); #Exits
    }


    return 1;
}

#-----------------------------------------------------------------------------

sub _get_input {

    my @args = @_;

    if ( !@args || (@args == 1 && $args[0] eq q{-}) )  {

        # Reading code from STDIN.  All the code is slurped into
        # a string.  PPI will barf if the string is just whitespace.
        my $code_string = do { local $RS = undef; <STDIN> };

        # Notice if STDIN was closed (pipe error, etc)
        if ( ! defined $code_string ) {
            $code_string = $EMPTY;
        }

        $code_string =~ m{ \S+ }xms || die qq{Nothing to critique.\n};
        return \$code_string;    #Convert to SCALAR ref for PPI
    }
    else {

        # Test to make sure all the specified files or directories
        # actually exist.  If any one of them is bogus, then die.
        if ( my $nonexistent = first { ! -e } @args ) {
            my $msg = qq{No such file or directory: '$nonexistent'};
            pod2usage( -exitstatus => 1, -message => $msg, -verbose => 0);
        }

        # Reading code from files or dirs.  If argument is a file,
        # then we process it as-is (even though it may not actually
        # be Perl code).  If argument is a directory, recursively
        # search the directory for files that look like Perl code.
        return map { (-d) ? Perl::Critic::Utils::all_perl_files($_) : $_ } @args;
    }
}

#------------------------------------------------------------------------------

sub _critique {

    my ( $opts_ref, @files_to_critique ) = @_;
    @files_to_critique || die "No perl files were found.\n";

    # Perl::Critic has lots of dependencies, so loading is delayed
    # until it is really needed.  This hack reduces startup time for
    # doing other things like getting the version number or dumping
    # the man page. Arguably, those things are pretty rare, but hey,
    # why not save a few seconds if you can.

    require Perl::Critic;
    $critic = Perl::Critic->new( %{$opts_ref} );
    $critic->policies() || die "No policies selected.\n";

    _set_up_pager($critic->config()->pager());

    my $number_of_violations = undef;
    my $had_error_in_file = 0;

    for my $file (@files_to_critique) {

        eval {
            my @violations = $critic->critique($file);
            $number_of_violations += scalar @violations;

            if (not $opts_ref->{'-statistics-only'}) {
                _render_report( $file, $opts_ref, @violations )
            }
            1;
        }
        or do {
            if ( my $exception = Perl::Critic::Exception::Parse->caught() ) {
                $had_error_in_file = 1;
                warn qq<Problem while critiquing "$file": $EVAL_ERROR\n>;
            }
            elsif ($EVAL_ERROR) {
                # P::C::Exception::Fatal includes the stack trace in its
                # stringification.
                die qq<Fatal error while critiquing "$file": $EVAL_ERROR\n>;
            }
            else {
                die qq<Fatal error while critiquing "$file". Unfortunately, >,
                    q<$@/$EVAL_ERROR >, ## no critic (RequireInterpolationOfMetachars)
                    qq<is empty, so the reason can't be shown.\n>;
            }
        }
    }

    if ( $opts_ref->{-statistics} or $opts_ref->{'-statistics-only'} ) {
        my $stats = $critic->statistics();
        _report_statistics( $opts_ref, $stats );
    }

    return $number_of_violations, $had_error_in_file;
}

#------------------------------------------------------------------------------

sub _render_report {
    my ( $file, $opts_ref, @violations ) = @_;

    # Only report the files, if asked.
    my $number_of_violations = scalar @violations;
    if ( $opts_ref->{'-files-with-violations'} ||
        $opts_ref->{'-files-without-violations'} ) {
        not ref $file
            and $opts_ref->{$number_of_violations ? '-files-with-violations' :
            '-files-without-violations'}
            and _out "$file\n";
        return $number_of_violations;
    }

    # Only report the number of violations, if asked.
    if( $opts_ref->{-count} ){
        ref $file || _out "$file: ";
        _out "$number_of_violations\n";
        return $number_of_violations;
    }

    # Hail all-clear unless we should shut up.
    if( !@violations && !$opts_ref->{-quiet} ) {
        ref $file || _out "$file ";
        _out "source OK\n";
        return 0;
    }

    # Otherwise, format and print violations
    my $verbosity = $critic->config->verbose();
    # $verbosity can be numeric or string, so use "eq" for comparison;
    $verbosity =
        ($verbosity eq $DEFAULT_VERBOSITY && @files > 1)
            ? $DEFAULT_VERBOSITY_WITH_FILE_NAME
            : $verbosity;
    my $fmt = Perl::Critic::Utils::verbosity_to_format( $verbosity );
    if (not -f $file) { $fmt =~ s< \%[fF] ><STDIN>xms; } #HACK!
    Perl::Critic::Violation::set_format( $fmt );

    my $color = $critic->config->color();
    _out $color ? _colorize_by_severity(@violations) : @violations;

    return $number_of_violations;
}

#-----------------------------------------------------------------------------

sub _set_up_pager {
    my ($pager_command) = @_;
    return if not $pager_command;
    return if not _at_tty();

    open my $pager, q<|->, $pager_command  ## no critic (InputOutput::RequireBriefOpen)
        or die qq<Unable to pipe to pager "$pager_command": $ERRNO\n>;

    $output = $pager;

    return;
}

#-----------------------------------------------------------------------------

sub _report_statistics {
    my ($opts_ref, $statistics) = @_;

    if (
            not $opts_ref->{'-statistics-only'}
        and (
                $statistics->total_violations()
            or  not $opts_ref->{-quiet} and $statistics->modules()
        )
    ) {
        _out "\n"; # There's prior output that we want to separate from.
    }

    my $files = _commaify($statistics->modules());
    my $subroutines = _commaify($statistics->subs());
    my $statements = _commaify($statistics->statements_other_than_subs());
    my $lines = _commaify($statistics->lines());
    my $width = max map { length } $files, $subroutines, $statements;

    _out sprintf "%*s %s.\n", $width, $files, 'files';
    _out sprintf "%*s %s.\n", $width, $subroutines, 'subroutines/methods';
    _out sprintf "%*s %s.\n", $width, $statements, 'statements';

    my $lines_of_blank = _commaify( $statistics->lines_of_blank() );
    my $lines_of_comment = _commaify( $statistics->lines_of_comment() );
    my $lines_of_data = _commaify( $statistics->lines_of_data() );
    my $lines_of_perl = _commaify( $statistics->lines_of_perl() );
    my $lines_of_pod = _commaify( $statistics->lines_of_pod() );

    $width =
        max map { length }
            $lines_of_blank, $lines_of_comment, $lines_of_data,
            $lines_of_perl,  $lines_of_pod;
    _out sprintf "\n%s %s:\n",            $lines, 'lines, consisting of';
    _out sprintf "    %*s %s.\n", $width, $lines_of_blank, 'blank lines';
    _out sprintf "    %*s %s.\n", $width, $lines_of_comment, 'comment lines';
    _out sprintf "    %*s %s.\n", $width, $lines_of_data, 'data lines';
    _out sprintf "    %*s %s.\n", $width, $lines_of_perl, 'lines of Perl code';
    _out sprintf "    %*s %s.\n", $width, $lines_of_pod, 'lines of POD';

    my $average_sub_mccabe = $statistics->average_sub_mccabe();
    if (defined $average_sub_mccabe) {
        _out
            sprintf
                "\nAverage McCabe score of subroutines was %.2f.\n",
                $average_sub_mccabe;
        }

    _out "\n";

    _out _commaify($statistics->total_violations()), " violations.\n";

    my $violations_per_file = $statistics->violations_per_file();
    if (defined $violations_per_file) {
        _out
            sprintf
                "Violations per file was %.3f.\n",
                $violations_per_file;
    }
    my $violations_per_statement = $statistics->violations_per_statement();
    if (defined $violations_per_statement) {
        _out
            sprintf
                "Violations per statement was %.3f.\n",
                $violations_per_statement;
    }
    my $violations_per_line = $statistics->violations_per_line_of_code();
    if (defined $violations_per_line) {
        _out
            sprintf
                "Violations per line of code was %.3f.\n",
                $violations_per_line;
    }

    if ( $statistics->total_violations() ) {
        _out "\n";

        my %severity_violations = %{ $statistics->violations_by_severity() };
        my @severities = reverse sort keys %severity_violations;
        $width =
            max
                map { length _commaify( $severity_violations{$_} ) }
                    @severities;
        foreach my $severity (@severities) {
            _out
                sprintf
                    "%*s severity %d violations.\n",
                    $width,
                    _commaify( $severity_violations{$severity} ),
                    $severity;
        }

        _out "\n";

        my %policy_violations = %{ $statistics->violations_by_policy() };
        my @policies = sort keys %policy_violations;
        $width =
            max
                map { length _commaify( $policy_violations{$_} ) }
                    @policies;
        foreach my $policy (@policies) {
            _out
                sprintf
                    "%*s violations of %s.\n",
                    $width,
                    _commaify($policy_violations{$policy}),
                    policy_short_name($policy);
        }
    }

    return;
}

#-----------------------------------------------------------------------------

# Only works for integers.
sub _commaify {
    my ( $number ) = @_;

    while ($number =~ s/ \A ( [-+]? \d+ ) ( \d{3} ) /$1,$2/xms) {
        # nothing
    }

    return $number;
}

#-----------------------------------------------------------------------------

sub _get_option_specification {

    return qw<
        5 4 3 2 1
        Safari
        version
        brutal
        count|C
        cruel
        doc=s
        exclude=s@
        force!
        gentle
        harsh
        help|?|H
        include=s@
        list
        list-enabled
        list-themes
        man
        color|colour!
        noprofile
        only!
        options
        pager=s
        profile|p=s
        profile-proto
        quiet
        severity=i
        single-policy|s=s
        stern
        statistics!
        statistics-only!
        profile-strictness=s
        theme=s
        top:i
        allow-unsafe
        verbose=s
        color-severity-highest|colour-severity-highest|color-severity-5|colour-severity-5=s
        color-severity-high|colour-severity-high|color-severity-4|colour-severity-4=s
        color-severity-medium|colour-severity-medium|color-severity-3|colour-severity-3=s
        color-severity-low|colour-severity-low|color-severity-2|colour-severity-2=s
        color-severity-lowest|colour-severity-lowest|color-severity-1|colour-severity-1=s
        files-with-violations|l
        files-without-violations|L
        program-extensions=s@
    >;
}

#-----------------------------------------------------------------------------

sub _colorize_by_severity {
    my @violations = @_;
    return @violations if _this_is_windows();
    return @violations if not eval {
        require Term::ANSIColor;
        Term::ANSIColor->VERSION( $_MODULE_VERSION_TERM_ANSICOLOR );
        1;
    };

    my $config = $critic->config();
    my %color_of = (
        $SEVERITY_HIGHEST   => $config->color_severity_highest(),
        $SEVERITY_HIGH      => $config->color_severity_high(),
        $SEVERITY_MEDIUM    => $config->color_severity_medium(),
        $SEVERITY_LOW       => $config->color_severity_low(),
        $SEVERITY_LOWEST    => $config->color_severity_lowest(),
    );

    return map { _colorize( "$_", $color_of{$_->severity()} ) } @violations;

}

#-----------------------------------------------------------------------------

sub _colorize {
    my ($string, $color) = @_;
    return $string if not defined $color;
    return $string if $color eq $EMPTY;
    # $terminator is a purely cosmetic change to make the color end at the end
    # of the line rather than right before the next line. It is here because
    # if you use background colors, some console windows display a little
    # fragment of colored background before the next uncolored (or
    # differently-colored) line.
    my $terminator = chomp $string ? "\n" : $EMPTY;
    return  Term::ANSIColor::colored( $string, $color ) . $terminator;
}

#-----------------------------------------------------------------------------

sub _this_is_windows {
    return 1 if $OSNAME =~ m/MSWin32/xms;
    return 0;
}

#-----------------------------------------------------------------------------

sub _at_tty {
    return -t STDOUT; ## no critic (ProhibitInteractiveTest);
}

#-----------------------------------------------------------------------------

sub _render_all_policy_listing {
    # Force P-C parameters, to catch all Policies on this site
    my %pc_params = (-profile => $EMPTY, -severity => $SEVERITY_LOWEST);
    return _render_policy_listing( %pc_params );
}

#-----------------------------------------------------------------------------

sub _render_policy_listing {
    my %pc_params = @_;

    require Perl::Critic::PolicyListing;
    require Perl::Critic;

    my @policies = Perl::Critic->new( %pc_params )->policies();
    my $listing = Perl::Critic::PolicyListing->new( -policies => \@policies );
    _out $listing;

    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _render_theme_listing {

    require Perl::Critic::ThemeListing;
    require Perl::Critic;

    my %pc_params = (-profile => $EMPTY, -severity => $SEVERITY_LOWEST);
    my @policies = Perl::Critic->new( %pc_params )->policies();
    my $listing = Perl::Critic::ThemeListing->new( -policies => \@policies );
    _out $listing;

    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _render_profile_prototype {

    require Perl::Critic::ProfilePrototype;
    require Perl::Critic;

    my %pc_params = (-profile => $EMPTY, -severity => $SEVERITY_LOWEST);
    my @policies = Perl::Critic->new( %pc_params )->policies();
    my $prototype = Perl::Critic::ProfilePrototype->new( -policies => \@policies );
    _out $prototype;

    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _render_policy_docs {

    my (%opts) = @_;
    my $pattern = delete $opts{-doc};

    require Perl::Critic;
    $critic = Perl::Critic->new(%opts);
    _set_up_pager($critic->config()->pager());

    require Perl::Critic::PolicyFactory;
    my @site_policies  = Perl::Critic::PolicyFactory->site_policy_names();
    my @matching_policies  = grep { /$pattern/ixms } @site_policies;

    # "-T" means don't send to pager
    my @perldoc_output = map {`perldoc -T $_`} @matching_policies;  ## no critic (ProhibitBacktick)
    _out @perldoc_output;

    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------

sub _display_version {
    _out "$VERSION\n";
    exit $EXIT_SUCCESS;
}

#-----------------------------------------------------------------------------
1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords
Twitter

=head1 NAME

Perl::Critic::Command - Guts of L<perlcritic|perlcritic>.


=head1 SYNOPSIS

    use Perl::Critic::Command qw< run >;

    local @ARGV = qw< --statistics-only lib bin >;
    run();


=head1 DESCRIPTION

This is the implementation of the L<perlcritic|perlcritic> command.  You can use
this to run the command without going through a command interpreter.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  However, its interface is
experimental, and will likely change.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<run()>

Does the equivalent of the L<perlcritic|perlcritic> command.  Unfortunately, at
present, this doesn't take any parameters but uses C<@ARGV> to get its
input instead.  Count on this changing; don't count on the current
interface.


=back


=head1 TO DO

Make C<run()> take parameters.  The equivalent of C<@ARGV> should be
passed as a reference.

Turn this into an object.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
