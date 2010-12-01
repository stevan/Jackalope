#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
}

my $repo = Jackalope->new->resolve( type => 'Jackalope::Schema::Repository' );
isa_ok($repo, 'Jackalope::Schema::Repository');

my @pass = (
    [],
    [ 4, 5, 6 ],
);

my @fail = (
    undef,
    1,
    30.2,
    "",
    "hello",
    { seven => 8 }
);

foreach my $data (@pass) {
    validation_pass(
        $repo->validate( { type => 'array' }, $data ),
        '... validate against the array type'
    );
}

foreach my $data (@fail) {
    validation_fail(
        $repo->validate( { type => 'array' }, $data ),
        '... correctly failed to validate against the array type'
    );
}

done_testing;