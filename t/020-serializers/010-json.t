#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Jackalope');
}

my $j = Jackalope->new;

{
    my $serializer = $j->resolve(
        service    => 'Jackalope::Serializer',
        parameters => {
            'format' => 'JSON'
        }
    );
    isa_ok($serializer, 'Jackalope::Serializer::JSON');

    is($serializer->serialize({ foo => 'bar' }), '{"foo":"bar"}', '... got the right JSON');
    is_deeply($serializer->deserialize('{"foo":"bar"}'), { foo => 'bar' }, '... got the right hashref');

    is($serializer->content_type, 'application/json', '... got the right content type for this serializer');
}

{
    my $serializer = $j->resolve(
        service    => 'Jackalope::Serializer',
        parameters => {
            'format'         => 'JSON',
            'default_params' => {
                pretty => 1
            }
        }
    );
    isa_ok($serializer, 'Jackalope::Serializer::JSON');

    is($serializer->serialize({ foo => 'bar' }), "{\n   \"foo\" : \"bar\"\n}\n", '... got the right JSON');
    is_deeply($serializer->deserialize('{"foo":"bar"}'), { foo => 'bar' }, '... got the right hashref');

    is($serializer->content_type, 'application/json', '... got the right content type for this serializer');
}

done_testing;