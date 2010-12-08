#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/CPAN/current/Bread-Board/lib';

use Bread::Board;

use Plack;
use Plack::Builder;
use Plack::App::Path::Router;

use Jackalope;
use Jackalope::Web::Service;

{
    package Jackalope::Web::Services::SpecServer;
    use Moose;

    has 'spec' => (
        is       => 'ro',
        isa      => 'Jackalope::Schema::Spec',
        required => 1,
        handles  => {
            'get_spec'    => 'get_spec',
            'get_typemap' => 'typemap'
        }
    );

    sub fetch_meta_schema_by_type {
        my ($self, $type) = @_;
        $self->_process_schema( $self->get_spec->{schema_map}->{ $self->get_typemap->{ $type } } );
    }

    sub fetch_schema_by_id {
        my ($self, $params) = @_;
        $self->_process_schema( $self->get_spec->{schema_map}->{ $params->{id} } );
    }

    sub _process_schema {
        my $self = shift;
        return Data::Visitor::Callback->new(
            hash => sub {
                my ($v, $data) = @_;
                if (exists $data->{'description'} && not ref $data->{'description'}) {
                    $data->{'description'} =~ s/^\n\s+//;
                    $data->{'description'} =~ s/\n\s*/ /g;
                    $data->{'description'} =~ s/\s*$//g;
                }
                return $data;
            }
        )->visit( shift );
    }

}

my $j = Jackalope->new;
my $c = container $j => as {

    typemap 'Jackalope::Web::Services::SpecServer' => infer;

    service 'SpecService' => (
        block => sub {
            my $s = shift;
            Jackalope::Web::Service->new(
                service => $s,
                schema  => {
                    id      => "web/spec_server",
                    type    => "object",
                    extends => { '$ref' => "schema/core/spec" },
                    links   => [
                        {
                            relation      => "self",
                            href          => "/spec",
                            method        => "GET",
                            target_schema => { '$ref' => '#' },
                            metadata      => {
                                controller => 'spec_server',
                                action     => 'get_spec'
                            }
                        },
                        {
                            relation      => "self",
                            href          => "/typemap",
                            method        => "GET",
                            target_schema => {
                                type  => "object",
                                items => { type => "string", 'format' => "uri" },
                            },
                            metadata      => {
                                controller => 'spec_server',
                                action     => 'get_typemap'
                            }
                        },
                        {
                            relation      => "self",
                            href          => "/fetch/schema",
                            method        => 'GET',
                            schema        => {
                                type       => "object",
                                properties => {
                                    id => { type => "string" }
                                }
                            },
                            target_schema => { '$ref' => 'schema/types/object' },
                            metadata      => {
                                controller => 'spec_server',
                                action     => 'fetch_schema_by_id'
                            }
                        },
                        {
                            relation      => "self",
                            href          => "/fetch/:type/schema",
                            uri_schema    => {
                                type       => "object",
                                properties => {
                                    type => {
                                        type => "string",
                                        enum => [ $s->param('repo')->spec->valid_types ]
                                    }
                                }
                            },
                            target_schema => { '$ref' => 'schema/types/schema' },
                            metadata      => {
                                controller  => 'spec_server',
                                action      => 'fetch_meta_schema_by_type',
                            }
                        }
                    ]
                }
            );
        },
        dependencies => {
            spec_server => 'type:Jackalope::Web::Services::SpecServer',
            repo        => 'type:Jackalope::Schema::Repository',
            serializer  => {
                'Jackalope::Serializer' => {
                    'format'         => 'JSON',
                    'default_params' => { pretty => 1 }
                }
            }
        }
    );
};



builder {
    enable "Plack::Middleware::Static" => (
        path => sub { s!^/static/!! },
        root => './root/static/'
    );
    Plack::App::Path::Router->new(
        router => $c->resolve( service => 'SpecService' )->get_router
    );
};


