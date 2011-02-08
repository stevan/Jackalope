#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
}

my $repo = Jackalope->new->resolve( type => 'Jackalope::Schema::Repository' );
isa_ok($repo, 'Jackalope::Schema::Repository');

foreach my $type ( $repo->spec->valid_types ) {

    my $schema = $repo->get_compiled_schema_for_type( $type )->compiled;

    validation_pass(
        $repo->validate(
            { '$ref' => 'jackalope/core/types/schema' },
            $schema,
        ),
        '... validate the compiled ' . $type . ' schema with the schema type'
    );
}

validation_pass(
    $repo->validate(
        { '$ref' => 'jackalope/core/types/schema' },
        $repo->get_compiled_schema_by_uri('jackalope/core/types/schema')->compiled,
    ),
    '... validate the compiled schema type with the schema type (bootstrappin)'
);

done_testing;