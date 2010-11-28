#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Type::Any');
}

{
    my $s = Jackalope::Schema::Type::Any->new;
    isa_ok($s, 'Jackalope::Schema::Type::Any');

    is($s->type, 'any', '... got the right type');
}

{
    my $s = Jackalope::Schema::Type::Any->new;
    isa_ok($s, 'Jackalope::Schema::Type::Any');

    ok($s->validate(undef), '... any type schemas validate everything');
    ok($s->validate(1), '... any type schemas validate everything');
    ok($s->validate(0), '... any type schemas validate everything');
    ok($s->validate('string'), '... any type schemas validate everything');
    ok($s->validate(10), '... any type schemas validate everything');
    ok($s->validate([1, 2, 3]), '... any type schemas validate everything');
    ok($s->validate({ one => 1, two => 2, three => 3 }), '... any type schemas validate everything');
}

done_testing;