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
use Path::Router;

use Plack;
use Plack::Builder;
use Plack::App::Path::Router::PSGI;

{
    package My::ShoppingCart::Repo;
    use Moose;
    use Clone 'clone';
    use Jackalope::REST::Error::NotImplemented;

    extends 'Jackalope::REST::Resource::Repository::Simple';

    has [ 'product_service', 'user_service' ] => (
        is       => 'ro',
        isa      => 'Jackalope::REST::Service',
        required => 1,
    );

    sub list   { Jackalope::REST::Error::NotImplemented->throw("List is not supported") }
    sub update { Jackalope::REST::Error::NotImplemented->throw("Update is not supported") }

    sub create {
        my ($self, $data) = @_;
        my $id = $self->get_next_id;
        $self->db->{ $id } = $data;
        return ( $id, $self->inflate_user_and_items( clone( $data ) ) );
    }

    sub get {
        my ($self, $id) = @_;
        return unless $self->db->{ $id };
        return $self->inflate_user_and_items( clone( $self->db->{ $id } ) );
    }

    sub add_item {
        my ($self, $id, $data) = @_;
        my $cart = $self->db->{ $id };
        (defined $cart)
            || Jackalope::REST::Error::ResourceNotFound->throw("no cart for id ($id)");
        push @{ $cart->{'items'} } => $data;
        return $self->wrap_data(
            $id,
            $self->inflate_user_and_items( clone( $cart ) )
        );
    }

    sub remove_item {
        my ($self, $id, $data) = @_;

        my $cart = $self->db->{ $id };
        $cart->{'items'} = [ grep { $_->{'$id'} != $data->{'$id'} } @{ $cart->{'items'} } ];
        return $self->wrap_data(
            $id,
            $self->inflate_user_and_items( clone( $cart ) )
        );
    }

    sub inflate_user_and_items {
        my ($self, $cart) = @_;

        my $user = $self->user_service->resource_repository->get_resource( $cart->{'user'}->{'$id'} );
        $self->user_service->generate_links_for_resource( $user );
        $cart->{'user'} = $user->pack;

        $cart->{'items'} = [
            map {
                my $product = $self->product_service->resource_repository->get_resource( $_->{'$id'} );
                $self->product_service->generate_links_for_resource( $product );
                $product->pack;
            } @{ $cart->{'items'} }
        ];

        $cart;
    }
}

{
    package My::ShoppingCart::Target::AddItem;
    use Moose;

    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, @args) = @_;
        my ($resource, $error) = $self->process_operation( 'add_item' => ( $r, @args ) );
        return $error if $error;
        return $self->process_psgi_output([ 202, [], [ $resource ] ]);
    }
}

{
    package My::ShoppingCart::Target::RemoveItem;
    use Moose;

    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, @args) = @_;
        my ($resource, $error) = $self->process_operation( 'remove_item' => ( $r, @args ) );
        return $error if $error;
        return $self->process_psgi_output([ 202, [], [ $resource ] ]);
    }
}

