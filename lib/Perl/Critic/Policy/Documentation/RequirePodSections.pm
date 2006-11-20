##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Documentation::RequirePodSections;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.22;

#---------------------------------------------------------------------------

my $expl = [133, 138];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW       }
sub default_themes   { return qw(pbp readability) }
sub applies_to       { return 'PPI::Document'     }

#---------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_lib_sections} = [ default_lib_sections() ];
    $self->{_script_sections} = [ default_script_sections() ];

    # Set config, if defined
    for my $section_type ( qw(lib_sections script_sections) ) {
        if ( defined $args{$section_type} ) {
            my @sections = split m{ \s* [|] \s* }mx, $args{$section_type};
            @sections = map { uc $_ } @sections;  #Nomalize CaSe!
            $self->{ "_$section_type" } = \@sections;
        }
    }

    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # This policy does not apply unless there is some real code in the
    # file.  For example, if this file is just pure POD, then
    # presumably this file is ancillary documentation and you can use
    # whatever headings you want.
    return if ! $doc->schild(0);

    my %found_sections = ();
    my @violations = ();

    my @required_sections = is_script($doc) ? @{ $self->{_script_sections} }
                                            : @{ $self->{_lib_sections} };

    my $pods_ref = $doc->find('PPI::Token::Pod');
    return if !$pods_ref;
    my $counter  = 0;  #Might use this to enforce ordering.

    # Round up the names of all the =head1 sections
    for my $pod ( @{ $pods_ref } ) {
        for my $found ( $pod =~ m{ ^ =head1 \s+ ( .+? ) \s* $ }gmx ) {
            #Leading/trailing whitespace is already removed
            $found_sections{ uc $found } = ++$counter;
        }
    }

    # Compare the required sections against those we found
    for my $required ( @required_sections ) {
        if ( ! exists $found_sections{$required} ) {
            my $desc = qq{Missing "$required" section in POD};
            push @violations, $self->violation( $desc, $expl, $doc );
        }
    }

    return @violations;
}

#---------------------------------------------------------------------------

sub default_lib_sections {

    return ( 'NAME',
             'VERSION',
             'SYNOPSIS',
             'DESCRIPTION',
             'SUBROUTINES/METHODS',
             'DIAGNOSTICS',
             'CONFIGURATION AND ENVIRONMENT',
             'DEPENDENCIES',
             'INCOMPATIBILITIES',
             'BUGS AND LIMITATIONS',
             'AUTHOR',
             'LICENSE AND COPYRIGHT',
        );
}

#---------------------------------------------------------------------------

sub default_script_sections {

    return ( 'NAME',
             'USAGE',
             'DESCRIPTION',
             'REQUIRED ARGUMENTS',
             'OPTIONS',
             'DIAGNOSTICS',
             'EXIT STATUS',
             'CONFIGURATION',
             'DEPENDENCIES',
             'INCOMPATIBILITIES',
             'BUGS AND LIMITATIONS',
             'AUTHOR',
             'LICENSE AND COPYRIGHT',
        );
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Documentation::RequirePodSections

=head1 DESCRIPTION

This Policy requires your POD to contain certain C<=head1> sections.
If the file doesn't contain any POD at all, then this Policy does not
apply.  Tools like L<Module::Starter> make it really easy to ensure
that every module has the same documentation framework, and they
can save you lots of keystrokes.

=head1 DEFAULTS

Different POD sections are required, depending on whether the file is a
library or script (which is determined by the presence or absence of a
perl shebang line).

             Default Required POD Sections

   Perl Libraries                     Perl Scripts
   ------------------------------------------------------
   NAME                               NAME
   VERSION                            VERSION
   SYNOPSIS                           USAGE
   DESCRIPTION                        DESCRIPTION
   SUBROUNTES/METHODS                 REQUIRED ARGUMENTS
                                      OPTIONS
   DIAGNOSTICS                        DIAGNOSTICS
                                      EXIT STATUS
   CONFIGURATION                      CONFIGURATION
   DEPENDENCIES                       DEPENDENCIES
   INCOMPATIBILITIES                  INCOMPATIBILITIES
   BUGS AND LIMITATIONS               BUGS AND LIMITATIONS
   AUTHOR                             AUTHOR
   LICENSE AND COPYRIGHT              LICENSE AND COPYRIGHT

=head1 CONSTRUCTOR

This policy accepts two additional key-value pairs in the C<new>
method.  The keys can be either C<'script_sections'> or
C<'lib_sections'>, and the value is always a string of pipe-delimited
POD section names.  These can be configured in the F<.perlcriticrc>
file like this:

 [Documentation::RequirePodSections]
 lib_sections    = NAME | SYNOPSIS | BUGS AND LIMITATIONS | AUTHOR
 script_sections = NAME | USAGE | OPTIONS | EXIT STATUS | AUTHOR

=head1 LIMITATIONS

Currently, this Policy does not look for the required POD sections
below the C<=head1> level.  Also, it does not require the sections to
appear in any particular order.

=head1 SUBROUTINES

=over 8

=item default_script_sections()

Returns a list of the default POD section that are required for Perl
scripts.  A Perl script is anything that contains a shebang line
that looks like C</perl/>.

=item default_lib_sections()

Returns a list of the default POD section that are required for Perl
libraries and modules.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 expandtab :
