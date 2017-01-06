package Perl::Critic::Policy::Variables::RequireInitializationForLocalVars;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"local" variable not initialized};
Readonly::Scalar my $EXPL => [ 78 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw(core pbp bugs certrec )          }
sub applies_to           { return 'PPI::Statement::Variable' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( $elem->type() eq 'local' && !_is_initialized($elem) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

#-----------------------------------------------------------------------------

sub _is_initialized {
    my $elem = shift;
    my $wanted = sub { $_[1]->isa('PPI::Token::Operator') && $_[1] eq q{=} };
    return $elem->find( $wanted ) ? 1 : 0;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::RequireInitializationForLocalVars - Write C<local $foo = $bar;> instead of just C<local $foo;>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Most people don't realize that a localized copy of a variable does not
retain its original value.  Unless you initialize the variable when
you C<local>-ize it, it defaults to C<undef>.  If you want the
variable to retain its original value, just initialize it to itself.
If you really do want the localized copy to be undef, then make it
explicit.

    package Foo;
    $Bar = '42';

    package Baz;

    sub frobulate {

        local $Foo::Bar;              #not ok, local $Foo::Bar is 'undef'
        local $Foo::Bar = undef;      #ok, local $Foo::Bar is obviously 'undef'
        local $Foo::Bar = $Foo::Bar;  #ok, local $Foo::Bar still equals '42'

    }


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
