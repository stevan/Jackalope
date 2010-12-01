#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::Schema::Repository');
}

my $repo = Jackalope::Schema::Repository->new;
isa_ok($repo, 'Jackalope::Schema::Repository');

my @pass = (
    "",
    "hello",
    "a1000",
);

my @fail = (
    undef,
    1,
    30.2,
    [ 4, 5, 6 ],
    { seven => 8 }
);

foreach my $data (@pass) {
    validation_pass(
        $repo->validate( { type => 'string' }, $data ),
        '... validate against the string type'
    );
}

foreach my $data (@fail) {
    validation_fail(
        $repo->validate( { type => 'string' }, $data ),
        '... correctly failed to validate against the string type'
    );
}

done_testing;