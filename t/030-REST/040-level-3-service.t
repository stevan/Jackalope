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

=pod

This is meant to model the Level 3 web service described in here:
http://martinfowler.com/articles/richardsonMaturityModel.html

See the embedded comments below

=cut

use Jackalope::REST::Resource;
use Jackalope::REST::Error::ResourceNotFound;
use Jackalope::REST::Error::ConflictDetected;

{
    package Level3::Service;
    use Moose;

    # this is a basic service, with
    # the router added in, check out
    # the source for both to see what
    # is added.
    with 'Jackalope::REST::Service',
         'Jackalope::REST::Service::Role::WithRouter';

    # these are our raw schemas ..
    has 'schemas' => ( is => 'ro', isa => 'ArrayRef[HashRef]', required => 1 );

    # but we need the compiled versions
    # to really do anything with 'em
    has 'compiled_schemas' => (
        is      => 'ro',
        lazy    => 1,
        default => sub {
            my $self = shift;
            $self->schema_repository->register_schemas( $self->schemas )
        }
    );

    # we will define this below ...
    has 'resource_repository' => (
        is       => 'ro',
        isa      => 'Level3::Service::ResourceRepository',
        required => 1
    );

    # this maps all the linkrels
    # that our schemas define to
    # target classes, which are
    # the endpoints of the router
    has '+linkrels_to_target_class' => (
        default => sub {
            return +{
                'doctor.open_slots'  => 'Level3::Service::Target::QueryOpenSlots',
                'slot.book'          => 'Level3::Service::Target::BookSlot',
                'appointment.read'   => 'Level3::Service::Target::AppointmentRead',
                'appointment.cancel' => 'Level3::Service::Target::AppointmentCancel',
            }
        }
    );

    # the router needs these
    # so we build a hash here
    # for them
    sub get_all_linkrels {
        my $self = shift;
        return +{
            map {
                %{ $_->{'links'} || {} }
            } @{ $self->compiled_schemas }
        }
    }

    package Level3::Service::ResourceRepository;
    use Moose;
    use MooseX::Params::Validate;

    # NOTE:
    # This is pretty much just a Mock
    # object to illustrate the other
    # bits of this test. Note that we
    # are free to throw exceptions
    # in here and they will get handled
    # automagically on up the chain.
    # - SL

    has 'slots' => (
        traits  => [ 'Hash' ],
        is      => 'ro',
        isa     => 'HashRef',
        default => sub {
            return +{
                '1234' => {
                    date   => 20101227,
                    start  => 1400,
                    end    => 1450,
                    doctor => { name => 'mjones' },
                },
                '5678' => {
                    date   => 20101227,
                    start  => 1500,
                    end    => 1550,
                    doctor => { name => 'mjones' },
                }
            }
        },
        handles => {
            'get_all_slots'  => 'elements',
            'get_slot_by_id' => 'get'
        }
    );

    my $APPOINTMENT_COUNTER = 0;
    has 'appointments' => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { +{} },
    );

    sub get_all_slots_for {
        my ($self, $doctor_id, $date) = validated_list(\@_,
            doctor => { isa => 'Str' },
            date   => { isa => 'Int' }
        );
        # This isn't actually for real :)
        my %open_slots = $self->get_all_slots;
        return [
            map {
                Jackalope::REST::Resource->new(
                    id   => $_,
                    body => $open_slots{ $_ }
                ),
            } sort keys %open_slots
        ];
    }

    sub create_appointment_for {
        my ($self, $slot_id, $patient) = validated_list(\@_,
            slot_id => { isa => 'Int' },
            patient => { isa => 'HashRef[Str]' }
        );

        my $slot = $self->get_slot_by_id( $slot_id );
        (defined $slot)
            || Jackalope::REST::Error::ConflictDetected->throw("Slot $slot_id is no longer available");
            # this ^ exception is basically
            # saying that the slot is no longer
            # available, which we are assuming
            # means that it has already been
            # booked. In a real application
            # it would be more sophisticated
            # then this.

        my $id = ++$APPOINTMENT_COUNTER;
        $self->appointments->{ $id } = {
            patient => $patient,
            slot    => $slot
        };
        Jackalope::REST::Resource->new(
            id   => $id,
            body => $self->appointments->{ $id }
        );
    }

    sub get_appointment {
        my ($self, $appt_id) = @_;

        (exists $self->appointments->{ $appt_id })
            || Jackalope::REST::Error::ResourceNotFound->throw("Appointment $appt_id is not found");

        Jackalope::REST::Resource->new(
            id   => $appt_id,
            body => $self->appointments->{ $appt_id }
        );
    }

    sub cancel_appointment {
        my ($self, $appt_id) = @_;

        (exists $self->appointments->{ $appt_id })
            || Jackalope::REST::Error::ResourceNotFound->throw("Appointment $appt_id is no longer available");

        delete $self->appointments->{ $appt_id };
        return;
    }

    ## TARGETS

    # These now are our target classes. They are
    # really just simple methods that call other
    # methods (brought in by the target role) to
    # check the input and verify the output.

    package Level3::Service::Target::QueryOpenSlots;
    use Moose;
    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, $doctor_id) = @_;

        my $params     = $self->sanitize_and_prepare_input( $r );
        my $open_slots = $self->service->resource_repository->get_all_slots_for(
            doctor => $doctor_id,
            date   => $params->{'date'}
        );

        my $result = [
            map {
                # add hyperlinks to our resource
                $_->add_links( $self->service->router->uri_for( 'slot.book' => $_ ) );
                # and pack it for serialization
                $_->pack;
            } @$open_slots
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

        my $patient     = $self->sanitize_and_prepare_input( $r );
        my $appointment = $self->service->resource_repository->create_appointment_for(
            slot_id => $slot_id,
            patient => $patient
        );

        # add some hyperlinks to our resource
        $appointment->add_links(
            $self->service->router->uri_for( $_ => $appointment )
        ) foreach qw[ appointment.read appointment.cancel ];

        $self->process_psgi_output(
            [ 201, [], [ $self->check_target_schema( $appointment->pack ) ] ]
        );
    }

    package Level3::Service::Target::AppointmentRead;
    use Moose;
    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, $appt_id) = @_;

        my $params      = $self->sanitize_and_prepare_input( $r );
        my $appointment = $self->service->resource_repository->get_appointment( $appt_id );

        # add some hyperlinks to our resource
        $appointment->add_links(
            $self->service->router->uri_for( $_ => $appointment )
        ) foreach qw[ appointment.read appointment.cancel ];

        $self->process_psgi_output(
            [ 200, [], [ $self->check_target_schema( $appointment->pack ) ] ]
        );
    }

    package Level3::Service::Target::AppointmentCancel;
    use Moose;
    with 'Jackalope::REST::Service::Target';

    sub execute {
        my ($self, $r, $appt_id) = @_;

        my $params = $self->sanitize_and_prepare_input( $r );

        # allow the optional If-Matches header to check
        # to make sure that the versions match, if not
        # we will throw an exception that will be handled
        # by the Service object (in the Router role)
        if ( my $if_matches = $r->headers->header('If-Matches') ) {
            my $appointment = $self->service->resource_repository->get_appointment( $appt_id );
            ($appointment->compare_version( $if_matches ))
                || Jackalope::REST::Error::ConflictDetected->throw("resource submitted has out of date version");
        }

        $self->service->resource_repository->cancel_appointment( $appt_id );
        $self->process_psgi_output(
            [ 204, [], [] ]
        );
    }
}

