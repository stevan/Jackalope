package Jackalope::ResourceRepository;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Digest;

has 'serializer' => (
    is       => 'ro',
    isa      => 'Jackalope::Serializer',
    required => 1,
    handles  => [qw[ serialize deserialize ]],
    trigger  => sub {
        my (undef, $serializer) = @_;
        $serialzier->has_canonical_support
            || confess "The serializer must support canonicalization to be used by the Resource Repository";
    }
);

# internal API, for consumers of this role

requires 'list';    # () => Array of [ Id, Data ]
requires 'create';  # (Data) => Id
requires 'get';     # (Id) => Data
requires 'update';  # (Id, Data) => Data
requires 'delete';  # (Id) => ()

# override-able methods

sub calculate_data_digest {
    my ($self, $data) = @_;
    Digest->new("SHA-256")
          ->add( $self->serialize( $data, { canonical => 1 } ) )
          ->hexdigest
}

sub wrap_data {
    my ($self, $id, $data) = @_;
    return +{
        id      => $id,
        version => $self->calculate_data_digest( $data ),
        body    => $data,
        links   => [] # leave this empty for the
    };
}

# external API, for service objects
# using an instance of the repository

sub list_resources {
    my ($self) = @_;
    return [  map { $self->wrap_data( @$_ ) } @{ $self->list } ];
}

sub create_resource {
    my ($self, $raw_data) = @_;
    my ($id, $data) = $self->create( $raw_data );
    return $self->wrap_data( $id, $data );
}

sub get_resource {
    my ($self, $id) = @_;
    return $self->wrap_data( $id, $self->get( $id ) );
}

sub update_resource {
    my ($self, $id, $new_data) = @_;
    return $self->wrap_data( $id, $self->update( $id, $new_data ) );
}

sub delete_resource {
    my ($self, $id) = @_;
    $self->delete( $id );
    return;
}

## error handlers

sub resource_not_found {
    my ($self, $message) = @_;
    die "404 Resource Not Found : $message"
}

sub conflict_detected {
    my ($self, $message) = @_;
    die "409 Conflict Detected : $message"
}

sub invalid_request {
    my ($self, $message) = @_;
    die "400 Bad Request : $message"
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Jackalope::ResourceRepository - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::ResourceRepository;

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
