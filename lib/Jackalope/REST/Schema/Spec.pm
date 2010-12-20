package Jackalope::REST::Schema::Spec;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Jackalope::Schema::Spec';

override '_all_spec_builder_methods' => sub {
    my $self = shift;
    super(), qw[
        resource
        resource_ref

        service_readonly
        service_non_editable
        service
    ]
};

## ------------------------------------------------------------------
## Resource Schema
## ------------------------------------------------------------------
## The Resource schema is a simple wrapper for web based resources
## it is mostly intended to be used for extension where the body
## property is overriden with the schema of your choice.
## ------------------------------------------------------------------

sub resource {
    my $self = shift;
    return +{
        id          => "schema/web/resource",
        title       => "The 'Resource' schema",
        description => q[
            The is a 'wrapper' of sorts for resources
            as viewed from the concept of the web and
            REST. It is mostly intended to be extended
            where the 'body' property is overriden with
            the schema of our choice.
        ],
        type        => "object",
        properties  => {
            id      => {
                type        => "string",
                description => q[
                    This is the ID of the given resource, it is
                    assumed to be some kind of string, which should
                    still just work fine even for numeric values.
                    This is expected to be the lookup key for
                    resources in a resource repository.
                ]
            },
            body    => {
                type        => "any",
                description => q[
                    This is the body of the resource, it is of type
                    'any' for now, but it as this schema is meant to
                    be extended and this property overridden, this is
                    basically whatever you need it to be.
                ]
            },
            version => {
                type        => "string",
                'format'    => "digest",
                description => q[
                    This is a digest string (SHA-256) representing the current
                    version of the resource. When the resource is updated
                    the version should be compared first, to make sure
                    that it has not been updated by another.
                ]
            }
        },
        additional_properties => {
            links   => {
                type        => "array",
                items       => { '$ref' => "schema/core/hyperlink" },
                description => q[
                    This is a list of links which represent the
                    capabilities of given resource, the consumer of
                    the resource can use these links to perform
                    different actions.
                ]
            }
        }
    }
}

## ------------------------------------------------------------------
## Resource Ref Schema
## ------------------------------------------------------------------
## The Resource Ref schema is meant to be a way to represent
## references to resources, it can be a convient way to refer
## to a resource only by it's ID and therefore save bandwidth.
## ------------------------------------------------------------------

sub resource_ref {
    my $self = shift;
    return +{
        id          => "schema/web/resource/ref",
        title       => "The 'Resource Ref' schema",
        description => q[
            This is meant to be a way to represent
            references to resources, it can be a convient
            way to refer to a resource only by it's ID
            and therefore save bandwidth.
        ],
        type        => "object",
        properties  => {
            '$id' => {
                type        => "string",
                description => q[
                    This is the lookup ID which can be
                    used to locate the resource.
                ]
            },
            type_of => {
                type        => "string",
                "format"    => "uri",
                description => q[
                    This is the schema URI for the type of
                    resource that this refers too.
                ]
            },
        },
        additional_properties => {
            link    => {
                extends               => { '$ref' => 'schema/core/hyperlink' },
                properties            => { rel    => { type => 'string', literal => 'read' } },
                additional_properties => { method => { type => 'string', literal => 'GET'  } },
                description           => q[
                    This is an optional hyperlink to read the resource
                    described, it should only ever be GET since it
                    is only for reading.
                ]
            },
            version => {
                type        => "string",
                'format'    => "digest",
                description => q[
                    This is a digest string (SHA-256) representing the current
                    version of the resource being pointed to. This can be used
                    to check to make sure that the resource has not changed
                    since it was last referred too.
                ]
            },
        }
    }
}

## ------------------------------------------------------------------
## Service Schemas
## ------------------------------------------------------------------
## The Service schema is a simple template for REST based web
## service that follows a convention for the standard operations
## that would be performed on a REST resource collection.
## ------------------------------------------------------------------

sub service_readonly {
    my $self = shift;
    return +{
        id    => 'schema/web/service/read-only',
        title => 'This is a simple read-only REST enabled schema',
        type  => 'object',
        links => {
            describedby => {
                rel           => 'describedby',
                href          => '/schema',
                method        => 'GET',
                target_schema => { '$ref' => 'schema/types/schema' },
            },
            list => {
                rel           => 'list',
                href          => '/',
                method        => 'GET',
                target_schema => {
                    type  => "array",
                    items => {
                        type       => 'object',
                        extends    => { '$ref' => 'schema/web/resource' },
                        properties => {
                            body => { '$ref' => '#' },
                        }
                    }
                },
            },
            read => {
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
            }
        }
    };
}

sub service_non_editable {
    my $self = shift;
    return +{
        id      => 'schema/web/service/non-editable',
        title   => 'This is a simple REST enabled schema',
        extends => { '$ref' => 'schema/web/service/read-only' },
        links   => {
            create => {
                rel           => 'create',
                href          => '/',
                method        => 'POST',
                data_schema   => { '$ref' => '#' },
                target_schema => {
                    type       => 'object',
                    extends    => { '$ref' => 'schema/web/resource' },
                    properties => {
                        body => { '$ref' => '#' },
                    }
                },
            },
            delete => {
                rel           => 'delete',
                href          => '/:id',
                method        => 'DELETE',
                uri_schema    => {
                    id => { type => 'string' }
                }
            }
        }
    };
}

sub service {
    my $self = shift;
    return +{
        id      => 'schema/web/service/crud',
        title   => 'This is a simple REST enabled schema',
        extends => { '$ref' => 'schema/web/service/non-editable' },
        links   => {
            edit => {
                rel           => 'edit',
                href          => '/:id',
                method        => 'PUT',
                data_schema   => {
                    type       => 'object',
                    extends    => { '$ref' => 'schema/web/resource' },
                    properties => {
                        body => { '$ref' => '#' },
                    }
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
            }
        }
    };
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Schema::Spec - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Schema::Spec;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
