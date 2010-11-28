#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Type::Number');
}

{
    my $s = Jackalope::Schema::Type::Number->new;
    isa_ok($s, 'Jackalope::Schema::Type::Number');

    is($s->type, 'number', '... got the right type');

    ok((not defined $s->minimum), '... got the right minimum');
    ok((not defined $s->maximum), '... got the right maximum');
    ok((not defined $s->exclusive_minimum), '... got the right exclusiveMinimum');
    ok((not defined $s->exclusive_maximum), '... got the right exclusiveMaximum');

}

{
    my $s = Jackalope::Schema::Type::Number->new(
        id               => "/schemas/number",
        minimum          => 2,
        maximum          => 10,
        exclusiveMinimum => 1,
        exclusiveMaximum => 0,
    );
    isa_ok($s, 'Jackalope::Schema::Type::Number');

    is($s->id,                "/schemas/number", '... got the right id');
    is($s->minimum,           2,                 '... got the right minimum');
    is($s->maximum,           10,                '... got the right maximum');
    is($s->exclusive_minimum, 1,                 '... got the right exclusiveMinimum');
    is($s->exclusive_maximum, 0,                 '... got the right exclusiveMaximum');

}

{
    my $s = Jackalope::Schema::Type::Number->new;
    isa_ok($s, 'Jackalope::Schema::Type::Number');

    ok(!$s->validate(undef), '... number type schemas validate everything');
    ok($s->validate(1.10), '... number type schemas validate everything');
    ok($s->validate(1), '... number type schemas validate everything');
    ok($s->validate(0), '... number type schemas validate everything');
    ok(!$s->validate('string'), '... number type schemas validate everything');
    ok($s->validate(10), '... number type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... number type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... number type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::Number->new(
        minimum => 3
    );
    isa_ok($s, 'Jackalope::Schema::Type::Number');

    ok(!$s->validate(undef), '... number type schemas validate everything');
    ok(!$s->validate('string'), '... number type schemas validate everything');
    ok(!$s->validate(1.10), '... number type schemas validate everything');
    ok($s->validate(3.10), '... number type schemas validate everything');
    ok(!$s->validate(1), '... number type schemas validate everything');
    ok(!$s->validate(0), '... number type schemas validate everything');
    ok($s->validate(3), '... number type schemas validate everything');
    ok($s->validate(4), '... number type schemas validate everything');
    ok($s->validate(10), '... number type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... number type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... number type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::Number->new(
        minimum          => 3,
        exclusiveMinimum => 1,
    );
    isa_ok($s, 'Jackalope::Schema::Type::Number');

    ok(!$s->validate(undef), '... number type schemas validate everything');
    ok(!$s->validate('string'), '... number type schemas validate everything');
    ok(!$s->validate(1.10), '... number type schemas validate everything');
    ok($s->validate(3.10), '... number type schemas validate everything');
    ok(!$s->validate(1), '... number type schemas validate everything');
    ok(!$s->validate(0), '... number type schemas validate everything');
    ok(!$s->validate(3), '... number type schemas validate everything');
    ok($s->validate(4), '... number type schemas validate everything');
    ok($s->validate(10), '... number type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... number type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... number type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::Number->new(
        maximum => 8
    );
    isa_ok($s, 'Jackalope::Schema::Type::Number');

    ok(!$s->validate(undef), '... number type schemas validate everything');
    ok(!$s->validate('string'), '... number type schemas validate everything');
    ok($s->validate(1.10), '... number type schemas validate everything');
    ok($s->validate(1), '... number type schemas validate everything');
    ok($s->validate(0), '... number type schemas validate everything');
    ok($s->validate(3), '... number type schemas validate everything');
    ok($s->validate(4), '... number type schemas validate everything');
    ok($s->validate(8), '... number type schemas validate everything');
    ok(!$s->validate(8.10), '... number type schemas validate everything');
    ok(!$s->validate(10), '... number type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... number type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... number type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::Number->new(
        maximum          => 8,
        exclusiveMaximum => 1
    );
    isa_ok($s, 'Jackalope::Schema::Type::Number');

    ok(!$s->validate(undef), '... number type schemas validate everything');
    ok(!$s->validate('string'), '... number type schemas validate everything');
    ok($s->validate(1.10), '... number type schemas validate everything');
    ok($s->validate(1), '... number type schemas validate everything');
    ok($s->validate(0), '... number type schemas validate everything');
    ok($s->validate(3), '... number type schemas validate everything');
    ok($s->validate(4), '... number type schemas validate everything');
    ok(!$s->validate(8), '... number type schemas validate everything');
    ok(!$s->validate(8.10), '... number type schemas validate everything');
    ok(!$s->validate(10), '... number type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... number type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... number type schemas validate everything');
}

done_testing;