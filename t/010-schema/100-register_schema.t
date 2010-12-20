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
            "links"=> {
                "self" => {
                    "rel"           => "self",
                    "method"        => "GET",
                    "href"          => "product/{id}/view",
                    "target_schema" => { '$ref' => "#" }
                },
                "edit" => {
                    "rel"         => "edit",
                    "href"        => "product/{id}/update",
                    "method"      => "POST",
                    "data_schema" => { '$ref' => "#" }
                },
            }
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
            "links" => {
                "/my_schemas/links/product_listing" => {
                    "rel"           => "/my_schemas/links/product_listing",
                    "method"        => "GET",
                    "href"          => "product/list",
                    "target_schema" => { '$ref' => "#" }
                },
                "create" => {
                    "rel"         => "create",
                    "href"        => "product/create",
                    "method"      => "POST",
                    "data_schema" => { '$ref' => "/my_schemas/product" }
                }
            }
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