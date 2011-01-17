#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
    use_ok('Jackalope::REST::Resource');
}

{
    my $r = Jackalope::REST::Resource->new(
        id      => '1229273732',
        body    => { hello => 'world' },
        version => 'v1'
    );
    isa_ok($r, 'Jackalope::REST::Resource');

    is($r->get('id'), '1229273732', '... got the right value with get()');
    is($r->get('hello'), 'world', '... got the right value with get()');
}

{
    my $r = Jackalope::REST::Resource->new(
        id      => '1229273732',
        body    => {
            a => {
                very => {
                    deep => 'value'
                }
            }
        },
        version => 'v1'
    );
    isa_ok($r, 'Jackalope::REST::Resource');

    is($r->get('id'), '1229273732', '... got the right value with get()');
    is($r->get('a.very.deep'), 'value', '... got the right value with get()');
}

{
    my $r = Jackalope::REST::Resource->new(
        id      => '1229273732',
        body    => {
            a => [
                {
                    very => {
                        deep => 'value'
                    }
                },
                {
                    nother => {
                        very => [
                            { deep => 'value' }
                        ]
                    }
                }
            ]
        },
        version => 'v1'
    );
    isa_ok($r, 'Jackalope::REST::Resource');

    is($r->get('id'), '1229273732', '... got the right value with get()');
    is($r->get('a.0.very.deep'), 'value', '... got the right value with get()');
    is($r->get('a.1.nother.very.0.deep'), 'value', '... got the right value with get()');
}


done_testing;