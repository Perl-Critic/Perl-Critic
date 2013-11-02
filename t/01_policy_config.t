#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use Carp qw< confess >;

use Perl::Critic::PolicyConfig;

use Test::More tests => 28;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------


{
    my $config =
        Perl::Critic::PolicyConfig->new('Some::Policy');

    is(
        $config->get_policy_short_name(),
        'Some::Policy',
        'Policy short name gets saved.',
    );
    is(
        $config->get_set_themes(),
        undef,
        'set_themes is undef when not specified.',
    );
    is(
        $config->get_add_themes(),
        undef,
        'add_themes is undef when not specified.',
    );
    is(
        $config->get_severity(),
        undef,
        'severity is undef when not specified.',
    );
    is(
        $config->get_maximum_violations_per_document(),
        undef,
        'maximum_violations_per_document is undef when not specified.',
    );
    ok(
        $config->is_empty(),
        'is_empty() is true when there were no configuration values.',
    );

    my @parameter_names = $config->get_parameter_names();
    is(
        scalar @parameter_names,
        0,
        'There are no parameter names left.',
    );

    test_standard_parameters_undef_via_get($config);
}

{
    my $config =
        Perl::Critic::PolicyConfig->new(
            'Some::Other::Policy',
            {
                custom_parameter   => 'blargh',

                # Standard parameters
                set_themes                      => 'thingy',
                add_themes                      => 'another thingy',
                severity                        => 'harsh',
                maximum_violations_per_document => '2',
            }
        );

    is(
        $config->get_policy_short_name(),
        'Some::Other::Policy',
        'Policy short name gets saved.',
    );
    is(
        $config->get_set_themes(),
        'thingy',
        'set_themes gets saved.',
    );
    is(
        $config->get_add_themes(),
        'another thingy',
        'add_themes gets saved.',
    );
    is(
        $config->get_severity(),
        'harsh',
        'severity gets saved.',
    );
    is(
        $config->get_maximum_violations_per_document(),
        '2',
        'maximum_violations_per_document gets saved.',
    );
    is(
        $config->get('custom_parameter'),
        'blargh',
        'custom_parameter gets saved.',
    );
    ok(
        ! $config->is_empty(),
        'is_empty() is false when there were configuration values.',
    );

    my @parameter_names = $config->get_parameter_names();
    is(
        scalar @parameter_names,
        1,
        'There is one parameter name left after construction.',
    );
    is(
        $parameter_names[0],
        'custom_parameter',
        'There parameter name is the expected value.',
    );

    test_standard_parameters_undef_via_get($config);

    $config->remove('custom_parameter');
    ok(
        $config->is_empty(),
        'is_empty() is true after removing "custom_parameter".',
    );

    @parameter_names = $config->get_parameter_names();
    is(
        scalar @parameter_names,
        0,
        'There are no parameter names left after removing "custom_parameter".',
    );
}


sub test_standard_parameters_undef_via_get {
    my ($config) = @_;
    my $policy_short_name = $config->get_policy_short_name();

    foreach my $parameter (
        qw<
            set_themes
            add_themes
            severity
            maximum_violations_per_document
            _non_public_data
        >
    ) {
        is(
            $config->get($parameter),
            undef,
            qq<"$parameter" is not defined via get() for $policy_short_name.>,
        )
    }

    return;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/01_policy_config.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
