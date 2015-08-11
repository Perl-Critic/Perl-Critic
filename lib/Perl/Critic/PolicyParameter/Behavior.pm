package Perl::Critic::PolicyParameter::Behavior;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Utils qw{ :characters };

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

sub new {
    my $class = shift;

    return bless {}, $class;
}

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    return;
}

#-----------------------------------------------------------------------------

sub generate_parameter_description {
    my ($self, $parameter) = @_;

    return $parameter->_get_description_with_trailing_period();
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::PolicyParameter::Behavior - Default type-specific actions for a parameter.


=head1 DESCRIPTION

Provides a standard set of functionality for a
L<Perl::Critic::PolicyParameter|Perl::Critic::PolicyParameter> so that
the developer of a policy does not have to provide it her/himself.
The developer can override most of the functionality in the
subclasses; these are just defaults.

All subclasses have singleton instances held onto by
L<Perl::Critic::PolicyParameter|Perl::Critic::PolicyParameter>.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 METHODS

=over

=item C<initialize_parameter( $parameter, $specification )>

Plug in the functionality this behavior provides into the parameter,
based upon the configuration provided by the specification.  The
configuration items looked for depends upon the specific behavior
subclass.

=item C<generate_parameter_description( $parameter )>

Create a description of the parameter, based upon the description on
the parameter itself, but enhancing it with information from this
behavior.

Note that this may return C<undef> if the parameter itself doesn't
have a description.  Also, the returned value may include multiple
lines.

=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2006-2011 Elliot Shank.

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
