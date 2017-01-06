package Perl::Critic::Policy::TestingAndDebugging::ProhibitProlongedStrictureOverride;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Don't turn off strict for large blocks of code};
Readonly::Scalar my $EXPL => [ 433 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'statements',
            description     => 'The maximum number of statements in a no strict block.',
            default_string  => '3',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_HIGH            }
sub default_themes   { return qw( core pbp bugs certrec )       }
sub applies_to       { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    return if $elem->type ne 'no';
    return if $elem->module ne 'strict';

    my $sib = $elem->snext_sibling;
    my $nstatements = 0;
    while ($nstatements++ <= $self->{_statements}) {
        return if !$sib;
        return if $sib->isa('PPI::Statement::Include') &&
            $sib->type eq 'use' &&
            $sib->module eq 'strict';
       $sib = $sib->snext_sibling;
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitProlongedStrictureOverride - Don't turn off strict for large blocks of code.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Every agrees that C<use strict> is the first step to writing
maintainable code in Perl.  However, sometimes C<strict> is a little
too strict.  In those cases, you can turn it off briefly with a C<no
strict> directive.

This policy checks that C<no strict> is only in effect for a small
number of statements.


=head1 CONFIGURATION

The default number of statements allowed per C<no strict> is three.
To override this number, put the following in your F<.perlcriticrc>:

    [TestingAndDebugging::ProhibitProlongedStrictureOverride]
    statements = 5


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
