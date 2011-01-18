package Jackalope::Schema::Repository;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Clone 'clone';
use Data::Visitor::Callback;

has '_compiled_schemas' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} }
);

has 'validator' => (
    is       => 'ro',
    isa      => 'Jackalope::Schema::Validator',
    required => 1
);

has 'spec' => (
    is       => 'ro',
    isa      => 'Jackalope::Schema::Spec',
    required => 1
);

sub DUMP {
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    return Dumper(
        Data::Visitor::Callback->new(
            hash => sub {
                my (undef, $data) = @_;
                delete $data->{'description'} unless ref $data->{'description'};
                delete $data->{'title'}       unless ref $data->{'title'};
                $data;
            }
        )->visit( $_[0] )
    );
}

sub BUILD {
    my $self = shift;

    # make sure the validator
    # has validations for all
    # the core types in the spec
    my $validator = $self->validator;
    foreach my $type ( $self->spec->valid_types ) {
        $validator->has_validator_for( $type )
            || confess "Validator missing validation routine for type($type)";
    }

    # compile all the schemas ...
    $self->_compiled_schemas( $self->_compile_core_schemas );
}

## Useful Predicates

sub is_a_schema_ref {
    my ($self, $ref) = @_;
    (defined $ref && ref $ref eq 'HASH')
        || confess "Ref must be defined and a HashRef";
    $self->_is_ref( $ref );
}

## Schema Accessors

sub get_compiled_schema_by_uri {
    my ($self, $uri) = @_;
    my $schema = $self->_compiled_schemas->{ $uri }
        || confess "Could not find schema for $uri";
    $schema->{'compiled'};
}

sub get_compiled_schema_for_type {
    my ($self, $type) = @_;
    my $schema = $self->_compiled_schemas->{ $self->spec->get_uri_for_type( $type ) }
        || confess "Could not find schema for $type";
    $schema->{'compiled'};
}

sub get_compiled_schema_by_ref {
    my ($self, $ref) = @_;
    ($self->_is_ref( $ref ))
        || confess "$ref is not a ref";
    my $schema = $self->_resolve_ref( $ref, $self->_compiled_schemas )
        || confess "Could not find schema for " . $ref->{'$ref'};
    $schema->{'compiled'};
}

sub get_schema_compiled_for_transport {
    my ($self, $uri) = @_;
    my $schema = $self->_compiled_schemas->{ $uri }
        || confess "Could not find schema for $uri";
    unless ( $self->_is_schema_compiled_for_transport( $schema ) ) {
        $schema = $self->_compile_schema_for_tranport( $schema );
    }
    $self->_create_transport_schema_map( $schema );
}

## Validators

sub validate {
    my ($self, $schema, $data) = @_;
    my $compiled_schema = $self->_compile_schema( $schema );
    $self->_validate_schema( $compiled_schema->{'compiled'} );
    return $self->validator->validate(
        $compiled_schema->{'compiled'},
        $data
    );
}

sub register_schema {
    my ($self, $schema) = @_;
    (exists $schema->{id})
        || confess "Can only register schemas that have an 'id'";
    my $compiled_schema = $self->_compile_schema( $schema );
    $self->_validate_schema( $compiled_schema->{'compiled'} );
    $self->_insert_compiled_schema( $compiled_schema );
    return $compiled_schema->{'compiled'};
}

sub register_schemas {
    my ($self, $schemas) = @_;
    (exists $_->{id})
        || confess "Can only register schemas that have an 'id'"
            foreach @$schemas;
    my @schema_ids = map { $_->{'id'} } @$schemas;
    my $schema_map = $self->_compile_schemas( @$schemas );
    return [
        map {
            $self->_validate_schema( $_->{'compiled'} );
            $self->_insert_compiled_schema( $_ );
            $_->{'compiled'};
        } @{ $schema_map }{ @schema_ids }
    ];
}

# ...

sub _validate_schema {
    my ($self, $schema) = @_;

    my $schema_type = $schema->{'type'};

    (defined $schema_type)
        || confess "schema id(" . $schema->{'id'} . ") does not have a type specified";

    my $result = $self->validator->validate(
        $self->get_compiled_schema_for_type( $schema_type ),
        $schema
    );

    if (exists $result->{error}) {
        require Data::Dumper;
        $Data::Dumper::Sortkeys = 1;
        die Data::Dumper::Dumper(
            {
                '001-error'       => "Invalid schema",
                '002-result'      => $result,
                '003-schema'      => $schema,
                '004-meta_schema' => $self->get_compiled_schema_for_type( $schema_type )
            }
        );
    }
}

# private compiled schema stuff

sub _insert_compiled_schema {
    my ($self, $schema) = @_;
    $self->_compiled_schemas->{ $schema->{'compiled'}->{'id'} } = $schema;
}

# Schema compilation

