package Perl::Critic::Policy::Modules::RequireBarewordIncludes;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Use a bareword instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                        }
sub default_severity     { return $SEVERITY_HIGHEST         }
sub default_themes       { return qw(core portability)      }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $child = $elem->schild(1);
    return if !$child;

    if ( $child->isa('PPI::Token::Quote') ) {
        my $type = $elem->type;
        my $desc = qq{"$type" statement with library name as string};
        return $self->violation( $desc, $EXPL, $elem );
    }
    return; #ok!
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireBarewordIncludes - Write C<require Module> instead of C<require 'Module.pm'>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

When including another module (or library) via the C<require> or
C<use> statements, it is best to identify the module (or library)
using a bareword rather than an explicit path.  This is because paths
are usually not portable from one machine to another.  Also, Perl
automatically assumes that the filename ends in '.pm' when the library
is expressed as a bareword.  So as a side-effect, this Policy
encourages people to write '*.pm' modules instead of the old-school
'*.pl' libraries.

    use 'My/Perl/Module.pm';  #not ok
    use My::Perl::Module;     #ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

This Policy is a replacement for C<ProhibitRequireStatements>, which
completely banned the use of C<require> for the sake of eliminating
the old '*.pl' libraries from Perl4.  Upon further consideration, I
realized that C<require> is quite useful and necessary to enable
run-time loading.  Thus, C<RequireBarewordIncludes> does allow you to
use C<require>, but still encourages you to write '*.pm' modules.

Sometimes, you may want to load modules at run-time, but you don't
know at design-time exactly which module you will need to load
(L<Perl::Critic|Perl::Critic> is an example of this).  In that case,
just attach the C<'## no critic'> annotation like so:

    require $module_name;  ## no critic


=head1 CREDITS

Chris Dolan <cdolan@cpan.org> was instrumental in identifying the
correct motivation for and behavior of this Policy.  Thanks Chris.


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
