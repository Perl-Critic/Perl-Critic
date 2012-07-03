#!perl

##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/t/00_modules.t $
#     $Date: 2009-11-01 20:13:44 -0500 (Sun, 01 Nov 2009) $
#   $Author: clonezone $
# $Revision: 3699 $
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use PPI::Document;

use Perl::Critic::Annotation;
use Perl::Critic::TestUtils qw(bundled_policy_names);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.118';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

my @bundled_policy_names = bundled_policy_names();

plan( tests => 85 );

#-----------------------------------------------------------------------------
# Test Perl::Critic::Annotation module interface

can_ok('Perl::Critic::Annotation', 'new');
can_ok('Perl::Critic::Annotation', 'create_annotations');
can_ok('Perl::Critic::Annotation', 'element');
can_ok('Perl::Critic::Annotation', 'effective_range');
can_ok('Perl::Critic::Annotation', 'disabled_policies');
can_ok('Perl::Critic::Annotation', 'disables_policy');
can_ok('Perl::Critic::Annotation', 'disables_all_policies');
can_ok('Perl::Critic::Annotation', 'disables_line');

annotate( <<"EOD", 0, 'Null case. Un-annotated document' );
#!/usr/local/bin/perl

print "Hello, world!\n";
EOD

annotate( <<"EOD", 1, 'Single block annotation for entire document' );

## no critic

print "Hello, world!\n";

EOD
my $note = choose_annotation( 0 );
ok( $note, 'Single block annotation defined' );
SKIP: {
    $note or skip( 'No annotation found', 4 );
    ok( $note->disables_all_policies(),
        'Single block annotation disables all policies' );
    ok( $note->disables_line( 4 ),
        'Single block annotation disables line 4' );
    my( $start, $finish ) = $note->effective_range();
    is( $start, 2,
        'Single block annotation starts at 2' );
    is( $finish, 6,
        'Single block annotation runs through 6' );
}

annotate( <<"EOD", 1, 'Block annotation for block (sorry!)' );

{
    ## no critic

    print "Hello, world!\n";
}

EOD
$note = choose_annotation( 0 );
ok( $note, 'Block annotation defined' );
SKIP: {
    $note or skip( 'No annotation found', 4 );
    ok( $note->disables_all_policies(),
        'Block annotation disables all policies' );
    ok( $note->disables_line( 5 ),
        'Block annotation disables line 5' );
    my( $start, $finish ) = $note->effective_range();
    is( $start, 3,
        'Block annotation starts at 3' );
    is( $finish, 6,
        'Block annotation runs through 6' );
}

SKIP: {
    foreach ( @bundled_policy_names ) {
        m/ FroBozzBazzle /smxi or next;
        skip( 'Policy FroBozzBazzle actually implemented', 6 );
        last;   # probably not necessary.
    }

    annotate( <<"EOD", 1, 'Bogus annotation' );

## no critic ( FroBozzBazzle )

print "Goodbye, cruel world!\n";

EOD

    $note = choose_annotation( 0 );
    ok( $note, 'Bogus annotation defined' );

    SKIP: {
        $note or skip( 'Bogus annotation not found', 4 );
        ok( ! $note->disables_all_policies(),
            'Bogus annotation does not disable all policies' );
        ok( $note->disables_line( 3 ),
            'Bogus annotation disables line 3' );
        my( $start, $finish ) = $note->effective_range();
        is( $start, 2,
            'Bogus annotation starts at 2' );
        is( $finish, 6,
            'Bogus annotation runs through 6' );
    }
}

SKIP: {
    @bundled_policy_names >= 8
        or skip( 'Need at least 8 bundled policies', 49 );
    my $max = 0;
    my $doc;
    my @annot;
    foreach my $fmt ( '(%s)', '( %s )', '"%s"', q<'%s'> ) {
        my $policy_name = $bundled_policy_names[$max++];
        $policy_name =~ s/ .* :: //smx;
        $note = sprintf "no critic $fmt", $policy_name;
        push @annot, $note;
        $doc .= "## $note\n## use critic\n";
        $policy_name = $bundled_policy_names[$max++];
        $policy_name =~ s/ .* :: //smx;
        $note = sprintf "no critic qw$fmt", $policy_name;
        push @annot, $note;
        $doc .= "## $note\n## use critic\n";
    }

    annotate( $doc, $max, 'Specific policies in various formats' );
    foreach my $inx ( 0 .. $max - 1 ) {
        $note = choose_annotation( $inx );
        ok( $note, "Specific annotation $inx ($annot[$inx]) defined" );
        SKIP: {
            $note or skip( "No annotation $inx found", 5 );
            ok( ! $note->disables_all_policies(),
                "Specific annotation $inx does not disable all policies" );
            my ( $policy_name ) = $bundled_policy_names[$inx] =~
                m/ ( \w+ :: \w+ ) \z /smx;
            ok ( $note->disables_policy( $bundled_policy_names[$inx] ),
                "Specific annotation $inx disables $policy_name" );
            my $line = $inx * 2 + 1;
            ok( $note->disables_line( $line ),
                "Specific annotation $inx disables line $line" );
            my( $start, $finish ) = $note->effective_range();
            is( $start, $line,
                "Specific annotation $inx starts at line $line" );
            is( $finish, $line + 1,
                "Specific annotation $inx runs through line " . ( $line + 1 ) );
        }
    }
}

annotate( <<"EOD", 1, 'Annotation on split statement' );

my \$foo =
    'bar'; ## no critic ($bundled_policy_names[0])

my \$baz = 'burfle';
EOD
$note = choose_annotation( 0 );
ok( $note, 'Split statement annotation found' );
SKIP: {
    $note or skip( 'Split statement annotation not found', 4 );
    ok( ! $note->disables_all_policies(),
        'Split statement annotation does not disable all policies' );
    ok( $note->disables_line( 3 ),
        'Split statement annotation disables line 3' );
    my( $start, $finish ) = $note->effective_range();
    is( $start, 3,
        'Split statement annotation starts at line 3' );
    is( $finish, 3,
        'Split statement annotation runs through line 3' );
}

annotate (<<'EOD', 1, 'Ensure annotations can span __END__' );
## no critic (RequirePackageMatchesPodName)

package Foo;

__END__

=head1 NAME

Bar - The wrong name for this package

=cut
EOD
$note = choose_annotation( 0 );
ok( $note, 'Annotation (hopefully spanning __END__) found' );
SKIP: {
    skip( 'Annotation (hopefully spanning __END__) not found', 1 )
    if !$note;
    ok( $note->disables_line( 7 ),
        'Annotation disables the POD after __END__' );
}


#-----------------------------------------------------------------------------

{
    my $doc;            # P::C::Document, held to prevent annotations from
                        # going away due to garbage collection of the parent.
    my @annotations;    # P::C::Annotation objects

    sub annotate {  ## no critic (RequireArgUnpacking)
        my ( $source, $count, $title ) = @_;
        $doc = PPI::Document->new( \$source ) or do {
            @_ = ( "Can not make PPI::Document for $title" );
            goto &fail;
        };
        $doc = Perl::Critic::Document->new( -source => $doc ) or do {
            @_ = ( "Can not make Perl::Critic::Document for $title" );
            goto &fail;
        };
        @annotations = Perl::Critic::Annotation->create_annotations( $doc );
        @_ = ( scalar @annotations, $count, $title );
        goto &is;
    }

    sub choose_annotation {
        my ( $index ) = @_;
        return $annotations[$index];
    }

}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/00_modules.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
