#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;
use Test::Jackalope::Fixtures;

BEGIN {
    use_ok('Jackalope');
}

my $repo = Jackalope->new->resolve( type => 'Jackalope::Schema::Repository' );
isa_ok($repo, 'Jackalope::Schema::Repository');

Test::Jackalope::Fixtures->new(
    fixture_dir => [ $FindBin::Bin, '..', '..', 'test_fixtures' ],
    repo        => $repo
)->run_fixtures_for_type( 'object' );

# some basic object types ...

validation_pass(
    $repo->validate(
        {
            type       => "object",
            properties => {
                name => { type => "string" },
                age  => {
                    type      => "integer",
                    less_than => 125
                }
            }
        },
        { name => 'Stevan', age => 35 }
    ),
    '... validated a complex object type'
);

validation_pass(
    $repo->validate(
        {
            "description"            => "Cyclic Schema",
            "type"                   => "object",
            "additional_properties"  => {
                "self" => { '$ref' => '#' }
            }
        },
        { self => { self => { self => {} } } }
    ),
    '... validated the cyclical schemea'
);

# more complex type

validation_pass(
    $repo->validate(
        {
            "description" => "Product",
            "type" => 'object',
            "properties" => {
                "id" => {
                    "type"        => "number",
                    "description" => "Product identifier",
                },
                "name" => {
                    "description" => "Name of the product",
                    "type"        => "string",
                },
                "price" => {
                    "type" =>  "number",
                    "minimum" => 0,
                }
            },
            "additional_properties" => {
                "tags" => {
                    "type" => "array",
                    "items" => {
                        "type" => "string"
                    }
                }
            },
            "links" => [
                {
                  "relation" => "self",
                  "href"     => "{id}"
                },
                {
                  "relation" => "self",
                  "href"     => "comments/?id={id}"
                }
            ]
        },
        { id => 1, name => 'Boom Box', price => 200.00, tags => [qw[ boomin box ]] }
    ),
    '... validated the complex schemea'
);

done_testing;