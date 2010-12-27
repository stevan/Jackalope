#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope::REST');
}

=pod

TODO:
Cannot load these schemas individually
we need to load them all at the same time
so that we can resolve all the references
at compile time. And since we have some
circular refs here (slot <=> doctor) we
need to be able to handle that somehow.
- SL

=cut

my $repo = Jackalope::REST->new->resolve(
    type => 'Jackalope::Schema::Repository'
);
isa_ok($repo, 'Jackalope::Schema::Repository');

my @schemas = (
    # Simple Patient Schema
    {
        id         => '/schemas/patient',
        type       => 'object',
        properties => {
            id => { type => 'string' },
        }
    },
    # Doctor Schema
    {
        id         => '/schemas/doctor',
        type       => 'object',
        properties => {
            id         => { type => 'string' },
            open_slots => {
                type  => 'array',
                items => { '$ref' => '/schemas/slot' },
            }
        },
        links => [
            # Query the open slots the doctor has ...
            {
                rel          => 'query_open_slots',
                href         => 'doctors/:id/slots/open',
                method       => 'GET',
                uri_schema   => { id => { type => 'number' } },
                # INPUT : the date you want ...
                data_schema  => {
                    type       => 'object',
                    properties => {
                        date => { type => 'number' }
                    }
                },
                # OUTPUT: a list of slot objects
                target_schema => {
                    type  => 'array',
                    items => { '$ref' => '/schemas/slot' }
                },
            }
        ]
    },
    # Slot Schema
    {
        id         => '/schemas/slot',
        type       => 'object',
        properties => {
            id     => { type => 'number' },
            date   => { type => 'number' },
            start  => { type => 'number' },
            end    => { type => 'number' },
            doctor => { '$ref' => '/schemas/doctor' },
        },
        links => [
            # link to book an appointment
            {
                rel           => 'book_slot',
                href          => 'slots/:id/book',
                method        => 'POST',
                uri_schema    => { id => { type => 'number' } },
                data_schema   => { '$ref' => '/schemas/patient' },    # INPUT : patient object
                target_schema => { '$ref' => '/schemas/appointment' } # OUTPUT : appointment object
            }
        ]
    },
    # Appointment Schema
    {
        id         => '/schemas/appointment',
        type       => 'object',
        properties => {
            id      => { type => 'number' },
            slot    => { '$ref' => '/schemas/slot' },
            patient => { '$ref' => '/schemas/patient' },
        },
        links => [
            # way to just view the appointment ...
            {
                rel           => 'read',
                href          => 'appointment/:id',
                uri_schema    => { id => { type => 'number' } },
                target_schema => { '$ref' => '#' }
            },
            # method to cancel the appointment (note the DELETE)
            {
                rel          => 'cancel',
                href         => 'appointment/:id/cancel',
                method       => 'DELETE',
                uri_schema   => { id => { type => 'number' } },
                # INPUT : optionaly provide a reason for cancelation
                data_schema  => {
                    type       => 'object',
                    properties => {
                        reason => { type => 'string' }
                    }
                },
            },
        ]
    }
);

my $compiled;
is(exception{
    $compiled = $repo->register_schemas( \@schemas )
}, undef, '... did not die when registering this schema');

#use Data::Dumper; warn Dumper $compiled;



done_testing;