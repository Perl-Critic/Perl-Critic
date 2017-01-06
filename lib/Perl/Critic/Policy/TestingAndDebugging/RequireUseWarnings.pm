package Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::Util qw(first);
use version ();

use Perl::Critic::Utils qw{ :severities $EMPTY };
use Perl::Critic::Utils::Constants qw{ :equivalent_modules };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Code before warnings are enabled};
Readonly::Scalar my $EXPL => [431];

Readonly::Scalar my $MINIMUM_VERSION => version->new(5.006);

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'equivalent_modules',
            description     =>
                q<The additional modules to treat as equivalent to "warnings".>,
            default_string  => $EMPTY,
            behavior        => 'string list',
            list_always_present_values => ['warnings', @WARNINGS_EQUIVALENT_MODULES],
        },
    );
}

sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core pbp bugs certrule ) }
sub applies_to           { return 'PPI::Document'     }

sub default_maximum_violations_per_document { return 1; }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, undef, $document ) = @_;

    my $version = $document->highest_explicit_perl_version();
    return if $version and $version < $MINIMUM_VERSION;

    # Find the first 'use warnings' statement
    my $warn_stmnt = $document->find_first( $self->_generate_is_use_warnings() );
    my $warn_line  = $warn_stmnt ? $warn_stmnt->location()->[0] : undef;

    # Find all statements that aren't 'use', 'require', or 'package'
    my $stmnts_ref =  $self->_find_isnt_include_or_package($document);
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

#-----------------------------------------------------------------------------

sub _generate_is_use_warnings {
    my ($self) = @_;

    return sub {
        my (undef, $elem) = @_;

        return 0 if !$elem->isa('PPI::Statement::Include');
        return 0 if $elem->type() ne 'use';

        # We only want file-scoped pragmas
        my $parent = $elem->parent();
        return 0 if !$parent->isa('PPI::Document');

        if ( my $pragma = $elem->pragma() ) {
            return 1 if $self->{_equivalent_modules}{$pragma};
        }
        elsif ( my $module = $elem->module() ) {
            return 1 if $self->{_equivalent_modules}{$module};
        }

        return 0;
    };
}

#-----------------------------------------------------------------------------
# Here, we're using the fact that Perl::Critic::Document::find() is optimized
# to search for elements based on their type.  This is faster than using the
# native PPI::Node::find() method with a custom callback function.

sub _find_isnt_include_or_package {
    my ($self, $doc) = @_;
    my $all_statements = $doc->find('PPI::Statement') or return;
    my @wanted_statements = grep { _statement_isnt_include_or_package($_) } @{$all_statements};
    return @wanted_statements ? \@wanted_statements : ();
}

#-----------------------------------------------------------------------------

sub _statement_isnt_include_or_package {
    my ($elem) = @_;
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

There are special exemptions for L<Moose|Moose>,
L<Moose::Role|Moose::Role>, and
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints> because
they enforces warnings; e.g.  C<'use Moose'> is treated as
equivalent to C<'use warnings'>.

This policy will not complain if the file explicitly states that it is
compatible with a version of perl prior to 5.6 via an include
statement, e.g. by having C<require 5.005> in it.

The maximum number of violations per document for this policy defaults
to 1.


=head1 CONFIGURATION

If you make use of things like
L<Moose::Exporter|Moose::Exporter>, you can create your own modules
that import the L<warnings|warnings> pragma into the code that is
C<use>ing them.  There is an option to add to the default set of
pragmata and modules in your F<.perlcriticrc>: C<equivalent_modules>.

    [TestingAndDebugging::RequireUseWarnings]
    equivalent_modules = MooseX::My::Sugar


=head1 BUGS

Needs to check for -w on the shebang line.


=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings|Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
