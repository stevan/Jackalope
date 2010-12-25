#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::REST::Router');
}

{
    my $router = Jackalope::REST::Router->new(
        linkrels => {
            create => {
                rel    => 'create',
                href   => '/',
                method => 'POST',
            }
        }
    );
    isa_ok($router, 'Jackalope::REST::Router');

    my $match = $router->match( '/', 'POST' );
    is_deeply($match->{link}, {
        rel    => 'create',
        href   => '/',
        method => 'POST',
    }, '... got the link we expected');
    is_deeply($match->{mapping}, [], '... got the mapping we expected');

    isa_ok(exception { $router->match('/foo', 'GET') },  'Jackalope::REST::Error::ResourceNotFound');
    isa_ok(exception { $router->match('/foo', 'POST') }, 'Jackalope::REST::Error::ResourceNotFound');

    isa_ok(exception { $router->match('/', 'GET') },     'Jackalope::REST::Error::MethodNotAllowed');
    isa_ok(exception { $router->match('/', 'DELETE') },  'Jackalope::REST::Error::MethodNotAllowed');

    is_deeply(
        $router->uri_for( 'create', {} ),
        { rel => 'create', href => '/', method => 'POST' },
        '... got the hyperlink we expected'
    );
    like(exception { $router->uri_for( 'read', {} ) }, qr/Could not find link for read/, '... got an exception as expected');
}

{
    my $router = Jackalope::REST::Router->new(
        linkrels => {
            read => {
                rel    => 'read',
                href   => '/:id',
                method => 'GET',
            }
        }
    );
    isa_ok($router, 'Jackalope::REST::Router');

    my $match = $router->match( '/10', 'GET' );
    is_deeply($match->{link}, {
        rel    => 'read',
        href   => '/:id',
        method => 'GET',
    }, '... got the link we expected');
    is_deeply($match->{mapping}, [ { id => 10 } ], '... got the mapping we expected');

    isa_ok(exception { $router->match('/foo/bar', 'GET') }, 'Jackalope::REST::Error::ResourceNotFound');
    isa_ok(exception { $router->match('/', 'GET') },        'Jackalope::REST::Error::ResourceNotFound');
    isa_ok(exception { $router->match('/', 'DELETE') },     'Jackalope::REST::Error::ResourceNotFound');

    isa_ok(exception { $router->match('/foo', 'POST') },    'Jackalope::REST::Error::MethodNotAllowed');

    is_deeply(
        $router->uri_for( 'read', { id => 10 } ),
        { rel => 'read', href => '/10', method => 'GET' },
        '... got the hyperlink we expected'
    );
    like(exception { $router->uri_for( 'create', {} ) }, qr/Could not find link for create/, '... got an exception as expected');
}

{
    my $router = Jackalope::REST::Router->new(
        linkrels => {
            delete_item => {
                rel    => 'delete_item',
                href   => '/:id/item/:item_id',
                method => 'PUT',
            }
        }
    );
    isa_ok($router, 'Jackalope::REST::Router');

    my $match = $router->match( '/10/item/1', 'PUT' );
    is_deeply($match->{link}, {
        rel    => 'delete_item',
        href   => '/:id/item/:item_id',
        method => 'PUT',
    }, '... got the link we expected');
    is_deeply($match->{mapping}, [ { id => 10 }, { item_id => 1 } ], '... got the mapping we expected');

    isa_ok(exception { $router->match('/10/item/10/foo', 'PUT') }, 'Jackalope::REST::Error::ResourceNotFound');
    isa_ok(exception { $router->match('/foo/bar/10', 'PUT') },     'Jackalope::REST::Error::ResourceNotFound');
    isa_ok(exception { $router->match('/foo/bar', 'GET') },        'Jackalope::REST::Error::ResourceNotFound');
    isa_ok(exception { $router->match('/', 'GET') },               'Jackalope::REST::Error::ResourceNotFound');
    isa_ok(exception { $router->match('/', 'DELETE') },            'Jackalope::REST::Error::ResourceNotFound');
    isa_ok(exception { $router->match('/foo', 'POST') },           'Jackalope::REST::Error::ResourceNotFound');

    isa_ok(exception { $router->match('/foo/item/10', 'GET') },    'Jackalope::REST::Error::MethodNotAllowed');
    isa_ok(exception { $router->match('/100/item/10', 'POST') },   'Jackalope::REST::Error::MethodNotAllowed');

    is_deeply(
        $router->uri_for( 'delete_item', { id => 10, item_id => 1 } ),
        { rel => 'delete_item', href => '/10/item/1', method => 'PUT' },
        '... got the hyperlink we expected'
    );
    like(exception { $router->uri_for( 'delete_item', {} ) }, qr/Mapping for delete_item missing id/, '... got an exception as expected');
    like(exception { $router->uri_for( 'delete_item', { id => 1 } ) }, qr/Mapping for delete_item missing item_id/, '... got an exception as expected');
    like(exception { $router->uri_for( 'create', {} ) }, qr/Could not find link for create/, '... got an exception as expected');
}

