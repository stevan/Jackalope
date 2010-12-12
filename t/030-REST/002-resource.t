#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::REST::Resource');
}

my $resource = Jackalope::REST::Resource->new(
    id      => '1229273732',
    body    => { hello => 'world' },
    version => 'v1'
);
isa_ok($resource, 'Jackalope::REST::Resource');

done_testing;