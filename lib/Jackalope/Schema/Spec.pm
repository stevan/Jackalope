package Jackalope::Schema::Spec;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

# for readability
sub true () { 1 }

## formatters needed for bootstrap
has 'valid_formatters' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [qw[
            uri
            uri_template
            regex
        ]]
    },
);

## basic set of hyperlink relations
has 'valid_hyperlink_relation' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [qw[
            self
            described_by
            create
        ]]
    },
);

has 'valid_types' => (
    is      => 'ro',
    isa     => 'ArrayRef',   
    default => sub {
        [qw[
            any
                null
                boolean
                number
                    integer
                string
                array
                object
                    schema        
        ]]
    },
);

## ------------------------------------------------------------------
## Jackalope Schema Spec
## ------------------------------------------------------------------
## This is the spec for a Jackalope Schema description, it is
## written itself as a Jackalope Schema description and so
## should be able to parse and validate itself.
##
## It is best to read this entire document from top to bottom, and
## then to re-read it again, in order to fully understand the spec.
## ------------------------------------------------------------------

sub meta_schemas {
    my $self = shift;

    ## ------------------------------------------------------------------
    ## Reference Schema
    ## ------------------------------------------------------------------
    ## The reference schema is needed in order to improve the
    ## re-usability of schemas, so therefore is added as a
    ## core element of the spec.
    ## ------------------------------------------------------------------

    my $ref = {
        id          => "schema/core/ref",
        title       => "The reference schema",
        description => q[
            This is an object to represent a 'reference'
            to another object. By convention, the value
            stored in $ref is the 'id' of another object.
            Additionally the value of '#' is also
            acceptable to indicate a reference to
            the containing schema.

            When a reference is encountered, it should
            be resolved and replaced by the value it
            references. There are no explict dereferencing
            operations. The exact details of when a
            reference is resolved and how are an implemention
            detail and out of the scope of this spec.
        ],
        type        => "object",
        properties  => {
            '$ref' => { type => "string", format => "uri" }
        }
    };

    ## ------------------------------------------------------------------
    ## Hyperlink Schema
    ## ------------------------------------------------------------------
    ## The Hyperlink schema is an additional schema which provides a way
    ## to talk about and describe links for resources.
    ## ------------------------------------------------------------------

    my $hyperlink = {
        id          => "schema/core/hyperlink",
        title       => "The 'Link' schema",
        description => q[
            This is the 'link' type for the hyper schema
            which represents links for resources.
        ],
        type        => "object",
        properties  => {
            relation => {
                type        => "string",
                enum        => [ @{ $self->valid_hyperlink_relation } ],
                description => q[
                    The relation of the link to the resource described
                    by the schema. Currently available values are:
                        self         - relating to an instance of the schema
                        described_by - a link the schema itself
                        create       - a link used to create instances
                ]
            },
            href => {
                type        => "string",
                format      => "uri_template",
                description => q[
                    This is a URI for the resource, it may also
                    be a URI template containing variables. In the
                    case of these templates the variables should be
                    resolved in the context of the object instance.
                    This means that a template like so:

                        /product/{id}/view

                    should be resolved to be this:

                        /product/1234/view

                    given an object with an 'id' property of 1234.
                ]
            },
        },
        additional_properties => {
            target_schema => {
                type        => "schema",
                description => q[
                    This is a schema (or a reference to a schema),
                    of the resource being linked to. Typically this
                    will be just { '$ref' => '#' } to indicate that
                    it refers to the schema it is contained within.
                ]
            },
            schema       => {
                type        => "schema",
                description => q[
                    This is a schema (or a reference to a schema)
                    of the submission data that will be accepted
                    by this link. In the case of a POST or PUT
                    method, the data is expected in the given
                    transport format. In the case of GET, this
                    should be an 'object' type schema and the
                    query string parameters should be checked
                    against it.
                ]
            },
            method       => {
                type        => "string",
                enum        => [ "GET", "POST", "PUT", "DELETE" ],
                description => "The HTTP method expected by this link"
            },
            title        => { type => "string", description => "The human readable title of a given link" },
            description  => { type => "string", description => "A short human readable description of the link" },
            metadata     => {
                type        => "object",
                description => q[
                    This is just a place for random additional metadata
                    that might be useful for your given implementation.
                    This is totally free form and can be anything you want.
                ]
            }
        }
    };

    ## ------------------------------------------------------------------
    ## Core Schema Types
    ## ------------------------------------------------------------------
    ## The schemas are split up into their respective types. The basic
    ## types represented here are those of JSON objects, but they should
    ## be compatible with any other data representation language out
    ## there, and easily implemented in any host language. The basic
    ## type structure is as follows:
    ##   Any
    ##       Null
    ##       Boolean
    ##       Number
    ##           Integer
    ##       String
    ##       Array[ T ]
    ##       Object[ String, T ]
    ## ------------------------------------------------------------------

    my $any = {
        id          => "schema/types/any",
        title       => "The 'Any' type schema",
        description => q[
            This is a schema for the 'any' type, it is the
            base schema type, all other schema types extend
            this one. Therefore this schema defines the
            base elements that are in all schemas, both
            required and optional.
        ],
        type        => "schema",
        properties  => {
            type => { type => "string", enum => [ "any" ] }
        },
        additional_properties => {
            id          => { type => "string", format => "uri", description => "This should be a URI" },
            title       => { type => "string", description => "The human readable title of a given schema" },
            description => { type => "string", description => "A short human readable description of the schema" },
            extends     => {
                type        => "schema",
                description => q[
                    This is a schema (or a reference to a schema)
                    represented as an 'object' instance. The exact
                    details of extension are described elsewhere.
                ]
            },
            links => {
                type        => "array",
                items       => { '$ref' => "schema/core/hyperlink" },
                is_unique   => true,
                description => q[
                    This is an array of 'link' objects, the purpose
                    of which is to provide a way to map services
                    to the objects described in a schema. In OOP terms,
                    you can think of them as methods, while the schema
                    describes the instance structure.
                ]
            }
        }
    };

    my $null = {
        id          => "schema/types/null",
        title       => "The 'Null' type schema",
        description => q[
            This is a schema for the 'null' type, it is not
            so much the absence of a value, but a value that
            explicity represents no value.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/any" },
        properties  => {
            type => { type => "string", enum => [ "null" ] }
        }
    };

    my $boolean = {
        id          => "schema/types/boolean",
        title       => "The 'Boolean' type schema",
        description => q[
            This is a schema for the 'boolean' type, a simple
            true/false value. However the details of what is
            considered true and what is considered false
            are different for different languages and this
            schema should take that into account based on the
            language it is validating. It is important to note
            that a transport format (JSON, XML, etc.) should
            provide a canonical representation of true/false
            so as to remove those language specific quirks.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/any" },
        properties  => {
            type => { type => "string", enum => [ "boolean" ] }
        }
    };

    my $number = {
        id          => "schema/types/number",
        title       => "The 'Number' type schema",
        description => q[
            This is a schema for the 'number' type, which is
            a numeric value that includes floating point
            numbers as well as whole numbers. The level of
            floating point precision and the possible size
            of a number are platform and implementation
            specific. However the spec reserves the right
            to possibly put a cap on this at a later date
            to help improve interoperability.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/any" },
        properties  => {
            type => { type => "string", enum => [ "number" ] },
        },
        additional_properties => {
            less_than             => { type => "number", description => "A number must be less than this value" },
            less_than_or_equal    => { type => "number", description => "A number must be less than or equal to this value" },
            greater_than          => { type => "number", description => "A number must be greater than this value" },
            greater_than_or_equal => { type => "number", description => "A number must be greater than or equal to this value" },
            enum             => {
                type        => "array",
                items       => { type => "number" },
                is_unique   => true,
                description => "This is an array of possible acceptable values, it should contain no duplicates"
            }
        }
    };

    my $integer = {
        id          => "schema/types/integer",
        title       => "The 'Integer' type schema",
        description => q[
            This is a schema for the 'integer' type, which is
            an extension of the 'number' type to not include
            floating point numbers. It handles all the same
            additional properties, but overrides them here
            such that they will only operate on valid integer
            values.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/number" },
        properties  => {
            type => { type => "string", enum => [ "integer" ] },
        },
        additional_properties => {
            less_than             => { type => "integer", description => "A integer must be less than this value" },
            less_than_or_equal    => { type => "integer", description => "A integer must be less than or equal to this value" },
            greater_than          => { type => "integer", description => "A integer must be greater than this value" },
            greater_than_or_equal => { type => "integer", description => "A integer must be greater than or equal to this value" },
            enum    => {
                type        => "array",
                items       => { type => "integer" },
                is_unique   => true,
                description => "This is an array of possible acceptable values, it should contain no duplicates"
            },
        }
    };

    my $string = {
        id          => "schema/types/string",
        title       => "The 'String' type schema",
        description => q[
            This is a schema for the 'string' type, which is
            any value that is explcitly cast as a string. This
            means that it can be an entirely numeric string,
            as long it is cast as a string based on the details
            of the implementation language. As with 'boolean'
            values, any transport format (JSON, XML, etc.) is
            expected to provide some kind of way to explicitly
            cast a given value as a given type so as to make
            for better interoperability.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/any" },
        properties  => {
            type => { type => "string", enum => [ "string" ] },
        },
        additional_properties => {
            min_length => { type => "number", description => "The minimum length of the string given" },
            max_length => { type => "number", description => "The maximum length of the string given" },
            pattern    => { type => "string", format => "regex", description => "A regular expression that can be checked against the string" },
            format     => {
                type        => "string",
                enum        => [ @{ $self->valid_formatters } ],
                description => "This is one of a set of built-in formatters",
            },
            enum       => {
                type        => "array",
                items       => { type => "string" },
                is_unique   => true,
                description => "This is an array of possible acceptable values, it should contain no duplicates"
            },
        }
    };

    my $array = {
        id          => "schema/types/array",
        title       => "The 'Array' type schema",
        description => q[
            This is a schema for the 'array' type, which is
            basically just a list of other values. The list
            by default are heterogenous, but using the
            optional 'items' property it is possible to
            constrain the list to be more homogenous.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/any" },
        properties  => {
            type => { type => "string", enum => [ "array" ] },
        },
        additional_properties => {
            min_items => { type => "integer", description => "The minimum number of items in the array" },
            max_items => { type => "integer", description => "The maximum number of items in the array" },
            is_unique => { type => "boolean", description => "A boolean to indicate of the list should contain no duplicates" },
            items     => {
                type        => "schema",
                description => q[
                    This is a schema (or a reference to a schema)
                    represented as an 'object' instance, which will
                    be used to validate all the elements in a list.
                ]
            },
        }
    };

    my $object = {
        id          => "schema/types/object",
        title       => "The 'Object' type schema",
        description => q[
            This is a schema for the 'object' type, which is
            a set of key/value pairs. The term 'object' is
            derived from Javascript, but this is the same as
            a hash in Perl, a dictionary in Python, an
            associative array in PHP, a Hashtable, a Map,
            all of which are essentially the same thing.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/any" },
        properties  => {
            type => { type => "string", enum => [ "object" ] },
        },
        additional_properties => {
            items      => {
                type        => "schema",
                description => q[
                    This is a schema (or a reference to a schema)
                    represented as an 'object' instance, which will
                    be used to validate all the values in the object.
                ]
            },
            properties => {
                type        => "object",
                items       => { type => "schema" },
                description => q[
                    This is a set of key/value pairs where the
                    key is a property name and the value is
                    a schema (or a reference to a schema)
                    represented as an 'object' instance. All
                    these properties are required and must be
                    present in order to pass validation.
                ]
            },
            additional_properties => {
                type        => "object",
                items       => { type => "schema" },
                description => q[
                    This is a set of key/value pairs where the
                    key is a property name and the value is
                    a schema (or a reference to a schema)
                    represented as an 'object' instance. These
                    properties however are optional and do not
                    need to exist in order to pass validation.
                ]
            }
        }
    };

    ## ------------------------------------------------------------------
    ## The Bootstrap type
    ## ------------------------------------------------------------------

    my $schema = {
        id          => "schema/types/schema",
        title       => "The 'Schema' type schema",
        description => q[
            This is a schema for the 'schema' type, it is
            composed entirely of turtles all the way down.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/object" },
        properties  => {
            type => { type => "string", enum => [ "schema" ] },
        },
    };

    ## ------------------------------------------------------------------
    ## The End
    ## ------------------------------------------------------------------

    [
        $ref,
        $hyperlink,
        $any,
            $null,
            $boolean,
            $number,
                $integer,
            $string,
            $array,
            $object,
                $schema
    ];
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Spec - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Spec;

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
