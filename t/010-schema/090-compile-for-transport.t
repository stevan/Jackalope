#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
}

my @schemas = (
    {
        id         => 'simple/person',
        title      => 'This is a simple person schema',
        type       => 'object',
        properties => {
            id         => { type => 'integer' },
            first_name => { type => 'string' },
            last_name  => { type => 'string' },
            age        => { type => 'integer', greater_than => 0 },
            sex        => { type => 'string', enum => [qw[ male female ]] }
        },
        links => {
            "self" => {
                rel           => 'self',
                href          => '/:id/read',
                method        => 'GET',
                target_schema => { '$ref' => '#' }
            },
            "edit" => {
                rel           => 'edit',
                href          => '/:id/update',
                method        => 'GET',
                target_schema => { '$ref' => '#' }
            }
        }
    },
    {
        id         => 'simple/employee',
        title      => 'This is a simple employee schema',
        extends    => { '$ref' => 'simple/person' },
        properties => {
            title   => { type => 'string' },
            manager => { '$ref' => '#' }
        },
        links => {
            "self" => {
                rel           => 'self',
                href          => '/:id',
                method        => 'GET',
                target_schema => { '$ref' => '#' }
            }
        }
    }
);

my $repo = Jackalope->new->resolve(
    type => 'Jackalope::Schema::Repository'
);
isa_ok($repo, 'Jackalope::Schema::Repository');

my $compiled;
is(exception{
    $compiled = $repo->register_schemas( \@schemas );
}, undef, '... did not die when registering this schema');

is_deeply(
    $repo->get_schema_compiled_for_transport('simple/employee'),
    {
        'simple/employee' => {
            id         => 'simple/employee',
            title      => 'This is a simple employee schema',
            type       => 'object',
            properties => {
                id         => { type => 'integer' },
                first_name => { type => 'string' },
                last_name  => { type => 'string' },
                age        => { type => 'integer', greater_than => 0 },
                sex        => { type => 'string', enum => [qw[ male female ]] },
                title      => { type => 'string' },
                manager    => { '$ref' => '#' }
            },
            additional_properties => {},
            links => {
                "self" => {
                    rel           => 'self',
                    href          => '/:id',
                    method        => 'GET',
                    target_schema => { '$ref' => '#' }
                },
                "edit" => {
                    rel           => 'edit',
                    href          => '/:id/update',
                    method        => 'GET',
                    target_schema => { '$ref' => '#' }
                }
            }
        }
    },
    '... got the right transport compiled schema'
);

done_testing;