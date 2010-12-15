package Jackalope::Schema::Repository;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Data::UUID;
use Clone 'clone';
use Data::Visitor::Callback;

has '_compiled_schemas' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_compiled_schemas'
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

use Data::Dumper;
sub DUMP {
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
    $self->_compiled_schemas;
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

# ...

sub _validate_schema {
    my ($self, $schema) = @_;

    my $schema_type = $schema->{'type'};

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

sub _build_compiled_schemas {
    # by default we load in the core ...
    return (shift)->_compile_core_schemas;
}

sub _insert_compiled_schema {
    my ($self, $schema) = @_;
    $self->_compiled_schemas->{ $schema->{'compiled'}->{'id'} } = $schema;
}

# Schema compilation

sub _compile_schema {
    my ($self, $schema) = @_;

    if ($self->_is_ref( $schema )) {
        $schema = $self->_resolve_ref( $schema, $self->_compiled_schemas )
            || confess "Could not find schema for " . $schema->{'$ref'};
    }

    unless ( $self->_is_schema_compiled( $schema ) ) {
        $schema = $self->_prepare_schema_for_compiling( $schema );
        $self->_flatten_extends( $schema, $self->_compiled_schemas );
        $self->_resolve_embedded_extends( $schema, $self->_compiled_schemas );
        $self->_resolve_refs( $schema, $self->_compiled_schemas );
        $self->_mark_as_compiled( $schema );
    }

    return $schema;
}

sub _compile_core_schemas {
    my $self = shift;

    my $spec       = $self->spec->get_spec;
    my @schemas    = map { $self->_prepare_schema_for_compiling( $_ ) } values %{ $spec->{'schema_map'} };
    my $schema_map = $self->_generate_schema_map( @schemas );

    foreach my $schema ( @schemas ) {
        $self->_flatten_extends( $schema, $schema_map );
    }

    # NOTE:
    # Dont think I need to do _resolve_embedded_extends
    # in here, because there shoudn't be any.
    # - SL

    foreach my $schema ( @schemas ) {
        $self->_resolve_refs( $schema, $schema_map );
    }

    foreach my $schema ( @schemas ) {
        $self->_mark_as_compiled( $schema );
    }

    return $schema_map;
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

sub _mark_as_compiled {
    my ($self, $schema) = @_;
    $schema->{'is_compiled'} = 1;
}

sub _is_schema_compiled {
    my ($self, $schema) = @_;
    (exists $schema->{'is_compiled'} && $schema->{'is_compiled'} == 1) ? 1 : 0
}

sub _generate_schema_map {
    my ($self, @schemas) = @_;
    return +{ map { $_->{'compiled'}->{'id'} => $_ } @schemas }
}

# compiling extensions

sub _flatten_extends {
    my ($self, $schema, $schema_map) = @_;
    if ( exists $schema->{'raw'}->{'extends'} && $self->_is_ref( $schema->{'raw'}->{'extends'} ) ) {
        $self->_merge_schema(
            $schema,
            $self->_resolve_ref( $schema->{'raw'}->{'extends'}, $schema_map ),
            $schema_map
        );
        $schema->{'compiled'}->{'properties'}            = $self->_merge_properties( properties            => $schema, $schema_map );
        $schema->{'compiled'}->{'additional_properties'} = $self->_merge_properties( additional_properties => $schema, $schema_map );
        delete $schema->{'compiled'}->{'extends'};
    }
}

sub _merge_schema {
    my ($self, $schema, $super, $schema_map) = @_;
    foreach my $key ( keys %{ $super->{'raw'} } ) {
        next if $key eq 'id'                     # ID should never be copied
             || $key eq 'properties'             # properties will be copied later
             || $key eq 'additional_properties'; # additional_properties will be copied later
        if ( not exists $schema->{'raw'}->{ $key } ) {
            $schema->{'compiled'}->{ $key } = ref $super->{'raw'}->{ $key }
                                            ? clone( $super->{'raw'}->{ $key } )
                                            : $super->{'raw'}->{ $key };
        }
    }
    if ( $super->{'raw'}->{'extends'} && $self->_is_ref( $super->{'raw'}->{'extends'} ) ) {
        $self->_merge_schema(
            $schema,
            $self->_resolve_ref( $super->{'raw'}->{'extends'}, $schema_map ),
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
    my ($self, $schema, $schema_map) = @_;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        hash => sub {
            my ($v, $data) = @_;
            if (exists $data->{'$ref'} && $self->_is_ref( $data )) {
                if ($self->_is_self_ref( $data )) {
                    $_ = $schema->{'compiled'};
                }
                else {
                    my $s = $self->_resolve_ref( $data, $schema_map );
                    (defined $s)
                        || confess "Could not find schema for " . $data->{'$ref'};
                    $_ = $s->{'compiled'};
                }
            }
        }
    )->visit(
        $schema->{'compiled'}
    );
}

sub _resolve_embedded_extends {
    my ($self, $schema, $schema_map) = @_;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        hash => sub {
            my ($v, $data) = @_;
            if ( exists $data->{'extends'} && $self->_is_ref( $data->{'extends'} ) ) {
                my $embedded_schema = $self->_prepare_schema_for_compiling( $data );
                my $new_schema_map  = { %$schema_map, '#' => $schema };
                $self->_merge_schema(
                    $embedded_schema,
                    $self->_resolve_ref( $data->{'extends'}, $new_schema_map ),
                    $new_schema_map
                );
                $embedded_schema->{'compiled'}->{'properties'}            = $self->_merge_properties( properties            => $embedded_schema, $new_schema_map );
                $embedded_schema->{'compiled'}->{'additional_properties'} = $self->_merge_properties( additional_properties => $embedded_schema, $new_schema_map );
                delete $embedded_schema->{'compiled'}->{'extends'};
                $_ = $embedded_schema->{'compiled'};
            }
        }
    )->visit(
        $schema->{'compiled'}
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
