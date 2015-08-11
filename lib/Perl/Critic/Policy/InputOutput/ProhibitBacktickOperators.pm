package Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities is_in_void_context };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Use IPC::Open3 instead};
Readonly::Scalar my $DESC => q{Backtick operator used};

Readonly::Scalar my $VOID_EXPL => q{Assign result to a variable or use system() instead};
Readonly::Scalar my $VOID_DESC => q{Backtick operator used in void context};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name        => 'only_in_void_context',
            description => 'Allow backticks everywhere except in void contexts.',
            behavior    => 'boolean',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw(core maintenance)   }
sub applies_to       { return qw(PPI::Token::QuoteLike::Backtick
                                 PPI::Token::QuoteLike::Command ) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $self->{_only_in_void_context} ) {
        return if not is_in_void_context( $elem );

        return $self->violation( $VOID_DESC, $VOID_EXPL, $elem );
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords perlipc

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators - Discourage stuff like C<@files = `ls $directory`>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Backticks are super-convenient, especially for CGI programs, but I
find that they make a lot of noise by filling up STDERR with messages
when they fail.  I think its better to use IPC::Open3 to trap all the
output and let the application decide what to do with it.

    use IPC::Open3 'open3';
    $SIG{CHLD} = 'IGNORE';

    @output = `some_command`;                      #not ok

    my ($writer, $reader, $err);
    open3($writer, $reader, $err, 'some_command'); #ok;
    @output = <$reader>;  #Output here
    @errors = <$err>;     #Errors here, instead of the console


=head1 CONFIGURATION

Alternatively, if you do want to use backticks, you can restrict
checks to void contexts by adding the following to your
F<.perlcriticrc> file:

    [InputOutput::ProhibitBacktickOperators]
    only_in_void_context = 1

The purpose of backticks is to capture the output of an external
command.  Use of them in a void context is likely a bug.  If the
output isn't actually required, C<system()> should be used.  Otherwise
assign the result to a variable.

    `some_command`;                      #not ok
    $output = `some_command`;            #ok
    @output = `some_command`;            #ok


=head1 NOTES

This policy also prohibits the generalized form of backticks seen as
C<qx{}>.

See L<perlipc|perlipc> for more discussion on using C<wait()> instead
of C<$SIG{CHLD} = 'IGNORE'>.

You might consider using the C<capture()> function from the
L<IPC::System::Simple|IPC::System::Simple> module for a safer way of
doing what backticks do, especially on Windows.  The module also has a
safe wrapper around C<system()>.


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
