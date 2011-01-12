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

my $repo = Jackalope::REST::Resource::Repository::MongoDB->new(
    collection     => $coll,
    use_custom_ids => 1
);

my $new = $repo->create_resource( { _id => "<custom-id>", foo => "bar" } );
isa_ok($new, 'Jackalope::REST::Resource');
is($new->id, '<custom-id>', '... got the right ID');

my $resources = $repo->list_resources();
isa_ok($resources->[0], 'Jackalope::REST::Resource');
is($resources->[0]->id, '<custom-id>', '... got the right ID');

my $gotten = $repo->get_resource( "<custom-id>" );
isa_ok($gotten, 'Jackalope::REST::Resource');
is($gotten->id, '<custom-id>', '... got the right ID');

$gotten->body( { foo => "bar", bar => "baz" } );

my $updated = $repo->update_resource( "<custom-id>", $gotten );
isa_ok($updated, 'Jackalope::REST::Resource');
is($updated->id, '<custom-id>', '... got the right ID');
is_deeply($updated->body, { foo => "bar", bar => "baz" }, '... got the right body');

is(exception{ $repo->delete_resource( "<custom-id>" ) }, undef, "... deleted successfully");

isa_ok(exception {
    $repo->get_resource( "<custom-id>" )
}, 'Jackalope::REST::Error::ResourceNotFound');

done_testing;




