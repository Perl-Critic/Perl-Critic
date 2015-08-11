package Perl::Critic::Policy::ValuesAndExpressions::ProhibitComplexVersion;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use Perl::Critic::Utils qw{ :booleans :characters :severities };
use Perl::Critic::Utils::PPI qw{
    get_next_element_in_same_simple_statement
    get_previous_module_used_on_same_line
    is_ppi_simple_statement
};
use Readonly;
use Scalar::Util qw{ blessed };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DOLLAR => q<$>;
# All uses of the $DOLLAR variable below are to prevent false failures in
# xt/author/93_version.t.
Readonly::Scalar my $VERSION_MODULE => q<version>;
Readonly::Scalar my $VERSION_VARIABLE => $DOLLAR . q<VERSION>;

Readonly::Scalar my $DESC =>
    $DOLLAR . q<VERSION value should not come from outside module>;
Readonly::Scalar my $EXPL =>
    q<If the version comes from outside the module, you can get everything from unexpected version changes to denial-of-service attacks.>;

#-----------------------------------------------------------------------------

sub supported_parameters { return (
        {
            name        => 'forbid_use_version',
            description =>
            qq<Make "use version; our ${DOLLAR}VERSION = qv('1.2.3');" a violation of this policy.>,
            default_string  => $FALSE,
            behavior        => 'boolean',
        },
    );
}
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance )     }
sub applies_to           { return 'PPI::Token::Symbol'       }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Any variable other than $VERSION is ignored.
    return if $VERSION_VARIABLE ne $elem->content();

    # We are only interested in assignments to $VERSION, but it might be a
    # list assignment, so if we do not find an assignment, we move up the
    # parse tree. If we hit a statement (or no parent at all) we do not
    # understand the code to be an assignment statement, and we simply return.
    my $operator;
    return if
            not $operator = get_next_element_in_same_simple_statement( $elem )
        or  $EQUAL ne $operator;

    # Find the simple statement we are in. If we can not find it, abandon the
    # attempt to analyze the code.
    my $statement = $self->_get_simple_statement( $elem )
        or return;

    # Check all symbols in the statement for violation.
    my $exception;
    return $exception if
        $exception =
            $self->_validate_fully_qualified_symbols($elem, $statement, $doc);

    # At this point we have found no data that is explicitly from outside the
    # file.  If the author wants to use a $VERSION from another module, _and_
    # wants MM->parse_version to understand it, the other module must be used
    # on the same line. So we assume no violation unless this has been done.
    my $module = get_previous_module_used_on_same_line( $elem )
        or return;

    # We make an exception for 'use version' unless configured otherwise; so
    # let it be written, so let it be done.
    return if $module eq $VERSION_MODULE and not $self->{_forbid_use_version};

    # We assume nefarious intent if we have any other module used on the same
    # line as the $VERSION assignment.
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

# Return the simple statement that contains our element. The classification
# done by is_ppi_simple_statement is not quite good enough in this case -- if
# our parent is a PPI::Structure::List, we want to keep looking.

sub _get_simple_statement {
    my ( $self, $elem ) = @_;

    my $statement = $elem;

    while ( $statement) {
        my $parent;
        if ( is_ppi_simple_statement( $statement ) ) {
            return $statement if
                    not $parent = $statement->parent()
                or  not $parent->isa( 'PPI::Structure::List' );
            $statement = $parent;
        } else {
            $statement = $statement->parent();
        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_fully_qualified_symbols {
    my ( $self, $elem, $statement, $doc ) = @_;

    # Find the package(s) in this file.
    my %local_package =
        map { $_->schild( 1 ) => 1 }
            @{ $doc->find( 'PPI::Statement::Package' ) || [] };
    $local_package{main} = 1;   # For completeness.

    # Check all symbols in the statement for violation.
    foreach my $symbol (
        @{ $statement->find( 'PPI::Token::Symbol' ) || [] }
    ) {
        if ( $symbol->canonical() =~ m< \A [@\$%&] ([\w:]*) :: >smx ) {
            $local_package{ $1 }
                or return $self->violation( $DESC, $EXPL, $elem );
        }
    }

    # Check all interpolatable strings in the statement for violation.
    # TODO this does not correctly handle "@{[some_expression()]}".
    foreach my $string (
        @{
                $statement->find(
                    sub {
                        return
                                $_[1]->isa('PPI::Token::Quote::Double')
                            ||  $_[1]->isa('PPI::Token::Quote::Interpolate');
                    }
                )
            or  []
        }
    ) {
        my $unquoted = $string->string();
        while (
            $unquoted =~
                m<
                    (?: \A | [^\\] )
                    (?: \\{2} )*
                    [@\$]
                    [{]?
                    ([\w:]*)
                    ::
                >gsmx
        ) {
            next if $local_package{ $1 };

            return $self->violation( $DESC, $EXPL, $elem );
        }
    }

    # Check all words in the statement for violation.
    foreach my $symbol ( @{ $statement->find( 'PPI::Token::Word' ) || [] } ) {
        if ( $symbol->content() =~ m/ \A ([\w:]*) :: /smx ) {
            return $self->violation( $DESC, $EXPL, $elem )
                if not $local_package{ $1 };
        }
    }

    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitComplexVersion - Prohibit version values from outside the module.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

One tempting way to keep a group of related modules at the same version number
is to have all of them import the version number from a designated module. For
example, module C<Foo::Master> could be the version master for the C<Foo>
package, and all other modules could use its C<$VERSION> by

    use Foo::Master; our $VERSION = $Foo::Master::VERSION;

This turns out not to be a good idea, because all sorts of unintended things
can happen - anything from unintended version number changes to
denial-of-service attacks (since C<Foo::Master> is executed by the 'use').

This policy examines statements that assign to C<$VERSION>, and declares a
violation under two circumstances: first, if that statement uses a
fully-qualified symbol that did not originate in a package declared in the
file; second if there is a C<use> statement on the same line that makes the
assignment.

By default, an exception is made for C<use version;> because of its
recommendation by Perl Best Practices. See the C<forbid_use_version>
configuration variable if you do not want an exception made for C<use
version;>.


=head1 CONFIGURATION

The construction

    use version; our $VERSION = qv('1.2.3');

is exempt from this policy by default, because it is recommended by Perl Best
Practices. Should you wish to identify C<use version;> as a violation, add the
following to your perlcriticrc file:

    [ValuesAndExpressions::ProhibitComplexVersion]
    forbid_use_version = 1


=head1 CAVEATS

This code assumes that the hallmark of a violation is a 'use' on the same line
as the C<$VERSION> assignment, because that is the way to have it seen by
L<ExtUtils::MakeMaker|ExtUtils::MakeMaker>->parse_version(). Other ways to get
a version value from outside the module can be imagined, and this policy is
currently oblivious to them.


=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>


=head1 COPYRIGHT

Copyright (c) 2009-2011 Tom Wyant.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
