##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils::PPIRegexp;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;
use Carp qw(croak);

use PPI::Node;

use base 'Exporter';

our $VERSION = '1.104';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    parse_regexp
    get_match_string
    get_substitute_string
    get_modifiers
    get_delimiters
    ppiify
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub parse_regexp {
    my ($elem) = @_;

    eval { require Regexp::Parser; } or return;

    my $re = get_match_string($elem);
    return if !defined $re;

    # Are there any external regexp modifiers?  If so, embed the ones
    # that matter before parsing.
    my %modifiers = get_modifiers($elem);
    my $mods = join q{}, map {$modifiers{$_} ? $_ : q{}} qw(i m x s);
    if ($mods) {
       $re = "(?$mods:$re)";
    }

    my $parser = Regexp::Parser->new;
    # If we can't parse the regexp, don't return a parse tree
    {
        local $SIG{__WARN__} = sub {};  # blissful silence...
        return if ! $parser->regex($re);
    }

    return $parser;
}

#-----------------------------------------------------------------------------

sub get_match_string {
    my ($elem) = @_;
    return if !$elem->{sections};
    my $section = $elem->{sections}->[0];
    return if !$section;
    return substr $elem->content, $section->{position}, $section->{size};
}

#-----------------------------------------------------------------------------

sub get_substitute_string {
    my ($elem) = @_;
    return if !$elem->{sections};
    my $section = $elem->{sections}->[1];
    return if !$section;
    return substr $elem->content, $section->{position}, $section->{size};
}

#-----------------------------------------------------------------------------

sub get_modifiers {
    my ($elem) = @_;
    return if !$elem->{modifiers};
    return %{ $elem->{modifiers} };
}

#-----------------------------------------------------------------------------

sub get_delimiters {
    my ($elem) = @_;
    return if !$elem->{sections};
    my @delimiters;
    if (!$elem->{sections}->[0]->{type}) {
        # PPI v1.118 workaround: the delimiters were not recorded in some cases
        # hack: pull them out ourselves
        # limitation: this regexp fails on s{foo}<bar>
        my $operator = defined $elem->{operator} ? $elem->{operator} : q{};
        @delimiters = join q{}, $elem =~ m/\A $operator (.).*?(.) (?:[xmsocgie]*) \z/xms;
    } else {
        @delimiters = ($elem->{sections}->[0]->{type});
        if ($elem->{sections}->[1]) {
            push @delimiters, $elem->{sections}->[1]->{type} || $delimiters[0];
        }
    }
    return @delimiters;
}

#-----------------------------------------------------------------------------

{
    ## This nastiness is to auto-vivify PPI packages from Regexp::Parser classes

    # Track which ones are already created
    my %seen = ('Regexp::Parser::__object__' => 1);

    sub _get_ppi_package {
        my ($src_class, $re_node) = @_;
        (my $dest_class = $src_class) =~ s/\A Regexp::Parser::/Perl::Critic::PPIRegexp::/xms;
        if (!$seen{$src_class}) {
            $seen{$src_class} = 1;
            croak 'Regexp node which is not in the Regexp::Parser namespace'
              if $dest_class eq $src_class;
            my $src_isa_name = $src_class . '::ISA';
            my $dest_isa_name = $dest_class . '::ISA';
            my @isa;
            for my $isa (eval "\@$src_isa_name") { ## no critic (StringyEval)
                my $dest_isa = _get_ppi_package($isa, $re_node);
                push @isa, $dest_isa;
            }
            eval "\@$dest_isa_name = qw(@isa)"; ## no critic (Eval)
            croak $EVAL_ERROR if $EVAL_ERROR;
        }
        return $dest_class;
    }
}

Readonly::Scalar my $NO_DEPTH_USED  => -1;

sub ppiify {
    my ($re) = @_;
    return if !$re;

    # walk the Regexp::Parser tree, converting to PPI nodes as we go

    my $ppire = PPI::Node->new;
    my @stack = ($ppire);
    my $iter = $re->walker;
    my $last_depth = $NO_DEPTH_USED;
    while (my ($node, $depth) = $iter->()) {
        if ($last_depth > $depth) { # -> parent
            # walker() creates pseudo-closing nodes for reasons I don't understand
            while ($last_depth-- > $depth) {
                pop @stack;
            }
        } else {
            my $src_class = ref $node;
            my $ppipkg = _get_ppi_package($src_class, $node);
            my $ppinode = $ppipkg->new($node);
            if ($last_depth == $depth) { # -> sibling
                $stack[-1] = $ppinode;
            } else {            # -> child
                push @stack, $ppinode;
            }
            $stack[-2]->add_element($ppinode); ## no critic qw(MagicNumbers)
        }
        $last_depth = $depth;
    }
    return $ppire;
}

