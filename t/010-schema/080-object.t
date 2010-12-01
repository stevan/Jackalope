#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::Schema::Repository');
    use_ok('Jackalope::Schema::Spec');
}

my $repo = Jackalope::Schema::Repository->new;
isa_ok($repo, 'Jackalope::Schema::Repository');

my @pass = (
    {}
);

my @fail = (
    undef,
    1,
    30.2,
    "",
    "hello",
    [],
    [ 4, 5, 6 ],
    { seven => 8 }
);

foreach my $data (@pass) {
    validation_pass(
        $repo->validate( { type => 'object' }, $data ),
        '... validate against the object type'
    );
}

foreach my $data (@fail) {
    validation_fail(
        $repo->validate( { type => 'object' }, $data ),
        '... correctly failed to validate against the object type'
    );
}

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