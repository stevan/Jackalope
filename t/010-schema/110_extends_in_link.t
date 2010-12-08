#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
}

my $schema = {
    id         => 'simple/crud/person',
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
            relation => 'create',
            href     => '/create',
            method   => 'PUT',
            schema   => {
                type       => "object",
                extends    => { '$ref' => '#' },
                properties => {
                    id => { type => 'null' }
                }
            },
            metadata => {
                controller => 'person_manager',
                action     => 'create'
            }
        }
    ]
};


done_testing;