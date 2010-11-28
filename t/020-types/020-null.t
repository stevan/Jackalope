#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Type::Null');
}

{
    my $s = Jackalope::Schema::Type::Null->new;
    isa_ok($s, 'Jackalope::Schema::Type::Null');

    is($s->type, 'null', '... got the right type');
}

{
    my $s = Jackalope::Schema::Type::Null->new;
    isa_ok($s, 'Jackalope::Schema::Type::Null');

    ok($s->validate(undef), '... null type schemas validate only undef values');
    ok(!$s->validate(1), '... null type schemas validate only undef values');
    ok(!$s->validate(0), '... null type schemas validate only undef values');
    ok(!$s->validate('string'), '... null type schemas validate only undef values');
    ok(!$s->validate(10), '... null type schemas validate only undef values');
    ok(!$s->validate([1, 2, 3]), '... null type schemas validate only undef values');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... null type schemas validate only undef values');
}


done_testing;