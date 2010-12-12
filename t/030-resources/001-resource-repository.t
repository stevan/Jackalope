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

    with 'Jackalope::ResourceRepository';

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
        (exists $self->db->{ $id })
            || $self->resource_not_found;
        return $self->db->{ $id };
    }

    sub update {
        my ($self, $id, $updated_data) = @_;
        (exists $self->db->{ $id })
            || $self->resource_not_found("Cannot Update");
        $self->db->{ $id } = $updated_data;
    }

    sub delete {
        my ($self, $id) = @_;
        (exists $self->db->{ $id })
            || $self->resource_not_found("Cannot delete");
        delete $self->db->{ $id };
        return;
    }
}

my $repo = Simple::DataRepo->new(
    serializer => Jackalope::Serializer::JSON->new,
);
isa_ok($repo, 'Simple::DataRepo');
does_ok($repo, 'Jackalope::ResourceRepository');

is( scalar @{ $repo->list_resources }, 0, '... no resources found');

$repo->create_resource( { foo => 'bar' } );
is( scalar @{ $repo->list_resources }, 1, '... 1 resource found');

$repo->create_resource( { bar => 'baz' } );
is( scalar @{ $repo->list_resources }, 2, '... 2 resources found');

$repo->create_resource( { baz => 'foo' } );
is( scalar @{ $repo->list_resources }, 3, '... 3 resources found');

{
    my $resources = $repo->list_resources;

    is($resources->[0]->{id}, 1, '... got the right id');
    is_deeply($resources->[0]->{body}, { foo => 'bar' }, '... got the right body');
    like($resources->[0]->{version}, qr/[a-f0-9]{64}/, '... got the right digest');

    is($resources->[1]->{id}, 2, '... got the right id');
    is_deeply($resources->[1]->{body}, { bar => 'baz' }, '... got the right body');
    like($resources->[1]->{version}, qr/[a-f0-9]{64}/, '... got the right digest');

    is($resources->[2]->{id}, 3, '... got the right id');
    is_deeply($resources->[2]->{body}, { baz => 'foo' }, '... got the right body');
    like($resources->[2]->{version}, qr/[a-f0-9]{64}/, '... got the right digest');

    is_deeply($resources->[0], $repo->get_resource(1), '... got the same resource');
    is($resources->[0]->{version}, $repo->get_resource(1)->{version}, '... got the same resource digest');

    my $updated = $repo->update_resource( 1, { foo => 'bar', bling => 'bling' } );

    is_deeply($updated, $repo->get_resource(1), '... got the updated resource');
    is($updated->{version}, $repo->get_resource(1)->{version}, '... got the same resource digest');
    isnt($resources->[0]->{version}, $updated->{version}, '... is a different resource digest now');
    is( scalar @{ $repo->list_resources }, 3, '... still 3 resources found');
}

$repo->delete_resource( 2 );
is( scalar @{ $repo->list_resources }, 2, '... now 2 resources found');

{
    my $resources = $repo->list_resources;

    is($resources->[0]->{id}, 1, '... got the right id');
    is_deeply($resources->[0]->{body}, { foo => 'bar', bling => 'bling' }, '... got the right body');
    like($resources->[0]->{version}, qr/[a-f0-9]{64}/, '... got the right digest');

    is($resources->[1]->{id}, 3, '... got the right id');
    is_deeply($resources->[1]->{body}, { baz => 'foo' }, '... got the right body');
    like($resources->[1]->{version}, qr/[a-f0-9]{64}/, '... got the right digest');
}

done_testing;




