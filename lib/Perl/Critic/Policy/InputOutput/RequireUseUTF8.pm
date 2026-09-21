package Perl::Critic::Policy::InputOutput::RequireUseUTF8;

use 5.010001;
use strict;
use warnings;

use version 0.77;
use Readonly;
use Scalar::Util qw{ blessed };

use Perl::Critic::Utils qw{ :severities $EMPTY };
use Perl::Critic::Utils::Constants qw{ :equivalent_modules };
use parent 'Perl::Critic::Policy';

our $VERSION = '1.156';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Code before utf8 is enabled};
Readonly::Scalar my $EXPL => [ 429 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'equivalent_modules',
            description     =>
                q<The additional modules to treat as equivalent to "utf8".>,
            default_string  => $EMPTY,
            behavior        => 'string list',
            list_always_present_values => ['utf8', @UTF8_EQUIVALENT_MODULES],
        },
    );
}

sub default_severity     { return $SEVERITY_HIGH        }
sub default_themes       { return qw( core bugs )     }
sub applies_to           { return 'PPI::Document'     }

sub default_maximum_violations_per_document { return 1; }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, undef, $doc ) = @_;

    # Find the first 'use utf8' statement
    my $utf8_stmnt = $doc->find_first( $self->_generate_is_use_utf8() );
    my $utf8_line  = $utf8_stmnt ? $utf8_stmnt->location()->[0] : undef;

    # Find all statements that aren't 'use', 'require', or 'package'
    my $stmnts_ref = _find_isnt_include_or_package($doc);
    return if not $stmnts_ref;

    # If the 'use utf8' statement is not defined, or the other
    # statement appears before the 'use utf8', then it violates.

    my @viols;
    for my $stmnt ( @{ $stmnts_ref } ) {
        last if $stmnt->isa('PPI::Statement::End');
        last if $stmnt->isa('PPI::Statement::Data');

        my $stmnt_line = $stmnt->location()->[0];
        if ( (! defined $utf8_line) || ($stmnt_line < $utf8_line) ) {
            push @viols, $self->violation( $DESC, $EXPL, $stmnt );
        }
    }
    return @viols;
}

#-----------------------------------------------------------------------------

sub _generate_is_use_utf8 {
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
            # Special case: use source::encoding 'utf8' (Perl 5.41+)
            if ( $module eq 'source::encoding' ) {
                return _is_source_encoding_utf8($elem);
            }
            return 1 if $self->{_equivalent_modules}{$module};
        }

        return 0;
    };
}

#-----------------------------------------------------------------------------

sub _is_source_encoding_utf8 {
    my ($elem) = @_;

    # Check if the argument is 'utf8' or "utf8"
    # use source::encoding 'utf8';
    my @children = $elem->schildren();
    for my $child (@children) {
        if ( $child->isa('PPI::Token::Quote') ) {
            my $string = $child->string();
            return 1 if $string eq 'utf8';
        }
    }

    return 0;
}

#-----------------------------------------------------------------------------
# Here, we're using the fact that Perl::Critic::Document::find() is optimized
# to search for elements based on their type.  This is faster than using the
# native PPI::Node::find() method with a custom callback function.

sub _find_isnt_include_or_package {
    my ($doc) = @_;
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

Perl::Critic::Policy::InputOutput::RequireUseUTF8 - Always C<use utf8>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Using the C<utf8> pragma ensures that string literals in your source code
are properly interpreted as UTF-8. This policy requires that the C<'use
utf8'> statement must come before any other statements except C<package>,
C<require>, and other C<use> statements. Thus, all the code in the entire
package will be affected.

As of Perl 5.41, C<use source::encoding 'utf8'> is also recognized as
equivalent to C<use utf8>.

There are special exemptions for modules like L<Mojolicious::Lite|Mojolicious::Lite>
and L<Dancer2|Dancer2> because using them enables the utf8 pragma automatically;
e.g. C<'use Mojolicious::Lite'> enables utf8, making an explicit C<'use utf8'>
unnecessary.

The maximum number of violations per document for this policy defaults to 1.


=head1 CONFIGURATION

If you make use of things like
L<Mojoliciouse::Lite|Mojoliciouse::Lite>, L<Dancer2|Dancer2> you can create your own modules
that import the L<utf8|utf8> pragma into the code that is
C<use>ing them.  There is an option to add to the default set of
pragmata and modules in your F<.perlcriticrc>: C<equivalent_modules>.

    [InputOutput::RequireUseUTF8]
    equivalent_modules = Dancer2 Mojolicious::Lite

=head1 AUTHOR

Kenta Kobayashi <kfly@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2025 Kenta Kobayashi.  Many rights reserved.

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
