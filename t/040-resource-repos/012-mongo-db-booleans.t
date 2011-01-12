#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Moose;

use Try::Tiny;
use ResourceRepoTest;
use Jackalope::Util qw[ true false ];

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

my $repo = Jackalope::REST::Resource::Repository::MongoDB->new(
    collection => $coll
);

my $id;
{
    my $resource = $repo->create_resource( { "true" => true(), "false" => false() } );
    isa_ok($resource, 'Jackalope::REST::Resource');

    $id = $resource->id;

    ok(Jackalope::Util::is_bool( $resource->body->{true} ), '... got back a real boolean');
    ok(Jackalope::Util::is_bool( $resource->body->{false} ), '... got back a real boolean');
    is($resource->body->{true}, true(), '... got back the right boolean');
    is($resource->body->{false}, false(), '... got back the right boolean');
}

{
    my $resource = $repo->get_resource( $id );
    isa_ok($resource, 'Jackalope::REST::Resource');

    ok(Jackalope::Util::is_bool( $resource->body->{true} ), '... got back a real boolean');
    ok(Jackalope::Util::is_bool( $resource->body->{false} ), '... got back a real boolean');
    is($resource->body->{true}, true(), '... got back the right boolean');
    is($resource->body->{false}, false(), '... got back the right boolean');

    $resource->body->{'true'}  = false();
    $resource->body->{'false'} = true();

    my $updated = $repo->update_resource( $id, $resource );
    isa_ok($updated, 'Jackalope::REST::Resource');

    ok(Jackalope::Util::is_bool( $updated->body->{true} ), '... got back a real boolean');
    ok(Jackalope::Util::is_bool( $updated->body->{false} ), '... got back a real boolean');
    is($updated->body->{true}, false(), '... got back the right boolean');
    is($updated->body->{false}, true(), '... got back the right boolean');
}

{
    my $resources = $repo->list_resources();

    ok(Jackalope::Util::is_bool( $resources->[0]->body->{true} ), '... got back a real boolean');
    ok(Jackalope::Util::is_bool( $resources->[0]->body->{false} ), '... got back a real boolean');
    is($resources->[0]->body->{true}, false(), '... got back the right boolean');
    is($resources->[0]->body->{false}, true(), '... got back the right boolean');
}


done_testing;




