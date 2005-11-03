package Perl::Critic::Policy::Miscellanea::RequireRcsKeywords;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use List::MoreUtils qw(none);
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $expl = [ 441 ];

#---------------------------------------------------------------------------

sub new {
    my ($class, %config) = @_;
    my $self = bless {}, $class;
    $self->{_keywords} = [ qw(Revision Source Date) ];
    $self->{_tested} = 0;

    #Set configuration, if defined.
    if ( defined $config{keywords} ) {
	$self->{_keywords} = [ split m{ \s+ }mx, $config{keywords} ];
    }

    return $self;
}


sub violates {
    my ( $self, $elem, $doc ) = @_;
    return if $self->{_tested};  #Only do this once!
    my @viols = ();

    my $nodes = $doc->find( \&_wanted );
    for my $keyword ( @{ $self->{_keywords} } ) {
	if ( (!$nodes) || none { $_ =~ m{ \$$keyword.*\$ }mx } @{$nodes} ) {
	  my $desc = qq{RCS keyword '\$$keyword\$' not found};
	  push @viols, Perl::Critic::Violation->new( $desc, $expl, [0,0] );
	}
    }

    $self->{_tested} = 1;
    return @viols;
}

sub _wanted {
  my ($doc, $elem) = @_;
  return    $elem->isa('PPI::Token::Comment')
         || $elem->isa('PPI::Token::Quote::Single')
         || $elem->isa('PPI::Token::Quote::Literal');
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Miscellanea::RequireRcsKeywords

=head1 DESCRIPTION

Every code file, no matter how small, should be kept in a
source-control repository.  Adding the magical RCS keywords to your
file helps the reader know where the file comes from, in case he or
she needs to modify it.  This Policy scans your file for comments that
look like this:

  # $Revision: 2.14 $
  # $Source: /myproject/lib/foo.pm $

A common practice is to use the C<$Revision$> keyword to automatically
define the C<$VERSION> variable like this:

  our ($VERSION) = '$Revision: 1.01 $' =~ m{ \$Revision: \s+ (\S+) }x;

=head1 CONSTRUCTOR

By default, this policy only requires the C<$Revision$>, C<$Source$>,
and C<$Date$> keywords.  To specify alternate keywords, pass them into
the constructor as a key-value pair, where the key is 'keywords' and
the value is a whitespace delimited series of keywords (without the
dollar-signs).  Or specify them in your F<.perlcriticrc> file like
this:

  [Miscellanea::RequireRcsKeywords]
  keywords = Revision Source Date Author Id 

See the doumentation on RCS for a list of supported keywords.  Many
source control systems are descended from RCS, so the keywords
supported by CVS and Subversion are probably the same.

=head1 NOTES 

Not every system has source-control tools, so this policy is not
loaded by default.  To have it loaded into Perl::Critic, put this in
your F<.perlcriticrc> file:

  [Miscellanea::RequireRcsKeywords]

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
