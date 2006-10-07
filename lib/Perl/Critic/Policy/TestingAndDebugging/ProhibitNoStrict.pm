#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict;

use strict;
use warnings;
use List::MoreUtils qw(all);
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $desc = q{Stricture disabled};
my $expl = [ 429 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST         }
sub default_themes    { return qw( pbp danger )          }
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

    return unless ($elem->type() eq 'no' && $elem->pragma() eq 'strict'); ## no critic

    #Arguments to 'no strict' are usually a list of literals or a qw()
    #list.  Rather than trying to parse the various PPI elements, I
    #just use a regex to split the statement into words.  This is
    #kinda lame, but it does the trick for now.

    my $stmnt = $elem->statement();
    return if !$stmnt;
    my @words = split m{ [^a-z]+ }mx, $stmnt;
    @words = grep { $_ !~ m{ qw|no|strict }mx } @words;
    return if all { exists $self->{_allow}->{$_} } @words;

    #If we get here, then it must be a violation
    return $self->violation( $desc, $expl, $elem );
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict

=head1 DESCRIPTION

There are good reasons for disabling certain kinds of strictures, But
if you were wise enough to C<use strict> in the first place, then it
doesn't make sense to disable it completely.  By default, any C<no
strict> statement will violate this policy.  However, you can
configure this Policy to allow certain types of strictures to be
disabled (See L<Configuration>).  A bare C<no strict> statement will
always raise a violation.

=head1 CONSTRUCTOR

This policy accepts one key-value pair in the constructor.  The key is
'allow' and the value is a string of whitespace delimited stricture
types that you want to permit.  These can be 'vars', 'subs' and/or
'refs'.  Users of the Perl::Critic engine can configure this in their
F<.perlcriticrc> file like this:

  [TestingAndDebugging::ProhibitStrictureDisabling]
  allow = vars subs refs

=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequirePackageStricture>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut
