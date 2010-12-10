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

is(exception{
    $repo->register_schema(
        {
            "id"          => "/my_schemas/product",
            "description" => "Product",
            "type"        => "object",
            "properties"  => {
                "id" => {
                      "type"        => "number",
                      "description" => "Product identifier"
                },
                "name"=> {
                      "description" => "Name of the product",
                      "type"        => "string"
                }
            },
            "links"=> [
                {
                    "label"         => "view_product",
                    "relation"      => "self",
                    "href"          => "product/{id}/view",
                    "target_schema" => { '$ref' => "#" }
                },
                {
                    "label"    => "update_product",
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
                    "label"         => "list_products",
                    "relation"      => "self",
                    "href"          => "product/list",
                    "target_schema" => { '$ref' => "#" }
                },
                {
                    "label"    => "create_product",
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