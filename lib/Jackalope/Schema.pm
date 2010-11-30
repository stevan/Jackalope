package Jackalope::Schema;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Data::Visitor::Callback;
use Try::Tiny;
use Scalar::Util 'looks_like_number';
use List::AllUtils 'any', 'uniq';
use Devel::PartialDump 'dump';
use Data::Dumper;


has 'original_schemas' => (
    init_arg => 'schemas',
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    required => 1
);

has 'compiled_schemas' => (
    is      => 'ro',
    isa     => 'HashRef[HashRef]',
    lazy    => 1,
    builder => '_compile_schemas'
);

sub _compile_schemas {
    my $self = shift;

    my @schemas = @{ $self->original_schemas };

    # - first we should build the basic schema map
    #   so that we can resolve uris, but this will
    #   not be what is actually stored, we have to
    #   build that at the end

    my %schema_map;
    foreach my $schema ( @schemas ) {
        $schema_map{ $schema->{id} } = $schema;
    }

    # - then we should flatten extends, but we should
    #   process the schemas individually and only
    #   process 'extends' that are 'refs' (which should
    #   perhaps be enforced in the spec??)

    my @flattened;
    foreach my $schema ( @schemas ) {
        push @flattened => $self->_flatten_extends( $schema, \%schema_map );
    }

    # - then we should resolve all the reminaing refs
    #   we need to be stricter about checking that it
    #   is indeed a ref and not the ref spec

    my @resolved;
    foreach my $schema ( @schemas ) {
        push @resolved => $self->_resolve_refs( $schema, \%schema_map );
    }

    return +{ map { $_->{id} => $_ } @resolved };
}

sub _resolve_refs {
    my ($self, $schema, $schema_map) = @_;
    return Data::Visitor::Callback->new(
        hash => sub {
            my ($v, $data) = @_;
            if (exists $data->{'$ref'} && $self->_is_ref( $data )) {
                return $schema_map->{ $data->{'$ref'} }
            }
            return $data;
        }
    )->visit( $schema );
}

sub _is_ref {
    my ($self, $ref) = @_;
    return (exists $ref->{'$ref'} && ((scalar keys %$ref) == 1)) ? 1 : 0;
}

sub _flatten_extends {
    my ($self, $schema, $schema_map) = @_;
    return Data::Visitor::Callback->new(
        hash => sub {
            my ($v, $data) = @_;
            if ( exists $data->{'extends'} &&  $self->_is_ref( $data->{'extends'} ) ) {
                return $self->_compile_properties( $data, $schema_map );
            }
            return $data;
        }
    )->visit(
        $self->_compile_properties( $schema, $schema_map )
    );
}

sub _compile_properties {
    my ($self, $schema, $schema_map) = @_;
    my ($compiled_properties, $compiled_additional_properties) = $self->_compile_extended_properties( $schema, $schema_map );
    $schema->{'__compiled_properties'}            = $compiled_properties;
    $schema->{'__compiled_additional_properties'} = $compiled_additional_properties;
    return $schema;
}

sub _compile_extended_properties {
    my ($self, $schema, $schema_map) = @_;
    return (
        $self->_merge_properties( properties            => $schema, $schema_map ),
        $self->_merge_properties( additional_properties => $schema, $schema_map )
    );
}

sub _merge_properties {
    my ($self, $type, $schema, $schema_map) = @_;
    return +{
        (exists $schema->{'extends'}
            ? %{ $self->_merge_properties( $type, $schema_map->{ $schema->{'extends'}->{'$ref'} }, $schema_map ) }
            : ()),
        %{ $schema->{ $type } || {} },
    }
}

sub compile { (shift)->compiled_schemas }

