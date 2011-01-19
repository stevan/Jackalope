package Jackalope::REST::Resource::Repository::MongoDB;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Data::Visitor::Callback;
use Scalar::Util;
use boolean ();
use MongoDB;
BEGIN {
    $MongoDB::BSON::use_boolean  = 1;
    $MongoDB::BSON::utf8_flag_on = 1;
}

with 'Jackalope::REST::Resource::Repository';

has 'collection' => (
    is       => 'ro',
    isa      => 'MongoDB::Collection',
    required => 1,
);

has 'use_custom_ids' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

before 'wrap_data' => sub {
    my ($self, $id, $data) = @_;
    # we will keep track of our
    # own IDs thank you very much
    delete $data->{_id} if exists $data->{_id};
};

sub list {
    my ($self, $params) = @_;

    $params->{'query'}  ||= {};
    $params->{'attrs'}  ||= {};

    unless ( exists $params->{'attrs'}->{'sort_by'} ) {
        $params->{'attrs'}->{'sort_by'} = { _id => 1 }; # sort by id
    }

    $self->_convert_query_params( $params->{'query'} );

    my $cursor = $self->collection->query(
        $params->{'query'},
        $params->{'attrs'},
    );

    return [
        map {
            my $data = $_;
            $self->_convert_from_booleans( $data );
            [
                ( $self->use_custom_ids
                    ? $_->{_id}
                    : $_->{_id}->value ),
                $data
            ]
        } $cursor->all
    ]
}

sub create {
    my ($self, $data) = @_;

    $self->_convert_to_booleans( $data );

    my $id = $self->collection->insert( $data, { safe => 1 } );
    $data  = $self->collection->find_one( { _id => $id } );

    $self->_convert_from_booleans( $data );

    return (
        ( $self->use_custom_ids ? $id : $id->value ),
        $data
    );
}

sub get {
    my ($self, $id) = @_;
    my $data = $self->collection->find_one(
        { _id => $self->_create_id( $id ) }
    );
    $self->_convert_from_booleans( $data );
    $data;
}

sub update {
    my ($self, $id, $updated_data) = @_;

    $self->_convert_to_booleans( $updated_data );

    $id = $self->_create_id( $id );

    $self->collection->update(
        { _id => $id },
        $updated_data,
        { safe => 1 }
    );

    $updated_data = $self->collection->find_one( { _id => $id } );

    $self->_convert_from_booleans( $updated_data );

    return $updated_data;
}

sub delete {
    my ($self, $id) = @_;

    my $query = { _id => $self->_create_id( $id ) };

    if ( $self->collection->find_one( $query, {} ) ) {
        return $self->collection->remove( $query, { safe => 1 } );
    }

    return;
}

sub _create_id {
    my ($self, $id) = @_;
    $self->use_custom_ids ? $id : MongoDB::OID->new(value => $id)
}

sub _convert_to_booleans {
    my ($self, $data) = @_;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        'JSON::XS::Boolean'  => sub {
            my ($v, $obj) = @_;
            $_ = $obj == JSON::XS::true ? boolean::true() : boolean::false();
        }

    )->visit( $data );
    return;
}

sub _convert_from_booleans {
    my ($self, $data) = @_;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        'boolean' => sub {
            my ($v, $obj) = @_;
            $_ = boolean::isTrue( $obj ) ? JSON::XS::true() : JSON::XS::false();
        }

    )->visit( $data );
    return;
}

sub _convert_query_params {
    my ($self, $query) = @_;
    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        'value' => sub {
            my ( undef, $val ) = @_;
            if ( $val eq 'true' ) {
                $_ = boolean::true();
            }
            elsif ( $val eq 'false' ) {
                $_ = boolean::false();
            }
            elsif ( Scalar::Util::looks_like_number( $val ) ) {
                $_ = $val + 0;
            }
            elsif ( $val =~ /^\/(.*)\/$/ ) {
                my $regexp = $1;
                $_ = qr/$regexp/;
            }
        }
    )->visit( $query );
    return;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Resource::Repository::MongoDB - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Resource::Repository::MongoDB;

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

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
