##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Modules::ProhibitUnusedImports;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw< :severities $EMPTY >;

use base 'Perl::Critic::Policy';

our $VERSION = '1.096';

#-----------------------------------------------------------------------------

Readonly::Scalar my $INTERESTING_IMPORT_REGEX => qr< \A [\$@%] \w+ \z >xms;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            # I can't recall any modules out there like this, but there have
            # got to be some.  Please replace this comment with an example
            # once one is found.
            name            => 'ignored_modules',
            description     => 'Modules to ignore the import lists of.',
            default_string  => $EMPTY,
            behavior        =>  'string list',
        }
    );
}

sub default_severity     { return $SEVERITY_LOW                      }
sub default_themes       { return qw< core maintenance performance > }
sub applies_to           { return 'PPI::Statement::Include'          }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    return if not $elem->type() eq 'use';

    my $module = $elem->module() || $elem->pragma();
    return if not $module;
    return if $self->{_ignored_modules}{$module};

    my %imported_symbols = _get_imported_symbols($elem);

    my $used_symbols = $document->find('PPI::Token::Symbol');
    if ($used_symbols) {
        foreach my $token ( @{$used_symbols} ) {
            delete $imported_symbols{ $token->symbol() };
        }
    }

    return if not keys %imported_symbols;

    my @violations;
    my $expl =
        $module eq 'vars'
            ? 'Unused variables impose extra maintenance and performance costs.'
            : 'Unused imports impose extra maintenance and performance costs.';
    foreach my $symbol (sort keys %imported_symbols) {
        my $desc =
            $module eq 'vars'
                ? qq<Variable "$symbol" is not used.>
                : qq<Imported symbol "$symbol" is not used.>;
        push
            @violations,
            $self->violation( $desc, $expl, $imported_symbols{$symbol} );
    }

    return @violations;
}


sub _get_imported_symbols {
    my ($elem) = @_;

    my %imported_symbols;

    foreach my $argument ( map { $_->tokens() } _arguments($elem) ) {
        if ( $argument->isa('PPI::Token::QuoteLike::Words') ) {
            foreach my $word ( _literal_from_token_words($argument) ) {
                if ($word =~ $INTERESTING_IMPORT_REGEX) {
                    $imported_symbols{$word} = $argument;
                }
            }
        }
        elsif (
                $argument->isa('PPI::Token::Quote::Single')
            or  $argument->isa('PPI::Token::Quote::Literal')
        ) {
            my $content = $argument->string();
            if ($content =~ $INTERESTING_IMPORT_REGEX) {
                $imported_symbols{$content} = $argument;
            }
        }
    } # end if

    return %imported_symbols;
}


# This code taken from unreleased PPI.  Delete this once the next version of
# PPI is released.  "$self" is not this Policy, but a PPI::Statement::Include.
sub _arguments {
    my $self = shift;

    my @arguments = $self->schildren();
    shift @arguments;  # Lose the "my", "no", etc.
    shift @arguments;  # Lose the module/perl version.

    return if not @arguments;

    if (
            $arguments[-1]->isa('PPI::Token::Structure')
        and $arguments[-1]->content() eq q<;>
    ) {
        pop @arguments;
    }

    return if not @arguments;

    if ( $arguments[0]->isa('PPI::Token::Number') ) {
        if ( my $after_number = $arguments[1] ) {
            if ( not $after_number->isa('PPI::Token::Operator') ) {
                shift @arguments;
            }
        } else {
            return;
        }
    }

    return @arguments;
}

# More unreleased PPI.  Delete, delete, delete.
sub _literal_from_token_words {
    my $self = shift;

    my $content = $self->content();
    $content = substr $self->content(), 3, length($content) - 4;

    return split q< >, $content;
}



1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitUnusedImports - Don't import things you aren't going to use.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

    use Foo '@BAR';             # ok (see use below)
    use This qw< $THAT >;       # not ok
    use Whizzo q/some_sub/;     # currently ok
    use GlobUtilities '*GLOB';  # currently ok

    foreach my $x (@BAR) {
        ...
    }


Unused imports impose a maintenance cost because you have to spend
time wondering why they're being used.  Unused imports impose a
performance cost because they use up slots in your package's symbol
table and, if you're not using any of the symbols from the imported
module at all, they're also wasting time and memory by being loaded.


=head1 CONFIGURATION

If you find some module that has you pass things that look like symbol names
to import but which aren't, you can get this policy to shut up about it by
specifying a value for the C<ignored_modules> option in your F<.perlcriticrc>:

    [Modules::ProhibitUnusedImports]
    ignored_modules = Foo::Bar Foobie::Bletch


=head1 BUGS

This can produce false negatives if you have multiple packages in a module.


=head1 TO DO

Detect unused subroutines and globs.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c) 2007-2009 Elliot Shank.  All rights reserved.

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
