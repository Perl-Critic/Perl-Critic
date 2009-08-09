##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw< :booleans :characters :severities >;
use base 'Perl::Critic::Policy';

#-----------------------------------------------------------------------------

our $VERSION = '1.103';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<String *may* require interpolation>;
Readonly::Scalar my $EXPL => [ 51 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'rcs_keywords',
            description     => 'RCS keywords to ignore in potential interpolation.',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity     { return $SEVERITY_LOWEST      }
sub default_themes       { return qw(core pbp cosmetic) }

sub applies_to           {
    return qw< PPI::Token::Quote::Single PPI::Token::Quote::Literal >;
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    my $rcs_keywords = $self->{_rcs_keywords};
    my @rcs_keywords = keys %{$rcs_keywords};

    if (@rcs_keywords) {
        my $rcs_regexes = [ map { qr/ \$ $_ [^\n\$]* \$ /xms } @rcs_keywords ];
        $self->{_rcs_regexes} = $rcs_regexes;
    }

    if ( not eval { require Email::Address; 1 } ) {
        no warnings 'redefine';
        *_looks_like_email_address = sub {};
    }

    return $TRUE;
}

sub violates {
    my ( $self, $elem, undef ) = @_;

    # The string() method strips off the quotes
    my $string = $elem->string();
    return if not _needs_interpolation($string);
    return if _looks_like_email_address($string);
    return if _looks_like_use_overload($elem);
    return if _looks_like_use_vars($elem);

    my $rcs_regexes = $self->{_rcs_regexes};
    return if $rcs_regexes and _contains_rcs_variable($string, $rcs_regexes);

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _needs_interpolation {
    my ($string) = @_;

    return
            $string =~ m< [\$\@] \S+ >xms              # Contains a $ or @
        ||  $string =~ m<                              # Contains metachars
                (?: \A | [^\\] )
                (?: \\{2} )*
                \\ [tnrfae0xcNLuLUEQ]
            >xms;
}

#-----------------------------------------------------------------------------

sub _looks_like_email_address {
    my ($string) = @_;

    return if $string =~ m< \W \@ >xms;

    return $string =~ $Email::Address::addr_spec;
}

#-----------------------------------------------------------------------------

sub _contains_rcs_variable {
    my ($string, $rcs_regexes) = @_;

    foreach my $regex ( @{$rcs_regexes} ) {
        return $TRUE if $string =~ m/$regex/xms;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _looks_like_use_overload {
    my ($elem) = @_;

    my $string = $elem->string();

    $string eq q<@{}>           ## no critic (RequireInterpolationOfMetachars)
        or $string eq q<${}>    ## no critic (RequireInterpolationOfMetachars)
        or return;

    my $statement = $elem;
    while ( not $statement->isa('PPI::Statement::Include') ) {
        $statement = $statement->parent() or return;
    }

    return if $statement->type() ne q<use>;
    return $statement->module() eq q<overload>;
}

#-----------------------------------------------------------------------------

sub _looks_like_use_vars {
    my ($elem) = @_;

    my $string = $elem->string();

    my $statement = $elem;
    while ( not $statement->isa('PPI::Statement::Include') ) {
        $statement = $statement->parent() or return;
    }

    return if $statement->type() ne q<use>;
    return $statement->module() eq q<vars>;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords RCS

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars - Warns that you might have used single quotes when you really wanted double-quotes.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

This policy warns you if you use single-quotes or C<q//> with a string
that has unescaped metacharacters that may need interpolation. Its
hard to know for sure if a string really should be interpolated
without looking into the symbol table.  This policy just makes an
educated guess by looking for metacharacters and sigils which usually
indicate that the string should be interpolated.


=head2 Exceptions

=over

=item *

C<${}> and C<@{}> in a C<use overload>,

    use overload '${}' => \&deref,     # ok
                 '@{}' => \&arrayize;  # ok

=item *

Variable names to C<use vars>.

    use vars '$x';          # ok
    use vars ('$y', '$z');  # ok
    use vars qw< $a $b >;   # ok


=item *

Email addresses, if you have L<Email::Address> installed.


=back


=head1 CONFIGURATION

The C<rcs_keywords> option allows you to stop this policy from complaining
about things that look like RCS variables, for example, in deriving values for
C<$VERSION> variables.

For example, if you've got code like

    our ($VERSION) = (q<$Revision$> =~ m/(\d+)/mx);

You can specify

    [ValuesAndExpressions::RequireInterpolationOfMetachars]
    rcs_keywords = Revision

in your F<.perlcriticrc> to provide an exemption.


=head1 NOTES

Perl's own C<warnings> pragma also warns you about this.


=head1 TODO

Handle email addresses.


=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals|Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

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
