package Jackalope::Schema::Spec;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::Util;

has 'valid_formatters' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [qw[
            uri
            uri_template
            regex
            uuid
            digest
        ]]
    },
);

has 'typemap' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        +{
            any             => 'schema/types/any',
                null        => 'schema/types/null',
                boolean     => 'schema/types/boolean',
                number      => 'schema/types/number',
                    integer => 'schema/types/integer',
                string      => 'schema/types/string',
                array       => 'schema/types/array',
                object      => 'schema/types/object',
                    schema  => 'schema/types/schema',
        }
    },
    handles => {
        'valid_types'      => 'keys',
        'get_uri_for_type' => 'get',
    }
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

# this is essentially a cache
# for the complied spec.
has '_spec' => (
    init_arg => undef,
    reader   => 'get_spec',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_spec'
);

sub _build_spec {
    my $self       = shift;
    my $typemap    = $self->typemap;
    my $schema_map = {};

    foreach my $type ( $self->_all_spec_builder_methods ) {
        my $schema = $self->$type();
        $schema_map->{ $schema->{'id'} } = $schema;
    }

    return +{
        version    => ${ $self->meta->get_package_symbol('$VERSION') } + 0,
        authority  => ${ $self->meta->get_package_symbol('$AUTHORITY') },
        typemap    => $typemap,
        schema_map => $schema_map,
        metadata   => {
            valid_formatters => $self->valid_formatters,
        }
    };
}

sub _all_spec_builder_methods {
    my $self = shift;
    keys %{ $self->typemap }, qw[ ref spec hyperlink xlink ]
}

## ------------------------------------------------------------------
## Spec Schema
## ------------------------------------------------------------------
## This basically specifies the Spec and how it should be structured.
## ------------------------------------------------------------------

sub spec {
    return +{
        id          => "schema/core/spec",
        title       => "The spec schema",
        description => "This is a schema to describe the full spec",
        type        => "object",
        properties  => {
            version   => { type => 'number' },
            authority => { type => 'string' },
            typemap   => {
                type        => "object",
                items       => { type => "string", 'format' => "uri" },
                description => "This is a mapping of the core type names to thier schema IDs."
            },
            schema_map => {
                type        => "object",
                items       => { type => "schema" },
                description => "This is the mapping of schema ID to schema, it is used for schema lookup"
            }
        },
        additional_properties => {
            metadata => {
                type        => "object",
                description => q[
                    This is a free-form metadata object where extra
                    information can be stored. None of the information
                    that is contained in here should be relied on, if
                    and when we need to rely on it, we can promote it
                    to a real property.
                ]
            }
        }
    };
}

## ------------------------------------------------------------------
## Reference Schema
## ------------------------------------------------------------------
## The reference schema is needed in order to improve the
## re-usability of schemas, so therefore is added as a
## core element of the spec.
## ------------------------------------------------------------------

sub ref {
    return +{
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
            '$ref' => { type => "string", 'format' => "uri" }
        }
    };
}

## ------------------------------------------------------------------
## Hyperlink Schema
## ------------------------------------------------------------------
## The Hyperlink schema is an additional schema which provides a way
## to talk about and describe links for resources.
## ------------------------------------------------------------------

