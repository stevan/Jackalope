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
    $repo->register_schemas(
        [
            {
                id         => '/schemas/doctor',
                type       => 'object',
                properties => {
                    name => { type => 'string' }
                },
                links => {
                    'doctor.open_slots' => {
                        rel          => 'doctor.open_slots',
                        href         => '/doctors/:id/slots/open',
                        method       => 'GET',
                        uri_schema   => { id => { type => 'string' } },
                        target_schema => {
                            type  => 'array',
                            items => {
                                extends    => { '$ref' => '/schemas/slot/wrapper' },
                                properties => {
                                    body => { '$ref' => '/schemas/slot' }
                                }
                            }
                        },
                    }
                }
            },
            {
                id         => '/schemas/slot/wrapper',
                type       => 'object',
                properties => {
                    id   => { type => 'number' },
                    body => { type => 'any '   },
                }
            },
            {
                id         => '/schemas/slot',
                type       => 'object',
                properties => {
                    date   => { type => 'number' },
                    start  => { type => 'number' },
                    end    => { type => 'number' },
                }
            },
        ]
    )
}, undef, '... did not die when registering this schema');

my $doctor = $repo->get_compiled_schema_by_uri('/schemas/doctor');

is_deeply(
    $doctor->links->{'doctor.open_slots'}->{'target_schema'}->{'items'},
    {
        'additional_properties' => {},
        'type' => 'object',
        'links' => {},
        'properties' => {
            'id' => { 'type' => 'number' },
            'body' => {
                'id' => '/schemas/slot',
                'type' => 'object',
                'properties' => {
                    'date' => { 'type' => 'number' },
                    'start' => { 'type' => 'number' },
                    'end' => {'type' => 'number' }
                }
            },
        }
    },
    '... the extended schema embedded in the link is resolved correctly'
);


done_testing;