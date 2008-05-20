##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage;

use strict;
use warnings;
use Readonly;

use File::Spec;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.083_005';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Package declaration must match filename};
Readonly::Scalar my $EXPL => q{Correct the filename or package statement};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    my $filename = $doc->filename;
    return if !$filename;

    # 'lib/Foo/Bar.pm' -> ('lib', 'Foo', 'Bar')
    my @path = File::Spec->splitpath($filename);
    $filename = $path[2];
    $filename =~ s/[.]\w+\z//mx;
    my @path_parts = grep {$_ ne q{}} File::Spec->splitdir($path[1]), $filename;

    # 'Foo::Bar' -> ('Foo', 'Bar')
    my $pkg_node = $doc->find_first('PPI::Statement::Package');
    return if !$pkg_node;
    my $pkg = $pkg_node->namespace;
    return if $pkg eq 'main';
    my @pkg_parts = split m/(?:\'|::)/mx, $pkg;

    # To succeed, at least the lastmost must match
    # Beyond that, the search terminates if a dirname is an impossible package name
    my $matched_any;
    while (@pkg_parts && @path_parts) {
        my $pkg_part = pop @pkg_parts;
        my $path_part = pop @path_parts;
        if ($pkg_part eq $path_part) {
            $matched_any = 1;
            next;
        }

        # if it's a path that's not a possible package (like 'Foo-Bar-1.00'), that's OK
        last if ($path_part =~ m/\W/mx);

        # Mismatched name
        return $self->violation( $DESC, $EXPL, $pkg_node );
    }

    return if $matched_any;
    return $self->violation( $DESC, $EXPL, $pkg_node );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage - Package declaration must match filename.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic> distribution.


=head1 DESCRIPTION

The package declaration should always match the name of the file that
contains it.  For example, C<package Foo::Bar;> should be in a file
called C<Bar.pm>.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

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
