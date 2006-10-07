#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings;

use strict;
use warnings;
use List::MoreUtils qw(all);
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $desc = q{Warnings disabled};
my $expl = [ 431 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH            }
sub default_themes    { return qw( risky pbp )           }
sub applies_to       { return 'PPI::Statement::Include' }

#---------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{_allow} = {};

    if( defined $args{allow} ) {
        for my $allowed ( split m{\W+}mx, lc $args{allow} ) {
            $self->{_allow}->{$allowed} = 1;
        }
    }

    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return unless ($elem->type() eq 'no' && $elem->pragma() eq 'warnings'); ## no critic

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
    return $self->violation( $desc, $expl, $elem );
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings

=head1 DESCRIPTION

There are good reasons for disabling certain kinds of warnings.  But
if you were wise enough to C<use warnings> in the first place, then it
doesn't make sense to disable them completely.  By default, any C<no
warnings> statement will violate this policy.  However, you can
configure this Policy to allow certain types of warnings to be
disabled (See L<Configuration>).  A bare C<no warnings> statement will
always raise a violation.

=head1 CONSTRUCTOR

This policy accepts one key-value pair in the constructor.  The key is
'allow' and the value is a string of whitespace delimited warning
types that you are willing to disable.  See L<perllexwarn> for a list
of possible warning types.  Users of the Perl::Critic engine can
configure this in their F<.perlcriticrc> file like this:

  [TestingAndDebugging::ProhibitWarningsDisabling]
  allow = uninitialized once

=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequirePackageWarnings>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut
