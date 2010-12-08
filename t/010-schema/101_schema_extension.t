#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
}

my $person = {
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
            relation      => 'self',
            href          => '/:id/read',
            method        => 'GET',
            target_schema => { '$ref' => '#' }
        }
    ]
};

my $employee = {
    id         => 'simple/employee',
    title      => 'This is a simple employee schema',
    extends    => { '$ref' => 'simple/person' },
    properties => {
        title   => { type => 'string' },
        manager => { '$ref' => '#' }
    }
};

=pod

the employee should inherit the 'type' and 'links' from person

also the self-ref in $person->links->[0] should resolve to $employee

=cut


done_testing;