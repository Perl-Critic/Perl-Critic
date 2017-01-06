package Perl::Critic::Policy::ControlStructures::ProhibitLabelsWithSpecialBlockNames;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

Readonly::Hash my %SPECIAL_BLOCK_NAMES =>
    hashify( qw< BEGIN END INIT CHECK UNITCHECK > );

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<Special block name used as label.>;
Readonly::Scalar my $EXPL =>
    q<Use a label that cannot be confused with BEGIN, END, CHECK, INIT, or UNITCHECK blocks.>;

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                      }
sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw< core bugs >         }
sub applies_to           { return qw< PPI::Token::Label > }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    # Does the function call have enough arguments?
    my $label = $elem->content();
    $label =~ s/ \s* : \z //xms;
    return if not $SPECIAL_BLOCK_NAMES{ $label };

    return $self->violation( $DESC, $EXPL, $elem );
}


1;

#-----------------------------------------------------------------------------

__END__

=for stopwords Lauen O'Regan

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitLabelsWithSpecialBlockNames - Don't use labels that are the same as the special block names.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

When using one of the special Perl blocks C<BEGIN>, C<END>, C<CHECK>,
C<INIT>, and C<UNITCHECK>, it is easy to mistakenly add a colon to the
end of the block name.  E.g.:

    # a BEGIN block that gets executed at compile time.
    BEGIN { <...code...> }

    # an ordinary labeled block that gets executed at run time.
    BEGIN: { <...code...> }

The labels "BEGIN:", "END:", etc. are probably errors.  This policy
prohibits the special Perl block names from being used as labels.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

The Perl Buzz article on this issue at
L<http://perlbuzz.com/2008/05/colons-invalidate-your-begin-and-end-blocks.html>.


=head1 ACKNOWLEDGMENT

Randy Lauen for identifying the problem.


=head1 AUTHOR

Mike O'Regan


=head1 COPYRIGHT

Copyright (c) 2008-2011 Mike O'Regan.  All rights reserved.

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
