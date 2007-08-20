##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::test_02_policy::StringParameterTest;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use Perl::Critic::Policy;

our $VERSION = 1.061;

#-----------------------------------------------------------------------------

parameter 'foo', {
    is_a                => 'string',
    with_description    => 'frobnicates the frobulator',
    with_default_string => 'bar'
};
#    which must be defined
#    and with the empty string being equivalent to undef

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_MEDIUM   }
sub default_themes       { return qw( self_test )    }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub violates {
    # This policy is never going to be used to critique code.
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::test_02_policy::StringParameterTest - Policy to test declaration of string PolicyParameters

=head1 DESCRIPTION

Testing, testing, testing.

=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
