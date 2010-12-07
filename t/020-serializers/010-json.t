#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Jackalope');
}

my $j = Jackalope->new;

my $serializer = $j->resolve(
    service    => 'Jackalope::Serializer',
    parameters => {
        'format' => 'JSON'
    }
);
isa_ok($serializer, 'Jackalope::Serializer::JSON');

is($serializer->serialize({ foo => 'bar' }), '{"foo":"bar"}', '... got the right JSON');
is_deeply($serializer->deserialize('{"foo":"bar"}'), { foo => 'bar' }, '... got the right hashref');

done_testing;