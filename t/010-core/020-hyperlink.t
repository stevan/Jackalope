#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::Schema::Core::Hyperlink');
}

use Jackalope::Schema::Type::Any;

{
    my $l = Jackalope::Schema::Core::Hyperlink->new;
    isa_ok($l, 'Jackalope::Schema::Core::Hyperlink');

    ok((not defined $l->rel), '... no rel defined');
    ok((not defined $l->href), '... no href defined');
    ok((not defined $l->target_schema), '... no target_schema defined');
    ok((not defined $l->schema), '... no schema defined');
    ok((not defined $l->title), '... no title defined');
    ok((not defined $l->description), '... no description defined');
    ok((not defined $l->metadata), '... no metadata defined');

    is($l->method, 'GET', '... got a method defined');
}

{
    my $l = Jackalope::Schema::Core::Hyperlink->new(
        rel          => 'self',
        href         => '/some/schema',
        targetSchema => Jackalope::Schema::Type::Any->new,
        schema       => Jackalope::Schema::Type::Any->new,
        method       => 'POST',
        title        => 'MyLink',
        description  => 'description of my link',
        metadata     => { foo => 'bar' }
    );
    isa_ok($l, 'Jackalope::Schema::Core::Hyperlink');

    is($l->rel,     'self',         '... got a rel defined');
    is($l->href,    '/some/schema', '... got a href defined');
    is($l->method,  'POST',         '... got a method defined');

    isa_ok($l->target_schema, 'Jackalope::Schema::Type::Any');
    isa_ok($l->schema,        'Jackalope::Schema::Type::Any');

    is($l->title, 'MyLink', '... got the right title');
    is($l->description, 'description of my link', '... got the right title');
    is_deeply($l->metadata, { foo => 'bar' }, '... got the expected metadata');
}

done_testing;