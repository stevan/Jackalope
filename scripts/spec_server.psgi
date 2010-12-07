#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/CPAN/current/Bread-Board/lib';

use Bread::Board;
use Moose::Util::TypeConstraints 'enum';

use Plack;
use Plack::Request;
use Plack::Builder;
use Plack::App::Path::Router;

use Jackalope;
use Jackalope::Web::Service;

{
    package Jackalope::Web::Services::SpecServer;
    use Moose;
    use MooseX::Params::Validate;

    has 'spec' => (
        is       => 'ro',
        isa      => 'Jackalope::Schema::Spec',
        required => 1
    );

    sub get_spec    { (shift)->spec->get_spec }
    sub get_typemap { (shift)->spec->typemap  }

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
                            target_schema => { '$ref' => 'schema/types/schema' },
                            metadata      => {
                                controller  => 'spec_server',
                                action      => 'fetch_meta_schema_by_type',
                                validations => {
                                    type => enum([ $s->param('repo')->spec->valid_types ])
                                }
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


