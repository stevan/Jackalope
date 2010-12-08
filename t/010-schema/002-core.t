#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;
use Test::Jackalope;
use Test::Jackalope::Fixtures;

BEGIN {
    use_ok('Jackalope');
}

my $repo = Jackalope->new->resolve( type => 'Jackalope::Schema::Repository' );
isa_ok($repo, 'Jackalope::Schema::Repository');

my $fixtures = Test::Jackalope::Fixtures->new(
    fixture_dir => [ $FindBin::Bin, '..', '..', 'fixtures' ],
    repo        => $repo
);

foreach my $type ( qw[ ref hyperlink ] ) {
    my $schema = $repo->get_compiled_schema_by_uri('schema/core/' . $type);
    validation_pass(
        $repo->validate(
            { '$ref' => 'schema/types/object' },
            $schema->{'compiled'},
        ),
        '... validate the compiled ' . $type . ' type with the schema type'
    );
    validation_pass(
        $repo->validate(
            { '$ref' => 'schema/types/object' },
            $schema->{'raw'},
        ),
        '... validate the raw ' . $type . ' type with the schema type'
    );
    $fixtures->run_fixtures_for_type( $type );
}




done_testing;