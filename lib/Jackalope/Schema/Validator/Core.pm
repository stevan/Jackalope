package Jackalope::Schema::Validator::Core;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Try::Tiny;
use Scalar::Util       ();
use List::AllUtils     ();
use Devel::PartialDump ();

has 'formaters' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        +{
            uri          => 1,
            uri_template => 1,
            regexp       => 1,
        }
    },
    handles => {
        'is_valid_formatter' => 'exists'
    }
);

sub any  { +{ pass => 1 } }
sub null {
    my (undef, undef, $data) = @_;
    (!defined $data)
        ? +{ pass => 1 }
        : +{ error => $data . ' is not null' }
}

sub boolean {
    my (undef, $schema, $data) = @_;
    (!defined($data) || $data eq "" || "$data" eq '1' || "$data" eq '0')
        ? +{ pass => 1 }
        : +{ error => $data . ' is not a boolean type' };
}

sub number {
    my (undef, $schema, $data) = @_;
    return {
        error => 'doesnt look like a number'
    } unless Scalar::Util::looks_like_number $data;

    return {
        error => 'numeric data is a reference'
    } if ref $data;

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
        } unless List::AllUtils::any { $data == $_ } @{ $schema->{enum} };
    }
    return +{ pass => 1 };
}

sub integer {
    my ($self, $schema, $data) = @_;
    return {
        error => (defined $data ? $data : 'undef') . ' is perhaps a floating point number'
    } unless defined $data && $data =~ /^\d+$/;
    return $self->number( $schema, $data );
}

sub string {
    my ($self, $schema, $data) = @_;
    return {
        error => 'string data is not defined'
    } unless defined $data;

    return {
        error => 'string look more like a number'
    } if Scalar::Util::looks_like_number $data;

    return {
        error => 'string data is a reference'
    } if ref $data;

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
        } unless $self->is_valid_formatter( $schema->{format} );
    }
    if (exists $schema->{enum}) {
        return {
            error => $data . ' is not part of (string) enum (' . (join ', ' => @{ $schema->{enum} } ) . ')'
        } unless List::AllUtils::any { $data eq $_ } @{ $schema->{enum} };
    }
    return +{ pass => 1 };
}

sub array {
    my ($self, $schema, $data) = @_;
    return {
        error => (Devel::PartialDump::dump $data) . ' is not an array'
    } unless ref $data eq 'ARRAY';

    if (exists $schema->{min_items}) {
        return {
            error => (Devel::PartialDump::dump $data) . ' does not meet the minimum items ' . $schema->{min_items} . ' with ' . (scalar @$data)
        } if (scalar @$data) <= ($schema->{min_items} - 1);
    }

    if (exists $schema->{max_items}) {
        return {
            error => (Devel::PartialDump::dump $data) . ' does not meet the maximum items ' . $schema->{max_items} . ' with ' . (scalar @$data)
        } if (scalar @$data) >= ($schema->{max_items} + 1);
    }

    return +{ pass => 1 } if (scalar @$data) == 0; # no need to carry on if it is empty

    if (exists $schema->{is_unique} && $schema->{is_unique}) {
        return  {
            error => (Devel::PartialDump::dump $data) . ' is not unique'
        } if (scalar @$data) != (scalar List::AllUtils::uniq @$data);
    }

    if (exists $schema->{items}) {
        my $item_schema = $schema->{items};
        my $validator   = $self->can( $item_schema->{type} );
        my @results     = map { $self->$validator( $item_schema, $_ ) } @$data;
        my @errors      = grep { exists $_->{error} } @results;

        return {
            error      => (Devel::PartialDump::dump $data) . ' did not pass the test for ' . $item_schema->{type} . ' schemas',
            sub_errors => \@errors
        } if @errors;
    }
    return +{ pass => 1 };
}

sub object {
    my ($self, $schema, $data) = @_;
    return {
        error => (Devel::PartialDump::dump $data) . ' is not an object'
    } unless ref $data eq 'HASH';

    my %all_props = map { $_ => undef } grep { !/^__/ } keys %$data;

    if (exists $schema->{__compiled_properties} && scalar keys %{ $schema->{__compiled_properties} }) {
        my $result = $self->_check_properties(
            $schema->{__compiled_properties}, $data, \%all_props
        );
        return {
            error      => (Devel::PartialDump::dump $data) . " did not pass properties check",
            sub_errors => $result
        } if exists $result->{error};
    }

    if (exists $schema->{__compiled_additional_properties} && scalar keys %{ $schema->{__compiled_additional_properties} }) {
        my $result = $self->_check_additional_properties(
            $schema->{__compiled_additional_properties}, $data, \%all_props
        );
        return {
            error      => (Devel::PartialDump::dump $data) . " did not pass additional properties check",
            sub_errors => $result
        } if exists $result->{error};
    }

    if (exists $schema->{__compiled_properties} || exists $schema->{__compiled_additional_properties}) {
        return {
            error           => (Devel::PartialDump::dump $data) . ' did not match all the expected properties',
            remaining_props => \%all_props,
            schema          => $schema,
        } if (scalar keys %all_props) != 0;
    }

    if (exists $schema->{items}) {
        my $item_schema = $schema->{items};
        my $validator   = $self->can( $item_schema->{type} );

        my @results     = map { $self->$validator( $item_schema, $_ )  } values %$data;
        my @errors      = grep { exists $_->{error} } @results;

        return {
            error      => (Devel::PartialDump::dump $data) . ' did not pass the test for ' . $item_schema->{type} . ' schemas',
            sub_errors => \@errors
        } if @errors;
    }
    return +{ pass => 1 };
}

*schema = \&object;

# ...

sub _check_properties {
    my ($self, $props, $data, $all_props) = @_;
    foreach my $k (keys %$props) {
        next if $k =~ /^__/;

        my $schema = $props->{ $k };

        return { error => "property '$k' didn't exist" } if not exists $data->{ $k };

        my $validator = $self->can( $schema->{type} );
        my $result    = $self->$validator( $schema, $data->{ $k } );
        return {
            error      => "property '$k' didn't pass the schema for '" . $schema->{type} . "'",
            sub_errors => $result
        } if exists $result->{error};

        delete $all_props->{ $k };
    }
    return +{ pass => 1 };
}

sub _check_additional_properties {
    my ($self, $props, $data, $all_props) = @_;
    foreach my $k (keys %$props) {
        next if $k =~ /^__/;

        my $schema = $props->{ $k };

        if (not exists $data->{ $k }) {
            delete $all_props->{ $k };
            next;
        }

        my $validator = $self->can( $schema->{type} );
        my $result    = $self->$validator( $schema, $data->{ $k } );
        return {
            error      => "property '$k' didn't pass the schema for '" . $schema->{type} . "'",
            sub_errors => $result
        } if exists $result->{error};

        delete $all_props->{ $k };
    }
    return +{ pass => 1 };
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Validator::Core - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Validator::Core;

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
