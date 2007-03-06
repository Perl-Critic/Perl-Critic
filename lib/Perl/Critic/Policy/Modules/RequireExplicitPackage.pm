##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Modules::RequireExplicitPackage;

use strict;
use warnings;
use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

my $expl = q{Violates encapsulation};
my $desc = q{Code not contained in explicit package};

#-----------------------------------------------------------------------------

sub supported_parameters { return qw( exempt_scripts ) }
sub default_severity  { return $SEVERITY_HIGH       }
sub default_themes    { return qw( core bugs )      }
sub applies_to        { return 'PPI::Document'      }

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    #Set config, if defined
    $self->{_exempt_scripts} =
      defined $args{exempt_scripts} ? $args{exempt_scripts} : 1;

    return $self;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # You can configure this policy to exclude scripts
    return if $self->{_exempt_scripts} && is_script($doc);

    # Find the first 'package' statement
    my $package_stmnt = $doc->find_first( 'PPI::Statement::Package' );
    my $package_line = $package_stmnt ? $package_stmnt->location()->[0] : undef;

    # Find all statements that aren't 'package' statements
    my $stmnts_ref = $doc->find( 'PPI::Statement' );
    return if !$stmnts_ref;
    my @non_packages = grep { !$_->isa('PPI::Statement::Package') } @{$stmnts_ref};
    return if !@non_packages;

    # If the 'package' statement is not defined, or the other
    # statements appear before the 'package', then it violates.

    my @viols = ();
    for my $stmnt ( @non_packages ) {
        # work around PPI bug: C<({})> results in a statement without a
        # location.
        my $stmnt_line = $stmnt->location() ? $stmnt->location()->[0] : -1;
        if ( (! defined $package_line) || ($stmnt_line < $package_line) ) {
            push @viols, $self->violation( $desc, $expl, $stmnt );
        }
    }

    return @viols;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireExplicitPackage

=head1 DESCRIPTION

In general, the first statement of any Perl module or
library should be a C<package> statement.  Otherwise, all the code
that comes before the C<package> statement is getting executed in the
caller's package, and you have no idea who that is.  Good
encapsulation and common decency require your module to keep its
innards to itself.

As for programs, most people understand that the default package is C<main>, so
this Policy doesn't apply to files that begin with a perl shebang.  If you want
to require an explicit C<package> declaration in all files, including programs,
then add the following to your F<.perlcriticrc> file

  [Modules::RequireExplicitPackage]
  exempt_scripts = 0

There are some valid reasons for not having a C<package> statement at
all.  But make sure you understand them before assuming that you
should do it too.

=head1 IMPORTANT CHANGES

This policy was formerly called C<ProhibitUnpackagedCode> which sounded
a bit odd.  If you get lots of "Cannot load policy module" errors,
then you probably need to change C<ProhibitUnpackagedCode> to
C<RequireExplicitPackage> in your F<.perlcriticrc> file.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
