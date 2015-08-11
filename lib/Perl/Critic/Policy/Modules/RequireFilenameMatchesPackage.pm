package Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage;

use 5.006001;
use strict;
use warnings;
use Readonly;

use File::Spec;

use Perl::Critic::Utils qw{ :characters :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Package declaration must match filename};
Readonly::Scalar my $EXPL => q{Correct the filename or package statement};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    return $document->is_module();   # Must be a library or module.
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    # 'Foo::Bar' -> ('Foo', 'Bar')
    my $pkg_node = $doc->find_first('PPI::Statement::Package');
    return if not $pkg_node;
    my $pkg = $pkg_node->namespace();
    return if $pkg eq 'main';
    my @pkg_parts = split m/(?:\'|::)/xms, $pkg;


    # 'lib/Foo/Bar.pm' -> ('lib', 'Foo', 'Bar')
    my $filename = $pkg_node->logical_filename() || $doc->filename();
    return if not $filename;

    my @path = File::Spec->splitpath($filename);
    $filename = $path[2];
    $filename =~ s/ [.] \w+ \z //xms;
    my @path_parts =
        grep {$_ ne $EMPTY} File::Spec->splitdir($path[1]), $filename;


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
        last if ($path_part =~ m/\W/xms);

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

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The package declaration should always match the name of the file that contains
it.  For example, C<package Foo::Bar;> should be in a file called C<Bar.pm>.
This makes it easier for developers to figure out which file a symbol comes
from when they see it in your code.  For instance, when you see C<<
Foo::Bar->new() >>, you should be able to find the class definition for a
C<Foo::Bar> in a file called F<Bar.pm>

Therefore, this Policy requires the last component of the first package name
declared in the file to match the physical filename.  Or if C<#line>
directives are used, then it must match the logical filename defined by the
prevailing C<#line> directive at the point of the package declaration.  Here
are some examples:

  # Any of the following in file "Foo/Bar/Baz.pm":
  package Foo::Bar::Baz;     # ok
  package Baz;               # ok
  package Nuts;              # not ok (doesn't match physical filename)

  # using #line directives in file "Foo/Bar/Baz.pm":
  #line 1 Nuts.pm
  package Nuts;             # ok
  package Baz;              # not ok (contradicts #line directive)

If the file is not deemed to be a module, then this Policy does not apply.
Also, if the first package namespace found in the file is "main" then this
Policy does not apply.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

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