sub _compile_schema_for_tranport {
    my ( $self, $schema ) = @_;
    $schema = $self->_prepare_schema_for_transport( $schema );
    $self->_flatten_extends( 'for_transport', $schema, $self->_compiled_schemas );
    $self->_resolve_embedded_extends( 'for_transport', $schema, $self->_compiled_schemas );
    $self->_prune_schema_for_transport( $schema->{'for_transport'} );
    $schema;
}

sub _compile_schema {
    my ($self, $schema) = @_;

    if ($self->_is_ref( $schema )) {
        $schema = $self->_resolve_ref( $schema, $self->_compiled_schemas )
            || confess "Could not find schema for " . $schema->{'$ref'};
    }

    unless ( $self->_is_schema_compiled( $schema ) ) {
        $schema = $self->_prepare_schema_for_compiling( $schema );
        $self->_flatten_extends( 'compiled', $schema, $self->_compiled_schemas );
        $self->_resolve_embedded_extends( 'compiled', $schema, $self->_compiled_schemas );
        $self->_resolve_refs( 'compiled', $schema, $self->_compiled_schemas );
        $self->_mark_as_compiled( $schema );
    }

    return $schema;
}

sub _compile_schemas {
    my $self    = shift;
    my @schemas = map {
        $self->_prepare_schema_for_compiling( $_ )
    } @_;

    my $schema_map = $self->_generate_schema_map( @schemas );

    foreach my $schema ( @schemas ) {
        $self->_flatten_extends( 'compiled', $schema, $schema_map );
    }

    foreach my $schema ( @schemas ) {
        $self->_resolve_embedded_extends( 'compiled', $schema, $schema_map );
    }

    foreach my $schema ( @schemas ) {
        $self->_resolve_refs( 'compiled', $schema, $schema_map );
    }

    foreach my $schema ( @schemas ) {
        $self->_mark_as_compiled( $schema );
    }

    return $schema_map;
}

sub _compile_core_schemas {
    my $self = shift;
    $self->_compile_schemas( values %{ $self->spec->get_spec->{'schema_map'} } );
}

sub _prepare_schema_for_compiling {
    my ($self, $raw) = @_;

    my $schema = +{
        raw         => $raw,
        compiled    => clone( $raw ),
        is_compiled => 0,
    };

    # NOTE:
    # this might not be good idea
    # - SL
    delete $schema->{'compiled'}->{'id'} unless $schema->{'compiled'}->{'id'};

    return $schema;
}

sub _prepare_schema_for_transport {
    my ($self, $schema) = @_;
    $schema->{'for_transport'} = clone( $schema->{'raw'} );
    return $schema;
}

sub _mark_as_compiled {
    my ($self, $schema) = @_;
    $schema->{'is_compiled'} = 1;
}

sub _is_schema_compiled {
    my ($self, $schema) = @_;
    (exists $schema->{'is_compiled'} && $schema->{'is_compiled'} == 1) ? 1 : 0
}

sub _is_schema_compiled_for_transport {
    my ($self, $schema) = @_;
    exists $schema->{'for_transport'} ? 1 : 0
}

sub _generate_schema_map {
    my ($self, @schemas) = @_;
    return +{
        %{ $self->_compiled_schemas },
        (map { $_->{'compiled'}->{'id'} => $_ } @schemas)
    }
}

sub _prune_schema_for_transport {
    my ($self, $transport_schema) = @_;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        hash => sub {
            my ($v, $data) = @_;
            if (exists $data->{'description'} && not ref $data->{'description'}) {
                delete $data->{'description'};
            }
            if (exists $data->{'title'} && not ref $data->{'title'}) {
                delete $data->{'title'};
            }
        }
    )->visit( $transport_schema );
}

sub _create_transport_schema_map {
    my ($self, $schema, $transport_map) = @_;

    $transport_map ||= {
        $schema->{'compiled'}->{'id'} => $schema->{'for_transport'}
    };

    my $schema_map = $self->_compiled_schemas;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        hash => sub {
            my ($v, $data) = @_;
            if (exists $data->{'$ref'} && $self->_is_ref( $data )) {
                unless ($self->_is_self_ref( $data )) {
                    unless ( exists $transport_map->{ $data->{'$ref'} } ) {
                        my $s = $self->_resolve_ref( $data, $schema_map );
                        (defined $s)
                            || confess "Could not find schema for " . $data->{'$ref'};
                        unless ( $self->_is_schema_compiled_for_transport( $s ) ) {
                            $s = $self->_compile_schema_for_tranport( $s );
                        }
                        $transport_map->{ $s->{'compiled'}->{'id'} } = $s->{'for_transport'};
                        $self->_create_transport_schema_map( $s, $transport_map );
                    }
                }
            }
        }
    )->visit(
        $schema->{'for_transport'}
    );

    $transport_map;
}


# compiling extensions

