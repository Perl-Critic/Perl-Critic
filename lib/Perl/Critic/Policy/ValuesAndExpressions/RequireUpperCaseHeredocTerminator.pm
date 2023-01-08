package Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator 1.150;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent 'Perl::Critic::Policy';

#-----------------------------------------------------------------------------

Readonly::Scalar my $HEREDOC_RX => qr{ \A << ~? \s* (["']?) [[:upper:]_] [[:upper:]\d_]* \1 \z }xms;
Readonly::Scalar my $DESC       => q{Heredoc terminator not alphanumeric and upper-case};
Readonly::Scalar my $EXPL       => [ 64 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw(core pbp cosmetic) }
sub applies_to           { return 'PPI::Token::HereDoc' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem !~ $HEREDOC_RX ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator - Write C< <<'THE_END'; > instead of C< <<'theEnd'; >.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

For legibility, HEREDOC terminators should be all UPPER CASE letters
(and numbers), without any whitespace.  Conway also recommends using a
standard prefix like "END_" but this policy doesn't enforce that.

  print <<'the End';  #not ok
  Hello World
  the End

  print <<'THE_END';  #ok
  Hello World
  THE_END


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator|Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
