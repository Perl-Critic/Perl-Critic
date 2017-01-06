package Perl::Critic::Utils::DataConversion;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :booleans };

use Exporter 'import';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw(
    boolean_to_number
    dor
    defined_or_empty
);

#-----------------------------------------------------------------------------

sub boolean_to_number {  ## no critic (RequireArgUnpacking)
    return $_[0] ? $TRUE : $FALSE;
}

#-----------------------------------------------------------------------------

sub dor {  ## no critic (RequireArgUnpacking)
    foreach (@_) {
        return $_ if defined;
    }
    return;
}

#-----------------------------------------------------------------------------

sub defined_or_empty {  ## no critic (RequireArgUnpacking)
    return defined $_[0] ? $_[0] : $EMPTY;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::DataConversion - Utilities for converting from one type of data to another.

=head1 DESCRIPTION

Provides data conversion functions.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over

=item C<boolean_to_number( $value )>

Return 0 or 1 based upon the value of parameter in a boolean context.


=item C<dor( $value, $default )>

Return either the value or the default based upon whether the value is
defined or not.

=item C<dor_n( $value0, $value1, ... )>

Returns the first defined value among its arguments. If none is defined,
simply returns.



=item C<defined_or_empty( $value )>

Return either the parameter or an empty string based upon whether the
parameter is defined or not.


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
