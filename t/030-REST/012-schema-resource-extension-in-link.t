#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::REST');
}

my $schemas = [
    # Doctor Schema
    {
        id         => '/schemas/doctor',
        type       => 'object',
        properties => {
            name => { type => 'string' }
        },
        links => {
            # Query the open slots the doctor has ...
            'doctor.open_slots' => {
                rel          => 'doctor.open_slots',
                href         => '/doctors/:id/slots/open',
                method       => 'GET',
                uri_schema   => { id => { type => 'string' } },
                # OUTPUT: a list of slot objects
                target_schema => {
                    type  => 'array',
                    items => {
                        extends    => { '$ref' => 'schema/web/resource' },
                        properties => {
                            body => { '$ref' => '/schemas/slot' }
                        }
                    }
                },
            }
        }
    },
    # Slot Schema
    {
        id         => '/schemas/slot',
        type       => 'object',
        properties => {
            date   => { type => 'number' },
            start  => { type => 'number' },
            end    => { type => 'number' },
        }
    },
];

my $repo = Jackalope::REST->new->resolve(
    type => 'Jackalope::Schema::Repository'
);
isa_ok($repo, 'Jackalope::Schema::Repository');

is(exception{
    $repo->register_schemas( $schemas );
}, undef, '... did not die when registering this schema');

my $doctor = $repo->get_compiled_schema_by_uri('/schemas/doctor');

is(
    $doctor->{'links'}->{'doctor.open_slots'}->{'target_schema'}->{'items'}->{'type'},
    'object',
    '... the extended schema embedded in the link is resolved correctly'
);
is_deeply(
    [ sort keys %{ $doctor->{'links'}->{'doctor.open_slots'}->{'target_schema'}->{'items'}->{'properties'} } ],
    [ sort qw[ body version id ]],
    '... the extended schema embedded in the link is resolved correctly'
);
is_deeply(
    [ sort keys %{ $doctor->{'links'}->{'doctor.open_slots'}->{'target_schema'}->{'items'}->{'additional_properties'} } ],
    [ sort qw[ links ] ],
    '... the extended schema embedded in the link is resolved correctly'
);
is_deeply(
    $doctor->{'links'}->{'doctor.open_slots'}->{'target_schema'}->{'items'}->{'properties'}->{'body'},
    {
        'id' => '/schemas/slot',
        'type' => 'object',
        'properties' => {
                          'date' => {
                                      'type' => 'number'
                                    },
                          'start' => {
                                       'type' => 'number'
                                     },
                          'end' => {
                                     'type' => 'number'
                                   }
                        }
    },
    '... the extended schema embedded in the link is resolved correctly'
);

done_testing;

