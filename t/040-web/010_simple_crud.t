#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/CPAN/current/Bread-Board/lib';

use Test::More;
use Test::Fatal;
use Test::Moose;
use Plack::Test;
use HTTP::Request::Common;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::Web::Service');
}

use Bread::Board;

use Plack;
use Plack::Builder;
use Plack::App::Path::Router;

{
    package Simple::CRUD::PersonManager;
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
        return [ values %{ $self->db } ]
    }

    sub create {
        my ($self, $person) = @_;
        my $id = ++$ID_COUNTER;
        $self->db->{ $id } = $person;
        return $id;
    }

    sub read {
        my ($self, $id) = @_;
        (exists $self->db->{ $id })
            || $self->resource_not_found;
        return $self->db->{ $id };
    }

    sub update {
        my ($self, $id, $updated_person) = @_;
        (exists $self->db->{ $id })
            || $self->resource_not_found("Cannot Update");
        $self->db->{ $id } = $updated_person;
    }

    sub delete {
        my ($self, $id) = @_;
        (exists $self->db->{ $id })
            || $self->resource_not_found("Cannot delete");
        delete $self->db->{ $id };
        return;
    }
}

my $j = Jackalope->new( use_web_spec => 1 );
my $c = container $j => as {

    typemap 'Simple::CRUD::PersonManager' => infer;

    service 'SimpleCRUDPerson' => (
        block => sub {
            my $s = shift;
            Jackalope::Web::Service->new(
                service => $s,
                schemas  => [
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
                ]
            );
        },
        dependencies => {
            resource_repository => 'type:Simple::CRUD::PersonManager',
            schema_repository   => 'type:Jackalope::Schema::Repository',
            serializer          => {
                'Jackalope::Serializer' => {
                    'format' => 'JSON'
                }
            }
        }
    );
};

my $app = Plack::App::Path::Router->new(
    router => $c->resolve( service => 'SimpleCRUDPerson' )->router
);

my $serializer = $c->resolve(
    service    => 'Jackalope::Serializer',
    parameters => { 'format' => 'JSON' }
);

test_psgi
      app    => $app,
      client => sub {
          my $cb = shift;
          {
              my $req = GET( "http://localhost/");
              my $res = $cb->($req);
              is($res->code, 200, '... got the right status for read');
              is_deeply(
                 $serializer->deserialize( $res->content ),
                 [],
                  '... got the right value for read'
              );
           }
           {
              my $req = POST( "http://localhost/" => (
                  Content => '{"first_name":"Stevan","last_name":"Little","age":37}'
              ));
              my $res = $cb->($req);
              is($res->code, 200, '... got the right status for read');
              is_deeply(
                 $serializer->deserialize( $res->content ),
                 [],
                  '... got the right value for read'
              );
          }
          {
              my $req = GET( "http://localhost/");
              my $res = $cb->($req);
              is($res->code, 200, '... got the right status for read');
              is_deeply(
                 $serializer->deserialize( $res->content ),
                 [
                    {
                        id       => 1,
                        resource => {
                            first_name => "Stevan",
                            last_name  => "Little",
                            age        => 37,
                        },
                        version => '...',
                        links => [
                            { relation => "self",   href => "/",  method => "GET"    },
                            { relation => "create", href => "/",  method => "POST"   },
                            { relation => "read",   href => "/1", method => "GET"    },
                            { relation => "update", href => "/1", method => "PUT"    },
                            { relation => "delete", href => "/1", method => "DELETE" },
                        ]
                    }
                 ],
                  '... got the right value for read'
              );
          }
      };

done_testing;