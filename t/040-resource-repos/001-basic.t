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
}

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

my $repo = Simple::DataRepo->new;
ResourceRepoTest::run_all_tests( $repo );

done_testing;




