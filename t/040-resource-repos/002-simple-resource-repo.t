#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Moose;
use ResourceRepoTest;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::REST::Resource::Repository::Simple');
}

my $repo = Jackalope::REST::Resource::Repository::Simple->new;
ResourceRepoTest->new(
    fixtures => [
        { id => 1, body => { foo => 'bar'   } },
        { id => 2, body => { bar => 'baz'   } },
        { id => 3, body => { baz => 'gorch' } },
        { id => 4, body => { gorch => 'foo' } },
    ]
)->run_all_tests( $repo );

done_testing;




