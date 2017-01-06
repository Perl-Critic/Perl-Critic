package Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $HEREDOC_RX => qr/ \A << \s* ["'] .* ['"] \z /xms;
Readonly::Scalar my $DESC       => q{Heredoc terminator must be quoted};
Readonly::Scalar my $EXPL       => [ 64 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_MEDIUM         }
sub default_themes       { return qw(core pbp maintenance) }
sub applies_to           { return 'PPI::Token::HereDoc'    }

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

Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator - Write C< print <<'THE_END' > or C< print <<"THE_END" >.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Putting single or double-quotes around your HEREDOC terminator make it
obvious to the reader whether the content is going to be interpolated
or not.

    print <<END_MESSAGE;    #not ok
    Hello World
    END_MESSAGE

    print <<'END_MESSAGE';  #ok
    Hello World
    END_MESSAGE

    print <<"END_MESSAGE";  #ok
    $greeting
    END_MESSAGE


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator|Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator>

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
