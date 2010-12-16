#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;
use Test::Jackalope::Fixtures;

BEGIN {
    use_ok('Jackalope');
}

my $repo = Jackalope->new->resolve( type => 'Jackalope::Schema::Repository' );
isa_ok($repo, 'Jackalope::Schema::Repository');

Test::Jackalope::Fixtures->new(
    fixture_dir => [ $FindBin::Bin, '..', '..', 'tests', 'fixtures' ],
    repo        => $repo
)->run_fixtures_for_type( 'boolean' );

done_testing;