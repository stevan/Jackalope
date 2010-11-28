#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Type::Object');
}

use Jackalope::Schema::Type::Any;
use Jackalope::Schema::Type::Number;

{
    my $s = Jackalope::Schema::Type::Object->new;
    isa_ok($s, 'Jackalope::Schema::Type::Object');

    is($s->type, 'object', '... got the right type');

    ok((not defined $s->properties), '... got the right properties');
    ok((not defined $s->additional_properties), '... got the right additional_properties');

}

{
    my $s = Jackalope::Schema::Type::Object->new(
        id         => "/schemas/object",
        properties => {
            test => Jackalope::Schema::Type::Any->new
        },
        additionalProperties => {
            another => Jackalope::Schema::Type::Any->new
        }
    );
    isa_ok($s, 'Jackalope::Schema::Type::Object');

    is($s->id, "/schemas/object", '... got the right id');

    isa_ok($s->properties->{test}, 'Jackalope::Schema::Type::Any');
    isa_ok($s->additional_properties->{another}, 'Jackalope::Schema::Type::Any');
}

{
    my $s = Jackalope::Schema::Type::Object->new;
    isa_ok($s, 'Jackalope::Schema::Type::Object');

    ok(!$s->validate(undef), '... object type dont validate everything');
    ok(!$s->validate(1), '... object type dont validate everything');
    ok(!$s->validate(0), '... object type dont validate everything');
    ok(!$s->validate('string'), '... object type dont validate everything');
    ok(!$s->validate(10), '... object type dont validate everything');
    ok(!$s->validate([1, 2, 3]), '... object type do validate arrays');
    ok(!$s->validate([]), '... object type do validate arrays');
    ok($s->validate({ one => 1, two => 2, three => 3 }), '... object type dont validate everything');
    ok($s->validate({}), '... object type dont validate everything');

}

{
    my $s = Jackalope::Schema::Type::Object->new(
        properties => {
            one   => Jackalope::Schema::Type::Number->new,
            two   => Jackalope::Schema::Type::Number->new,
            three => Jackalope::Schema::Type::Number->new,
        }
    );
    isa_ok($s, 'Jackalope::Schema::Type::Object');

    ok(!$s->validate(undef), '... object type dont validate everything');
    ok(!$s->validate(1), '... object type dont validate everything');
    ok(!$s->validate(0), '... object type dont validate everything');
    ok(!$s->validate('string'), '... object type dont validate everything');
    ok(!$s->validate(10), '... object type dont validate everything');
    ok(!$s->validate([1, 2, 3]), '... object type do validate arrays');
    ok(!$s->validate([]), '... object type do validate arrays');

    ok(!$s->validate({}), '... object type dont validate everything');
    ok(!$s->validate({ one => 1 }), '... object type dont validate everything');
    ok(!$s->validate({ one => 1, two => 2 }), '... object type dont validate everything');
    ok($s->validate({ one => 1, two => 2, three => 3 }), '... object type dont validate everything');

    ok(!$s->validate({ one => 1, two => 2, three => 3, four => 4 }), '... object type dont validate everything');
}

done_testing;