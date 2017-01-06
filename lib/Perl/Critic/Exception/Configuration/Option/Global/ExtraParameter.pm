package Perl::Critic::Exception::Configuration::Option::Global::ExtraParameter;

use 5.006001;
use strict;
use warnings;

use Readonly;

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration::Option::Global::ExtraParameter' => {
        isa         => 'Perl::Critic::Exception::Configuration::Option::Global',
        description => 'The configuration referred to a non-existant global option.',
        alias       => 'throw_extra_global',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_extra_global >;

#-----------------------------------------------------------------------------

sub full_message {
    my ( $self ) = @_;

    my $source = $self->source();
    if ($source) {
        $source = qq{ (found in "$source")};
    }
    else {
        $source = q{};
    }

    my $option_name = $self->option_name();

    return qq{"$option_name" is not a supported option$source.};
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::Configuration::Option::Global::ExtraParameter - The configuration referred to a non-existent global option.

=head1 DESCRIPTION

A representation of the configuration attempting to specify a value
for an option that L<Perl::Critic|Perl::Critic> doesn't have, whether
from a F<.perlcriticrc>, another profile file, or command line.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 CLASS METHODS

=over

=item C<< throw( option_name => $option_name, source => $source ) >>

See L<Exception::Class/"throw">.


=item C<< new( option_name => $option_name, source => $source ) >>

See L<Exception::Class/"new">.


=back


=head1 METHODS

=over

=item C<full_message()>

Provide a standard message for values for non-existent parameters for
policies.  See L<Exception::Class/"full_message">.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
