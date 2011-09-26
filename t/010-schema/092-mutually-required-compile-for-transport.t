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
        id         => 'simple/foo',
        type       => 'object',
        properties => {
            bar => { '__ref__' => 'simple/bar' }
        }
    },
    {
        id         => 'simple/bar',
        type       => 'object',
        properties => {
            foo => { '__ref__' => 'simple/foo' }
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
    $repo->get_schema_compiled_for_transport('simple/foo'),
    {
        'simple/foo' => {
            id         => 'simple/foo',
            type       => 'object',
            properties => {
                bar => { '__ref__' => 'simple/bar' }
            }
        },
        'simple/bar' => {
            id         => 'simple/bar',
            type       => 'object',
            properties => {
                foo => { '__ref__' => 'simple/foo' }
            }
        }
    },
    '... got the right transport compiled schema even with mutually recursive schemas'
);

done_testing;