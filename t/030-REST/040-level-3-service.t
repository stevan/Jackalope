#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/CPAN/current/Bread-Board/lib';

use Test::More;
use Test::Fatal;
use Test::Moose;
use Bread::Board;
use Plack::Test;
use HTTP::Request::Common qw[ GET PUT POST DELETE ];

BEGIN {
    use_ok('Jackalope::REST');
}

use Jackalope::REST::Resource;

{
    package Level3::Service;
    use Moose;

    with 'Jackalope::REST::Service',
         'Jackalope::REST::Service::Role::WithRouter';

    has 'schemas'          => ( is => 'ro', isa => 'ArrayRef[HashRef]', required => 1 );
    has 'compiled_schemas' => (
        is      => 'ro',
        lazy    => 1,
        default => sub {
            my $self = shift;
            $self->schema_repository->register_schemas( $self->schemas )
        }
    );

    has '+linkrels_to_target_class' => (
        default => sub {
            return +{
                'doctor.open_slots'  => 'Level3::Service::Target::QueryOpenSlots',
                'slot.book'          => 'Level3::Service::Target::BookSlot',
                'appointment.read'   => 'Level3::Service::Target::AppointmentRead',
                'appointment.cancel' => 'Level3::Service::Target::AppointmentRead',
            }
        }
    );

    sub get_all_linkrels {
        my $self = shift;
        return +{
            map {
                %{ $_->{'links'} || {} }
            } @{ $self->compiled_schemas }
        }
    }

    package Level3::Service::Target::QueryOpenSlots;
    use Moose;
    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, $doctor_id) = @_;
        my $params = $self->sanitize_and_prepare_input( $r );
        my $result = [
            map {
                $_->add_links( $self->service->router->uri_for( 'slot.book' => $_ ) );
                $_->pack
            } (
                Jackalope::REST::Resource->new(
                    id   => '1234',
                    body => {
                        date   => $params->{'date'},
                        start  => 1400,
                        end    => 1450,
                        doctor => { name => $doctor_id },
                    }
                ),
                Jackalope::REST::Resource->new(
                    id   => '5678',
                    body => {
                        date   => $params->{'date'},
                        start  => 1500,
                        end    => 1550,
                        doctor => { name => $doctor_id },
                    }
                )
            )
        ];
        $self->process_psgi_output(
            [ 200, [], [ $self->check_target_schema( $result ) ] ]
        );
    }

    package Level3::Service::Target::BookSlot;
    use Moose;
    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, $slot_id) = @_;

    }

    package Level3::Service::Target::AppointmentRead;
    use Moose;
    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, $appt_id) = @_;
    }

    package Level3::Service::Target::AppointmentCancel;
    use Moose;
    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, $appt_id) = @_;
    }
}

my $j = Jackalope::REST->new;
my $c = container $j => as {

    service 'Level3Schemas' => [
        # Simple Patient Schema
        {
            id         => '/schemas/patient',
            type       => 'object',
            properties => {
                name => { type => 'string' },
            }
        },
        # Doctor Schema
        {
            id         => '/schemas/doctor',
            type       => 'object',
            properties => {
                name => { type => 'string' }
            },
            links => {
                # Query the open slots the doctor has ...
                'doctor.open_slots' => {
                    rel          => 'doctor.open_slots',
                    href         => '/doctors/:id/slots/open',
                    method       => 'GET',
                    uri_schema   => { id => { type => 'string' } },
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
                        items => {
                            extends    => { '$ref' => 'schema/web/resource' },
                            properties => {
                                body => { '$ref' => '/schemas/slot' }
                            }
                        }
                    },
                }
            }
        },
        # Slot Schema
        {
            id         => '/schemas/slot',
            type       => 'object',
            properties => {
                date   => { type => 'number' },
                start  => { type => 'number' },
                end    => { type => 'number' },
                doctor => { '$ref' => '/schemas/doctor' },
            },
            links => {
                # link to book an appointment
                'slot.book' => {
                    rel           => 'slot.book',
                    href          => '/slots/:id',
                    method        => 'POST',
                    uri_schema    => { id => { type => 'string' } },
                    data_schema   => { '$ref' => '/schemas/patient' },    # INPUT : patient object
                    target_schema => { '$ref' => '/schemas/appointment' } # OUTPUT : appointment object
                }
            }
        },
        # Appointment Schema
        {
            id         => '/schemas/appointment',
            type       => 'object',
            properties => {
                slot    => { '$ref' => '/schemas/slot' },
                patient => { '$ref' => '/schemas/patient' },
            },
            links => {
                # way to just view the appointment ...
                'appointment.read' => {
                    rel           => 'appointment.read',
                    href          => '/appointment/:id',
                    method        => 'GET',
                    uri_schema    => { id => { type => 'string' } },
                    target_schema => { '$ref' => '#' }
                },
                # method to cancel the appointment (note the DELETE)
                'appointment.cancel' => {
                    rel          => 'appointment.cancel',
                    href         => '/appointment/:id',
                    method       => 'DELETE',
                    uri_schema   => { id => { type => 'string' } },
                    # INPUT : optionaly provide a reason for cancelation
                    data_schema  => {
                        type       => 'object',
                        properties => {
                            reason => { type => 'string' }
                        }
                    },
                },
            }
        }
    ];

    service 'Level3Service' => (
        class        => 'Level3::Service',
        dependencies => {
            schema_repository => 'type:Jackalope::Schema::Repository',
            schemas           => 'Level3Schemas',
            serializer        => {
                'Jackalope::Serializer' => {
                    'format' => 'JSON'
                }
            }
        }
    );
};

my $service = $c->resolve( service => 'Level3Service' );
my $app     = $service->to_app;

my $serializer = $c->resolve(
    service    => 'Jackalope::Serializer',
    parameters => { 'format' => 'JSON' }
);

test_psgi( app => $app, client => sub {
    my $cb = shift;

    #diag("Listing resources (expecting empty set)");
    {
        my $req = GET("http://localhost/doctors/mjones/slots/open?date=20101227");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for list ');
        is_deeply(
           $serializer->deserialize( $res->content ),
           [
                {
                    'id' => '1234',
                    'body' => {
                        'date'   => '20101227',
                        'start'  => 1400,
                        'end'    => 1450,
                        'doctor' => { 'name' => 'mjones' },
                    },
                    'version' => '3a827c91daff9650f999d08692ac708302633dff7eb2762ee58e807a8bbd9ebb',
                    'links' => [
                        { 'rel' => 'slot.book', 'href' => '/slots/1234', 'method' => 'POST' }
                    ]
                },
                {
                    'id' => '5678',
                    'body' => {
                        'date'   => '20101227',
                        'start'  => 1500,
                        'end'    => 1550,
                        'doctor' => { 'name' => 'mjones' },
                    },
                    'version' => '666f00cded59bf01b9634c11628a2a0007c5edeb20bf75a2577bff0da5cbb095',
                    'links' => [
                        { 'rel' => 'slot.book', 'href' => '/slots/5678', 'method' => 'POST' }
                    ]
                }
            ],
            '... got the right value for list'
        );
    }
});


done_testing;