##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.095_001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC  => q{Subroutine called with "&" sigil};
Readonly::Scalar my $EXPL  => [ 175 ];

Readonly::Hash my %EXEMPTIONS =>
    hashify( qw< defined exists goto sort > );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_LOW            }
sub default_themes       { return qw(core pbp maintenance) }
sub applies_to           { return 'PPI::Token::Symbol'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $psib = $elem->sprevious_sibling();
    if ( $psib ) {
        #Sigil is allowed if taking a reference, e.g. "\&my_sub"
        return if $psib->isa('PPI::Token::Cast') && $psib eq q{\\};
    }

    return if ( $elem !~ m{\A [&] }xms ); # ok

    # look up past parens to get say the "defined" in "defined(&foo)" or
    # "defined((&foo))" etc
    if (! $psib) {
        my $up = $elem;
        while (($up = $up->parent)
               && ($up->isa('PPI::Statement::Expression')
                   || $up->isa('PPI::Structure::List')
                   || $up->isa('PPI::Statement'))) {
            if (my $word = $up->sprevious_sibling) {
                # For a word set $psib to have it checked against %EXEMPTIONS
                # below.  For a non-word it's a violation, leave $psib false
                # to get there.
                if ($word->isa('PPI::Token::Word')) {
                    $psib = $word;
                }
                last;
            }
        }
    }
    return if $psib and $EXEMPTIONS{$psib};

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils - Don't call functions with a leading ampersand sigil.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Since Perl 5, the ampersand sigil is completely optional when invoking
subroutines.  And it's easily confused with the bitwise 'and'
operator.

  @result = &some_function(); #Not ok
  @result = some_function();  #ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