my $j = Jackalope::REST->new;
my $c = container $j => as {

    typemap 'Jackalope::REST::Resource::Repository::Simple' => infer;

    service 'ProductSchema' => {
        id         => "test/product",
        extends    => { '$ref' => 'schema/web/service' },
        properties => {
            sku  => { type => "string" },
            desc => { type => "string" }
        }
    };

    service 'ProductService' => (
        lifecycle    => 'Singleton',
        class        => 'Jackalope::REST::Service',
        dependencies => {
            schema_repository   => 'type:Jackalope::Schema::Repository',
            resource_repository => 'type:Jackalope::REST::Resource::Repository::Simple',
            schema              => 'ProductSchema',
            serializer          => {
                'Jackalope::Serializer' => {
                    'format' => 'JSON'
                }
            }
        }
    );

    service 'UserSchema' => {
        id         => "test/user",
        extends    => { '$ref' => 'schema/web/service' },
        properties => {
            username => { type => "string" }
        }
    };

    service 'UserService' => (
        lifecycle    => 'Singleton',
        class        => 'Jackalope::REST::Service',
        dependencies => {
            schema_repository   => 'type:Jackalope::Schema::Repository',
            resource_repository => 'type:Jackalope::REST::Resource::Repository::Simple',
            schema              => 'UserSchema',
            serializer          => {
                'Jackalope::Serializer' => {
                    'format' => 'JSON'
                }
            }
        }
    );

    service 'ShoppingCartSchema' => {
        id         => "test/shoppingcart",
        type       => "object",
        properties => {
            user => {
                extends    => { '$ref' => "schema/web/resource" },
                properties => { body => { '$ref' => "test/user" } }
            },
            items  => {
                type  => "array",
                items => {
                    extends    => { '$ref' => "schema/web/resource" },
                    properties => { body => { '$ref' => "test/product" } }
                }
            }
        },
        links => [
            # skipping the described-by, which you would do in real life ...
            {
                rel           => 'create',
                href          => '/create',
                method        => 'POST',
                data_schema   => {
                    type       => 'object',
                    properties => {
                        user  => {
                            extends    => { '$ref' => 'schema/web/resource/ref' },
                            properties => { type_of => { type => "string", literal => "test/user" } }
                        },
                        items => {
                            type  => 'array',
                            items => {
                                extends    => { '$ref' => 'schema/web/resource/ref' },
                                properties => { type_of => { type => "string", literal => "test/product" } }
                            }
                        },
                    }
                },
                target_schema => {
                    type       => 'object',
                    extends    => { '$ref' => 'schema/web/resource' },
                    properties => {
                        body => { '$ref' => '#' },
                    }
                },
            },
            {
                rel           => 'read',
                href          => '/:id',
                method        => 'GET',
                target_schema => {
                    type       => 'object',
                    extends    => { '$ref' => 'schema/web/resource' },
                    properties => {
                        body => { '$ref' => '#' },
                    }
                },
                uri_schema    => {
                    id => { type => 'string' }
                }
            },
            {
                rel           => 'my/shoppingCart/target/addItem',
                href          => '/:id/add_item',
                method        => 'PUT',
                data_schema   => {
                    extends    => { '$ref' => 'schema/web/resource/ref' },
                    properties => { type_of => { type => "string", literal => "test/product" } }
                },
                target_schema => {
                    type       => 'object',
                    extends    => { '$ref' => 'schema/web/resource' },
                    properties => {
                        body => { '$ref' => '#' },
                    }
                },
                uri_schema    => {
                    id => { type => 'string' }
                }
            },
            {
                rel           => 'my/shoppingCart/target/removeItem',
                href          => '/:id/remove_item',
                method        => 'PUT',
                data_schema   => {
                    extends    => { '$ref' => 'schema/web/resource/ref' },
                    properties => { type_of => { type => "string", literal => "test/product" } }
                },
                target_schema => {
                    type       => 'object',
                    extends    => { '$ref' => 'schema/web/resource' },
                    properties => {
                        body => { '$ref' => '#' },
                    }
                },
                uri_schema    => {
                    id => { type => 'string' }
                }
            },
            {
                rel           => 'delete',
                href          => '/:id/delete',
                method        => 'DELETE',
                uri_schema    => {
                    id => { type => 'string' }
                }
            }
        ]
    };

    service 'MyShoppingCartRepo' => (
        class        => 'My::ShoppingCart::Repo',
        dependencies => {
            product_service => 'ProductService',
            user_service    => 'UserService',
        }
    );

    service 'ShoppingCartService' => (
        lifecycle    => 'Singleton',
        class        => 'Jackalope::REST::Service',
        dependencies => {
            schema_repository   => 'type:Jackalope::Schema::Repository',
            resource_repository => 'MyShoppingCartRepo',
            schema              => 'ShoppingCartSchema',
            serializer          => {
                'Jackalope::Serializer' => {
                    'format' => 'JSON'
                }
            }
        }
    );

};

my $product_service = $c->resolve( service => 'ProductService' );
my $user_service    = $c->resolve( service => 'UserService' );
my $cart_service    = $c->resolve( service => 'ShoppingCartService' );