sub _flatten_extends {
    my ($self, $which, $schema, $schema_map) = @_;
    if ( exists $schema->{'raw'}->{'extends'} && $self->_is_ref( $schema->{'raw'}->{'extends'} ) ) {
        my $super_schema = $self->_resolve_ref( $schema->{'raw'}->{'extends'}, $schema_map );
        (defined $super_schema)
            || confess "Could not find '" . $schema->{'raw'}->{'extends'}->{'$ref'} . "' schema to extend";
        $self->_merge_schema(
            $which,
            $schema,
            $super_schema,
            $schema_map
        );
        $schema->{ $which }->{'properties'}            = $self->_merge_properties( properties            => $schema, $schema_map );
        $schema->{ $which }->{'additional_properties'} = $self->_merge_properties( additional_properties => $schema, $schema_map );
        $schema->{ $which }->{'links'}                 = $self->_merge_properties( links                 => $schema, $schema_map );
        delete $schema->{ $which }->{'extends'};
    }
}

sub _merge_schema {
    my ($self, $which, $schema, $super, $schema_map) = @_;
    foreach my $key ( keys %{ $super->{'raw'} } ) {
        next if $key eq 'id'                     # ID should never be copied
             || $key eq 'properties'             # properties will be copied later
             || $key eq 'additional_properties'  # additional_properties will be copied later
             || $key eq 'links';                 # links will be copied later
        if ( not exists $schema->{'raw'}->{ $key } ) {
            $schema->{ $which }->{ $key } = ref $super->{'raw'}->{ $key }
                                            ? clone( $super->{'raw'}->{ $key } )
                                            : $super->{'raw'}->{ $key };
        }
    }
    if ( $super->{'raw'}->{'extends'} && $self->_is_ref( $super->{'raw'}->{'extends'} ) ) {
        my $super_schema = $self->_resolve_ref( $super->{'raw'}->{'extends'}, $schema_map );
        (defined $super_schema)
            || confess "Could not find '" . $super->{'raw'}->{'extends'}->{'$ref'} . "' schema to extend";
        $self->_merge_schema(
            $which,
            $schema,
            $super_schema,
            $schema_map
        );
    }
}

sub _merge_properties {
    my ($self, $prop_type, $schema, $schema_map) = @_;
    return +{
        (exists $schema->{'raw'}->{'extends'}
            ? %{
                $self->_merge_properties(
                    $prop_type,
                    $self->_resolve_ref( $schema->{'raw'}->{'extends'}, $schema_map ),
                    $schema_map
                )
              }
            : ()),
        %{ clone( $schema->{'raw'}->{ $prop_type } || {} ) },
    }
}

# resolving references in a schema

sub _resolve_refs {
    my ($self, $which, $schema, $schema_map) = @_;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        hash => sub {
            my ($v, $data) = @_;
            if (exists $data->{'$ref'} && $self->_is_ref( $data )) {
                if ($self->_is_self_ref( $data )) {
                    $_ = $schema->{ $which };
                }
                else {
                    my $s = $self->_resolve_ref( $data, $schema_map );
                    (defined $s)
                        || confess "Could not find schema for " . $data->{'$ref'};
                    $_ = $s->{ $which };
                }
            }
        }
    )->visit(
        $schema->{ $which }
    );
}

sub _resolve_embedded_extends {
    my ($self, $which, $schema, $schema_map) = @_;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        hash => sub {
            my ($v, $data) = @_;
            if ( exists $data->{'extends'} && $self->_is_ref( $data->{'extends'} ) ) {
                my $embedded_schema = $self->_prepare_schema_for_compiling( $data );
                my $new_schema_map  = { %$schema_map, '#' => $schema };
                my $super_schema    = $self->_resolve_ref( $data->{'extends'}, $new_schema_map );
                (defined $super_schema)
                    || confess "Could not find '" . $data->{'extends'}->{'$ref'} . "' schema to extend";
                $self->_merge_schema(
                    $which,
                    $embedded_schema,
                    $super_schema,
                    $new_schema_map
                );
                $embedded_schema->{ $which }->{'properties'}            = $self->_merge_properties( properties            => $embedded_schema, $new_schema_map );
                $embedded_schema->{ $which }->{'additional_properties'} = $self->_merge_properties( additional_properties => $embedded_schema, $new_schema_map );
                $embedded_schema->{ $which }->{'links'}                 = $self->_merge_properties( links                 => $embedded_schema, $new_schema_map );
                delete $embedded_schema->{ $which }->{'extends'};
                $_ = $embedded_schema->{ $which };
            }
        }
    )->visit(
        $schema->{ $which }
    );
}

# Ref utils

sub _resolve_ref {
    my ($self, $ref, $schema_map) = @_;
    return $schema_map->{ $ref->{'$ref'} };
}

sub _is_ref {
    my ($self, $ref) = @_;
    return (exists $ref->{'$ref'} && ((scalar keys %$ref) == 1) && not ref $ref->{'$ref'}) ? 1 : 0;
}

sub _is_self_ref {
    my ($self, $ref) = @_;
    return ($self->_is_ref( $ref ) && $ref->{'$ref'} eq '#') ? 1 : 0;
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Repository - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Repository;

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
