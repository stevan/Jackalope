#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Type::Integer');
}

{
    my $s = Jackalope::Schema::Type::Integer->new;
    isa_ok($s, 'Jackalope::Schema::Type::Integer');

    is($s->type, 'integer', '... got the right type');
}

{
    my $s = Jackalope::Schema::Type::Integer->new;
    isa_ok($s, 'Jackalope::Schema::Type::Integer');

    ok(!$s->validate(undef), '... integer type schemas validate everything');
    ok(!$s->validate(1.10), '... integer type schemas validate everything');
    ok($s->validate(1), '... integer type schemas validate everything');
    ok($s->validate(0), '... integer type schemas validate everything');
    ok(!$s->validate('string'), '... integer type schemas validate everything');
    ok($s->validate(10), '... integer type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... integer type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... integer type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::Integer->new(
        minimum => 3
    );
    isa_ok($s, 'Jackalope::Schema::Type::Integer');

    ok(!$s->validate(undef), '... integer type schemas validate everything');
    ok(!$s->validate('string'), '... integer type schemas validate everything');
    ok(!$s->validate(1.10), '... integer type schemas validate everything');
    ok(!$s->validate(1), '... integer type schemas validate everything');
    ok(!$s->validate(0), '... integer type schemas validate everything');
    ok($s->validate(3), '... integer type schemas validate everything');
    ok($s->validate(4), '... integer type schemas validate everything');
    ok($s->validate(10), '... integer type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... integer type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... integer type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::Integer->new(
        minimum          => 3,
        exclusiveMinimum => 1,
    );
    isa_ok($s, 'Jackalope::Schema::Type::Integer');

    ok(!$s->validate(undef), '... integer type schemas validate everything');
    ok(!$s->validate('string'), '... integer type schemas validate everything');
    ok(!$s->validate(1.10), '... integer type schemas validate everything');
    ok(!$s->validate(1), '... integer type schemas validate everything');
    ok(!$s->validate(0), '... integer type schemas validate everything');
    ok(!$s->validate(3), '... integer type schemas validate everything');
    ok($s->validate(4), '... integer type schemas validate everything');
    ok($s->validate(10), '... integer type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... integer type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... integer type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::Integer->new(
        maximum => 8
    );
    isa_ok($s, 'Jackalope::Schema::Type::Integer');

    ok(!$s->validate(undef), '... integer type schemas validate everything');
    ok(!$s->validate('string'), '... integer type schemas validate everything');
    ok(!$s->validate(1.10), '... integer type schemas validate everything');
    ok($s->validate(1), '... integer type schemas validate everything');
    ok($s->validate(0), '... integer type schemas validate everything');
    ok($s->validate(3), '... integer type schemas validate everything');
    ok($s->validate(4), '... integer type schemas validate everything');
    ok($s->validate(8), '... integer type schemas validate everything');
    ok(!$s->validate(10), '... integer type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... integer type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... integer type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::Integer->new(
        maximum          => 8,
        exclusiveMaximum => 1
    );
    isa_ok($s, 'Jackalope::Schema::Type::Integer');

    ok(!$s->validate(undef), '... integer type schemas validate everything');
    ok(!$s->validate('string'), '... integer type schemas validate everything');
    ok(!$s->validate(1.10), '... integer type schemas validate everything');
    ok($s->validate(1), '... integer type schemas validate everything');
    ok($s->validate(0), '... integer type schemas validate everything');
    ok($s->validate(3), '... integer type schemas validate everything');
    ok($s->validate(4), '... integer type schemas validate everything');
    ok(!$s->validate(8), '... integer type schemas validate everything');
    ok(!$s->validate(10), '... integer type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... integer type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... integer type schemas validate everything');
}

done_testing;