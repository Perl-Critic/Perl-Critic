##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Variables::RequireLocalizedPunctuationVars;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification hashify};
use base 'Perl::Critic::Policy';

our $VERSION = '1.083_003';

#-----------------------------------------------------------------------------

Readonly::Scalar my $PACKAGE_RX => qr/::/mx;
Readonly::Hash   my %EXCEPTIONS => hashify(qw(
    $_
    $ARG
    @_
));
Readonly::Scalar my $DESC => q{Magic variables should be assigned as "local"};
Readonly::Scalar my $EXPL => [ 81, 82 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw(core pbp bugs)          }
sub applies_to           { return 'PPI::Token::Operator'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne q{=};

    my $destination = $elem->sprevious_sibling;
    return if !$destination;  # huh? assignment in void context??

    if (_is_non_local_magic_dest($destination)) {
       return $self->violation( $DESC, $EXPL, $elem );
    }
    return;  # OK
}

sub _is_non_local_magic_dest {
    my $elem = shift;

    #print "Test dest $elem, @{[ref $elem]}\n";

    # Quick exit if in good form
    my $modifier = $elem->sprevious_sibling;
    return
        if
                $modifier
            &&  $modifier->isa('PPI::Token::Word')
            &&  ($modifier eq 'local' || $modifier eq 'my');

    # Implementation note: Can't rely on PPI::Token::Magic,
    # unfortunately, because we need English too

    if ($elem->isa('PPI::Token::Symbol')) {
        return _is_magic_var($elem);
    } elsif ($elem->isa('PPI::Structure::List') || $elem->isa('PPI::Statement::Expression')) {
        for my $child ($elem->schildren) {
            return 1 if _is_non_local_magic_dest($child);
        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _is_magic_var {
    my ($elem) = @_;

    my $variable_name = "$elem";
    return if $EXCEPTIONS{$variable_name};
    return 1 if $elem->isa('PPI::Token::Magic'); # optimization(?), and helps with PPI 1.118 carat bug
    return if ! is_perl_global( $elem );

    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::RequireLocalizedPunctuationVars - Magic variables should be assigned as "local".

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic> distribution.


=head1 DESCRIPTION

Punctuation variables (and their English.pm equivalents) are global
variables.  Messing with globals is dangerous in a complex program as
it can lead to very subtle and hard to fix bugs.  If you must change a
magic variable in a non-trivial program, do it in a local scope.

For example, to slurp a filehandle into a scalar, it's common to set
the record separator to undef instead of a newline.  If you choose to
do this (instead of using L<File::Slurp>!) then be sure to localize
the global and change it for as short a time as possible.

   # BAD:
   $/ = undef;
   my $content = <$fh>;

   # BETTER:
   my $content;
   {
       local $/ = undef;
       $content = <$fh>;
   }

   # A popular idiom:
   my $content = do { local $/ = undef; <$fh> };

This policy also allows the use of C<my>.  Perl prevents using C<my>
with "proper" punctuation variables, but allows C<$a>, C<@ARGV>, the
names declared by L<English>, etc.  This is not a good coding
practice, however it is not the concern of this specific policy to
complain about that.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 CAVEATS

The current PPI (v1.118) has a bug where $^ variables absorb following
whitespace by mistake.  This makes it harder to spot those as magic
variables.  Hopefully this will be fixed by PPI 1.200.  In the
meantime, we have a workaround in this module.

Additionally, PPI v1.118 fails to recognize %! and %^H as magic
variables.  PPI instead sees the "%" as a modulus operator.  We have
no workaround for that bug right now.

=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007-2008 Chris Dolan.  Many rights reserved.

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
