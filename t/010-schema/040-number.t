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
    10,
    30.2
);

my @fail = (
    undef,
    "hello",
    [ 4, 5, 6 ],
    { seven => 8 }
);

foreach my $data (@pass) {
    validation_pass(
        $repo->validate( { type => 'number' }, $data ),
        '... validate against the number type'
    );
}

foreach my $data (@fail) {
    validation_fail(
        $repo->validate( { type => 'number' }, $data ),
        '... correctly failed to validate against the number type'
    );
}

done_testing;