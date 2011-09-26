#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Jackalope;
use Test::Jackalope::Fixtures;

BEGIN {
    use_ok('Jackalope');
}

my $repo = Jackalope->new->resolve( type => 'Jackalope::Schema::Repository' );
isa_ok($repo, 'Jackalope::Schema::Repository');

my $fixtures = Test::Jackalope::Fixtures->new( repo => $repo );

foreach my $type ( qw[ ref linkrel hyperlink ] ) {
    my $schema = $repo->get_compiled_schema_by_uri('jackalope/core/' . $type)->compiled;
    validation_pass(
        $repo->validate(
            { '__ref__' => 'jackalope/core/types/object' },
            $schema,
        ),
        '... validate the compiled ' . $type . ' type with the schema type'
    );
    $fixtures->run_fixtures_for_type( $type );
}

validation_pass(
    $repo->validate(
        { '__ref__' => 'jackalope/core/spec' },
        $repo->spec->get_spec,
    ),
    '... validate the spec with the spec schema'
);


done_testing;