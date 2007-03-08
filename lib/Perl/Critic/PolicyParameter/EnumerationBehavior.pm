##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PolicyParameter::EnumerationBehavior;

use strict;
use warnings;
use Carp qw(confess);
use Perl::Critic::Utils qw{ $PERIOD &words_from_string &hashify };

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    my $values_string = $specification->{enumeration_values}
        or confess 'No enumeration_values given for ',
                    $parameter->get_name(), $PERIOD;

    my %values = hashify( words_from_string( $values_string ) );

    my $allow_multiple_values =
        $specification->{enumeration_allow_multiple_values};

    if ($allow_multiple_values) {
        $parameter->_set_parser(
            sub {
                my $config_string = shift;

                my @potential_values = words_from_string($config_string);

                my @bad_values =
                    grep { not defined $values{$_} } @potential_values;
                if (@bad_values) {
                    # TODO: include policy name.
                    die 'Invalid values given in configuration for "',
                        $parameter->get_name(),
                        q{": },
                        join (q{, }, @bad_values),
                        qq{.\n};
                }

                return @potential_values;
            }
        );
    } else {
        $parameter->_set_parser(
            sub {
                my $config_string = shift;

                if ( not defined $values{$config_string} ) {
                    # TODO: include policy name.
                    die 'Invalid value given in configuration for "',
                        $parameter->get_name(),
                        qq{": $config_string.\n};
                }

                return $config_string;
            }
        );
    }

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::PolicyParameter::Behavior - Type-specific subroutines for a PolicyParameter.

=head1 DESCRIPTION


=head1 METHODS


=head1 DOCUMENTATION


=head1 OVERLOADS


=head1 AUTHOR

Elliot Shank <perl@galumph.org>

=head1 COPYRIGHT

Copyright (c) 2006 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
