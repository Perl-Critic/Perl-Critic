package Perl::Critic::Policy::Modules::RequireBarewordIncludes;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $expl = q{Use a bareword instead};

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Statement::Include') || return;
    my $child = $elem->schild(1) || return;

    if( $child->isa('PPI::Token::Quote') ) {
	my $type = $elem->type();
	my $desc = qq{'$type' statement with library name as string};
	return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return; #ok!
}


1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireBarewordIncludes

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

=head1 NOTES

This Policy is a replacement for 'ProhibitRequireStatements', which
completely banned the use of C<require> for the sake of eliminating
the old '*.pl' libraries from Perl4.  Upon further consideration, I
realized that C<require> is quite useful and necessary to enable
run-time loading.  Thus, 'RequireBarewordIncludes' does allow you to
use C<require>, but still encourages you to write '*.pm' modules.

Sometimes, you may want to load modules at run-time, but you don't
know at design-time exactly which module you will need to load
(L<Perl::Critic> is an example of this).  In that case, just attach
the C<'## no critic'> pseudo-pragma like so:

  require $module_name;  ## no critic


=head1 CREDITS

Chris Dolan <cdolan@cpan.org> was instrumental in identifying the
correct motivation for and behavior of this Policy.  Thanks Chris.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
