##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings;

use strict;
use warnings;
use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

my $desc = q{Version string used};
my $expl = q{Use a real number instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return() }
sub default_severity { return $SEVERITY_MEDIUM          }
sub default_themes   { return qw(core pbp maintenance)       }
sub applies_to       { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( $elem->type() eq 'use' || $elem->type() eq 'require' ) {

        #This is a pretty crude way to verify that a version string is
        #being used.  But there are several permutations of the syntax
        #for C<use> and C<require>.  Also PPI doesn't parses strings
        #like "5.6.1" as an integer that is being concatenated to a
        #float.  I'm not sure if this should be reported as a bug.

        if ( $elem =~ m{ \b v? \d+ [.] \d+ [.] \d+ \b }mx ) {
            return $self->violation( $desc, $expl, $elem );
        }
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings

=head1 DESCRIPTION

Whenever you C<use> or C<require> a module, you can specify a minimum
version requirement.  To ensure compatibility with older Perls, this
version number should be expressed as a floating-point number.  Do not
use v-strings or three-part numbers.  The Perl convention for expressing
version numbers as floats is: version + (patch level / 1000).

  use Foo v1.2    qw(foo bar);  # not ok
  use Foo 1.2.03  qw(foo bar);  # not ok
  use Foo 1.00203 qw(foo bar);  # ok

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
