##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings;

use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(all);

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};
use base 'Perl::Critic::Policy';

our $VERSION = 1.077;

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Warnings disabled};
Readonly::Scalar my $EXPL => [ 431 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw( allow )               }
sub default_severity { return $SEVERITY_HIGH            }
sub default_themes   { return qw( core bugs pbp )       }
sub applies_to       { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->{_allow} = {};

    if( defined $config->{allow} ) {
        my $allowed = lc $config->{allow}; #String of words
        my %allowed = hashify( $allowed =~ m/ (\w+) /gmx );
        $self->{_allow} = \%allowed;
    }

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, undef ) = @_;

    return if $elem->type()   ne 'no';
    return if $elem->pragma() ne 'warnings';

    #Arguments to 'no warnings' are usually a list of literals or a
    #qw() list.  Rather than trying to parse the various PPI elements,
    #I just use a regext to split the statement into words.  This is
    #kinda lame, but it does the trick for now.

    my $stmnt = $elem->statement();
    return if !$stmnt;
    my @words = split m{ [^a-z]+ }mx, $stmnt;
    @words = grep { $_ !~ m{ qw|no|warnings }mx } @words;
    return if all { exists $self->{_allow}->{$_} } @words;

    #If we get here, then it must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings

=head1 DESCRIPTION

There are good reasons for disabling certain kinds of warnings.  But if you
were wise enough to C<use warnings> in the first place, then it doesn't make
sense to disable them completely.  By default, any C<no warnings> statement
will violate this policy.  However, you can configure this Policy to allow
certain types of warnings to be disabled (See L<Configuration>).  A bare C<no
warnings> statement will always raise a violation.

=head1 CONFIGURATION

The permitted warning types can be configured via the C<allow> option.  The
value is a list of whitespace-delimited warning types that you want to be able
to disable.  See L<perllexwarn> for a list of possible warning types.  An
example of this customization:

  [TestingAndDebugging::ProhibitNoWarnings]
  allow = uninitialized once

=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
