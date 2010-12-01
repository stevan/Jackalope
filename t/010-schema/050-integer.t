#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::Schema::Repository');
    use_ok('Jackalope::Schema::Spec');
}

my $repo = Jackalope::Schema::Repository->new;
isa_ok($repo, 'Jackalope::Schema::Repository');

my @pass = (
    1,
    0,
    10
);

my @fail = (
    undef,
    30.2,
    "hello",
    [ 4, 5, 6 ],
    { seven => 8 }
);

foreach my $data (@pass) {
    validation_pass(
        $repo->validate( { type => 'integer' }, $data ),
        '... validate against the integer type'
    );
}

foreach my $data (@fail) {
    validation_fail(
        $repo->validate( { type => 'integer' }, $data ),
        '... correctly failed to validate against the integer type'
    );
}

done_testing;