package Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $GLOB_RX => qr< [*?] >xms;
Readonly::Scalar my $DESC    => q{Glob written as <...>};
Readonly::Scalar my $EXPL    => [ 167 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                                }
sub default_severity     { return $SEVERITY_HIGHEST                 }
sub default_themes       { return qw( core pbp bugs )               }
sub applies_to           { return 'PPI::Token::QuoteLike::Readline' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem =~ $GLOB_RX ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction - Use C<glob q{*}> instead of <*>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway discourages the use of the C< <..> > construct for globbing, as
it is easily confused with the angle bracket file input operator.
Instead, he recommends the use of the C<glob()> function as it makes
it much more obvious what you're attempting to do.

    @files = <*.pl>;              # not ok
    @files = glob '*.pl';         # ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Graham TerMarsch.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
