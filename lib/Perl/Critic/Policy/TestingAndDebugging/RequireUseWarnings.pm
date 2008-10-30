##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::Util qw(first);
use version ();

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.093_02';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Code before warnings are enabled};
Readonly::Scalar my $EXPL => [431];

Readonly::Scalar my $MINIMUM_VERSION => version->new(5.006);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp ) }
sub applies_to           { return 'PPI::Document'     }

sub default_maximum_violations_per_document { return 1; }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    my $version = $document->highest_explicit_perl_version();
    return if $version and $version < $MINIMUM_VERSION;

    # Find the first 'use warnings' statement
    my $warn_stmnt = $document->find_first( \&_is_use_warnings );
    my $warn_line  = $warn_stmnt ? $warn_stmnt->location()->[0] : undef;

    # Find all statements that aren't 'use', 'require', or 'package'
    my $stmnts_ref = $document->find( \&_isnt_include_or_package );
    return if !$stmnts_ref;

    # If the 'use warnings' statement is not defined, or the other
    # statement appears before the 'use warnings', then it violates.

    my @viols = ();
    for my $stmnt ( @{ $stmnts_ref } ) {
        last if $stmnt->isa('PPI::Statement::End');
        last if $stmnt->isa('PPI::Statement::Data');

        my $stmnt_line = $stmnt->location()->[0];
        if ( (! defined $warn_line) || ($stmnt_line < $warn_line) ) {
            push @viols, $self->violation( $DESC, $EXPL, $stmnt );
        }
    }
    return @viols;
}

sub _is_use_warnings {
    my (undef, $elem) = @_;

    return 0 if !$elem->isa('PPI::Statement::Include');
    return 0 if $elem->type() ne 'use';

    if (
            $elem->pragma() ne 'warnings'
        and $elem->module() ne 'Moose'
        and $elem->module() ne 'Moose::Role'
    ) {
        return 0;
    }

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

Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings - Always C<use warnings>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Using warnings, and paying attention to what they say, is probably the
single most effective way to improve the quality of your code.  This
policy requires that the C<'use warnings'> statement must come before
any other statements except C<package>, C<require>, and other C<use>
statements.  Thus, all the code in the entire package will be
affected.

There are special exemptions for L<Moose|Moose> and
L<Moose::Role|Moose::Role> because they enforces strictness; e.g.
C<'use Moose'> is treated as equivalent to C<'use warnings'>.

This policy will not complain if the file explicitly states that it is
compatible with a version of perl prior to 5.6 via an include
statement, e.g. by having C<require 5.005> in it.

The maximum number of violations per document for this policy defaults
to 1.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 BUGS

Needs to check for -w on the shebang line.


=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings|Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
