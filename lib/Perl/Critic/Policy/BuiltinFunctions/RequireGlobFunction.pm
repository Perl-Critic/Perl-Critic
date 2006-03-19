##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.14_02';
$VERSION = eval $VERSION;    ## no critic

#----------------------------------------------------------------------------

my $glob_rx = qr{ [\*\?] }x;
my $desc    = q{Glob written as <...>};
my $expl    = [ 167 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST }
sub applies_to { return 'PPI::Token::QuoteLike::Readline' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    if ( $elem =~ $glob_rx ) {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }
    return;    #ok!
}

1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction

=head1 DESCRIPTION

Conway discourages the use of the C<E<lt>..E<gt>> construct for globbing, as
its heavily associated with I/O in most people's minds.  Instead, he recommends
the use of the C<glob()> function as it makes it much more obvious what you're
attempting to do.

  @files = <*.pl>;              # not ok
  @files = glob( "*.pl" );      # ok

=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2005-2006 Graham TerMarsch.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
