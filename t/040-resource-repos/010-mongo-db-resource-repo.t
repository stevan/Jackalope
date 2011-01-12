#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Moose;

use Try::Tiny;
use ResourceRepoTest;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::REST::Resource::Repository::MongoDB');
}

my $mongo = try {
    MongoDB::Connection->new( host => 'localhost', port => 27017 );
} catch {
    diag('... no MongoDB instance to connect too');
    done_testing();
    exit();
};

# get rid of any old DBs
$mongo->get_database('jackalope-test')->drop;

my $db    = $mongo->get_database('jackalope-test');
my $coll  = $db->get_collection('resources');

my $repo = Jackalope::REST::Resource::Repository::MongoDB->new( collection => $coll );

ResourceRepoTest->new(
    fixtures => [
        { body => { foo => 'bar'   } },
        { body => { bar => 'baz'   } },
        { body => { baz => 'gorch' } },
        { body => { gorch => 'foo' } },
    ],
    id_callback => sub {
        my ($tester, $repo) = @_;

        # grab all the IDs we just created ...
        my @ids = map {
            $_->{_id}->value;
        } $repo->collection->find->all;

        # add them to the fixtures
        foreach my $fixture ( @{ $tester->fixtures } ) {
            $fixture->{id} = shift @ids;
        }

        # make sure to sort the fixtures now
        $tester->sort_fixtures(sub {
            $_[0]->{id} cmp $_[1]->{id}
        });
    }
)->run_all_tests( $repo );

done_testing;




