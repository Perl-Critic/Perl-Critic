package Perl::Critic::Policy::ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Hash my %SPECIAL_LITERAL => map { '__' . $_ . '__' => 1 }
                                      qw( FILE LINE PACKAGE END DATA );
Readonly::Scalar my $DESC =>
    q{Heredoc terminator must not be a special literal};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_MEDIUM         }
sub default_themes       { return qw(core maintenance)     }
sub applies_to           { return 'PPI::Token::HereDoc'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # remove << and (optional) quotes from around terminator
    ( my $heredoc_terminator = $elem ) =~
        s{ \A << \s* (["']?) (.*) \1 \z }{$2}xms;

    if ( $SPECIAL_LITERAL{ $heredoc_terminator } ) {
        my $expl = qq{Used "$heredoc_terminator" as heredoc terminator};
        return $self->violation( $DESC, $expl, $elem );
    }

    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator - Don't write C< print <<'__END__' >.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Using one of Perl's special literals as a HEREDOC terminator could be
confusing to tools that try to parse perl.

    print <<'__END__';           #not ok
    Hello world
    __END__

    print <<'__END_OF_WORLD__';  #ok
    Goodbye world!
    __END_OF_WORLD__

The special literals that this policy prohibits are:

=over

=item __END__

=item __DATA__

=item __PACKAGE__

=item __FILE__

=item __LINE__

=back


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator|Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator>

L<Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator|Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator>


=head1 AUTHOR

Kyle Hasselbacher <kyle@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2009-2011 Kyle Hasselbacher.

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
