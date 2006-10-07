#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::CodeLayout::RequireTidyCode;

use strict;
use warnings;
use English qw(-no_match_vars);
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#----------------------------------------------------------------------------

my $desc = q{Code is not tidy};
my $expl = [ 33 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST }
sub default_themes    { return qw(pbp cosmetic) }
sub applies_to       { return 'PPI::Document'  }

#---------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    #Set configuration if defined
    $self->{_perltidyrc} = $args{perltidyrc};
    if (defined $self->{_perltidyrc} && $self->{_perltidyrc} eq $EMPTY)
    {
       $self->{_perltidyrc} = \$EMPTY;
    }

    return $self;
}

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # If Perl::Tidy is missing, silently pass this test
    eval { require Perl::Tidy; };
    return if $EVAL_ERROR;

    # Perl::Tidy seems to produce slightly different output, depending
    # on the trailing whitespace in the input.  As best I can tell,
    # Perl::Tidy will truncate any extra trailing newlines, and if the
    # input has no trailing newline, then it adds one.  But when you
    # re-run it through Perl::Tidy here, that final newline gets lost,
    # which causes the policy to insist that the code is not tidy.
    # This only occurs when Perl::Tidy is writing the output to a
    # scalar, but does not occur when writing to a file.  I may
    # investigate further, but for now, this seems to do the trick.

    my $source = $doc->serialize();
    $source =~ s{ \s+ \Z}{\n}mx;

    my $dest    = $EMPTY;
    my $stderr  = $EMPTY;


    # Perl::Tidy gets confused if @ARGV has arguments from
    # another program.  Also, we need to override the
    # stdout and stderr redirects that the user may have
    # configured in their .perltidyrc file.
    local @ARGV = qw(-nst -nse);  ## no critic

    # Trap Perl::Tidy errors, just in case it dies
    eval {
        Perl::Tidy::perltidy(
            source      => \$source,
            destination => \$dest,
            stderr      => \$stderr,
            defined $self->{_perltidyrc} ? (perltidyrc => $self->{_perltidyrc}) : (),
       );
    };

    if ($stderr || $EVAL_ERROR) {

        # Looks like perltidy had problems
        $desc = q{perltidy had errors!!};
    }

    if ( $source ne $dest ) {
        return $self->violation( $desc, $expl, $elem );
    }

    return;    #ok!
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireTidyCode

=head1 DESCRIPTION

Conway does make specific recommendations for whitespace and
curly-braces in your code, but the most important thing is to adopt a
consistent layout, regardless of the specifics.  And the easiest way
to do that is to use L<Perl::Tidy>.  This policy will complain if
you're code hasn't been run through Perl::Tidy.

=head1 CONSTRUCTOR

This Policy accepts an additional key-value pair in the constructor.
The key must be C<perltidyrc> and the value is the filename of a
Perl::Tidy configuration file.  The default is C<undef>, which tells
Perl::Tidy to look in it's default location.  Users of Perl::Critic
can configure this in their F<.perlcriticrc> file like this:

  [CodeLayout::RequireTidyCode]
  perltidyrc = /usr/share/perltidy.conf

As a special case, setting C<perltidyrc> to the empty string tells
Perl::Tidy not to load any configuration file at all and just use
Perl::Tidy's own default style.

  [CodeLayout::RequireTidyCode]
  perltidyrc = 

=head1 NOTES

L<Perl::Tidy> is not included in the Perl::Critic distribution.  The
latest version of Perl::Tidy can be downloaded from CPAN.  If
Perl::Tidy is not installed, this policy is silently ignored.

=head1 SEE ALSO

L<Perl::Tidy>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
