##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::NamingConventions::Capitalization;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $LOWER_RX       => qr/ [[:lower:]] /xms;
Readonly::Scalar my $UPPER_RX       => qr/ [[:upper:]] /xms;
Readonly::Scalar my $PACKAGE_RX     => qr/ :: /xms;
Readonly::Scalar my $DESC           => 'Capitalization';
Readonly::Scalar my $EXPL           => [ 45 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                            }
sub default_severity     { return $SEVERITY_LOWEST              }
sub default_themes       { return qw( core pbp cosmetic )       }

sub applies_to {
    return 'PPI::Statement::Variable',
           'PPI::Statement::Package',
           'PPI::Statement::Sub';
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $violates
      = $elem->isa("PPI::Statement::Variable") ? _variable_capitalization($elem)
      : $elem->isa("PPI::Statement::Package")  ? _package_capitalization($elem)
      : $elem->isa("PPI::Statement::Sub")      ? _sub_capitalization($elem)
      :                                          die "Should never reach this point"
      ;

    return $self->violation( $DESC, $EXPL, $elem ) if $violates;
    return;
}

sub _variable_capitalization {
    my $elem = shift;

    for my $name ( $elem->variables() ) {
        # Fully qualified names are exempt because we can't be responsible for
        # other people's sybols.
        next if $elem->type() eq 'local' && $name =~ m/$PACKAGE_RX/xms;

        # Allow CONSTANTS
        next if $name !~ $LOWER_RX;

        # Words in variable names cannot be capitalized unless
        # camelCase is in use
        return 1 if $name =~ m{ [^[:alpha:]] $UPPER_RX }xmso;
    }

    return;
}

sub _package_capitalization {
    my $elem = shift;
    my @names = split /::/, $elem->namespace;

    for my $name (@names) {
        # Each word should be capitalized.
        return 1 unless $name =~ m{ ^ $UPPER_RX }xmso;
    }

    return;
}

sub _sub_capitalization {
    my $elem = shift;
    my $name = $elem->name;

    # Words in subroutine names cannot be capitalized
    # unless camelCase is in use.
    return 1 if $name =~ m{
                              (?: ^ | [^[:alpha:]] )
                              $UPPER_RX
                          }xmso;
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=head1 NAME

Perl::Critic::Policy::NamingConventions::Capitalization - Distinguish different program components by case.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic> distribution.


=head1 DESCRIPTION

Conway recommends to distinguish different program components by case.

Normal subroutines, methods and variables are all in lower case.

    my $foo;            # ok
    my $foo_bar;        # ok
    sub foo {}          # ok
    sub foo_bar {}      # ok

    my $Foo;            # not ok
    my $foo_Bar;        # not ok
    sub Foo     {}      # not ok
    sub foo_Bar {}      # not ok

Package and class names are capitalized.

    package IO::Thing;     # ok
    package Web::FooBar    # ok

    package foo;           # not ok
    package foo::Bar;      # not ok

Constants are in all-caps.

    Readonly::Scalar my $FOO = 42;  # ok

    Readonly::Scalar my $foo = 42;  # not ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 BUGS

The policy cannot currently tell that a variable is being declared as
a constant, thus any variable may be made all-caps.


=head1 SEE ALSO

To control use of camelCase see
L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs|Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs>
and
L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars|Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars>.


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 COPYRIGHT

Copyright (c) 2008 Michael G Schwern.  All rights reserved.

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