# Now we create out Bread::Board containers

my $j = Jackalope::REST->new;
my $c = container $j => as {

    # we can define out raw schemas as
    # a bread-board literal service

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
                    # OUTPUT: a list of slot objects (wrapped as resources)
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
                    # INPUT : patient object
                    data_schema   => { '$ref' => '/schemas/patient' },
                    # OUTPUT : appointment object (wrapped as resource)
                    target_schema => {
                        extends    => { '$ref' => 'schema/web/resource' },
                        properties => {
                            body => { '$ref' => '/schemas/appointment' }
                        }
                    }
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
                    # OUTPUT : appointment object (wrapped as resource)
                    target_schema => {
                        extends    => { '$ref' => 'schema/web/resource' },
                        properties => {
                            body => { '$ref' => '#' }
                        }
                    }
                },
                # method to cancel the appointment (note the DELETE)
                'appointment.cancel' => {
                    rel          => 'appointment.cancel',
                    href         => '/appointment/:id',
                    method       => 'DELETE',
                    uri_schema   => { id => { type => 'string' } },
                },
            }
        }
    ];

    # create our resource repository through inferrence
    typemap 'Level3::Service::ResourceRepository' => infer;

    # and now join it all together as a service
    service 'Level3Service' => (
        class        => 'Level3::Service',
        dependencies => {
            schema_repository   => 'type:Jackalope::Schema::Repository',
            resource_repository => 'type:Level3::Service::ResourceRepository',
            schemas             => 'Level3Schemas',
            serializer          => {
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

    {
        my $req = GET("http://localhost/doctors/mjones/slots/open?date=20101227");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for query-ing open slots');
        is_deeply(
           $serializer->deserialize( $res->content ),
           [
                {
                    'id' => '1234',
                    'body' => {
                        'date'   => 20101227,
                        'start'  => 1400,
                        'end'    => 1450,
                        'doctor' => { 'name' => 'mjones' },
                    },
                    'version' => '4003b4f63156c825263eab5221d707f3bd69f774c63555c949897fc896d42314',
                    'links' => [
                        { 'rel' => 'slot.book', 'href' => '/slots/1234', 'method' => 'POST' }
                    ]
                },
                {
                    'id' => '5678',
                    'body' => {
                        'date'   => 20101227,
                        'start'  => 1500,
                        'end'    => 1550,
                        'doctor' => { 'name' => 'mjones' },
                    },
                    'version' => '265358df6a5742773a6402427da4acc68db3dabf18de4335c90ce378b68e0fc6',
                    'links' => [
                        { 'rel' => 'slot.book', 'href' => '/slots/5678', 'method' => 'POST' }
                    ]
                }
            ],
            '... got the right value for query-ing open slots'
        );
    }
    {
        my $req = POST("http://localhost/slots/1234" => (
            Content => '{"name":"jsmith"}'
        ));
        my $res = $cb->($req);
        is($res->code, 201, '... got the right status for booking a slot ');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                'id' => '1',
                'body' => {
                    'patient' => { 'name' => 'jsmith' },
                    'slot'    => {
                        'date'   => 20101227,
                        'start'  => 1400,
                        'end'    => 1450,
                        'doctor' => { 'name' => 'mjones' },
                    }
                },
                'version' => '60d074abd47f78a18a541c38fe045e0dd0b70bc0ea7a2e0d2c64e8349501ed8c',
                'links' => [
                    { 'rel' => 'appointment.read', 'href' => '/appointment/1', 'method' => 'GET' },
                    { 'rel' => 'appointment.cancel', 'href' => '/appointment/1', 'method' => 'DELETE' }
                ]
            },
            '... got the right value for booking a slot'
        );
    }
    {
        my $req = POST("http://localhost/slots/12345" => (
            Content => '{"name":"jsmith"}'
        ));
        my $res = $cb->($req);
        is($res->code, 409, '... got the right status for booking a slot that doesnt exist');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                'code'    => 409,
                'desc'    => 'Conflict Detected',
                'message' => 'Slot 12345 is no longer available'
            },
            '... got the right value for booking  a slot that doesnt exist'
        );
    }
    {
        my $req = GET("http://localhost//appointment/1");
        my $res = $cb->($req);
        is($res->code, 200, '... got the right status for apptointment read');
        is_deeply(
           $serializer->deserialize( $res->content ),
           {
               'id' => '1',
               'body' => {
                   'patient' => { 'name' => 'jsmith' },
                   'slot'    => {
                       'date'   => 20101227,
                       'start'  => 1400,
                       'end'    => 1450,
                       'doctor' => { 'name' => 'mjones' },
                   }
               },
               'version' => '60d074abd47f78a18a541c38fe045e0dd0b70bc0ea7a2e0d2c64e8349501ed8c',
               'links' => [
                   { 'rel' => 'appointment.read', 'href' => '/appointment/1', 'method' => 'GET' },
                   { 'rel' => 'appointment.cancel', 'href' => '/appointment/1', 'method' => 'DELETE' }
               ]
           },
            '... got the right value for apptointment read'
        );
    }
    {
        my $req = DELETE("http://localhost//appointment/1" => (
            'If-Matches' => 'bogus'
        ));
        my $res = $cb->($req);
        is($res->code, 409, '... got the right status for apptointment delete (error)');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                'code'    => 409,
                'desc'    => 'Conflict Detected',
                'message' => 'resource submitted has out of date version'
            },
            '... got the right value for apptointment delete (error)'
        );
    }
    {
        my $req = DELETE("http://localhost//appointment/1" => (
            'If-Matches' => '60d074abd47f78a18a541c38fe045e0dd0b70bc0ea7a2e0d2c64e8349501ed8c'
        ));
        my $res = $cb->($req);
        is($res->code, 204, '... got the right status for apptointment delete');
    }
    {
        my $req = GET("http://localhost//appointment/1");
        my $res = $cb->($req);
        is($res->code, 404, '... got the right status for apptointment read (error)');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                'code'    => 404,
                'desc'    => 'Resource Not Found',
                'message' => 'Appointment 1 is not found'
            },
            '... got the right value for apptointment read (error)'
        );
    }
    {
        my $req = DELETE("http://localhost//appointment/1");
        my $res = $cb->($req);
        is($res->code, 404, '... got the right status for apptointment delete (error)');
        is_deeply(
            $serializer->deserialize( $res->content ),
            {
                'code'    => 404,
                'desc'    => 'Resource Not Found',
                'message' => 'Appointment 1 is no longer available'
            },
            '... got the right value for apptointment delete (error)'
        );
    }
});


done_testing;