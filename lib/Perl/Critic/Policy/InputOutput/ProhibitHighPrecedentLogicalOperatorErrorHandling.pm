package Perl::Critic::Policy::InputOutput::ProhibitHighPrecedentLogicalOperatorErrorHandling;

use 5.006;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :ppi :booleans };

use base 'Perl::Critic::Policy';

our $VERSION = '1.133_01';

Readonly::Scalar my $DESC  => q{Use of "||" for error handling in open statement};
Readonly::Scalar my $EXPL  => q{Use "or" instead of "||", which shortcuts for error handling};

sub supported_parameters { return () }
sub default_severity { return $SEVERITY_HIGH }
sub default_themes   { return qw< bugs core > }

sub applies_to {
    return qw<
        PPI::Token::Word
    >;
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    return if $elem->content() ne 'open';

    # We discovered a parenthesis, so we are ok
    return if $self->_uses_parenthesis($elem);

    if ($self->_is_high_precedence_logical_operator($elem->snext_sibling())) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return; # ok!
}

sub _uses_parenthesis {
    my ( $self, $elem ) = @_;

    if ($elem->snext_sibling()->content() =~ m/^[\s]*[(]/xism) {
        return $TRUE;
    } else {
        return $FALSE;
    }
}

sub _is_high_precedence_logical_operator {
    my ( $self, $sibling ) = @_;

    if ($sibling) {
        if ($sibling->class eq 'PPI::Token::Operator') {
            if ($sibling->content eq q{||}) {
                return $TRUE;
            }
        }
        return $self->_is_high_precedence_logical_operator($sibling->snext_sibling());
    }

    return $FALSE;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitHighPrecedentLogicalOperatorErrorHandling - prohibits logical error handling in open statements

=head1 VERSION

This documentation describes version 0.01

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic> distribution.

=head1 DESCRIPTION

This policy addresses an anti-pattern and possible bug. If you use 3-argument C<open> combinted with the high precedence logical or operator C<||> for error handling.

If the file parameter is pointing to a non-existant file, the use of a high precedence logical operator C<||>, does not short-cut as expected. This implies that the bug only is present if the file does not exist. If the file exist, but cannot be opened the error handling is not working as expected.

    open my $fh, '<', $file
            || die "Can't open '$file': $!"; # not okay

    open(my $fh, '<', $file)
        || die "Can't open '$file': $!"; # okay

    open my $fh, '<', $file
        or die "Can't open '$file': $!"; # okay

The remedy is to use parentheses for C<open> or the lower precendedence logical operator C<or>.

Alternatively L<autodie|https://metacpan.org/pod/autodie> can be used,

=head1 CONFIGURATION

This policy is not configurable at this time.

=head1 DEPENDENCIES AND REQUIREMENTS

This distribution requires:

=over

=item * Perl 5.6.0 syntactially for the actual implementation

=item * L<Carp|https://metacpan.org/pod/Carp>, in core since Perl 5.

=item * L<Readonly|https://metacpan.org/pod/Readonly>

=item * L<Perl::Critic::Policy|https://metacpan.org/pod/Perl::Critic::Policy>

=item * L<Perl::Critic::Utils|https://metacpan.org/pod/Perl::Critic::Utils>

=back

Please see the listing in the file: F<cpanfile>, included with the distribution for a complete listing and description for configuration, test and development.

=head1 SEE ALSO

=over

=item * L<Blog post on Perl Hacks: A Subtle Bug|https://perlhacks.com/2019/01/a-subtle-bug/> by Dave Cross L<@davorg|https://twitter.com/davorg>

=item * L<Same Blog post on Medium: A Subtle Bug|https://culturedperl.com/a-subtle-bug-c9982f681cb8> by Dave Cross L<@davorg|https://twitter.com/davorg>

=item * L<Perl::Critic|https://metacpan.org/pod/Perl::Critic>

=back

=head1 MOTIVATION

The motivation for this Perl::Critic policy came from a L<Blog post on Perl Hacks: A Subtle Bug|https://perlhacks.com/2019/01/a-subtle-bug/> by Dave Cross L<@davorg|https://twitter.com/davorg>

In the blog post Dave demonstrates a very subtle bug, which I think many Perl programmers have been or could be bitten by. But instead of searching through the code as a one time activity, I think this would do better as a Perl::Critic policy, so if the bug a some point was reintroduced in the code base it would be caught by Perl::Critic, if you use Perl::Critic that is - and you do use Perl::Critic right?

=head1 AUTHOR

=over

=item * jonasbn <jonasbn@cpan.org>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * L<Dave Cross (@davord)|https://twitter.com/jmaslak> / L<DAVECROSS|https://metacpan.org/author/DAVECROSS> for the blog post sparking the idea for this policy, see link to blog post under L</MOTIVATION> or L</REFERENCES>

=back

=head1 COPYRIGHT

Perl::Critic::Policy::InputOutput::ProhibitHighPrecedentLogicalOperatorErrorHandling is (C) by jonasbn 2019

Perl::Critic::Policy::InputOutput::ProhibitHighPrecedentLogicalOperatorErrorHandling is released under the Artistic License 2.0

Please see the LICENSE file included with the distribution of this module

=cut