sub hyperlink {
    my $self = shift;
    return +{
        id          => "schema/core/hyperlink",
        title       => "The 'HyperLink' schema",
        description => q[
            This is the 'link' type for the hyper schema
            which represents links for resources.
        ],
        type        => "object",
        properties  => {
            rel => {
                type        => "string",
                description => q[
                    This string should in some way describe the relation
                    of the link to the object instance. The validity of
                    the values is determined by the consumer of the
                    link data. By convention it should either be one
                    of well-know link relations, which can be found here
                    http://www.iana.org/assignments/link-relations/link-relations.xhtml,
                    or a URI specific to the consumer of this link data.
                ]
            },
            href => {
                type        => "string",
                'format'    => "uri_template",
                description => q[
                    This is a URI for the resource, it may also
                    be a URI template containing variables (using the
                    RoR style colon prefix). In the case of these
                    templates the variables should be resolved in
                    the context of the object instance. This means
                    that a template like so:

                        /product/:id/view

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
            data_schema  => {
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
            uri_schema   => {
                type        => "object",
                items       => { type => 'schema' },
                description => q[
                    This is a schema (or a reference to a schema)
                    of the results of the mapping of the URI-template
                    in the 'href' property. On the server side it
                    can be used to validate the value that we get,
                    and on the client side it can be used to check
                    to assure the URL being called is valid.
                ]
            },
            method       => {
                type        => "string",
                enum        => [ "GET", "POST", "PUT", "DELETE" ],
                description => q[
                    The HTTP method expected by this link, if
                    this isn't included then GET is assumed.
                ],
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
}

## ------------------------------------------------------------------
## Xlink Schema
## ------------------------------------------------------------------
## The Xlink schema is an additional schema which provides a way
## to represent concrete links that are described with the hyperlink
## schema above.
## ------------------------------------------------------------------

sub xlink {
    my $self = shift;
    return +{
        id          => "schema/core/xlink",
        title       => "The 'XLink' schema",
        description => q[
            This is the 'link' type for the hyper schema
            which represents the concrete links that are
            described with the hyperlink schema.
        ],
        type        => "object",
        properties  => {
            rel => {
                type        => "string",
                description => q[
                    This string describes the relation of the link
                    to the actual resource it points to. For more
                    details see the docs for the 'rel' element
                    in the schema/core/hyperlink schema.
                ]
            },
            href => {
                type        => "string",
                'format'    => "uri",
                description => q[
                    This is a URI of the resource the link is pointing to.
                ]
            },
        },
        additional_properties => {
            method       => {
                type        => "string",
                enum        => [ "GET", "POST", "PUT", "DELETE" ],
                description => q[
                    The HTTP method expected by this link, if
                    this isn't included then GET is assumed.
                ],
            }
        }
    };
}

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

sub any {
    return +{
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
            type => { type => "string", literal =>"any" }
        },
        additional_properties => {
            id          => { type => "string", 'format' => "uri", description => "This should be a URI" },
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
}

sub null {
    return +{
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
            type => { type => "string", literal => "null" }
        }
    };
}

sub boolean {
    return +{
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
            type => { type => "string", literal => "boolean" }
        }
    };
}

sub number {
    return +{
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
            type => { type => "string", literal => "number" },
        },
        additional_properties => {
            less_than                => { type => "number", description => "A number must be less than this value" },
            less_than_or_equal_to    => { type => "number", description => "A number must be less than or equal to this value" },
            greater_than             => { type => "number", description => "A number must be greater than this value" },
            greater_than_or_equal_to => { type => "number", description => "A number must be greater than or equal to this value" },
            enum             => {
                type        => "array",
                items       => { type => "number" },
                is_unique   => true,
                description => "This is an array of possible acceptable values, it should contain no duplicates"
            }
        }
    };
}

sub integer {
    return +{
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
            type => { type => "string", literal => "integer" },
        },
        additional_properties => {
            less_than                => { type => "integer", description => "A integer must be less than this value" },
            less_than_or_equal_to    => { type => "integer", description => "A integer must be less than or equal to this value" },
            greater_than             => { type => "integer", description => "A integer must be greater than this value" },
            greater_than_or_equal_to => { type => "integer", description => "A integer must be greater than or equal to this value" },
            enum    => {
                type        => "array",
                items       => { type => "integer" },
                is_unique   => true,
                description => "This is an array of possible acceptable values, it should contain no duplicates"
            },
        }
    };
}

sub string {
    my $self = shift;
    return +{
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
            type => { type => "string", literal => "string" },
        },
        additional_properties => {
            literal    => { type => "string", description => "A literal value that must match exactly" },
            min_length => { type => "number", description => "The minimum length of the string given" },
            max_length => { type => "number", description => "The maximum length of the string given" },
            pattern    => { type => "string", 'format' => "regex", description => "A regular expression that can be checked against the string" },
            'format'   => {
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
}

sub array {
    return +{
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
            type => { type => "string", literal => "array" },
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
}

sub object {
    return +{
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
            type => { type => "string", literal => "object" },
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
}

## ------------------------------------------------------------------
## The Bootstrap type
## ------------------------------------------------------------------

sub schema {
    return +{
        id          => "schema/types/schema",
        title       => "The 'Schema' type schema",
        description => q[
            This is a schema for the 'schema' type, it is
            composed entirely of turtles all the way down.
        ],
        type        => "schema",
        extends     => { '$ref' => "schema/types/object" },
        properties  => {
            type => { type => "string", literal => "schema" },
        },
    };
}

## ------------------------------------------------------------------
## The End
## ------------------------------------------------------------------

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
