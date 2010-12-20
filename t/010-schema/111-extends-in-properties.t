#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
}

my $repo = Jackalope->new->resolve( type => 'Jackalope::Schema::Repository' );
isa_ok($repo, 'Jackalope::Schema::Repository');

is(exception{
    $repo->register_schema(
        {
            id         => 'simple/employee',
            title      => 'This is a simple employee schema',
            type       => 'object',
            properties => {
                id         => { type => 'integer' },
                first_name => { type => 'string' },
                last_name  => { type => 'string' },
                age        => { type => 'integer', greater_than => 0 },
                sex        => { type => 'string', enum => [qw[ male female ]] },
                pay_scale  => { type => 'string', enum => [qw[ low medium high ]] },
            }
        }
    )
}, undef, '... did not die when registering this schema');

is(exception{
    $repo->register_schema(
        {
            id         => 'simple/manager',
            title      => 'This is a simple manager schema',
            extends    => { '$ref' => 'simple/employee' },
            properties => {
                title     => { type => 'string' },
                pay_scale => { type => 'string', literal => 'high' },
                assistant => {
                    extends    => { '$ref' => 'simple/employee' },
                    properties => {
                        pay_scale => { type => 'string', literal => 'medium' },
                    }
                }
            }
        }
    )
}, undef, '... did not die when registering this schema');

my $employee = $repo->get_compiled_schema_by_uri('simple/employee');
my $manager  = $repo->get_compiled_schema_by_uri('simple/manager');

is_deeply(
    $manager,
    {
        'links' => {},
        'additional_properties' => {},
        'type' => 'object',
        'id' => 'simple/manager',
        'title' => 'This is a simple manager schema',
        'properties' => {
            'assistant' => {
                'links' => {},
                'additional_properties' => {},
                'title' => 'This is a simple employee schema',
                'type' => 'object',
                'properties' => {
                    'id' => { 'type' => 'integer' },
                    'age' => { 'greater_than' => 0, 'type' => 'integer' },
                    'sex' => { 'enum' => [ 'male', 'female' ], 'type' => 'string' },
                    'first_name' => {'type' => 'string' },
                    'last_name' => { 'type' => 'string' },
                    pay_scale => { type => 'string', literal => 'medium' }
                }
            },
            'title' => { 'type' => 'string' },
            'id' => { 'type' => 'integer' },
            'age' => { 'greater_than' => 0, 'type' => 'integer' },
            'sex' => { 'enum' => [ 'male', 'female' ], 'type' => 'string' },
            'first_name' => {'type' => 'string' },
            'last_name' => { 'type' => 'string' },
            pay_scale => { type => 'string', literal => 'high' }
        }
    },
    '... manager schema is inflated correctly'
);

done_testing;