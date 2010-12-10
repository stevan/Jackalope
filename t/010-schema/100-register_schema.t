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
                    "relation"      => "self",
                    "href"          => "product/{id}/view",
                    "target_schema" => { '$ref' => "#" }
                },
                {
                    "relation"    => "edit",
                    "href"        => "product/{id}/update",
                    "method"      => "POST",
                    "data_schema" => { '$ref' => "#" }
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
                    "relation"      => "/my_schemas/links/product_listing",
                    "href"          => "product/list",
                    "target_schema" => { '$ref' => "#" }
                },
                {
                    "relation"    => "create",
                    "href"        => "product/create",
                    "method"      => "POST",
                    "data_schema" => { '$ref' => "/my_schemas/product" }
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