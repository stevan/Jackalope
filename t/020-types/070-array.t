#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Type::Array');
}

# for validation testing ...
use Jackalope::Schema::Type::Any;
use Jackalope::Schema::Type::Number;

{
    my $s = Jackalope::Schema::Type::Array->new;
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    is($s->type, 'array', '... got the right type');

    ok((not defined $s->items), '... got the right items');
    ok((not defined $s->min_items), '... got the right min_items');
    ok((not defined $s->max_items), '... got the right max_items');
    ok((not defined $s->unique_items), '... got the right unique_items');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        id          => "/schemas/array",
        items       => Jackalope::Schema::Type::Any->new,
        minItems    => 2,
        maxItems    => 10,
        uniqueItems => 1,
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    is($s->id,          "/schemas/array", '... got the right id');
    is($s->min_items,    2, '... got the right min_items');
    is($s->max_items,    10, '... got the right max_items');
    is($s->unique_items, 1, '... got the right unique_items');
    isa_ok($s->items, 'Jackalope::Schema::Type::Any');

}

{
    my $s = Jackalope::Schema::Type::Array->new;
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok(!$s->validate(undef), '... array type dont validate everything');
    ok(!$s->validate(1), '... array type dont validate everything');
    ok(!$s->validate(0), '... array type dont validate everything');
    ok(!$s->validate('string'), '... array type dont validate everything');
    ok(!$s->validate(10), '... array type dont validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... array type dont validate everything');

    ok($s->validate([1, 2, 3]), '... array type do validate arrays');
    ok($s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        minItems => 2
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok($s->validate([1, 2, 3]), '... array type do validate arrays');
    ok($s->validate([1, 2]), '... array type do validate arrays');
    ok(!$s->validate([1]), '... array type do validate arrays');
    ok(!$s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        maxItems => 5
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok(!$s->validate([1, 2, 3, 4, 5, 6]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3, 4, 5]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3, 4]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3]), '... array type do validate arrays');
    ok($s->validate([1, 2]), '... array type do validate arrays');
    ok($s->validate([1]), '... array type do validate arrays');
    ok($s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        maxItems => 5,
        minItems => 2
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok(!$s->validate([1, 2, 3, 4, 5, 6]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3, 4, 5]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3, 4]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3]), '... array type do validate arrays');
    ok($s->validate([1, 2]), '... array type do validate arrays');
    ok(!$s->validate([1]), '... array type do validate arrays');
    ok(!$s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        uniqueItems => 1
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok(!$s->validate([1, 2, 1, 4, 2]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3, 4]), '... array type do validate arrays');
    ok(!$s->validate([1, 1]), '... array type do validate arrays');
    ok($s->validate([1, 2]), '... array type do validate arrays');
    ok($s->validate([1]), '... array type do validate arrays');
    ok($s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        maxItems    => 4,
        minItems    => 2,
        uniqueItems => 1
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok(!$s->validate([1, 2, 3, 4, 5]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3, 4]), '... array type do validate arrays');
    ok(!$s->validate([1, 2, 1, 4, 2]), '... array type do validate arrays');
    ok($s->validate([1, 2, 3, 4]), '... array type do validate arrays');
    ok(!$s->validate([1, 1]), '... array type do validate arrays');
    ok($s->validate([1, 2]), '... array type do validate arrays');
    ok(!$s->validate([1]), '... array type do validate arrays');
    ok(!$s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        items => Jackalope::Schema::Type::Any->new
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok($s->validate([ undef ]), '... array type do validate arrays');
    ok($s->validate([ [1], [2], [3], [4]]), '... array type do validate arrays');
    ok($s->validate([qw[ one two ]]), '... array type do validate arrays');
    ok($s->validate([1, 'two']), '... array type do validate arrays');
    ok($s->validate([1]), '... array type do validate arrays');
    ok($s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        items => Jackalope::Schema::Type::Number->new
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok(!$s->validate([ undef ]), '... array type do validate arrays');
    ok(!$s->validate([ [1], [2], [3], [4]]), '... array type do validate arrays');
    ok(!$s->validate([qw[ one two ]]), '... array type do validate arrays');
    ok(!$s->validate([1, 'two']), '... array type do validate arrays');
    ok($s->validate([1, 2, 3, 4, 5]), '... array type do validate arrays');
    ok($s->validate([1]), '... array type do validate arrays');
    ok($s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        items => Jackalope::Schema::Type::Array->new(
            items => Jackalope::Schema::Type::Number->new
        )
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok(!$s->validate([ undef ]), '... array type do validate arrays');
    ok($s->validate([ [1], [2], [3], [4]]), '... array type do validate arrays');
    ok($s->validate([ [1], [2, 2, 3], [3, 4], [4]]), '... array type do validate arrays');
    ok(!$s->validate([ [1], [2, 'x'], [3, 4], [4]]), '... array type do validate arrays');
    ok(!$s->validate([qw[ one two ]]), '... array type do validate arrays');
    ok(!$s->validate([1, 'two']), '... array type do validate arrays');
    ok(!$s->validate([1, 2, 3, 4, 5]), '... array type do validate arrays');
    ok(!$s->validate([1]), '... array type do validate arrays');
    ok($s->validate([]), '... array type do validate arrays');
}

{
    my $s = Jackalope::Schema::Type::Array->new(
        items => Jackalope::Schema::Type::Array->new(
            maxItems => 2,
            items    => Jackalope::Schema::Type::Number->new
        )
    );
    isa_ok($s, 'Jackalope::Schema::Type::Array');

    ok(!$s->validate([ undef ]), '... array type do validate arrays');
    ok($s->validate([ [1], [2], [3], [4]]), '... array type do validate arrays');
    ok(!$s->validate([ [1], [2, 2, 3], [3, 4], [4]]), '... array type do validate arrays');
    ok(!$s->validate([ [1], [2, 'x'], [3, 4], [4]]), '... array type do validate arrays');
    ok(!$s->validate([qw[ one two ]]), '... array type do validate arrays');
    ok(!$s->validate([1, 'two']), '... array type do validate arrays');
    ok(!$s->validate([1, 2, 3, 4, 5]), '... array type do validate arrays');
    ok(!$s->validate([1]), '... array type do validate arrays');
    ok($s->validate([]), '... array type do validate arrays');
}


done_testing;