##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitPerl4PackageNames;

use strict;
use warnings;
use Perl::Critic::Utils qw{ :characters :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

my $desc = q{Use double colon (::) to separate package name components instead of single quotes (').};

#-----------------------------------------------------------------------------

sub supported_parameters { return() }
sub default_severity     { return $SEVERITY_LOW                              }
sub default_themes       { return qw(core maintenance)                       }
sub applies_to           { return qw ( PPI::Token::Word PPI::Token::Symbol ) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    my $content = $elem->content();

    if ( (index $content, $QUOTE) < 0 ) {
                return;
    }

    if ( $elem->isa('PPI::Token::Word') && is_hash_key($elem) ) {
        return;
    }

    return
        $self->violation(
            $desc,
            qq{"$content" uses the obsolete single quote package separator."},
            $elem
        );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitPerl4PackageNames

=head1 DESCRIPTION

Since Perl 5, there are very few reasons to declare C<local>
variables.  The most common exceptions are Perl's magical global
variables.  If you do need to modify one of those global variables,
you should localize it first.  You should also use the L<English>
module to give those variables more meaningful names.

  local $foo;   #not ok
  my $foo;      #ok

  use English qw(-no_match_vars);
  local $INPUT_RECORD_SEPARATOR    #ok
  local $RS                        #ok
  local $/;                        #not ok

=head1 NOTES

If an external module uses package variables as its interface, then
using C<local> is actually a pretty sensible thing to do.  So
Perl::Critic will not complain if you C<local>-ize variables with a
fully qualified name such as C<$Some::Package::foo>.  However, if
you're in a position to dictate the module's interface, I strongly
suggest using accessor methods instead.

=head1 SEE ALSO

L<Perl::Critic::Policy::Variables::ProhibitPunctuationVars>

=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
