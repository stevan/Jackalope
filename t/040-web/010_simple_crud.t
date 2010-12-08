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

    has 'id_counter' => (
        traits  => [ 'Counter' ],
        is      => 'bare',
        isa     => 'Int',
        default => 0,
        handles => {
            'get_next_id' => 'inc'
        }
    );

    has 'db' => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { +{} },
    );

    sub create {
        my ($self, $person) = @_;
        my $id = $self->get_next_id;
        $person->{id} = $id;
        $self->db->{ $id } = $person;
        return $id;
    }

    sub read {
        my ($self, $id) = @_;
        return $self->db->{ $id };
    }

    sub update {
        my ($self, $id, $person) = @_;
        $self->db->{ $id } = $person;
        return;
    }

    sub delete {
        my ($self, $id) = @_;
        delete $self->db->{ $id };
        return;
    }
}

my $j = Jackalope->new;
my $c = container $j => as {

    typemap 'Simple::CRUD::PersonManager' => infer;

    service 'SimpleCRUDPerson' => (
        block => sub {
            my $s = shift;
            Jackalope::Web::Service->new(
                service => $s,
                schema  => {
                    id         => 'simple/crud/person',
                    title      => 'This is a simple person schema',
                    type       => 'object',
                    properties => {
                        id         => { type => 'integer' },
                        first_name => { type => 'string' },
                        last_name  => { type => 'string' },
                        age        => { type => 'integer', greater_than => 0 },
                        sex        => { type => 'string', enum => [qw[ male female ]] }
                    },
                    links => [
                        {
                            relation => 'create',
                            href     => '/create',
                            method   => 'PUT',
                            schema   => { '$ref' => '#' },
                            metadata => {
                                controller => 'person_manager',
                                action     => 'create'
                            }
                        },
                        {
                            relation      => 'self',
                            href          => '/:id',
                            method        => 'GET',
                            target_schema => { '$ref' => '#' },
                            uri_schema    => {
                                type       => 'object',
                                properties => {
                                    id => { type => 'integer' }
                                }
                            },
                            metadata => {
                                controller => 'person_manager',
                                action     => 'read'
                            }
                        },
                        {
                            relation      => 'self',
                            href          => '/:id/update',
                            method        => 'POST',
                            schema        => { '$ref' => '#' },
                            uri_schema    => {
                                type       => 'object',
                                properties => {
                                    id => { type => 'integer' }
                                }
                            },
                            metadata => {
                                controller => 'person_manager',
                                action     => 'update'
                            }
                        },
                        {
                            relation      => 'self',
                            href          => '/:id/delete',
                            method        => 'DELETE',
                            uri_schema    => {
                                type       => 'object',
                                properties => {
                                    id => { type => 'integer' }
                                }
                            },
                            metadata => {
                                controller => 'person_manager',
                                action     => 'delete'
                            }
                        }
                    ]
                }
            );
        },
        dependencies => {
            person_manager => 'type:Simple::CRUD::PersonManager',
            repo           => 'type:Jackalope::Schema::Repository',
            serializer     => {
                'Jackalope::Serializer' => {
                    'format'         => 'JSON',
                    'default_params' => { canonical => 1 }
                }
            }
        }
    );
};

my $app = Plack::App::Path::Router->new(
    router => $c->resolve( service => 'SimpleCRUDPerson' )->get_router
);

test_psgi
      app    => $app,
      client => sub {
          my $cb = shift;
          {
              my $req = PUT( "http://localhost/create" => (
                  Content => '{"id":-1,"first_name":"Stevan","last_name":"Little","age":37,"sex":"male"}'
              ));
              my $res = $cb->($req);
              is($res->code, 201, '... got the right status for create');
              is($res->content, '', '... got the right value for create');
          }
          {
              my $req = GET( "http://localhost/1");
              my $res = $cb->($req);
              is($res->code, 200, '... got the right status for read');
              is($res->content, '{"age":37,"first_name":"Stevan","id":1,"last_name":"Little","sex":"male"}', '... got the right value for read');
          }
          {
              my $req = POST( "http://localhost/1/update" => (
                  Content => '{"id":1,"first_name":"Stevie","last_name":"Little","age":36,"sex":"male"}'
              ));
              my $res = $cb->($req);
              is($res->code, 202, '... got the right status for update');
              is($res->content, '', '... got the right value for update');
          }
      };

done_testing;