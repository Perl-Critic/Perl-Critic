package Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict;

use 5.006001;
use strict;
use warnings;

use version 0.77;
use Readonly;
use Scalar::Util qw{ blessed };

use Perl::Critic::Utils qw{ :severities $EMPTY };
use Perl::Critic::Utils::Constants qw{ :equivalent_modules };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Code before strictures are enabled};
Readonly::Scalar my $EXPL => [ 429 ];

Readonly::Scalar my $PERL_VERSION_WHICH_IMPLIES_STRICTURE => qv('v5.11.0');

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'equivalent_modules',
            description     =>
                q<The additional modules to treat as equivalent to "strict".>,
            default_string  => $EMPTY,
            behavior        => 'string list',
            list_always_present_values => ['strict', @STRICT_EQUIVALENT_MODULES],
        },
    );
}

sub default_severity     { return $SEVERITY_HIGHEST   }
sub default_themes       { return qw( core pbp bugs certrule certrec ) }
sub applies_to           { return 'PPI::Document'     }

sub default_maximum_violations_per_document { return 1; }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, undef, $doc ) = @_;

    # Find the first 'use strict' statement
    my $strict_stmnt = $doc->find_first( $self->_generate_is_use_strict() );
    my $strict_line  = $strict_stmnt ? $strict_stmnt->location()->[0] : undef;

    # Find all statements that aren't 'use', 'require', or 'package'
    my $stmnts_ref = $self->_find_isnt_include_or_package($doc);
    return if not $stmnts_ref;

    # If the 'use strict' statement is not defined, or the other
    # statement appears before the 'use strict', then it violates.

    my @viols = ();
    for my $stmnt ( @{ $stmnts_ref } ) {
        last if $stmnt->isa('PPI::Statement::End');
        last if $stmnt->isa('PPI::Statement::Data');

        my $stmnt_line = $stmnt->location()->[0];
        if ( (! defined $strict_line) || ($stmnt_line < $strict_line) ) {
            push @viols, $self->violation( $DESC, $EXPL, $stmnt );
        }
    }
    return @viols;
}

#-----------------------------------------------------------------------------

sub _generate_is_use_strict {
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
        elsif ( my $version = $elem->version() ) {
            # Currently Adam returns a string here. He has said he may return
            # a version object in the future, so best be prepared.
            if ( not blessed( $version ) or not $version->isa( 'version' ) ) {
                if ( 'v' ne substr $version, 0, 1
                    and ( $version =~ tr/././ ) > 1 ) {
                    $version = 'v' . $version;
                }
                $version = version->parse( $version );
            }
            return 1 if $PERL_VERSION_WHICH_IMPLIES_STRICTURE <= $version;
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

Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict - Always C<use strict>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Using strictures is probably the single most effective way to improve
the quality of your code.  This policy requires that the C<'use
strict'> statement must come before any other statements except
C<package>, C<require>, and other C<use> statements.  Thus, all the
code in the entire package will be affected.

There are special exemptions for L<Moose|Moose>,
L<Moose::Role|Moose::Role>, and
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints> because
they enforces strictness; e.g.  C<'use Moose'> is treated as
equivalent to C<'use strict'>.

The maximum number of violations per document for this policy defaults
to 1.


=head1 CONFIGURATION

If you make use of things like
L<Moose::Exporter|Moose::Exporter>, you can create your own modules
that import the L<strict|strict> pragma into the code that is
C<use>ing them.  There is an option to add to the default set of
pragmata and modules in your F<.perlcriticrc>: C<equivalent_modules>.

    [TestingAndDebugging::RequireUseStrict]
    equivalent_modules = MooseX::My::Sugar


=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict|Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
