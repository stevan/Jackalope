#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/CPAN/current/Bread-Board/lib';

use Bread::Board;

use Moose::Util::TypeConstraints 'enum';
use Path::Router;

use Plack;
use Plack::Request;
use Plack::Builder;
use Plack::App::Path::Router;

use Jackalope;
use Jackalope::Web::RouteBuilder;

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

my $repo = $j->resolve( type => 'Jackalope::Schema::Repository' );
$repo->register_schema({
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
                # TODO
                # fragment resolution, this should be
                # something like a ref to #propeties.typemap
                # of something similar
                # - SL
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
                    type => enum([ $repo->spec->valid_types ])
                }
            }
        }
    ]
});


my $c = container $j => as {

    typemap 'Jackalope::Web::Services::SpecServer' => infer;

    service 'router_config' => (
        block        => sub { $repo->compiled_schemas->{'web/spec_server'}->{'links'} },
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

    service 'Router' => (
        block => sub {
            my $s       = shift;
            my $router  = Path::Router->new;
            my $service = $s->parent->get_service('router_config');
            my $links   = $service->get;

            foreach my $link ( @$links ) {
                $router->add_route(
                    @{
                        Jackalope::Web::RouteBuilder->new(
                            link_spec => $link,
                            service   => $service
                        )->compile_routes
                    }
                )
            }

            $router;
        }
    );
};



builder {
    enable "Plack::Middleware::Static" => (
        path => sub { s!^/static/!! },
        root => './root/static/'
    );
    Plack::App::Path::Router->new( router => $c->resolve( service => 'Router' ) );
};


