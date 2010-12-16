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
            links => [
                {
                    rel         => 'create',
                    href        => '/create',
                    method      => 'PUT',
                    data_schema => {
                        extends    => { '$ref' => '#' },
                        properties => {
                            id => { type => 'null' }
                        },
                        links => []
                    },
                    metadata    => {
                        controller => 'person_manager',
                        action     => 'create'
                    }
                }
            ]
        }
    )
}, undef, '... did not die when registering this schema');

my $person = $repo->get_compiled_schema_by_uri('simple/person');

is_deeply(
    $person->{'links'}->[0]->{'data_schema'}->{'properties'},
    {
        'id' => { 'type' => 'null' },
        'first_name' => { 'type' => 'string' },
        'last_name' => { 'type' => 'string' },
        'age' => {
            'type' => 'integer',
            'greater_than' => 0
        },
        'sex' => {
            'type' => 'string',
            'enum' => [ 'male', 'female' ]
        }
    },
    '... the extended schema embedded in the link is resolved correctly'
);


done_testing;