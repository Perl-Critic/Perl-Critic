#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $desc = q{Code before strictures are enabled};
my $expl = [ 429 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST }
sub default_themes    { return qw( pbp danger )  }
sub applies_to       { return 'PPI::Document'   }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, undef, $doc ) = @_;

    # Find the first 'use strict' statement
    my $strict_stmnt = $doc->find_first( \&_is_use_strict );
    my $strict_line  = $strict_stmnt ? $strict_stmnt->location()->[0] : undef;

    # Find all statements that aren't 'use', 'require', or 'package'
    my $stmnts_ref = $doc->find( \&_isnt_include_or_package );
    return if !$stmnts_ref;

    # If the 'use strict' statement is not defined, or the other
    # statement appears before the 'use strict', then it violates.

    my @viols = ();
    for my $stmnt ( @{ $stmnts_ref } ) {
        last if $stmnt->isa('PPI::Statement::End');
        last if $stmnt->isa('PPI::Statement::Data');
        my $stmnt_line = $stmnt->location()->[0];
        if ( (! defined $strict_line) || ($stmnt_line < $strict_line) ) {
            push @viols, $self->violation( $desc, $expl, $stmnt );
        }
    }
    return @viols;
}

sub _is_use_strict {
    my (undef, $elem) = @_;

    return 0 if !$elem->isa('PPI::Statement::Include');
    return 0 if $elem->type() ne 'use';
    return 0 if $elem->pragma() ne 'strict';
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

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict

=head1 DESCRIPTION

Using strictures is probably the single most effective way to improve
the quality of your code.  This policy requires that the C<'use
strict'> statement must come before any other statements except
C<package>, C<require>, and other C<use> statements.  Thus, all the
code in the entire package will be affected.

=head1 NOTES

Up through version 0.15, this Policy only reported a violation for the
first offending statement.  Starting in version 0.15_03, this Policy
was modified to report a violation for every offending statement.
This change closes a loophole with the C<"## no critic">
pseudo-pragmas.  But for old legacy code that isn't strict, it
produces B<a lot> of violations.  The best way to alleviate the
problem is to organize your code like this.

  ## no critic 'RequireUseStrict';
  ## Legacy code goes here...

  use strict;
  ## New code goes here...

In this manner, you can develop new code that is strict, but allow the
strictures to be disabled for all your legacy code.  Perl::Critic will
only report violations of this policy that occur on lines after the
C<"## use critic"> pseudo-pragma.

=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut
