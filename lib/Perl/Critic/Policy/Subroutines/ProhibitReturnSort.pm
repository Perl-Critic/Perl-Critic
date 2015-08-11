package Perl::Critic::Policy::Subroutines::ProhibitReturnSort;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"return" statement followed by "sort"};
Readonly::Scalar my $EXPL => q{Behavior is undefined if called in scalar context};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_HIGHEST  }
sub default_themes       { return qw(core bugs certrule )      }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem->content() ne 'return';
    return if is_hash_key($elem);

    my $sib = $elem->snext_sibling();
    return if !$sib;
    return if !$sib->isa('PPI::Token::Word');
    return if $sib->content() ne 'sort';

    # Must be 'return sort'
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords Ulrich Wisser

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitReturnSort - Behavior of C<sort> is not defined if called in scalar context.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The behavior of the builtin C<sort> function is not defined if called
in scalar context.  So if you write a subroutine that directly
C<return>s the result of a C<sort> operation, then you code will
behave unpredictably if someone calls your subroutine in a scalar
context.  This Policy emits a violation if the C<return> keyword
is directly followed by the C<sort> function.  To safely return a
sorted list of values from a subroutine, you should assign the
sorted values to a temporary variable first.  For example:

   sub frobulate {

       return sort @list;  # not ok!

       @sorted_list = sort @list;
       return @sort        # ok
   }

=head1 KNOWN BUGS

This Policy is not sensitive to the C<wantarray> function.  So the
following code would generate a false violation:

   sub frobulate {

       if (wantarray) {
           return sort @list;
       }
       else{
           return join @list;
       }
   }

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 CREDITS

This Policy was suggested by Ulrich Wisser and the L<http://iis.se> team.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
