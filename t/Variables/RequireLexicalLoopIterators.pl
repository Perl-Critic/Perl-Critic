=name Basic failure

=failures 2

=cut

for $foo ( @list ) {}
foreach $foo ( @list ) {}

#----------------------------------------------------------------

=name Basic passing

=failures 0

=cut

for my $foo ( @list ) {}
foreach my $foo ( @list ) {}

#----------------------------------------------------------------

=name Implicit $_ passes

=failures 0

=cut

for ( @list ) {}
foreach ( @list ) {}

#----------------------------------------------------------------

=name Other compounds

=failures 0

=cut

for ( $i=0; $i<10; $i++ ) {}
while ( $condition ) {}
until ( $condition ) {}
