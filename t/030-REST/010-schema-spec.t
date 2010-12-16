#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;
use Test::Jackalope;
use Test::Jackalope::Fixtures;

BEGIN {
    use_ok('Jackalope::REST');
}

my $repo = Jackalope::REST->new->resolve(
    type => 'Jackalope::Schema::Repository'
);
isa_ok($repo, 'Jackalope::Schema::Repository');

my $fixtures = Test::Jackalope::Fixtures->new(
    fixture_dir => [ $FindBin::Bin, '..', '..', 'tests', 'fixtures' ],
    repo        => $repo
);

foreach my $type ( qw[ resource service ] ) {
    my $schema = $repo->get_compiled_schema_by_uri('schema/web/' . $type);
    validation_pass(
        $repo->validate(
            { '$ref' => 'schema/types/object' },
            $schema,
        ),
        '... validate the compiled ' . $type . ' type with the schema type'
    );
    $fixtures->run_fixtures_for_type( $type );
}

done_testing;