#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::Schema');
}

my $schemas = do "$FindBin::Bin/../spec/jwsd-spec.pl";

unless ($schemas) {
    warn "Couldn't compile: $@" if $@;
    warn "Couldn't open for reading: $!" if $!;
}

my $repo = Jackalope::Schema->new(
    schemas => $schemas
);
isa_ok($repo, 'Jackalope::Schema');

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


done_testing;