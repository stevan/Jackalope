#!/usr/bin/perl

use strict;
use warnings;

use Path::Router;

use Plack;
use Plack::Request;
use Plack::Builder;
use Plack::App::Path::Router;

use Jackalope;
use Jackalope::Serializer::JSON;

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
        my ($self, $type) = validated_list(\@_,
            type => { isa => "Str" },
        );
        $self->_process_schema( $self->get_spec->{schema_map}->{ $self->get_typemap->{ $type } } );
    }

    sub fetch_schema_by_id {
        my ($self, $id) = validated_list(\@_,
            id => { isa => "Str" },
        );
        $self->_process_schema( $self->get_spec->{schema_map}->{ $id } );
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
                controller => 'SpecServer',
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
                controller => 'SpecServer',
                action     => 'get_typemap'
            }
        },
        {
            relation      => "self",
            href          => "/fetch/schema",
            method        => "GET",
            schema        => {
                type       => "object",
                properties => {
                    id => { type => "string" }
                }
            },
            target_schema => { '$ref' => 'schema/types/object' },
            metadata      => {
                controller => 'SpecServer',
                action     => 'fetch_schema_by_id'
            }
        },
        {
            relation      => "self",
            href          => "/fetch/meta/schema",
            method        => "GET",
            schema        => {
                type       => "object",
                properties => {
                    type => { type => "string" }
                }
            },
            target_schema => { '$ref' => 'schema/types/schema' },
            metadata      => {
                controller => 'SpecServer',
                action     => 'fetch_meta_schema_by_type'
            }
        }
    ]
});

my $spec_server = $repo->compiled_schemas->{'web/spec_server'};

my $serializer = Jackalope::Serializer::JSON->new;

my %CONTROLLERS = (
    SpecServer => Jackalope::Web::Services::SpecServer->new(
        spec => Jackalope::Schema::Spec->new
    )
);

my $router = Path::Router->new;

foreach my $link ( @{ $spec_server->{links} } ) {
    $router->add_route(
        $link->{href},
        target => sub {
            my $r = shift;

            my $params;
            if ( exists $link->{schema} ) {
                my $schema = $link->{schema};

                if ( $link->{method} eq 'GET' ) {
                    $params = $r->query_parameters->as_hashref_mixed;
                }
                elsif ( $link->{method} eq 'POST' || $link->{method} eq 'PUT' ) {
                    $params = $serializer->deserialize( $r->content );
                }

                my $result = $repo->validate( $schema, $params );
                if ($result->{error}) {
                    return [ 500, [], [ "Params failed to validate"] ];
                }
            }

            my $controller = $CONTROLLERS{ $link->{metadata}->{controller} };
            my $action     = $controller->can( $link->{metadata}->{action} );
            my $output     = $controller->$action( %$params );

            if ( exists $link->{target_schema} ) {
                my $result = $repo->validate( $link->{target_schema}, $output );
                if ($result->{error}) {
                    return [ 500, [], [ "Output didn't match the target_schema"] ];
                }
            }

            return [ 200, [], [ $serializer->serialize( $output, { pretty => 1 } ) ] ];
        }
    );
}


builder {
    enable "Plack::Middleware::Static" => (
        path => sub { s!^/static/!! },
        root => './root/static/'
    );
    Plack::App::Path::Router->new( router => $router );
};


