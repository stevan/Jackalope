package ResourceRepoTest;
use Moose;

use Test::More;
use Test::Moose;
use Test::Fatal;

has 'fixtures' => (
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef[ HashRef ]',
    required => 1,
    handles  => {
        'fixture_count' => 'count',
        'get_fixture'   => 'get',
        'sort_fixtures' => 'sort_in_place'
    }
);

has 'id_callback' => (
    is      => 'ro',
    isa     => 'CodeRef'
);

sub run_all_tests {
    my $self = shift;
    my $repo = shift;

    $self->test_repo_object( $repo );
    $self->populate_data( $repo );

    if ( my $callback = $self->id_callback ) {
        $callback->( $self, $repo );
    }

    {
        my $resources = $self->test_list_resources( $repo );
        $self->test_get_resource( $repo, $resources );
        $self->test_update_resource( $repo, $resources );
        $self->test_errors( $repo, $resources );
        $self->test_delete_resource( $repo, $resources );
    }

    {
        my $resources = $self->test_list_resources_again( $repo );
        $self->test_delete_resource_again( $repo, $resources );
    }
}

sub test_repo_object {
    my $self = shift;
    my $repo = shift;
    does_ok($repo, 'Jackalope::REST::Resource::Repository');
}

sub populate_data {
    my $self = shift;
    my $repo = shift;
    is( scalar @{ $repo->list_resources }, 0, '... no resources found');

    foreach my $fixture ( @{ $self->fixtures } ) {
        $repo->create_resource( $fixture->{body} );
    }

    is( scalar @{ $repo->list_resources }, $self->fixture_count, '... all the resource found');
}


sub test_list_resources {
    my $self      = shift;
    my $repo      = shift;
    my $resources = $repo->list_resources;

    foreach my $i ( 0 .. ($self->fixture_count - 1) ) {
        my $f = $self->get_fixture( $i );
        is($resources->[$i]->id, $f->{id}, '... got the right id');
        is_deeply($resources->[$i]->body, $f->{body}, '... got the right body');
        like($resources->[$i]->version, qr/[a-f0-9]{64}/, '... got the right digest');
    }

    return $resources;
}

sub test_get_resource {
    my $self = shift;
    my ($repo, $resources) = @_;

    my $id = $self->get_fixture(0)->{id};

    is_deeply($resources->[0], $repo->get_resource( $id ), '... got the same resource');
    is($resources->[0]->version, $repo->get_resource( $id )->version, '... got the same resource digest');
}


sub test_update_resource {
    my $self = shift;
    my ($repo, $resources) = @_;

    my $id = $self->get_fixture(0)->{id};

    $resources->[0]->body( { foo => 'bar', bling => 'bling' } );

    my $updated = $repo->update_resource( $id, $resources->[0] );

    is_deeply($updated, $repo->get_resource( $id ), '... got the updated resource');
    is($updated->version, $repo->get_resource( $id )->version, '... got the same resource digest');
    isnt($resources->[0]->version, $updated->version, '... is a different resource digest now');
    is( scalar @{ $repo->list_resources }, $self->fixture_count, '... still 3 resources found');
}

sub test_errors {
    my $self = shift;
    my ($repo, $resources) = @_;

    my $id = $self->get_fixture(0)->{id};

    like(exception { $repo->get_resource(10101) }, qr/404 Resource Not Found/, '... got the exception like we expected');
    like(exception { $repo->update_resource(10101, $resources->[0]) }, qr/400 Bad Request/, '... got the exception like we expected');
    like(exception { $repo->update_resource($id, $resources->[0]) }, qr/409 Conflict Detected/, '... got the exception like we expected');
    like(exception { $repo->delete_resource(10101) }, qr/404 Resource Not Found/, '... got the exception like we expected');
}

sub test_delete_resource {
    my $self = shift;
    my ($repo, $resources) = @_;

    my $id = $self->get_fixture(1)->{id};

    my $resource_to_delete = $resources->[1];

    $repo->delete_resource( $id );
    is( scalar @{ $repo->list_resources }, ($self->fixture_count - 1), '... now 2 resources found');

    like(exception { $repo->get_resource($id) }, qr/404 Resource Not Found/, '... got the exception like we expected');
    like(exception { $repo->update_resource($id, $resource_to_delete) }, qr/404 Resource Not Found/, '... got the exception like we expected');
}

sub test_list_resources_again {
    my $self = shift;
    my $repo = shift;

    my $resources = $repo->list_resources;

    my $one = $self->get_fixture(0);

    is($resources->[0]->id, $one->{id}, '... got the right id');
    is_deeply($resources->[0]->body, { foo => 'bar', bling => 'bling' }, '... got the right body');
    like($resources->[0]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    my $three = $self->get_fixture(2);

    is($resources->[1]->id, $three->{id}, '... got the right id');
    is_deeply($resources->[1]->body, $three->{body}, '... got the right body');
    like($resources->[1]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    return $resources;
}


sub test_delete_resource_again {
    my $self = shift;
    my ($repo, $resources) = @_;


    is(exception {
        $repo->delete_resource( $self->get_fixture(0)->{id}, { if_matches => $resources->[0]->{'version'} }  )
    }, undef, '... deletion succeed');
    is( scalar @{ $repo->list_resources }, ($self->fixture_count - 2), '... now 1 resource found');

    like(exception {
        $repo->delete_resource( $self->get_fixture(2)->{id}, { if_matches => $resources->[0]->{'version'} }  )
    }, qr/409 Conflict Detected/, '... deletion failed (like we wanted it to)');

    is( scalar @{ $repo->list_resources }, ($self->fixture_count - 2), '... still 1 resource found (because deletion failed)');
}

1;

__END__
