#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Jackalope');
}

my @schemas = (
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
                    items => { '__ref__' => '/schemas/slot' }
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
            doctor => { '__ref__' => '/schemas/doctor' },
        },
        links => {
            # link to book an appointment
            'slot.book' => {
                rel           => 'slot.book',
                href          => 'slots/:id',
                method        => 'POST',
                uri_schema    => { id => { type => 'number' } },
                data_schema   => { '__ref__' => '/schemas/patient' },    # INPUT : patient object
                target_schema => { '__ref__' => '/schemas/appointment' } # OUTPUT : appointment object
            }
        }
    },
    # Appointment Schema
    {
        id         => '/schemas/appointment',
        type       => 'object',
        properties => {
            slot    => { '__ref__' => '/schemas/slot' },
            patient => { '__ref__' => '/schemas/patient' },
        },
        links => {
            # way to just view the appointment ...
            'appointment.read' => {
                rel           => 'appointment.read',
                href          => 'appointment/:id',
                method        => 'GET',
                uri_schema    => { id => { type => 'number' } },
                target_schema => { '__ref__' => '#' }
            },
            # method to cancel the appointment (note the DELETE)
            'appointment.cancel' => {
                rel          => 'appointment.cancel',
                href         => 'appointment/:id',
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
        }
    }
);

my $repo = Jackalope->new->resolve(
    type => 'Jackalope::Schema::Repository'
);
isa_ok($repo, 'Jackalope::Schema::Repository');

my $compiled;
is(exception{
    $compiled = $repo->register_schemas( \@schemas );
}, undef, '... did not die when registering this schema');

is_deeply(
    $repo->get_schema_compiled_for_transport('/schemas/patient'),
    {
        '/schemas/patient' => {
            id         => '/schemas/patient',
            type       => 'object',
            properties => {
                name => { type => 'string' },
            }
        }
    },
    '... got the right transport compiled schema /schemas/patient'
);

is_deeply(
    $repo->get_schema_compiled_for_transport('/schemas/doctor'),
    {
        '/schemas/patient' => {
            id         => '/schemas/patient',
            type       => 'object',
            properties => {
                name => { type => 'string' },
            }
        },
        '/schemas/doctor' => {
            id         => '/schemas/doctor',
            type       => 'object',
            properties => {
                name => { type => 'string' }
            },
            links => {
                'doctor.open_slots' => {
                    rel          => 'doctor.open_slots',
                    href         => 'doctors/:id/slots/open',
                    method       => 'GET',
                    uri_schema   => { id => { type => 'number' } },
                    data_schema  => {
                        type       => 'object',
                        properties => {
                            date => { type => 'number' }
                        }
                    },
                    target_schema => {
                        type  => 'array',
                        items => { '__ref__' => '/schemas/slot' }
                    },
                }
            }
        },
        '/schemas/slot' => {
            id         => '/schemas/slot',
            type       => 'object',
            properties => {
                date   => { type => 'number' },
                start  => { type => 'number' },
                end    => { type => 'number' },
                doctor => { '__ref__' => '/schemas/doctor' },
            },
            links => {
                'slot.book' => {
                    rel           => 'slot.book',
                    href          => 'slots/:id',
                    method        => 'POST',
                    uri_schema    => { id => { type => 'number' } },
                    data_schema   => { '__ref__' => '/schemas/patient' },
                    target_schema => { '__ref__' => '/schemas/appointment' }
                }
            }
        },
        '/schemas/appointment' => {
            id         => '/schemas/appointment',
            type       => 'object',
            properties => {
                slot    => { '__ref__' => '/schemas/slot' },
                patient => { '__ref__' => '/schemas/patient' },
            },
            links => {
                'appointment.read' => {
                    rel           => 'appointment.read',
                    href          => 'appointment/:id',
                    method        => 'GET',
                    uri_schema    => { id => { type => 'number' } },
                    target_schema => { '__ref__' => '#' }
                },
                'appointment.cancel' => {
                    rel          => 'appointment.cancel',
                    href         => 'appointment/:id',
                    method       => 'DELETE',
                    uri_schema   => { id => { type => 'number' } },
                    data_schema  => {
                        type       => 'object',
                        properties => {
                            reason => { type => 'string' }
                        }
                    },
                },
            }
        }
    },
    '... got the right transport compiled schema /schemas/doctor'
);

