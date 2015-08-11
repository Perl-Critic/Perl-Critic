package Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion
                            :classification :characters };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Array my @ALLOW => qw( import AUTOLOAD DESTROY );
Readonly::Hash my %ALLOW => hashify( @ALLOW );
Readonly::Scalar my $DESC  => q{Subroutine name is a homonym for builtin %s %s};
Readonly::Scalar my $EXPL  => [177];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_HIGH        }
sub default_themes       { return qw( core bugs pbp certrule )   }
sub applies_to           { return 'PPI::Statement::Sub' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem->isa('PPI::Statement::Scheduled'); #e.g. BEGIN, INIT, END
    return if exists $ALLOW{ $elem->name() };

    my $homonym_type = $EMPTY;
    if ( is_perl_builtin( $elem ) ) {
        $homonym_type = 'function';
    }
    elsif ( is_perl_bareword( $elem ) ) {
        $homonym_type = 'keyword';
    }
    else {
        return;    #ok!
    }

    my $desc = sprintf $DESC, $homonym_type, $elem->name();
    return $self->violation($desc, $EXPL, $elem);
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords perlfunc perlsyn

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms - Don't declare your own C<open> function.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Common sense dictates that you shouldn't declare subroutines with the same
name as one of Perl's built-in functions or keywords.  See
L<perlfunc|perlfunc> for a list of built-in functions; see L<perlsyn|perlsyn>
for keywords.

  sub open {}    #not ok
  sub exit {}    #not ok
  sub print {}   #not ok
  sub foreach {} #not ok
  sub if {}      #not ok

  #You get the idea...

Exceptions are made for C<BEGIN>, C<END>, C<INIT> and C<CHECK> blocks,
as well as C<AUTOLOAD>, C<DESTROY>, and C<import> subroutines.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 CAVEATS

It is reasonable to declare an B<object> method with the same name as
a Perl built-in function, since they are easily distinguished from
each other.  However, at this time, Perl::Critic cannot tell whether a
subroutine is static or an object method.

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
