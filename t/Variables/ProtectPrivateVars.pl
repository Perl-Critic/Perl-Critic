=name Basic failure

=failures 6

=cut

$Other::Package::_foo;
@Other::Package::_bar;
%Other::Package::_baz;
&Other::Package::_quux;
*Other::Package::_xyzzy;
\$Other::Package::_foo;

#----------------------------------------------------------------

=head1 Basic passing

=failures 0

=cut

$_foo;
@_bar;
%_baz;
&_quux;
\$_foo;
$::_foo;
