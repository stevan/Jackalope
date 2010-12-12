#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
}

use Jackalope::Serializer::JSON;

{
    package Simple::DataRepo;
    use Moose;

    with 'Jackalope::REST::Resource::Repository';

    my $ID_COUNTER = 0;

    has 'db' => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { +{} },
    );

    sub list {
        my $self = shift;
        return [ map { [ $_, $self->db->{ $_ } ] } sort keys %{ $self->db } ]
    }

    sub create {
        my ($self, $data) = @_;
        my $id = ++$ID_COUNTER;
        $self->db->{ $id } = $data;
        return ( $id, $data );
    }

    sub get {
        my ($self, $id) = @_;
        return $self->db->{ $id };
    }

    sub update {
        my ($self, $id, $updated_data) = @_;
        $self->db->{ $id } = $updated_data;
    }

    sub delete {
        my ($self, $id) = @_;
        delete $self->db->{ $id };
    }
}

my $repo = Simple::DataRepo->new(
    serializer => Jackalope::Serializer::JSON->new,
);
isa_ok($repo, 'Simple::DataRepo');
does_ok($repo, 'Jackalope::REST::Resource::Repository');

is( scalar @{ $repo->list_resources }, 0, '... no resources found');

$repo->create_resource( { foo => 'bar' } );
is( scalar @{ $repo->list_resources }, 1, '... 1 resource found');

$repo->create_resource( { bar => 'baz' } );
is( scalar @{ $repo->list_resources }, 2, '... 2 resources found');

$repo->create_resource( { baz => 'foo' } );
is( scalar @{ $repo->list_resources }, 3, '... 3 resources found');

my $resource_to_delete;

{
    my $resources = $repo->list_resources;

    is($resources->[0]->id, 1, '... got the right id');
    is_deeply($resources->[0]->body, { foo => 'bar' }, '... got the right body');
    like($resources->[0]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    is($resources->[1]->id, 2, '... got the right id');
    is_deeply($resources->[1]->body, { bar => 'baz' }, '... got the right body');
    like($resources->[1]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    is($resources->[2]->id, 3, '... got the right id');
    is_deeply($resources->[2]->body, { baz => 'foo' }, '... got the right body');
    like($resources->[2]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    is_deeply($resources->[0], $repo->get_resource(1), '... got the same resource');
    is($resources->[0]->version, $repo->get_resource(1)->version, '... got the same resource digest');

    my $updated = $repo->update_resource( 1, $resources->[0]->clone( body => { foo => 'bar', bling => 'bling' } ) );

    is_deeply($updated, $repo->get_resource(1), '... got the updated resource');
    is($updated->version, $repo->get_resource(1)->version, '... got the same resource digest');
    isnt($resources->[0]->version, $updated->version, '... is a different resource digest now');
    is( scalar @{ $repo->list_resources }, 3, '... still 3 resources found');

    like(exception { $repo->get_resource(10) }, qr/404 Resource Not Found/, '... got the exception like we expected');
    like(exception { $repo->update_resource(10, $resources->[0]) }, qr/400 Bad Request/, '... got the exception like we expected');
    like(exception { $repo->update_resource(1, $resources->[0]) }, qr/409 Conflict Detected/, '... got the exception like we expected');
    like(exception { $repo->delete_resource(10) }, qr/404 Resource Not Found/, '... got the exception like we expected');

    $resource_to_delete = $resources->[1];
}

$repo->delete_resource( 2 );
is( scalar @{ $repo->list_resources }, 2, '... now 2 resources found');

like(exception { $repo->get_resource(2) }, qr/404 Resource Not Found/, '... got the exception like we expected');
like(exception { $repo->update_resource(2, $resource_to_delete) }, qr/404 Resource Not Found/, '... got the exception like we expected');

{
    my $resources = $repo->list_resources;

    is($resources->[0]->id, 1, '... got the right id');
    is_deeply($resources->[0]->body, { foo => 'bar', bling => 'bling' }, '... got the right body');
    like($resources->[0]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    is($resources->[1]->id, 3, '... got the right id');
    is_deeply($resources->[1]->body, { baz => 'foo' }, '... got the right body');
    like($resources->[1]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    is(exception {
        $repo->delete_resource( 1, { if_matches => $resources->[0]->{'version'} }  )
    }, undef, '... deletion succeed');
    is( scalar @{ $repo->list_resources }, 1, '... now 1 resource found');

    like(exception {
        $repo->delete_resource( 3, { if_matches => $resources->[0]->{'version'} }  )
    }, qr/409 Conflict Detected/, '... deletion failed (like we wanted it to)');

    is( scalar @{ $repo->list_resources }, 1, '... still 1 resource found (because deletion failed)');
}

done_testing;




