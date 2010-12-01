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

foreach my $type ( @{ $repo->spec->valid_types } ) {
    validation_pass(
        $repo->validate(
            { '$ref' => 'schema/types/schema' },
            $repo->compiled_schemas->{'schema/types/' . $type},
        ),
        '... validate the ' . $type . ' schema with the schema type'
    );
}

validation_pass(
    $repo->validate(
        { '$ref' => 'schema/types/schema' },
        $repo->compiled_schemas->{'schema/types/schema'},
    ),
    '... validate the schema type with the schema type (bootstrappin)'
);

done_testing;