{
    package   ## no critic (ProhibitMultiplePackages, NamingConventions::Capitalization)  # hide from PAUSE
      Perl::Critic::PPIRegexp::__object__;
    use base 'PPI::Node';

    # Base wrapper class for PPI versions of Regexp::Parser classes

    # This is a hack because we call everything PPI::Node instances instead of
    # PPI::Token instances.  One downside is that PPI::Dumper doesn't work on
    # regexps.

    sub new {
        my ($class, $re_node) = @_;
        my $self = $class->SUPER::new();
        $self->{_re} = $re_node;
        return $self;
    }
    sub content {
        my ($self) = @_;
        return $self->{_re}->visual;
    }
    sub re {
        my ($self) = @_;
        return $self->{_re};
    }
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::PPIRegexp - Utility functions for dealing with PPI regexp tokens.


=head1 SYNOPSIS

   use Perl::Critic::Utils::PPIRegexp qw(:all);
   use PPI::Document;
   my $doc = PPI::Document->new(\'m/foo/');
   my $elem = $doc->find('PPI::Token::Regexp::Match')->[0];
   print get_match_string($elem);  # yields 'foo'


=head1 DESCRIPTION

As of PPI v1.1xx, the PPI regexp token classes
(L<PPI::Token::Regexp::Match|PPI::Token::Regexp::Match>,
L<PPI::Token::Regexp::Substitute|PPI::Token::Regexp::Substitute> and
L<PPI::Token::QuoteLike::Regexp|PPI::Token::QuoteLike::Regexp>) has a
very weak interface, so it is necessary to dig into internals to learn
anything useful.  This package contains subroutines to encapsulate
that excess intimacy.  If future versions of PPI gain better
accessors, this package will start using those.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over

=item C<parse_regexp( $token )>

Parse the regexp token with L<Regexp::Parser|Regexp::Parser>.  If that
module is not available or if there is a parse error, returns undef.
If a parse success, returns a Regexp::Parser instance that can be used
to walk the regexp object model.

CAVEAT: This method pays special attention to the C<x> modifier to the
regexp.  If present, we wrap the regexp string in C<(?x:...)> to
ensure a proper parse.  This does change the object model though.

Someday if PPI gets native Regexp support, this method may become
deprecated.


=item C<ppiify( $regexp )>

Given a L<Regexp::Parser|Regexp::Parser> instance (perhaps as returned
from C<parse_regexp>) convert it to a tree of L<PPI::Node|PPI::Node>
instances.  This is useful because PPI has a more familiar and
powerful programming model than the Regexp::Parser object tree.

Someday if PPI gets native Regexp support, this method may become a
no-op.


=item C<get_match_string( $token )>

Returns the match portion of the regexp or undef if the specified
token is not a regexp.  Examples:

    m/foo/;         # yields 'foo'
    s/foo/bar/;     # yields 'foo'
    / \A a \z /xms; # yields ' \\A a \\z '
    qr{baz};        # yields 'baz'


=item C<get_substitute_string( $token )>

Returns the substitution portion of a search-and-replace regexp or
undef if the specified token is not a valid regexp.  Examples:

    m/foo/;         # yields undef
    s/foo/bar/;     # yields 'bar'


=item C<get_modifiers( $token )>

Returns a hash containing booleans for the modifiers of the regexp, or
undef if the token is not a regexp.

    /foo/xms;  # yields (m => 1, s => 1, x => 1)
    s/foo//;   # yields ()
    qr/foo/i;  # yields (i => 1)


=item C<get_delimiters( $token )>

Returns one (or two for a substitution regexp) two-character strings
indicating the delimiters of the regexp, or an empty list if the token
is not a regular expression token.  For example:

    m/foo/;      # yields ('//')
    m#foo#;      # yields ('##')
    m<foo>;      # yields ('<>')
    s/foo/bar/;  # yields ('//', '//')
    s{foo}{bar}; # yields ('{}', '{}')
    s{foo}/bar/; # yields ('{}', '//')   valid, but yuck!
    qr/foo/;     # yields ('//')


=back


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2007-2009 Chris Dolan.  Many rights reserved.

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