is_deeply(
    $repo->get_schema_compiled_for_transport('/schemas/appointment'),
    {
        '/schemas/patient' => {
            id         => '/schemas/patient',
            type       => 'object',
            properties => {
                name => { type => 'string' },
            }
        },
        '/schemas/doctor' => {
            id         => '/schemas/doctor',
            type       => 'object',
            properties => {
                name => { type => 'string' }
            },
            links => {
                'doctor.open_slots' => {
                    rel          => 'doctor.open_slots',
                    href         => 'doctors/:id/slots/open',
                    method       => 'GET',
                    uri_schema   => { id => { type => 'number' } },
                    data_schema  => {
                        type       => 'object',
                        properties => {
                            date => { type => 'number' }
                        }
                    },
                    target_schema => {
                        type  => 'array',
                        items => { '__ref__' => '/schemas/slot' }
                    },
                }
            }
        },
        '/schemas/slot' => {
            id         => '/schemas/slot',
            type       => 'object',
            properties => {
                date   => { type => 'number' },
                start  => { type => 'number' },
                end    => { type => 'number' },
                doctor => { '__ref__' => '/schemas/doctor' },
            },
            links => {
                'slot.book' => {
                    rel           => 'slot.book',
                    href          => 'slots/:id',
                    method        => 'POST',
                    uri_schema    => { id => { type => 'number' } },
                    data_schema   => { '__ref__' => '/schemas/patient' },
                    target_schema => { '__ref__' => '/schemas/appointment' }
                }
            }
        },
        '/schemas/appointment' => {
            id         => '/schemas/appointment',
            type       => 'object',
            properties => {
                slot    => { '__ref__' => '/schemas/slot' },
                patient => { '__ref__' => '/schemas/patient' },
            },
            links => {
                'appointment.read' => {
                    rel           => 'appointment.read',
                    href          => 'appointment/:id',
                    method        => 'GET',
                    uri_schema    => { id => { type => 'number' } },
                    target_schema => { '__ref__' => '#' }
                },
                'appointment.cancel' => {
                    rel          => 'appointment.cancel',
                    href         => 'appointment/:id',
                    method       => 'DELETE',
                    uri_schema   => { id => { type => 'number' } },
                    data_schema  => {
                        type       => 'object',
                        properties => {
                            reason => { type => 'string' }
                        }
                    },
                },
            }
        }
    },
    '... got the right transport compiled schema /schemas/appointment'
);

is_deeply(
    $repo->get_schema_compiled_for_transport('/schemas/slot'),
    {
        '/schemas/patient' => {
            id         => '/schemas/patient',
            type       => 'object',
            properties => {
                name => { type => 'string' },
            }
        },
        '/schemas/doctor' => {
            id         => '/schemas/doctor',
            type       => 'object',
            properties => {
                name => { type => 'string' }
            },
            links => {
                'doctor.open_slots' => {
                    rel          => 'doctor.open_slots',
                    href         => 'doctors/:id/slots/open',
                    method       => 'GET',
                    uri_schema   => { id => { type => 'number' } },
                    data_schema  => {
                        type       => 'object',
                        properties => {
                            date => { type => 'number' }
                        }
                    },
                    target_schema => {
                        type  => 'array',
                        items => { '__ref__' => '/schemas/slot' }
                    },
                }
            }
        },
        '/schemas/slot' => {
            id         => '/schemas/slot',
            type       => 'object',
            properties => {
                date   => { type => 'number' },
                start  => { type => 'number' },
                end    => { type => 'number' },
                doctor => { '__ref__' => '/schemas/doctor' },
            },
            links => {
                'slot.book' => {
                    rel           => 'slot.book',
                    href          => 'slots/:id',
                    method        => 'POST',
                    uri_schema    => { id => { type => 'number' } },
                    data_schema   => { '__ref__' => '/schemas/patient' },
                    target_schema => { '__ref__' => '/schemas/appointment' }
                }
            }
        },
        '/schemas/appointment' => {
            id         => '/schemas/appointment',
            type       => 'object',
            properties => {
                slot    => { '__ref__' => '/schemas/slot' },
                patient => { '__ref__' => '/schemas/patient' },
            },
            links => {
                'appointment.read' => {
                    rel           => 'appointment.read',
                    href          => 'appointment/:id',
                    method        => 'GET',
                    uri_schema    => { id => { type => 'number' } },
                    target_schema => { '__ref__' => '#' }
                },
                'appointment.cancel' => {
                    rel          => 'appointment.cancel',
                    href         => 'appointment/:id',
                    method       => 'DELETE',
                    uri_schema   => { id => { type => 'number' } },
                    data_schema  => {
                        type       => 'object',
                        properties => {
                            reason => { type => 'string' }
                        }
                    },
                },
            }
        }
    },
    '... got the right transport compiled schema /schemas/slot'
);

done_testing;