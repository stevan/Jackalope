#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::Schema::Repository');
}

my $repo = Jackalope::Schema::Repository->new;
isa_ok($repo, 'Jackalope::Schema::Repository');

validation_pass(
    $repo->validate(
        { '$ref' => 'schema/types/schema' },
        $repo->compiled_schemas->{'schema/types/schema'},
    ),
    '... validate the schema type with the schema type'
);

validation_pass( $repo->validate( { type => 'number' }, 5 ), '... we validated a number correctly' );
validation_pass( $repo->validate( { type => 'number' }, 1.5 ), '... we validated a number correctly' );
validation_fail( $repo->validate( { type => 'number' }, "foo" ), '... we validated a number correctly' );
validation_fail( $repo->validate( { type => 'number' }, undef ), '... we validated a number correctly' );
validation_fail( $repo->validate( { type => 'number' }, [] ), '... we validated a number correctly' );
validation_fail( $repo->validate( { type => 'number' }, {} ), '... we validated a number correctly' );

validation_pass( $repo->validate( { type => 'integer' }, 1 ), '... we validated a integer correctly' );
validation_fail( $repo->validate( { type => 'integer' }, 1.5 ), '... we validated a integer correctly' );
validation_fail( $repo->validate( { type => 'integer' }, "foo" ), '... we validated a number correctly' );
validation_fail( $repo->validate( { type => 'integer' }, undef ), '... we validated a number correctly' );
validation_fail( $repo->validate( { type => 'integer' }, [] ), '... we validated a number correctly' );
validation_fail( $repo->validate( { type => 'integer' }, {} ), '... we validated a number correctly' );

validation_pass( $repo->validate( { type => 'number', less_than => 10 }, 5 ), '... we validated a number correctly' );
validation_fail( $repo->validate( { type => 'number', less_than => 10 }, 11 ), '... we validated a number correctly' );

validation_pass(
    $repo->validate(
        { '$ref' => 'schema/core/ref' },
        { '$ref' => 'schema/core/ref' }
    ),
    '... validate a ref type'
);

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

is(exception{
    $repo->register_schema(
        {
            "id"          => "/my_schemas/product",
            "description" => "Product",
            "type"        => "object",
            "properties"  => {
                "id" => {
                      "type"        => "number",
                      "description" => "Product identifier",
                      "required"    => 1
                },
                "name"=> {
                      "description" => "Name of the product",
                      "type"        => "string",
                      "required"    => 1
                }
            },
            "links"=> [
                {
                    "relation"      => "self",
                    "href"          => "product/{id}/view",
                    "target_schema" => { '$ref' => "#" }
                },
                {
                    "relation" => "self",
                    "href"     => "product/{id}/update",
                    "method"   => "POST",
                    "schema"   => { '$ref' => "#" }
                },
            ]
        }
    )
}, undef, '... did not die when registering this schema');

is(exception{
    $repo->register_schema(
        {
            "id"          => "/my_schemas/product/list",
            "description" => "Product List",
            "type"        => "array",
            "items"       => {
                '$ref' => "/my_schemas/product"
            },
            "links" => [
                {
                    "relation"      => "self",
                    "href"          => "product/list",
                    "target_schema" => { '$ref' => "#" }
                },
                {
                    "relation" => "create",
                    "href"     => "product/create",
                    "method"   => "POST",
                    "schema"   => { '$ref' => "/my_schemas/product" }
                }
            ]
        }
    )
}, undef, '... did not die when registering this schema');


validation_pass(
    $repo->validate(
        { '$ref' => '/my_schemas/product' },
        { id => 10, name => "Log" }
    ),
    '... validate against the registered product type'
);

validation_pass(
    $repo->validate(
        { '$ref' => '/my_schemas/product/list' },
        [
            { id => 10, name => "Log" },
            { id => 11, name => "Phone" },
        ]
    ),
    '... validate against the registered product type'
);


done_testing;