#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Core::Ref');
}

{
    my $s = Jackalope::Schema::Core::Ref->new;
    isa_ok($s, 'Jackalope::Schema::Core::Ref');

    ok((not defined $s->ref), '... no ref defined');
}

{
    my $s = Jackalope::Schema::Core::Ref->new(
        '$ref' => '/some/schema'
    );
    isa_ok($s, 'Jackalope::Schema::Core::Ref');

    is($s->ref, '/some/schema', '... ref defined');
}

done_testing;