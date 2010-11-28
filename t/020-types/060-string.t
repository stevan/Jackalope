#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Type::String');
}

{
    my $s = Jackalope::Schema::Type::String->new;
    isa_ok($s, 'Jackalope::Schema::Type::String');

    is($s->type, 'string', '... got the right type');

    ok((not defined $s->pattern), '... got the right pattern');
    ok((not defined $s->min_length), '... got the right min_length');
    ok((not defined $s->max_length), '... got the right max_length');

}

{
    my $s = Jackalope::Schema::Type::String->new(
        id        => "/schemas/string",
        minLength => 2,
        maxLength => 10,
        pattern   => '.*'
    );
    isa_ok($s, 'Jackalope::Schema::Type::String');

    is($s->id,         "/schemas/string", '... got the right id');
    is($s->min_length, 2,                 '... got the right minLength');
    is($s->max_length, 10,                '... got the right maxLength');
    is($s->pattern,    '.*',            '... got the right pattern');
}

{
    my $s = Jackalope::Schema::Type::String->new;
    isa_ok($s, 'Jackalope::Schema::Type::String');

    ok(!$s->validate(undef), '... string type schemas validate everything');
    ok(!$s->validate(1), '... string type schemas validate everything');
    ok(!$s->validate(0), '... string type schemas validate everything');
    ok($s->validate('string'), '... string type schemas validate everything');
    ok(!$s->validate(10), '... string type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... string type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... string type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::String->new(
        minLength => 2
    );
    isa_ok($s, 'Jackalope::Schema::Type::String');

    ok($s->validate('string'), '... string type schemas validate everything');
    ok($s->validate('str'), '... string type schemas validate everything');
    ok($s->validate('st'), '... string type schemas validate everything');
    ok(!$s->validate('s'), '... string type schemas validate everything');
    ok(!$s->validate(undef), '... string type schemas validate everything');
    ok(!$s->validate(1), '... string type schemas validate everything');
    ok(!$s->validate(0), '... string type schemas validate everything');
    ok(!$s->validate(10), '... string type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... string type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... string type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::String->new(
        maxLength => 5
    );
    isa_ok($s, 'Jackalope::Schema::Type::String');

    ok(!$s->validate('string'), '... string type schemas validate everything');
    ok($s->validate('strin'), '... string type schemas validate everything');
    ok($s->validate('str'), '... string type schemas validate everything');
    ok($s->validate('st'), '... string type schemas validate everything');
    ok($s->validate('s'), '... string type schemas validate everything');
    ok(!$s->validate(undef), '... string type schemas validate everything');
    ok(!$s->validate(1), '... string type schemas validate everything');
    ok(!$s->validate(0), '... string type schemas validate everything');
    ok(!$s->validate(10), '... string type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... string type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... string type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::String->new(
        minLength => 2,
        maxLength => 5
    );
    isa_ok($s, 'Jackalope::Schema::Type::String');

    ok(!$s->validate('string'), '... string type schemas validate everything');
    ok($s->validate('strin'), '... string type schemas validate everything');
    ok($s->validate('str'), '... string type schemas validate everything');
    ok($s->validate('st'), '... string type schemas validate everything');
    ok(!$s->validate('s'), '... string type schemas validate everything');
    ok(!$s->validate(undef), '... string type schemas validate everything');
    ok(!$s->validate(1), '... string type schemas validate everything');
    ok(!$s->validate(0), '... string type schemas validate everything');
    ok(!$s->validate(10), '... string type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... string type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... string type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::String->new(
        pattern => '.*'
    );
    isa_ok($s, 'Jackalope::Schema::Type::String');

    ok($s->validate('string'), '... string type schemas validate everything');
    ok($s->validate('strin'), '... string type schemas validate everything');
    ok($s->validate('str'), '... string type schemas validate everything');
    ok($s->validate('st'), '... string type schemas validate everything');
    ok($s->validate('s'), '... string type schemas validate everything');
    ok(!$s->validate(undef), '... string type schemas validate everything');
    ok(!$s->validate(1), '... string type schemas validate everything');
    ok(!$s->validate(0), '... string type schemas validate everything');
    ok(!$s->validate(10), '... string type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... string type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... string type schemas validate everything');
}

{
    my $s = Jackalope::Schema::Type::String->new(
        pattern => 's\d{2}s'
    );
    isa_ok($s, 'Jackalope::Schema::Type::String');

    ok(!$s->validate('string'), '... string type schemas validate everything');
    ok(!$s->validate('strin'), '... string type schemas validate everything');
    ok($s->validate('s22s'), '... string type schemas validate everything');
    ok(!$s->validate('s2ds'), '... string type schemas validate everything');
    ok(!$s->validate(undef), '... string type schemas validate everything');
    ok(!$s->validate(1), '... string type schemas validate everything');
    ok(!$s->validate(0), '... string type schemas validate everything');
    ok(!$s->validate(10), '... string type schemas validate everything');
    ok(!$s->validate([1, 2, 3]), '... string type schemas validate everything');
    ok(!$s->validate({ one => 1, two => 2, three => 3 }), '... string type schemas validate everything');
}

done_testing;