my $router = Path::Router->new;
$router->include_router( 'product/' => $product_service->router );
$router->include_router( 'user/'    => $user_service->router );
$router->include_router( 'cart/'    => $cart_service->router );

foreach my $service ( $product_service, $user_service, $cart_service ) {
    $service->update_router( $router );
}

my $app = Plack::App::Path::Router::PSGI->new( router => $router );

my $serializer = $c->resolve(
    service    => 'Jackalope::Serializer',
    parameters => { 'format' => 'JSON' }
);

test_psgi( app => $app, client => sub {
    my $cb = shift;

    diag("POST-ing user");
    {
        my $req = POST("http://localhost/user/create" => (
            Content => '{"username":"stevan"}'
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for creation');
        is($res->header('Location'), 'user/1', '... got the right URL for the item');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    username => 'stevan'
                },
                version => '7f53a57fae8a7548af8677e60a46c2526d85569b1752ac679b376880bdd4f2a2',
                links => [
                    { rel => "describedby", href => "user/schema",   method => "GET"    },
                    { rel => "list",        href => "user",          method => "GET"    },
                    { rel => "create",      href => "user/create",   method => "POST"   },
                    { rel => "read",        href => "user/1",        method => "GET"    },
                    { rel => "edit",        href => "user/1/edit",   method => "PUT"    },
                    { rel => "delete",      href => "user/1/delete", method => "DELETE" },
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("GET-ing user");
    {
        my $req = GET("http://localhost/user/1");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for read');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    username => 'stevan'
                },
                version => '7f53a57fae8a7548af8677e60a46c2526d85569b1752ac679b376880bdd4f2a2',
                links => [
                    { rel => "describedby", href => "user/schema",   method => "GET"    },
                    { rel => "list",        href => "user",          method => "GET"    },
                    { rel => "create",      href => "user/create",   method => "POST"   },
                    { rel => "read",        href => "user/1",        method => "GET"    },
                    { rel => "edit",        href => "user/1/edit",   method => "PUT"    },
                    { rel => "delete",      href => "user/1/delete", method => "DELETE" },
                ]
            },
            '... got the right value for read'
        );
    }

    diag("POST-ing product");
    {
        my $req = POST("http://localhost/product/create" => (
            Content => '{"sku":"123456","desc":"disco-ball"}'
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for creation');
        is($res->header('Location'), 'product/1', '... got the right URL for the item');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    sku  => "123456",
                    desc => "disco-ball"
                },
                version => '07c302816348f4e67f0a8f3701aca90330c65a5030f48a2dbb891bcc6c18520d',
                links => [
                    { rel => "describedby", href => "product/schema",   method => "GET"    },
                    { rel => "list",        href => "product",          method => "GET"    },
                    { rel => "create",      href => "product/create",   method => "POST"   },
                    { rel => "read",        href => "product/1",        method => "GET"    },
                    { rel => "edit",        href => "product/1/edit",   method => "PUT"    },
                    { rel => "delete",      href => "product/1/delete", method => "DELETE" },
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("POST-ing product");
    {
        my $req = POST("http://localhost/product/create" => (
            Content => '{"sku":"227272","desc":"dancin-shoes"}'
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for creation');
        is($res->header('Location'), 'product/2', '... got the right URL for the item');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 2,
                body => {
                    sku  => "227272",
                    desc => "dancin-shoes"
                },
                version => 'd2e63b1870594d57bc16999e7f61e1f84fe91ba1cd47388a85d52fda206cb1cc',
                links => [
                    { rel => "describedby", href => "product/schema",   method => "GET"    },
                    { rel => "list",        href => "product",          method => "GET"    },
                    { rel => "create",      href => "product/create",   method => "POST"   },
                    { rel => "read",        href => "product/2",        method => "GET"    },
                    { rel => "edit",        href => "product/2/edit",   method => "PUT"    },
                    { rel => "delete",      href => "product/2/delete", method => "DELETE" },
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("POST-ing product");
    {
        my $req = POST("http://localhost/product/create" => (
            Content => '{"sku":"3838372","desc":"polyester-suit"}'
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for creation');
        is($res->header('Location'), 'product/3', '... got the right URL for the item');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 3,
                body => {
                    sku  => "3838372",
                    desc => "polyester-suit"
                },
                version => 'e13d199dae9e277e852c79b236106d4727ed52be9bee385c39fa66c9475aa4ff',
                links => [
                    { rel => "describedby", href => "product/schema",   method => "GET"    },
                    { rel => "list",        href => "product",          method => "GET"    },
                    { rel => "create",      href => "product/create",   method => "POST"   },
                    { rel => "read",        href => "product/3",        method => "GET"    },
                    { rel => "edit",        href => "product/3/edit",   method => "PUT"    },
                    { rel => "delete",      href => "product/3/delete", method => "DELETE" },
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("POST-ing cart");
    {
        my $req = POST("http://localhost/cart/create" => (
            Content => $serializer->serialize({
                user  => { '$id' => '1', type_of => 'test/user' },
                items => [
                    { '$id' => '1', type_of => 'test/product' },
                    { '$id' => '2', type_of => 'test/product' }
                ]
            })
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for creation');
        is($res->header('Location'), 'cart/1', '... got the right URL for the item');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    user => {
                        id   => 1,
                        body => {
                            username => 'stevan'
                        },
                        version => '7f53a57fae8a7548af8677e60a46c2526d85569b1752ac679b376880bdd4f2a2',
                        links => [
                            { rel => "describedby", href => "user/schema",   method => "GET"    },
                            { rel => "list",        href => "user",          method => "GET"    },
                            { rel => "create",      href => "user/create",   method => "POST"   },
                            { rel => "read",        href => "user/1",        method => "GET"    },
                            { rel => "edit",        href => "user/1/edit",   method => "PUT"    },
                            { rel => "delete",      href => "user/1/delete", method => "DELETE" },
                        ]
                    },
                    items => [
                        {
                            id   => 1,
                            body => {
                                sku  => "123456",
                                desc => "disco-ball"
                            },
                            version => '07c302816348f4e67f0a8f3701aca90330c65a5030f48a2dbb891bcc6c18520d',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/1",        method => "GET"    },
                                { rel => "edit",        href => "product/1/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/1/delete", method => "DELETE" },
                            ]
                        },
                        {
                            id   => 2,
                            body => {
                                sku  => "227272",
                                desc => "dancin-shoes"
                            },
                            version => 'd2e63b1870594d57bc16999e7f61e1f84fe91ba1cd47388a85d52fda206cb1cc',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/2",        method => "GET"    },
                                { rel => "edit",        href => "product/2/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/2/delete", method => "DELETE" },
                            ]
                        }
                    ]
                },
                version => '6f2b0ecaeb1dfc8fc50c2bb0cae7c685969793ea2aee5016dd2075c76ae40a94',
                links => [
                    { rel => "create",                         href => "cart/create",     method => "POST"   },
                    { rel => "read",                           href => "cart/1",          method => "GET"    },
                    { rel => "my/shoppingCart/target/addItem", href => "cart/1/add_item", method => "PUT"    },
                    { rel => "my/shoppingCart/target/removeItem", href => "cart/1/remove_item", method => "PUT"    },
                    { rel => "delete",                         href => "cart/1/delete",   method => "DELETE" },
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("GET-ing cart");
    {
        my $req = GET("http://localhost/cart/1");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for creation');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    user => {
                        id   => 1,
                        body => {
                            username => 'stevan'
                        },
                        version => '7f53a57fae8a7548af8677e60a46c2526d85569b1752ac679b376880bdd4f2a2',
                        links => [
                            { rel => "describedby", href => "user/schema",   method => "GET"    },
                            { rel => "list",        href => "user",          method => "GET"    },
                            { rel => "create",      href => "user/create",   method => "POST"   },
                            { rel => "read",        href => "user/1",        method => "GET"    },
                            { rel => "edit",        href => "user/1/edit",   method => "PUT"    },
                            { rel => "delete",      href => "user/1/delete", method => "DELETE" },
                        ]
                    },
                    items => [
                        {
                            id   => 1,
                            body => {
                                sku  => "123456",
                                desc => "disco-ball"
                            },
                            version => '07c302816348f4e67f0a8f3701aca90330c65a5030f48a2dbb891bcc6c18520d',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/1",        method => "GET"    },
                                { rel => "edit",        href => "product/1/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/1/delete", method => "DELETE" },
                            ]
                        },
                        {
                            id   => 2,
                            body => {
                                sku  => "227272",
                                desc => "dancin-shoes"
                            },
                            version => 'd2e63b1870594d57bc16999e7f61e1f84fe91ba1cd47388a85d52fda206cb1cc',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/2",        method => "GET"    },
                                { rel => "edit",        href => "product/2/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/2/delete", method => "DELETE" },
                            ]
                        }
                    ]
                },
                version => '6f2b0ecaeb1dfc8fc50c2bb0cae7c685969793ea2aee5016dd2075c76ae40a94',
                links => [
                    { rel => "create",                         href => "cart/create",     method => "POST"   },
                    { rel => "read",                           href => "cart/1",          method => "GET"    },
                    { rel => "my/shoppingCart/target/addItem", href => "cart/1/add_item", method => "PUT"    },
                    { rel => "my/shoppingCart/target/removeItem", href => "cart/1/remove_item", method => "PUT"    },
                    { rel => "delete",                         href => "cart/1/delete",   method => "DELETE" },
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("PUT-ing a new item");
    {
        my $req = PUT("http://localhost/cart/1/add_item" => (
            Content => '{"$id":"3","type_of":"test/product"}'
        ));
        my $res = $cb->($req);
        is($res->code, 202, '... got the right status for adding an item');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    user => {
                        id   => 1,
                        body => {
                            username => 'stevan'
                        },
                        version => '7f53a57fae8a7548af8677e60a46c2526d85569b1752ac679b376880bdd4f2a2',
                        links => [
                            { rel => "describedby", href => "user/schema",   method => "GET"    },
                            { rel => "list",        href => "user",          method => "GET"    },
                            { rel => "create",      href => "user/create",   method => "POST"   },
                            { rel => "read",        href => "user/1",        method => "GET"    },
                            { rel => "edit",        href => "user/1/edit",   method => "PUT"    },
                            { rel => "delete",      href => "user/1/delete", method => "DELETE" },
                        ]
                    },
                    items => [
                        {
                            id   => 1,
                            body => {
                                sku  => "123456",
                                desc => "disco-ball"
                            },
                            version => '07c302816348f4e67f0a8f3701aca90330c65a5030f48a2dbb891bcc6c18520d',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/1",        method => "GET"    },
                                { rel => "edit",        href => "product/1/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/1/delete", method => "DELETE" },
                            ]
                        },
                        {
                            id   => 2,
                            body => {
                                sku  => "227272",
                                desc => "dancin-shoes"
                            },
                            version => 'd2e63b1870594d57bc16999e7f61e1f84fe91ba1cd47388a85d52fda206cb1cc',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/2",        method => "GET"    },
                                { rel => "edit",        href => "product/2/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/2/delete", method => "DELETE" },
                            ]
                        },
                        {
                            id   => 3,
                            body => {
                                sku  => "3838372",
                                desc => "polyester-suit"
                            },
                            version => 'e13d199dae9e277e852c79b236106d4727ed52be9bee385c39fa66c9475aa4ff',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/3",        method => "GET"    },
                                { rel => "edit",        href => "product/3/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/3/delete", method => "DELETE" },
                            ]
                        }
                    ]
                },
                version => 'a59edbdb6b270e3cdb74e8e729f6a9ea2f82fc9b72db3813159f3516205fe29c',
                links => [
                    { rel => "create",                         href => "cart/create",     method => "POST"   },
                    { rel => "read",                           href => "cart/1",          method => "GET"    },
                    { rel => "my/shoppingCart/target/addItem", href => "cart/1/add_item", method => "PUT"    },
                    { rel => "my/shoppingCart/target/removeItem", href => "cart/1/remove_item", method => "PUT"    },
                    { rel => "delete",                         href => "cart/1/delete",   method => "DELETE" },
                ]
            },
            '... got the right value for creation'
        );
    }

    diag("PUT-ing to delete the new item from cart");
    {
        my $req = PUT("http://localhost/cart/1/remove_item" => (
            Content => '{"$id":"3","type_of":"test/product"}'
        ));
        my $res = $cb->($req);
        is($res->code, 202, '... got the right status for removing an item');

        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                id   => 1,
                body => {
                    user => {
                        id   => 1,
                        body => {
                            username => 'stevan'
                        },
                        version => '7f53a57fae8a7548af8677e60a46c2526d85569b1752ac679b376880bdd4f2a2',
                        links => [
                            { rel => "describedby", href => "user/schema",   method => "GET"    },
                            { rel => "list",        href => "user",          method => "GET"    },
                            { rel => "create",      href => "user/create",   method => "POST"   },
                            { rel => "read",        href => "user/1",        method => "GET"    },
                            { rel => "edit",        href => "user/1/edit",   method => "PUT"    },
                            { rel => "delete",      href => "user/1/delete", method => "DELETE" },
                        ]
                    },
                    items => [
                        {
                            id   => 1,
                            body => {
                                sku  => "123456",
                                desc => "disco-ball"
                            },
                            version => '07c302816348f4e67f0a8f3701aca90330c65a5030f48a2dbb891bcc6c18520d',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/1",        method => "GET"    },
                                { rel => "edit",        href => "product/1/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/1/delete", method => "DELETE" },
                            ]
                        },
                        {
                            id   => 2,
                            body => {
                                sku  => "227272",
                                desc => "dancin-shoes"
                            },
                            version => 'd2e63b1870594d57bc16999e7f61e1f84fe91ba1cd47388a85d52fda206cb1cc',
                            links => [
                                { rel => "describedby", href => "product/schema",   method => "GET"    },
                                { rel => "list",        href => "product",          method => "GET"    },
                                { rel => "create",      href => "product/create",   method => "POST"   },
                                { rel => "read",        href => "product/2",        method => "GET"    },
                                { rel => "edit",        href => "product/2/edit",   method => "PUT"    },
                                { rel => "delete",      href => "product/2/delete", method => "DELETE" },
                            ]
                        },
                    ]
                },
                version => '6f2b0ecaeb1dfc8fc50c2bb0cae7c685969793ea2aee5016dd2075c76ae40a94',
                links => [
                    { rel => "create",                         href => "cart/create",     method => "POST"   },
                    { rel => "read",                           href => "cart/1",          method => "GET"    },
                    { rel => "my/shoppingCart/target/addItem", href => "cart/1/add_item", method => "PUT"    },
                    { rel => "my/shoppingCart/target/removeItem", href => "cart/1/remove_item", method => "PUT"    },
                    { rel => "delete",                         href => "cart/1/delete",   method => "DELETE" },
                ]
            },
            '... got the right value for creation'
        );
    }


    diag("DELETE-ing cart (with conditional match)");
    {
        my $req = DELETE("http://localhost/cart/1/delete" => (
            'If-Matches' => '6f2b0ecaeb1dfc8fc50c2bb0cae7c685969793ea2aee5016dd2075c76ae40a94'
        ));
        my $res = $cb->($req);
        is($res->code, 204, '... got the right status for delete');
        is( $res->content, '', '... got the right value for delete' );
    }

    diag("GET-ing cart (but get 404 because we deleted it)");
    {
        my $req = GET("http://localhost/cart/1");
        my $res = $cb->($req);
        is($res->code, 404, '... got the right status for creation');
        like( $res->content, qr/404 Resource Not Found \: no resource for id \(1\)/, '... got the right value for the 404' );
    }
});


done_testing;
