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
            "id"          => "/some/schema",
            "type"        => "object",
            "properties"  => {
                "id" => { "type" => "number" },
                "name"=> { "type" => "string" }
            },
        }
    )
}, undef, '... did not die when registering this schema');


validation_pass(
    $repo->validate(
        { '__ref__' => '/some/schema' },
        { id => 10, name => "Log" }
    ),
    '... validate against the registered schema'
);


done_testing;