package Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr;

use 5.006001;
use strict;
use warnings;
use Readonly;
use version 0.77 ();

use Perl::Critic::Utils qw{ :severities :classification :language };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Lvalue form of "substr" used};
Readonly::Scalar my $EXPL => [ 165 ];

Readonly::Scalar my $ASSIGNMENT_PRECEDENCE => precedence_of( q{=} );
Readonly::Scalar my $MINIMUM_PERL_VERSION => version->new( 5.005 );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance pbp ) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    # perl5005delta says that is when the fourth argument to substr()
    # was introduced, so ... (RT #59112)
    my $version = $document->highest_explicit_perl_version();
    return ! $version || $version >= $MINIMUM_PERL_VERSION;
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem->content() ne 'substr';
    return if ! is_function_call($elem);

    my $sib = $elem;
    while ($sib = $sib->snext_sibling()) {
        if ( $sib->isa( 'PPI::Token::Operator' ) ) {
            my $rslt = $ASSIGNMENT_PRECEDENCE <=> precedence_of(
                $sib->content() );
            return if $rslt < 0;
            return $self->violation( $DESC, $EXPL, $sib ) if $rslt == 0;
        }
    }
    return; #ok!
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords perlfunc substr 4th

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr - Use 4-argument C<substr> instead of writing C<substr($foo, 2, 6) = $bar>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway discourages the use of C<substr()> as an lvalue, instead
recommending that the 4-argument version of C<substr()> be used
instead.

    substr($something, 1, 2) = $newvalue;     # not ok
    substr($something, 1, 2, $newvalue);      # ok

The four-argument form of C<substr()> was introduced in Perl 5.005.
This policy does not report violations on code which explicitly
specifies an earlier version of Perl (e.g. C<use 5.004;>).

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<"substr" in perlfunc|perlfunc/substr> (or C<perldoc -f substr>).

L<"4th argument to substr" in perl5005delta|perl5005delta/4th argument to substr>


=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Graham TerMarsch.  All rights reserved.

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
