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
    undef
);

my @fail = (
    1,
    "two",
    3.1,
    [ 4, 5, 6 ],
    { seven => 8 }
);

foreach my $data (@pass) {
    validation_pass(
        $repo->validate( { type => 'null' }, $data ),
        '... validate against the null type'
    );
}

foreach my $data (@fail) {
    validation_fail(
        $repo->validate( { type => 'null' }, $data ),
        '... correctly failed to validate against the null type'
    );
}

done_testing;