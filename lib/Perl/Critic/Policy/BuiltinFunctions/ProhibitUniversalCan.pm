package Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalCan;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{UNIVERSAL::can should not be used as a function};
Readonly::Scalar my $EXPL => q{Use eval{$obj->can($pkg)} instead};  ## no critic (RequireInterp);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw( core maintenance certrule ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if !($elem eq 'can' || $elem eq 'UNIVERSAL::can');
    return if ! is_function_call($elem); # this also permits 'use UNIVERSAL::can;'

    return $self->violation( $DESC, $EXPL, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalCan - Write C<< eval { $foo->can($name) } >> instead of C<UNIVERSAL::can($foo, $name)>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

    print UNIVERSAL::can($obj, 'Foo::Bar') ? 'yes' : 'no';  #not ok
    print eval { $obj->can('Foo::Bar') } ? 'yes' : 'no';    #ok

As of Perl 5.9.3, the use of UNIVERSAL::can as a function has been
deprecated and the method form is preferred instead.  Formerly, the
functional form was recommended because it gave valid results even
when the object was C<undef> or an unblessed scalar.  However, the
functional form makes it impossible for packages to override C<can()>,
a technique which is crucial for implementing mock objects and some
facades.

See L<UNIVERSAL::can|UNIVERSAL::can> for a more thorough discussion of
this topic.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa|Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa>


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Chris Dolan.

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
