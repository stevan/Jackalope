#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
}

my $repo = Jackalope->new(
    use_web_spec => 1
)->resolve(
    type => 'Jackalope::Schema::Repository'
);
isa_ok($repo, 'Jackalope::Schema::Repository');

is(exception{
    $repo->register_schema(
        {
            id         => 'simple/person',
            title      => 'This is a simple person schema',
            extends    => { '$ref' => 'schema/web/service' },
            properties => {
                first_name => { type => 'string' },
                last_name  => { type => 'string' },
                age        => { type => 'integer', greater_than => 0 },
            }
        }
    )
}, undef, '... did not die when registering this schema');

my $person = $repo->get_compiled_schema_by_uri('simple/person');

is($person->{'links'}->[0]->{'target_schema'}->{'items'}->{'properties'}->{'body'}, $person, '... self referring schema for LIST');
is($person->{'links'}->[1]->{'data_schema'}, $person, '... self referring schema for POST');
is($person->{'links'}->[1]->{'target_schema'}->{'properties'}->{'body'}, $person, '... self referring schema for POST');
is($person->{'links'}->[2]->{'target_schema'}->{'properties'}->{'body'}, $person, '... self referring schema for GET');
is($person->{'links'}->[3]->{'data_schema'}, $person, '... self referring schema for UPDATE');
is($person->{'links'}->[3]->{'target_schema'}->{'properties'}->{'body'}, $person, '... self referring schema for UPDATE');


done_testing;