{
    my %valid_formatters = (
        uri          => sub { 1 },
        uri_template => sub { 1 },
        regexp       => sub { 1 },
    );

    my %types_and_validators;

    my $bool_check = sub {
        my ($schema, $data) = @_;
        (
          defined($data)
          and ref($data)
          and (
            eval { $data->isa('JSON::XS::Boolean') }
            or
            eval { $data->isa('JSON::PP::Boolean') }
            or
            eval { $data->isa('boolean') }
          )
        ) ? { pass => 1 } : { error => $data . ' is not a boolean type' };
    };

    my $number_check = sub {
        my ($schema, $data) = @_;
        return {
            error => 'doesnt look like a number'
        } unless looks_like_number $data;
        if (exists $schema->{less_than}) {
            return {
                error => $data . ' is not less than ' . $schema->{less_than}
            } if $schema->{less_than} < $data;
        }
        if (exists $schema->{less_than_or_equal_to}) {
            return {
                error => $data . ' is not less than or equal to ' . $schema->{less_than_or_equal_to}
            } if $schema->{less_than_or_equal_to} <= $data;
        }
        if (exists $schema->{greater_than}) {
            return {
                error => $data . ' is not greater than ' . $schema->{greater_than}
            } if $schema->{greater_than} > $data;
        }
        if (exists $schema->{greater_than_or_equal_to}) {
            return {
                error => $data . ' is not greater than or equal to ' . $schema->{greater_than_or_equal_to}
            } if $schema->{greater_than_or_equal_to} >= $data;
        }
        if (exists $schema->{enum}) {
            return {
                error => $data . ' is not part of (number) enum (' . (join ', ' => @{ $schema->{enum} } ) . ')'
            } unless any { $data == $_ } @{ $schema->{enum} };
        }
        return +{ pass => 1 };
    };

    my $string_check = sub {
        my ($schema, $data) = @_;
        return {
            error => 'string data is not defined'
        } unless defined $data;
        if (exists $schema->{min_length}) {
            return {
                error => $data . ' is not the minimum length of ' . $schema->{min_length}
            } if (length $data) <= ($schema->{min_length} - 1);
        }
        if (exists $schema->{max_length}) {
            return {
                error => $data . ' is more then the maximum length of ' . $schema->{max_length}
            } if (length $data) >= ($schema->{max_length} + 1);
        }
        if (exists $schema->{pattern}) {
            return {
                error => $data . ' does not match the pattern (' . $schema->{pattern} . ')'
            } if $data !~ /$schema->{pattern}/;
        }
        if (exists $schema->{format}) {
            return {
                error => $data . ' is not one of the built-in formats'
            } unless try { $valid_formatters{ $schema->{format} }->( $data ) };
        }
        if (exists $schema->{enum}) {
            return {
                error => $data . ' is not part of (string) enum (' . (join ', ' => @{ $schema->{enum} } ) . ')'
            } unless any { $data eq $_ } @{ $schema->{enum} };
        }
        return +{ pass => 1 };
    };

    my $array_check = sub {
        my ($schema, $data) = @_;
        return {
            error => (dump $data) . ' is not an array'
        } unless ref $data eq 'ARRAY';
        if (exists $schema->{min_items}) {
            return {
                error => (dump $data) . ' does not meet the minimum items ' . $schema->{min_items} . ' with ' . (scalar @$data)
            } if (scalar @$data) <= ($schema->{min_items} - 1);
        }
        if (exists $schema->{max_items}) {
            return {
                error => (dump $data) . ' does not meet the maximum items ' . $schema->{max_items} . ' with ' . (scalar @$data)
            } if (scalar @$data) >= ($schema->{max_items} + 1);
        }
        return +{ pass => 1 } if (scalar @$data) == 0; # no need to carry on if it is empty
        if (exists $schema->{is_unique} && $schema->{is_unique}) {
            return  {
                error => (dump $data) . ' is not unique'
            } if (scalar @$data) != (scalar uniq @$data);
        }
        if (exists $schema->{items}) {
            my $item_schema = $schema->{items};
            my $validator   = $types_and_validators{ $item_schema->{type} };
            my @results     = map { $validator->( $item_schema, $_ ) } @$data;
            my @errors      = grep { exists $_->{error} } @results;

            return {
                error      => (dump $data) . ' did not pass the test for ' . $item_schema->{type} . ' schemas',
                sub_errors => \@errors
            } if @errors;
        }
        return +{ pass => 1 };
    };

    my $property_check = sub {
        my ($props, $data, $all_props) = @_;
        foreach my $k (keys %$props) {

            next if $k =~ /^__/;

            my $schema = $props->{ $k };

            return { error => "property '$k' didn't exist" } if not exists $data->{ $k };

            my $result = $types_and_validators{ $schema->{type} }->( $schema, $data->{ $k } );
            return {
                error      => "property '$k' didn't pass the schema for '" . $schema->{type} . "'",
                sub_errors => $result
            } if exists $result->{error};

            delete $all_props->{ $k };
        }
        return +{ pass => 1 };
    };

    my $additional_property_check = sub {
        my ($props, $data, $all_props) = @_;

        foreach my $k (keys %$props) {
            next if $k =~ /^__/;

            my $schema = $props->{ $k };

            if (not exists $data->{ $k }) {
                #warn "prop $k doesnt exist in $data, so deleting it and skipping";
                delete $all_props->{ $k };
                next;
            }

            my $result = $types_and_validators{ $schema->{type} }->( $schema, $data->{ $k } );
            return {
                error      => "property '$k' didn't pass the schema for '" . $schema->{type} . "'",
                sub_errors => $result
            } if exists $result->{error};

            #warn "found prop $k in $data and it passed, so deleting";

            delete $all_props->{ $k };
        }
        return +{ pass => 1 };
    };


    my $object_check = sub {
        my ($schema, $data) = @_;
        return {
            error => (dump $data) . ' is not an object'
        } unless ref $data eq 'HASH';

        my %all_props = map { $_ => undef } grep { !/^__/ } keys %$data;

        if (exists $schema->{__compiled_properties} && scalar keys %{ $schema->{__compiled_properties} }) {
            my $result = $property_check->(
                $schema->{__compiled_properties}, $data, \%all_props
            );
            return {
                error      => (dump $data) . " did not pass properties check",
                sub_errors => $result
            } if exists $result->{error};
        }

        if (exists $schema->{__compiled_additional_properties} && scalar keys %{ $schema->{__compiled_additional_properties} }) {
            my $result = $additional_property_check->(
                $schema->{__compiled_additional_properties}, $data, \%all_props
            );
            return {
                error      => (dump $data) . " did not pass additional properties check",
                sub_errors => $result
            } if exists $result->{error};
        }

        if (exists $schema->{__compiled_properties} || exists $schema->{__compiled_additional_properties}) {
            return {
                error           => (dump $data) . ' did not match all the expected properties',
                remaining_props => \%all_props,
                schema          => $schema,
            } if (scalar keys %all_props) != 0;
        }

        if (exists $schema->{items}) {
            my $item_schema = $schema->{items};
            my $validator   = $types_and_validators{ $item_schema->{type} };

            my @results     = map { $validator->( $item_schema, $_ )  } values %$data;
            my @errors      = grep { exists $_->{error} } @results;

            return {
                error      => (dump $data) . ' did not pass the test for ' . $item_schema->{type} . ' schemas',
                sub_errors => \@errors
            } if @errors;
        }
        return +{ pass => 1 };
    };

    %types_and_validators = (
        any     => sub { +{ pass => 1 } },
        null    => sub { defined $_[1] ? { pass => 1 } : { error => $_[0] . ' is not null' } },
        boolean => $bool_check,
        number  => $number_check,
        integer => sub {
            return {
                error => (defined $_[1] ? $_[1] : 'undef') . ' is perhaps a floating point number'
            } unless defined $_[1] && $_[1] =~ /^\d+$/;
            return $number_check->( @_ );
        },
        string  => $string_check,
        array   => $array_check,
        object  => $object_check,
        schema  => $object_check,
    );

    sub validate {
        my ($self, $schema, $data) = @_;

        unless (exists $schema->{__compiled_properties} && exists $schema->{__compiled_additional_properties}) {
            $schema = $self->_flatten_extends( $schema, $self->compiled_schemas );
            $schema = $self->_resolve_refs( $schema, $self->compiled_schemas );
        }

        my $result = $types_and_validators{schema}->(
            $self->compiled_schemas->{'schema/types/' . $schema->{type}},
            $schema
        );

        if ($result->{error}) {
            die Dumper [
                "Invalid schema",
                $result,
                $schema,
                $self->compiled_schemas->{'schema/types/' . $schema->{type}}
            ];
        }

        return $types_and_validators{ $schema->{type} }->(
            $schema,
            $data
        );
    }
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema;

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
