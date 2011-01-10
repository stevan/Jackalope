package Jackalope::REST::Resource::Repository::MongoDB;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

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
    my ($self, $query, $attrs) = @_;

    $query ||= {}; # query all
    $attrs ||= { sort_by => { _id => 1 } }; # sort by id

    return [
        map {
            [ $_->{_id}->value, $_ ]
        } $self->collection->query( $query, $attrs )->all
    ]
}

sub create {
    my ($self, $data) = @_;
    my $id = $self->collection->insert( $data, { safe => 1 } );
    return ( ( $self->use_custom_ids ? $id : $id->value ), $data );
}

sub get {
    my ($self, $id) = @_;
    return $self->collection->find_one(
        { _id => $self->_create_id( $id ) }
    );
}

sub update {
    my ($self, $id, $updated_data) = @_;

    $self->collection->update(
        { _id => $self->_create_id( $id ) },
        $updated_data,
        { safe => 1 }
    );

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
