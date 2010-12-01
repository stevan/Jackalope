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
    undef,
    1,
    0,
    ""
);

my @fail = (
    10,
    "hello",
    30.2,
    [ 4, 5, 6 ],
    { seven => 8 }
);

foreach my $data (@pass) {
    validation_pass(
        $repo->validate( { type => 'boolean' }, $data ),
        '... validate against the boolean type'
    );
}

foreach my $data (@fail) {
    validation_fail(
        $repo->validate( { type => 'boolean' }, $data ),
        '... correctly failed to validate against the boolean type'
    );
}

done_testing;