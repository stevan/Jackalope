#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Type::Boolean');
}

{
    my $s = Jackalope::Schema::Type::Boolean->new;
    isa_ok($s, 'Jackalope::Schema::Type::Boolean');

    is($s->type, 'boolean', '... got the right type');
}

{
    my $s = Jackalope::Schema::Type::Boolean->new;
    isa_ok($s, 'Jackalope::Schema::Type::Boolean');

    ok($s->validate(undef), '... boolean type schemas validate true of false values');
    ok($s->validate(1), '... boolean type schemas validate true of false values');
    ok($s->validate(0), '... boolean type schemas validate true of false values');
    ok(!$s->validate('string'), '... boolean type schemas validate true of false values');
    ok(!$s->validate(10), '... boolean type schemas validate true of false values');
    ok(!$s->validate([1, 2, 3]), '... boolean type schemas validate true of false values');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... boolean type schemas validate true of false values');
}

done_testing;