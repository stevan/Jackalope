#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/CPAN/current/Bread-Board/lib',
        '/Users/stevan/Projects/CPAN/current/Plack-App-Path-Router/lib';

use Bread::Board;
use Path::Router;
use Jackalope::REST;
use Jackalope::REST::Resource::Repository::Simple;

use Plack;
use Plack::Builder;
use Plack::App::Path::Router::PSGI;

my $j = Jackalope::REST->new;
my $c = container $j => as {

    service 'MySchema' => {
        id         => 'simple/person',
        title      => 'This is a simple person schema',
        extends    => { '$ref' => 'schema/web/service' },
        properties => {
            first_name => { type => 'string' },
            last_name  => { type => 'string' },
            age        => { type => 'integer', greater_than => 0 },
        }
    };

    typemap 'Jackalope::REST::Resource::Repository::Simple' => infer;

    service 'MyService' => (
        class        => 'Jackalope::REST::CRUD::Service',
        dependencies => {
            schema_repository   => 'type:Jackalope::Schema::Repository',
            resource_repository => 'type:Jackalope::REST::Resource::Repository::Simple',
            schema              => 'MySchema',
            serializer          => {
                'Jackalope::Serializer' => {
                    'format' => 'JSON'
                }
            }
        }
    );
};

my $service = $c->resolve( service => 'MyService' );
my $router  = Path::Router->new;
$router->add_route( '/' => (
    target => sub {
        [ 302, [ 'Location' => 'static/index.html' ], []]
    }
));
$router->include_router( 'people/' => $service->router );
$service->update_router( $router );

my $app = Plack::App::Path::Router::PSGI->new( router => $router );

builder {
    enable "Plack::Middleware::Static" => (
        path => sub { s!^/static/!! },
        root => './htdocs/'
    );
    $app;
};

