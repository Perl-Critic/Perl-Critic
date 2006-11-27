=name basic

=failures 3

=cut

$/ = undef;
$| = 1;
$> = 3;

#----------------------------------------------------------------

=head1 English is nice

=failures 0

=cut

$RS = undef;
$INPUT_RECORD_SEPARATOR = "\n";
$OUTPUT_AUTOFLUSH = 1;
print $foo, $baz;

#----------------------------------------------------------------

=name Permitted variables

=failures 0

=cut

$string =~ /((foo)bar)/;
$foobar = $1;
$foo = $2;
$3;
$stat = stat(_);
@list = @_;
my $line = $_;

#----------------------------------------------------------------

=name Configuration

=parms { allow => '$@ $!' }

=failures 0

=cut

print $@;
print $!;
