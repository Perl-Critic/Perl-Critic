package Perl::Critic::Policy::Variables::ProtectPrivateVars;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Private variable used};
Readonly::Scalar my $EXPL => q{Use published APIs};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                   }
sub default_severity     { return $SEVERITY_MEDIUM     }
sub default_themes       { return qw(core maintenance certrule ) }
sub applies_to           { return 'PPI::Token::Symbol' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem =~ m{ \w::_\w+ \z }xms ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProtectPrivateVars - Prevent access to private vars in other packages.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

By convention Perl authors (like authors in many other languages)
indicate private methods and variables by inserting a leading
underscore before the identifier.  This policy catches attempts to
access private variables from outside the package itself.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 HISTORY

This policy is inspired by a similar test in L<B::Lint|B::Lint>


=head1 SEE ALSO

L<Perl::Critic::Policy::Subroutines::ProtectPrivateSubs|Perl::Critic::Policy::Subroutines::ProtectPrivateSubs>


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
