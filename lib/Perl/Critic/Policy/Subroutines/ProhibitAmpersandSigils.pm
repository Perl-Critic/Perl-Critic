package Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC  => q{Subroutine called with "&" sigil};
Readonly::Scalar my $EXPL  => [ 175 ];

Readonly::Hash my %EXEMPTIONS =>
    hashify( qw< defined exists goto sort > );

Readonly::Hash my %IS_COMMA =>
    hashify( q{,}, q{=>} );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_LOW            }
sub default_themes       { return qw(core pbp maintenance) }
sub applies_to           { return 'PPI::Token::Symbol'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $previous = $elem->sprevious_sibling();
    if ( $previous ) {
        #Sigil is allowed if taking a reference, e.g. "\&my_sub"
        return if $previous->isa('PPI::Token::Cast') && $previous eq q{\\};
    }

    return if ( $elem !~ m{\A [&] }xms ); # ok

    # look up past parens to get say the "defined" in "defined(&foo)" or
    # "defined((&foo))" etc
    if (not $previous or
            $previous->isa( 'PPI::Token::Operator' ) and
            $IS_COMMA{ $previous->content() } ) {
        my $up = $elem;

        PARENT:
        while (
                ($up = $up->parent)
            and (
                    $up->isa('PPI::Statement::Expression')
                or  $up->isa('PPI::Structure::List')
                or  $up->isa('PPI::Statement')
            )
        ) {
            if (my $word = $up->sprevious_sibling) {
                # Since backslashes distribute over lists (per perlref), if
                # we have a list and the previous is a backslash, we're cool.
                return if
                        $up->isa('PPI::Structure::List')
                    &&  $word->isa('PPI::Token::Cast')
                    &&  $word->content() eq q{\\};

                # For a word set $previous to have it checked against %EXEMPTIONS
                # below.  For a non-word it's a violation, leave $previous false
                # to get there.
                if ($word->isa('PPI::Token::Word')) {
                    $previous = $word;
                }
                last PARENT;
            }
        }
    }
    return if $previous and $EXEMPTIONS{$previous};

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
subroutines.  It also turns off checking of subroutine prototypes.
It's easily confused with the bitwise 'and' operator.

  @result = &some_function(); # not ok
  @result = some_function();  # ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