{
    my $router = Jackalope::REST::Router->new(
        linkrels => {
            create => {
                rel    => 'create',
                href   => '/',
                method => 'POST',
            },
            list => {
                rel    => 'list',
                href   => '/',
                method => 'GET',
            },
            read => {
                rel    => 'read',
                href   => '/:id',
                method => 'GET',
            },
            edit => {
                rel    => 'edit',
                href   => '/:id',
                method => 'PUT',
            }
        }
    );
    isa_ok($router, 'Jackalope::REST::Router');

    {
        my $match = $router->match( '/10', 'GET' );
        is_deeply($match->{link}, {
            rel    => 'read',
            href   => '/:id',
            method => 'GET',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [ { id => 10 } ], '... got the mapping we expected');
    }
    {
        my $match = $router->match( '/10', 'PUT' );
        is_deeply($match->{link}, {
            rel    => 'edit',
            href   => '/:id',
            method => 'PUT',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [ { id => 10 } ], '... got the mapping we expected');
    }
    {
        my $match = $router->match( '/', 'POST' );
        is_deeply($match->{link}, {
            rel    => 'create',
            href   => '/',
            method => 'POST',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [], '... got the mapping we expected');
    }

    {
        my $match = $router->match( '/', 'GET' );
        is_deeply($match->{link}, {
            rel    => 'list',
            href   => '/',
            method => 'GET',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [], '... got the mapping we expected');
    }

    isa_ok(exception { $router->match('/foo/bar', 'GET') }, 'Jackalope::REST::Error::ResourceNotFound');

    isa_ok(exception { $router->match('/', 'DELETE') },     'Jackalope::REST::Error::MethodNotAllowed');
    isa_ok(exception { $router->match('/', 'PUT') },        'Jackalope::REST::Error::MethodNotAllowed');
    isa_ok(exception { $router->match('/foo', 'POST') },    'Jackalope::REST::Error::MethodNotAllowed');

    is_deeply(
        $router->uri_for( 'read', { id => 10 } ),
        { rel => 'read', href => '/10', method => 'GET' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'edit', { id => 2 } ),
        { rel => 'edit', href => '/2', method => 'PUT' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'create', {} ),
        { rel => 'create', href => '/', method => 'POST' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'list', {} ),
        { rel => 'list', href => '/', method => 'GET' },
        '... got the hyperlink we expected'
    );

}

{
    my $router = Jackalope::REST::Router->new(
        uri_base => '/test',
        linkrels => {
            create => {
                rel    => 'create',
                href   => '/',
                method => 'POST',
            },
            list => {
                rel    => 'list',
                href   => '/',
                method => 'GET',
            },
            read => {
                rel    => 'read',
                href   => '/:id',
                method => 'GET',
            },
            edit => {
                rel    => 'edit',
                href   => '/:id',
                method => 'PUT',
            }
        }
    );
    isa_ok($router, 'Jackalope::REST::Router');

    {
        my $match = $router->match( '/test/10', 'GET' );
        is_deeply($match->{link}, {
            rel    => 'read',
            href   => '/:id',
            method => 'GET',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [ { id => 10 } ], '... got the mapping we expected');
    }
    {
        my $match = $router->match( '/test/10', 'PUT' );
        is_deeply($match->{link}, {
            rel    => 'edit',
            href   => '/:id',
            method => 'PUT',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [ { id => 10 } ], '... got the mapping we expected');
    }
    {
        my $match = $router->match( '/test/', 'POST' );
        is_deeply($match->{link}, {
            rel    => 'create',
            href   => '/',
            method => 'POST',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [], '... got the mapping we expected');
    }

    {
        my $match = $router->match( '/test/', 'GET' );
        is_deeply($match->{link}, {
            rel    => 'list',
            href   => '/',
            method => 'GET',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [], '... got the mapping we expected');
    }

    isa_ok(exception { $router->match('/test/foo/bar', 'GET') }, 'Jackalope::REST::Error::ResourceNotFound');

    isa_ok(exception { $router->match('/test/', 'DELETE') },     'Jackalope::REST::Error::MethodNotAllowed');
    isa_ok(exception { $router->match('/test/', 'PUT') },        'Jackalope::REST::Error::MethodNotAllowed');
    isa_ok(exception { $router->match('/test/foo', 'POST') },    'Jackalope::REST::Error::MethodNotAllowed');

    is_deeply(
        $router->uri_for( 'read', { id => 10 } ),
        { rel => 'read', href => '/test/10', method => 'GET' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'edit', { id => 2 } ),
        { rel => 'edit', href => '/test/2', method => 'PUT' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'create', {} ),
        { rel => 'create', href => '/test/', method => 'POST' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'list', {} ),
        { rel => 'list', href => '/test/', method => 'GET' },
        '... got the hyperlink we expected'
    );

}

{
    my $router = Jackalope::REST::Router->new(
        uri_base => 'test/foo',
        linkrels => {
            create => {
                rel    => 'create',
                href   => '/',
                method => 'POST',
            },
            list => {
                rel    => 'list',
                href   => '/',
                method => 'GET',
            },
            read => {
                rel    => 'read',
                href   => '/:id',
                method => 'GET',
            },
            edit => {
                rel    => 'edit',
                href   => '/:id',
                method => 'PUT',
            }
        }
    );
    isa_ok($router, 'Jackalope::REST::Router');

    {
        my $match = $router->match( 'test/foo/10', 'GET' );
        is_deeply($match->{link}, {
            rel    => 'read',
            href   => '/:id',
            method => 'GET',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [ { id => 10 } ], '... got the mapping we expected');
    }
    {
        my $match = $router->match( 'test/foo/10', 'PUT' );
        is_deeply($match->{link}, {
            rel    => 'edit',
            href   => '/:id',
            method => 'PUT',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [ { id => 10 } ], '... got the mapping we expected');
    }
    {
        my $match = $router->match( 'test/foo/', 'POST' );
        is_deeply($match->{link}, {
            rel    => 'create',
            href   => '/',
            method => 'POST',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [], '... got the mapping we expected');
    }

    {
        my $match = $router->match( 'test/foo/', 'GET' );
        is_deeply($match->{link}, {
            rel    => 'list',
            href   => '/',
            method => 'GET',
        }, '... got the link we expected');
        is_deeply($match->{mapping}, [], '... got the mapping we expected');
    }

    isa_ok(exception { $router->match('test/foo/foo/bar', 'GET') }, 'Jackalope::REST::Error::ResourceNotFound');

    isa_ok(exception { $router->match('test/foo/', 'DELETE') },     'Jackalope::REST::Error::MethodNotAllowed');
    isa_ok(exception { $router->match('test/foo/', 'PUT') },        'Jackalope::REST::Error::MethodNotAllowed');
    isa_ok(exception { $router->match('test/foo/foo', 'POST') },    'Jackalope::REST::Error::MethodNotAllowed');

    is_deeply(
        $router->uri_for( 'read', { id => 10 } ),
        { rel => 'read', href => 'test/foo/10', method => 'GET' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'edit', { id => 2 } ),
        { rel => 'edit', href => 'test/foo/2', method => 'PUT' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'create', {} ),
        { rel => 'create', href => 'test/foo/', method => 'POST' },
        '... got the hyperlink we expected'
    );
    is_deeply(
        $router->uri_for( 'list', {} ),
        { rel => 'list', href => 'test/foo/', method => 'GET' },
        '... got the hyperlink we expected'
    );

}


done_testing;