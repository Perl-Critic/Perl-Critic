##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings;

use strict;
use warnings;
use Perl::Critic::Utils;
use List::Util qw(first);
use base 'Perl::Critic::Policy';

our $VERSION = 0.230;

#-----------------------------------------------------------------------------

my $desc = q{Code before warnings are enabled};
my $expl = [431];

#-----------------------------------------------------------------------------

sub supported_parameters { return() }
sub default_severity { return $SEVERITY_HIGH  }
sub default_themes    { return qw( core bugs pbp ) }
sub applies_to       { return 'PPI::Document' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Find the first 'use warnings' statement
    my $warn_stmnt = $doc->find_first( \&_is_use_warnings );
    my $warn_line  = $warn_stmnt ? $warn_stmnt->location()->[0] : undef;

    # Find all statements that aren't 'use', 'require', or 'package'
    my $stmnts_ref = $doc->find( \&_isnt_include_or_package );
    return if !$stmnts_ref;

    # If the 'use warnings' statement is not defined, or the other
    # statement appears before the 'use warnings', then it violates.

    my @viols = ();
    for my $stmnt ( @{ $stmnts_ref } ) {
        last if $stmnt->isa('PPI::Statement::End');
        last if $stmnt->isa('PPI::Statement::Data');

        # work around PPI bug: C<({})> results in a statement without a
        # location.
        my $stmnt_line = $stmnt->location() ? $stmnt->location()->[0] : -1;
        if ( (! defined $warn_line) || ($stmnt_line < $warn_line) ) {
            push @viols, $self->violation( $desc, $expl, $stmnt );
        }
    }
    return @viols;
}

sub _is_use_warnings {
    my (undef, $elem) = @_;

    return 0 if !$elem->isa('PPI::Statement::Include');
    return 0 if $elem->type() ne 'use';
    return 0 if $elem->pragma() ne 'warnings';
    return 1;
}

sub _isnt_include_or_package {
    my (undef, $elem) = @_;
    return 0 if ! $elem->isa('PPI::Statement');
    return 0 if $elem->isa('PPI::Statement::Package');
    return 0 if $elem->isa('PPI::Statement::Include');
    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings

=head1 DESCRIPTION

Using warnings, and paying attention to what they say, is probably the
single most effective way to improve the quality of your code.  This
policy requires that the C<'use warnings'> statement must come before
any other statements except C<package>, C<require>, and other C<use>
statements.  Thus, all the code in the entire package will be affected.

=head1 NOTES

Up through version 0.15, this Policy only reported a violation for the
first offending statement.  Starting in version 0.15_03, this Policy
was modified to report a violation for every offending statement.
This change closes a loophole with the C<"## no critic">
pseudo-pragmas.  But for old legacy code that doesn't use warnings, it
produces B<a lot> of violations.  The best way to alleviate the
problem is to organize your code like this.

  ## no critic 'RequireUseWarnings';

  ## Legacy code goes here...

  ## use critic;
  use warnings;

  ## New code goes here...

In this manner, you can develop new code with warnings enabled, but
still allow the warnings to be disabled for all your legacy code.
Perl::Critic will only report violations of this policy that occur on
lines after the C<"## use critic"> pseudo-pragma.

=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
