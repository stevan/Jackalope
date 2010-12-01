#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::Schema::Repository');
}

my $repo = Jackalope::Schema::Repository->new;
isa_ok($repo, 'Jackalope::Schema::Repository');

foreach my $type ( qw[ ref hyperlink ] ) {
    validation_pass(
        $repo->validate(
            { '$ref' => 'schema/types/object' },
            $repo->compiled_schemas->{'schema/core/' . $type},
        ),
        '... validate the ' . $type . ' type with the schema type'
    );
}

validation_pass(
    $repo->validate(
        { '$ref' => 'schema/core/ref' },
        { '$ref' => 'schema/core/ref' }
    ),
    '... validate a ref type'
);

my @links = (
    {
        "relation" => "self",
        "href"     => "{id}"
    },
    {
        "relation" => "described_by",
        "href"     => "schema/{type}"
    },
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
    {
        "relation"    => "create",
        "href"        => "product/create",
        "method"      => "POST",
        "schema"      => { '$ref' => "/my_schemas/product" },
        "title"       => "Create Product",
        "description" => "Create a product resource with this",
        "metadata"    => {
            controller => 'ProductFactory',
            action     => 'create_product'
        }
    }
);

foreach my $link (@links) {
    validation_pass(
        $repo->validate( { '$ref' => 'schema/core/hyperlink' }, $link ),
        '... validate a hyperlink type'
    );
}


done_testing;