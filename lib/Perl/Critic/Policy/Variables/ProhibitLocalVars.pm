package Perl::Critic::Policy::Variables::ProhibitLocalVars;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $PACKAGE_RX => qr/::/xms;
Readonly::Scalar my $DESC => q{Variable declared as "local"};
Readonly::Scalar my $EXPL => [ 77, 78, 79 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw(core pbp maintenance)   }
sub applies_to           { return 'PPI::Statement::Variable' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( $elem->type() eq 'local' && !_all_global_vars($elem) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

#-----------------------------------------------------------------------------

sub _all_global_vars {

    my $elem = shift;
    for my $variable_name ( $elem->variables() ) {
        next if $variable_name =~ $PACKAGE_RX;
        # special exception for Test::More
        next if $variable_name eq '$TODO'; ## no critic (InterpolationOfMetachars)
        return if ! is_perl_global( $variable_name );
    }
    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitLocalVars - Use C<my> instead of C<local>, except when you have to.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Since Perl 5, there are very few reasons to declare C<local>
variables.  The most common exceptions are Perl's magical global
variables.  If you do need to modify one of those global variables,
you should localize it first.  You should also use the
L<English|English> module to give those variables more meaningful
names.

    local $foo;   #not ok
    my $foo;      #ok

    use English qw(-no_match_vars);
    local $INPUT_RECORD_SEPARATOR    #ok
    local $RS                        #ok
    local $/;                        #not ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

If an external module uses package variables as its interface, then
using C<local> is actually a pretty sensible thing to do.  So
Perl::Critic will not complain if you C<local>-ize variables with a
fully qualified name such as C<$Some::Package::foo>.  However, if
you're in a position to dictate the module's interface, I strongly
suggest using accessor methods instead.

=head1 SEE ALSO

L<Perl::Critic::Policy::Variables::ProhibitPunctuationVars|Perl::Critic::Policy::Variables::ProhibitPunctuationVars>

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
