#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/CPAN/current/Bread-Board/lib';

use Test::More;
use Test::Fatal;
use Test::Moose;
use Bread::Board;
use Plack::Test;
use HTTP::Request::Common;

BEGIN {
    use_ok('Jackalope::REST');
}

use Plack;
use Plack::Builder;
use Plack::App::Path::Router;

{
    package My::DataRepo;
    use Moose;
    with 'Jackalope::REST::Resource::Repository';

    my $ID_COUNTER = 0;
    has 'db' => ( is => 'ro', isa => 'HashRef', default => sub { +{} } );

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

my $j = Jackalope::REST->new;
my $c = container $j => as {

    service 'MySchemas' => [
        {
            id         => 'simple/person',
            title      => 'This is a simple person schema',
            extends    => { '$ref' => 'schema/web/service' },
            properties => {
                first_name => { type => 'string' },
                last_name  => { type => 'string' },
                age        => { type => 'integer', greater_than => 0 },
            }
        }
    ];

    typemap 'My::DataRepo' => infer;
    service 'MyService' => (
        class        => 'Jackalope::REST::Service',
        dependencies => {
            schema_repository   => 'type:Jackalope::Schema::Repository',
            resource_repository => 'type:My::DataRepo',
            schemas             => 'MySchemas',
            serializer          => {
                'Jackalope::Serializer' => {
                    'format' => 'JSON'
                }
            }
        }
    );
};

my $service = $c->resolve( service => 'MyService' );
isa_ok($service, 'Jackalope::REST::Service');

isa_ok($service->schema_repository, 'Jackalope::Schema::Repository');
isa_ok($service->resource_repository, 'My::DataRepo');
does_ok($service->resource_repository, 'Jackalope::REST::Resource::Repository');
is_deeply($service->schemas, [
    {
        id         => 'simple/person',
        title      => 'This is a simple person schema',
        extends    => { '$ref' => 'schema/web/service' },
        properties => {
            first_name => { type => 'string' },
            last_name  => { type => 'string' },
            age        => { type => 'integer', greater_than => 0 },
        }
    }
], '... got the schema we expected');
isa_ok($service->router, 'Path::Router');

my $app = Plack::App::Path::Router->new( router => $service->router );

my $serializer = $c->resolve(
    service    => 'Jackalope::Serializer',
    parameters => { 'format' => 'JSON' }
);

test_psgi( app => $app, client => sub {
    my $cb = shift;
    #{
    #    my $req = GET( "http://localhost/");
    #    my $res = $cb->($req);
    #    is($res->code, 200, '... got the right status for read');
    #    is_deeply(
    #       $serializer->deserialize( $res->content ),
    #       [],
    #        '... got the right value for read'
    #    );
    #}
    {
        my $req = POST( "http://localhost/create" => (
            Content => '{"first_name":"Stevan","last_name":"Little","age":37}'
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for read');
        is_deeply(
           $serializer->deserialize( $res->content ),
           {
                 id   => 1,
                 body => {
                     first_name => "Stevan",
                     last_name  => "Little",
                     age        => 37,
                 },
                 version => 'fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2',
                 links => [
                     { rel => "list",   href => "",         method => "GET"    },
                     { rel => "create", href => "create",   method => "POST"   },
                     { rel => "read",   href => "1",        method => "GET"    },
                     { rel => "edit",   href => "1/edit",   method => "PUT"    },
                     { rel => "delete", href => "1/delete", method => "DELETE" },
                 ]
            },
            '... got the right value for read'
        );
    }
});


done_testing;