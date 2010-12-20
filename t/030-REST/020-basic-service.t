#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/CPAN/current/Bread-Board/lib',
        '/Users/stevan/Projects/CPAN/current/Plack-App-Path-Router/lib';

use Test::More;
use Test::Fatal;
use Test::Moose;
use Bread::Board;
use Plack::Test;
use HTTP::Request::Common qw[ GET PUT POST DELETE ];

BEGIN {
    use_ok('Jackalope::REST');
}

use Jackalope::REST::Resource::Repository::Simple;

use Plack;
use Plack::Builder;
use Plack::App::Path::Router::PSGI;

my $j = Jackalope::REST->new;
my $c = container $j => as {

    service 'MySchema' => {
        id         => 'simple/person',
        title      => 'This is a simple person schema',
        extends    => { '$ref' => 'schema/web/service/crud' },
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
isa_ok($service, 'Jackalope::REST::CRUD::Service');
does_ok($service, 'Jackalope::REST::Service');

isa_ok($service->schema_repository, 'Jackalope::Schema::Repository');
isa_ok($service->resource_repository, 'Jackalope::REST::Resource::Repository::Simple');
does_ok($service->resource_repository, 'Jackalope::REST::Resource::Repository');
is_deeply($service->schema, {
    id         => 'simple/person',
    title      => 'This is a simple person schema',
    extends    => { '$ref' => 'schema/web/service/crud' },
    properties => {
        first_name => { type => 'string' },
        last_name  => { type => 'string' },
        age        => { type => 'integer', greater_than => 0 },
    }
}, '... got the schema we expected');
isa_ok($service->router, 'Path::Router');

my $app = Plack::App::Path::Router::PSGI->new( router => $service->router );

my $serializer = $c->resolve(
    service    => 'Jackalope::Serializer',
    parameters => { 'format' => 'JSON' }
);

test_psgi( app => $app, client => sub {
    my $cb = shift;

    diag("Listing resources (expecting empty set)");
    {
        my $req = GET("http://localhost/");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for list ');
        is_deeply(
           $serializer->deserialize( $res->content ),
           [],
            '... got the right value for list'
        );
    }

    diag("POSTing resource");
    {
        my $req = POST("http://localhost/create" => (
            Content => '{"first_name":"Stevan","last_name":"Little","age":37}'
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for creation');
        is($res->header('Location'), '1', '... got the right URL for the item');
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
                    { rel => "create",      href => "create",   method => "POST"   },
                    { rel => "delete",      href => "1/delete", method => "DELETE" },
                    { rel => "describedby", href => "schema",   method => "GET"    },
                    { rel => "edit",        href => "1/edit",   method => "PUT"    },
                    { rel => "list",        href => "",         method => "GET"    },
                    { rel => "read",        href => "1",        method => "GET"    }
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("Error check");
    {
        my $req = POST("http://localhost/create" => (
            Content => '{"first_name":"Stevan","last_name":"Little"}'
        ));
        my $res = $cb->($req);
        is($res->code, 500, '... got the right status for this exception');
        like($res->content, qr/Params failed to validate against data_schema/, '... got the error we expected');
    }

    diag("Listing resources (expecting one in set)");
    {
        my $req = GET("http://localhost/");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for list');
        is_deeply(
            $serializer->deserialize( $res->content ),
            [
                {
                    id   => 1,
                    body => {
                        first_name => "Stevan",
                        last_name  => "Little",
                        age        => 37,
                    },
                    version => 'fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2',
                    links => [
                        { rel => "create",      href => "create",   method => "POST"   },
                        { rel => "delete",      href => "1/delete", method => "DELETE" },
                        { rel => "describedby", href => "schema",   method => "GET"    },
                        { rel => "edit",        href => "1/edit",   method => "PUT"    },
                        { rel => "list",        href => "",         method => "GET"    },
                        { rel => "read",        href => "1",        method => "GET"    }
                    ]
                },
            ],
            '... got the right value for list'
        );
    }

    diag("GETing resource we just posted");
    {
        my $req = GET("http://localhost/1");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for read');
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
                    { rel => "create",      href => "create",   method => "POST"   },
                    { rel => "delete",      href => "1/delete", method => "DELETE" },
                    { rel => "describedby", href => "schema",   method => "GET"    },
                    { rel => "edit",        href => "1/edit",   method => "PUT"    },
                    { rel => "list",        href => "",         method => "GET"    },
                    { rel => "read",        href => "1",        method => "GET"    }
                ]
            },
            '... got the right value for read'
        );
    }

    diag("Error check");
    {
        my $req = GET("http://localhost/2");
        my $res = $cb->($req);
        is($res->code, 404, '... got the right status for not found');
    }

    diag("PUTing updates to the resource we just posted");
    {
        my $req = PUT("http://localhost/1/edit" => (
            Content => '{"id":"1","version":"fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2","body":{"first_name":"Stevan","last_name":"Little","age":38}}'
        ));
        my $res = $cb->($req);
        is($res->code, 202, '... got the right status for edit');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    first_name => "Stevan",
                    last_name  => "Little",
                    age        => 38,
                },
                version => '9d4a75302bb634edf050d6b838b050b978bea1460d5879618e8e3ae8c291247f',
                links => [
                    { rel => "create",      href => "create",   method => "POST"   },
                    { rel => "delete",      href => "1/delete", method => "DELETE" },
                    { rel => "describedby", href => "schema",   method => "GET"    },
                    { rel => "edit",        href => "1/edit",   method => "PUT"    },
                    { rel => "list",        href => "",         method => "GET"    },
                    { rel => "read",        href => "1",        method => "GET"    }
                ]
            },
            '... got the right value for edit'
        );
    }

    diag("Error check");
    {
        my $req = PUT("http://localhost/1/edit" => (
            Content => '{"id":"1","versi":"fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2","body":{"first_name":"Stevan","last_name":"Little","age":38}}'
        ));
        my $res = $cb->($req);
        is($res->code, 500, '... got the right status for this exception');
        like($res->content, qr/Params failed to validate against data_schema/, '... got the error we expected');
    }
    {
        my $req = PUT("http://localhost/2/edit" => (
            Content => '{"id":"1","version":"fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2","body":{"first_name":"Stevan","last_name":"Little","age":38}}'
        ));
        my $res = $cb->($req);
        is($res->code, 400, '... got the right status for this exception');
        like($res->content, qr/the id does not match the id of the updated resource/, '... got the error we expected');
    }
    {
        my $req = PUT("http://localhost/2/edit" => (
            Content => '{"id":"2","version":"fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2","body":{"first_name":"Stevan","last_name":"Little","age":38}}'
        ));
        my $res = $cb->($req);
        is($res->code, 404, '... got the right status for not found');
    }
    {
        my $req = PUT("http://localhost/1/edit" => (
            Content => '{"id":"1","version":"fe982ce14ce2b2a1c09762decdeb1522a1e0a2ca390673446c930ca5fd11d2","body":{"first_name":"Stevan","last_name":"Little","age":38}}'
        ));
        my $res = $cb->($req);
        is($res->code, 409, '... got the right status for this exception');
        like($res->content, qr/resource submitted has out of date version/, '... got the error we expected');
    }


    diag("GETing resource we just updated");
    {
        my $req = GET("http://localhost/1" );
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for read');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    first_name => "Stevan",
                    last_name  => "Little",
                    age        => 38,
                },
                version => '9d4a75302bb634edf050d6b838b050b978bea1460d5879618e8e3ae8c291247f',
                links => [
                    { rel => "create",      href => "create",   method => "POST"   },
                    { rel => "delete",      href => "1/delete", method => "DELETE" },
                    { rel => "describedby", href => "schema",   method => "GET"    },
                    { rel => "edit",        href => "1/edit",   method => "PUT"    },
                    { rel => "list",        href => "",         method => "GET"    },
                    { rel => "read",        href => "1",        method => "GET"    }
                ]
            },
            '... got the right value for read'
        );
    }

    diag("Errors");
    {
        my $req = GET("http://localhost/1/delete");
        my $res = $cb->($req);
        is($res->code, 405, '... got the right status for bad method');
        is($res->header('Allow'), 'DELETE', '... got the right Allow header');
    }
    {
        my $req = DELETE("http://localhost/1/delete" => (
            'If-Matches' => '9d4a75302bb63df050d6b838b050b978bea1460d5879618e8e3ae8c291247f'
        ));
        my $res = $cb->($req);
        is($res->code, 409, '... got the right status for this exception');
        like($res->content, qr/resource submitted has out of date version/, '... got the error we expected');
    }

    diag("DELETEing resource we just updated (with conditional match)");
    {
        my $req = DELETE("http://localhost/1/delete" => (
            'If-Matches' => '9d4a75302bb634edf050d6b838b050b978bea1460d5879618e8e3ae8c291247f'
        ));
        my $res = $cb->($req);
        is($res->code, 204, '... got the right status for delete');
        is_deeply( $res->content, '', '... got the right value for delete' );
    }

    diag("Listing resources (expecting empty set)");
    {
        my $req = GET( "http://localhost/");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for list ');
        is_deeply(
           $serializer->deserialize( $res->content ),
           [],
            '... got the right value for list'
        );
    }

    diag("POSTing resource");
    {
        my $req = POST("http://localhost/create" => (
            Content => '{"first_name":"Stevan","last_name":"Little","age":37}'
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for creation');
        is($res->header('Location'), '2', '... got the right URL for the item');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 2,
                body => {
                    first_name => "Stevan",
                    last_name  => "Little",
                    age        => 37,
                },
                version => 'fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2',
                links => [
                    { rel => "create",      href => "create",   method => "POST"   },
                    { rel => "delete",      href => "2/delete", method => "DELETE" },
                    { rel => "describedby", href => "schema",   method => "GET"    },
                    { rel => "edit",        href => "2/edit",   method => "PUT"    },
                    { rel => "list",        href => "",         method => "GET"    },
                    { rel => "read",        href => "2",        method => "GET"    }
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("DELETEing resource we just updated (without conditional match)");
    {
        my $req = DELETE("http://localhost/2/delete");
        my $res = $cb->($req);
        is($res->code, 204, '... got the right status for delete');
        is_deeply( $res->content, '', '... got the right value for delete' );
    }

    diag("Listing resources (expecting empty set)");
    {
        my $req = GET( "http://localhost/");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for list ');
        is_deeply(
           $serializer->deserialize( $res->content ),
           [],
            '... got the right value for list'
        );
    }

    diag("Calling the DescribedBy");
    {
        my $req = GET( "http://localhost/schema");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for list ');
        is_deeply(
           $serializer->deserialize( $res->content ),
           {
               id         => 'simple/person',
               title      => 'This is a simple person schema',
               extends    => { '$ref' => 'schema/web/service/crud' },
               properties => {
                   first_name => { type => 'string' },
                   last_name  => { type => 'string' },
                   age        => { type => 'integer', greater_than => 0 },
               }
           },
            '... got the right value for list'
        );
    }

    diag("Errors");
    {
        my $req = POST("http://localhost/schema");
        my $res = $cb->($req);
        is($res->code, 405, '... got the right status for bad method');
        is($res->header('Allow'), 'GET', '... got the right Allow header');
    }

});


done_testing;