##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/lib/Perl/Critic/Config.pm $
#     $Date: 2008-10-26 16:41:34 -0700 (Sun, 26 Oct 2008) $
#   $Author: clonezone $
# $Revision: 2831 $
##############################################################################

package Perl::Critic::Annotation;

use 5.006001;
use strict;
use warnings;

use Carp qw(confess);
use English qw(-no_match_vars);

use Perl::Critic::PolicyFactory;
use Perl::Critic::Utils qw(:characters hashify);

#-----------------------------------------------------------------------------

our $VERSION = '1.094';

#=============================================================================
# CLASS methods

sub create_annotations {
    my ($class, $doc) = @_;
    
    my @annotations = ();
    my $comment_elements_ref  = $doc->find('PPI::Token::Comment') || return;
    my $annotation_rx  = qr{\A (?: [#]! .*? )? \s* [#][#] \s* no  \s+ critic}xms;
    for my $annotation_element ( grep { $_ =~ $annotation_rx } @{$comment_elements_ref} ) {
        push @annotations, Perl::Critic::Annotation->new( -element => $annotation_element);
    }
    
    return @annotations;
}

#-----------------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    $self->_init(@args);
    return $self;
}

#=============================================================================
# OBJECT methods

sub _init {
    my ($self, %args) = @_;
    my $annotation_element = $args{-element} || confess '-element argument is required';
    $self->{_element} = $annotation_element;

    my %disabled_policies = _parse_annotation( $annotation_element );
    $self->{_disables_all_policies} = %disabled_policies ? 0 : 1;
    $self->{_disabled_policies} = \%disabled_policies;

    # Grab surrounding nodes to determine the context.
    # This determines whether the annotation applies to
    # the current line or the block that follows.
    my $annotation_line = $annotation_element->location()->[0];
    my $parent = $annotation_element->parent();
    my $grandparent = $parent ? $parent->parent() : undef;
    my $sib = $annotation_element->sprevious_sibling();

    # Handle case when it appears on the shebang line.  In this
    # situation, it only affects the first line, not the whole doc
    if ( $annotation_element =~ m{\A [#]!}xms) {
        $self->{_effective_range} = [$annotation_line, $annotation_line];
        return $self;
    }

    # Handle single-line usage on simple statements.  In this
    # situation, it only affects the line that it appears on.
    # TODO: Make this work for simple statements that are broken
    # onto multiple lines.
    if ( $sib && $sib->location->[0] == $annotation_line ) {
        $self->{_effective_range} = [$annotation_line, $annotation_line];
        return $self;
    }

    # Handle single-line usage on compound statements.  In this
    # situation -- um -- I'm not sure how this works, but it does.
    if ( ref $parent eq 'PPI::Structure::Block' ) {
        if ( ref $grandparent eq 'PPI::Statement::Compound'
            || ref $grandparent eq 'PPI::Statement::Sub' ) {
            if ( $parent->location->[0] == $annotation_line ) {
                my $grandparent_line = $grandparent->location->[0];
                $self->{_effective_range} = [$grandparent_line, $grandparent_line];
                return $self;
            }
        }
    }


    # Handle multi-line usage.  This is either a "no critic" ..
    # "use critic" region or a block where "no critic" is in effect
    # until the end of the scope.  The start is the always the "no
    # critic" which we already found.  So now we have to search for the end.
    my $end = $annotation_element;
    my $use_critic = qr{\A \s* [#][#] \s* use \s+ critic}xms;

  SIB:
    while ( my $esib = $end->next_sibling() ) {
        $end = $esib; # keep track of last sibling encountered in this scope
        last SIB if $esib->isa('PPI::Token::Comment') && $esib =~ $use_critic;
    }

    # We either found an end or hit the end of the scope.
    my $ending_line = $end->location->[0];
    $self->{_effective_range} = [$annotation_line, $ending_line];
    return $self;
}

#-----------------------------------------------------------------------------

sub element {
    my ($self) = @_;
    return $self->{_element};
}

#-----------------------------------------------------------------------------

sub effective_range {
    my $self = shift;
    return @{ $self->{_effective_range} };
}

#-----------------------------------------------------------------------------

sub disabled_policies {
    my $self = shift;
    return keys %{ $self->{_disabled_policies} };
}

#-----------------------------------------------------------------------------

sub disables_policy {
    my ($self, $policy_name) = @_;
    return 1 if $self->{_disabled_policies}->{$policy_name};
    return 1 if $self->disables_all_policies();
    return 0;
}

#-----------------------------------------------------------------------------

sub disables_all_policies {
    my ($self) = @_;
    return $self->{_disables_all_policies};
}

#-----------------------------------------------------------------------------

sub disables_line {
    my ($self, $line_number) = @_;
    my $effective_range = $self->{_effective_range};
    return 1 if $line_number >= $effective_range->[0] and $line_number <= $effective_range->[-1];
    return 0;
}

#-----------------------------------------------------------------------------

sub _parse_annotation {

    my ($annotation_element) = @_;

    #############################################################################
    # This regex captures the list of Policy name patterns that are to be
    # disabled.  It is generally assumed that the element has already been
    # verified as a no-critic annotation.  So if this regex does not match,
    # then it implies that all Policies are to be disabled.
    #
    my $no_critic = qr{\#\# \s* no \s+ critic \s* (?:qw)? [("'] ([\s\w:,]+) }xms;
    #                  -------------------------- ------- ----- -----------
    #                                 |              |      |        |
    #   "## no critic" with optional spaces          |      |        |
    #                                                |      |        |
    #             Policy list may be prefixed with "qw"     |        |
    #                                                       |        |
    #         Optional Policy list must begin with one of these      |
    #                                                                |
    #                 Capture entire Policy list (with delimiters) here
    #
    #############################################################################

    my @disabled_policy_names = ();
    if ( my ($patterns_string) = $annotation_element =~ $no_critic ) {

        # Compose the specified modules into a regex alternation.  Wrap each
        # in a no-capturing group to permit "|" in the modules specification.

        my @policy_name_patterns = split m{\s *[,\s] \s*}xms, $patterns_string;
        my $re = join $PIPE, map {"(?:$_)"} @policy_name_patterns;
        my @site_policy_names = Perl::Critic::PolicyFactory::site_policy_names();
        @disabled_policy_names = grep {m/$re/ixms} @site_policy_names;

        # It is possible that the Policy patterns listed in the annotation do not
        # match any of the site policy names.  This could happen when running
        # on a machine that does not have the same set of Policies as the author.
        # So we must return something here, otherwise all Policies will be
        # disabled.  We probably need to add a mechanism to (optionally) warn
        # about this, just to help the author avoid writing invalid Policy names.

        if (not @disabled_policy_names) {
            @disabled_policy_names = @policy_name_patterns;
        }
    }

    return hashify(@disabled_policy_names);
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Annotation - Represents a "## no critic" annotation

=head1 SYNOPSIS

  use Perl::Critic::Annotation;
  $annotation = Perl::Critic::Annotation->new( -element => $no_critic_ppi_element );
  
  $bool = $annotation->disables_line( $number );
  $bool = $annotation->disables_policy( $policy_object );
  $bool = $annotation->disables_all_policies();
  
  ($start, $end) = $annotation->effective_range();
  @disabled_policy_names = $annotation->disabled_policies();
  
=head1 DESCRIPTION

L<Perl::Critic::Annotation> represents a single C<"## no critic"> annotation in a
L<PPI:Document>.  The Annotation takes care of parsing the annotation and 
keeps track of which lines and Policies it affects. It is intended to
encapsulate the details of the no-critic annotations, and to provide a way for 
Policy objects to interact with the annotations (via a L<Perl::Critic::Document>).

=head1 CLASS METHODS

=over

=item create_annotations( -doc => $doc )

Given a L<Perl::Critic::Document>, finds all the C<"## no critic"> annotations
and constructs a new L<Perl::Critic::Annotation> for each one and returns
them.  The order of the returned objects is not defined.  It is generally
expected that clients will use this interface rather than calling the
L<Perl::Critic::Annotation> constructor directly.

=back

=head1 CONSTRUCTOR

=over

=item C<< new( -element => $ppi_annotation_element ) >>

Returns a reference to a new Annotation object.  The B<-element> argument
is required and should be a C<PPI::Token::Comment> that conforms to the 
C<"## no critic"> syntax.

=back

=head1 METHODS

=over

=item C<< disables_line( $line ) >>

Returns true if this Annotation disables C<$line> for any (or all) Policies.

=item C<< disables_policy( $policy_object ) >>

=item C<< disables_policy( $policy_name ) >>

Returns true if this Annotation disables C<$polciy_object> or C<$policy_name>
at any (or all) lines.

=item C<< disables_all_policies() >>

Returns true if this Annotation disables all Policies at any (or all) lines.
If this method returns true, C<disabled_policies> will return an empty list.

=item C<< effective_range() >>

Returns a two-element list, representing the first and last line numbers where
this Annotation has effect.

=item C<< disabled_policies() >>

Returns a list of the names of the Policies that are affected by this Annotation.
If this list is empty, then it means that all Policies are affected by this
Annotation, and C<disables_all_policies()> should return true.

=item C<< element() >>

Returns the L<PPI::Element> where this annotation started.  This is typically
an instance of L<PPI::Token::Comment>.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

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
