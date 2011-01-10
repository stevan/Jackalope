package ResourceRepoTest;

use strict;
use warnings;

use Test::More;
use Test::Moose;
use Test::Fatal;

sub run_all_tests {
    my $repo = shift;

    test_repo_object( $repo );
    populate_data( $repo );

    {
        my $resources = test_list_resources( $repo );
        test_get_resource( $repo, $resources );
        test_update_resource( $repo, $resources );
        test_errors( $repo, $resources );
        test_delete_resource( $repo, $resources );
    }

    {
        my $resources = test_list_resources_again( $repo );
        test_delete_resource_again( $repo, $resources );
    }
}

sub test_repo_object {
    my $repo = shift;
    does_ok($repo, 'Jackalope::REST::Resource::Repository');
}

sub populate_data {
    my $repo = shift;
    is( scalar @{ $repo->list_resources }, 0, '... no resources found');

    $repo->create_resource( { foo => 'bar' } );
    is( scalar @{ $repo->list_resources }, 1, '... 1 resource found');

    $repo->create_resource( { bar => 'baz' } );
    is( scalar @{ $repo->list_resources }, 2, '... 2 resources found');

    $repo->create_resource( { baz => 'foo' } );
    is( scalar @{ $repo->list_resources }, 3, '... 3 resources found');
}

sub test_list_resources {
    my $repo      = shift;
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

    return $resources;
}

sub test_get_resource {
    my ($repo, $resources) = @_;

    is_deeply($resources->[0], $repo->get_resource(1), '... got the same resource');
    is($resources->[0]->version, $repo->get_resource(1)->version, '... got the same resource digest');
}


sub test_update_resource {
    my ($repo, $resources) = @_;

    $resources->[0]->body( { foo => 'bar', bling => 'bling' } );

    my $updated = $repo->update_resource( 1, $resources->[0] );

    is_deeply($updated, $repo->get_resource(1), '... got the updated resource');
    is($updated->version, $repo->get_resource(1)->version, '... got the same resource digest');
    isnt($resources->[0]->version, $updated->version, '... is a different resource digest now');
    is( scalar @{ $repo->list_resources }, 3, '... still 3 resources found');
}

sub test_errors {
    my ($repo, $resources) = @_;

    like(exception { $repo->get_resource(10) }, qr/404 Resource Not Found/, '... got the exception like we expected');
    like(exception { $repo->update_resource(10, $resources->[0]) }, qr/400 Bad Request/, '... got the exception like we expected');
    like(exception { $repo->update_resource(1, $resources->[0]) }, qr/409 Conflict Detected/, '... got the exception like we expected');
    like(exception { $repo->delete_resource(10) }, qr/404 Resource Not Found/, '... got the exception like we expected');
}

sub test_delete_resource {
    my ($repo, $resources) = @_;

    my $resource_to_delete = $resources->[1];

    $repo->delete_resource( 2 );
    is( scalar @{ $repo->list_resources }, 2, '... now 2 resources found');

    like(exception { $repo->get_resource(2) }, qr/404 Resource Not Found/, '... got the exception like we expected');
    like(exception { $repo->update_resource(2, $resource_to_delete) }, qr/404 Resource Not Found/, '... got the exception like we expected');
}

sub test_list_resources_again {
    my $repo = shift;

    my $resources = $repo->list_resources;

    is($resources->[0]->id, 1, '... got the right id');
    is_deeply($resources->[0]->body, { foo => 'bar', bling => 'bling' }, '... got the right body');
    like($resources->[0]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    is($resources->[1]->id, 3, '... got the right id');
    is_deeply($resources->[1]->body, { baz => 'foo' }, '... got the right body');
    like($resources->[1]->version, qr/[a-f0-9]{64}/, '... got the right digest');

    return $resources;
}


sub test_delete_resource_again {
    my ($repo, $resources) = @_;

    is(exception {
        $repo->delete_resource( 1, { if_matches => $resources->[0]->{'version'} }  )
    }, undef, '... deletion succeed');
    is( scalar @{ $repo->list_resources }, 1, '... now 1 resource found');

    like(exception {
        $repo->delete_resource( 3, { if_matches => $resources->[0]->{'version'} }  )
    }, qr/409 Conflict Detected/, '... deletion failed (like we wanted it to)');

    is( scalar @{ $repo->list_resources }, 1, '... still 1 resource found (because deletion failed)');
}

1;

__END__
