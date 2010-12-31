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
        }
    )
}, undef, '... did not die when registering this schema');

is(exception{
    $repo->register_schema(
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
    )
}, undef, '... did not die when registering this schema');

my $person   = $repo->get_compiled_schema_by_uri('simple/person');
my $employee = $repo->get_compiled_schema_by_uri('simple/employee');

ok(exists $employee->{'type'}, '... employee has the type key');
is($employee->{'type'}, 'object', '... it is the right employee type');

ok(exists $employee->{'links'}, '... employee has the links key');
isnt($employee->{'links'}, $person->{'links'}, '... employee has a different links list then person');

is($employee->{'properties'}->{'manager'}, $employee, '... manager schema is inflated correctly');

is($employee->{'links'}->{'self'}->{'target_schema'}, $employee, '... employee link goes to itself in the target_schema');
is($person->{'links'}->{'self'}->{'target_schema'}, $person, '... person link goes to itself in the target_schema');

is($employee->{'links'}->{'edit'}->{'target_schema'}, $employee, '... employee link goes to itself in the target_schema');
is($person->{'links'}->{'edit'}->{'target_schema'}, $person, '... person link goes to itself in the target_schema');


done_testing;