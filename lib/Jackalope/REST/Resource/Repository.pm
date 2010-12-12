package Jackalope::REST::Resource::Repository;
use Moose::Role;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Digest;
use Jackalope::Serializer;
use Jackalope::REST::Resource;

has 'serializer' => (
    is       => 'ro',
    isa      => subtype(
        'Jackalope::Serializer'
            => where { $_->has_canonical_support }
            => message { "Serializer must have canonical support" }
    ),
    required => 1,
    handles  => [qw[ serialize deserialize ]]
);

has 'resource_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Jackalope::REST::Resource',
);

## internal API, for consumers of this role

requires 'list';    # () => Array of [ Id, Data ]
requires 'create';  # (Data) => Id
requires 'get';     # (Id) => Data
requires 'update';  # (Id, Data) => Data
requires 'delete';  # (Id) => ()

## override-able methods

# if you want to calculate the digest in some other way
# then you can override the two methods below to both
# generate and compare versions in a different way.

sub calculate_version {
    my ($self, $data) = @_;
    Digest->new("SHA-256")
          ->add( $self->serialize( $data, { canonical => 1 } ) )
          ->hexdigest
}

sub detect_conflict {
    my ($self, $old_version, $new_version) = @_;

    $old_version = $old_version->version if blessed $old_version;
    $new_version = $new_version->version if blessed $new_version;

    # check it to make sure that the
    # new still has the old version string
    # so we know it has not gone out
    # of sync
    ($old_version eq $new_version)
        || confess "409 Conflict Detected, resource submitted has out of date version";
}

# parameterizable resource_class should be
# enough in most cases, but if you need to
# do extra data munging or something, then
# override this method

sub wrap_data {
    my ($self, $id, $data) = @_;
    return $self->resource_class->new(
        id      => $id,
        body    => $data,
        version => $self->calculate_version( $data ),
    );
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
    my $data = $self->get( $id );
    (defined $data)
        || confess "404 Resource Not Found for $id";
    return $self->wrap_data( $id, $data );
}

sub update_resource {
    my ($self, $id, $updated_resource) = @_;

    ($id eq $updated_resource->id)
        || confess "400 Bad Request : The id does not match the id of the updated resource";

    # grab the old resource at this id ...
    my $old_resource = $self->get_resource( $id );

    # check for a conflict
    $self->detect_conflict(
        $old_resource,
        $updated_resource
    );

    # commit the data and re-wrap it
    return $self->wrap_data(
        $id,
        $self->update(
            $id,
            $updated_resource->body
        )
    );
}

sub delete_resource {
    my ($self, $id, $params) = @_;

    # this is an optional param ...
    if ( my $version_to_check = $params->{'if_matches'} ) {
        # grab the old resource at this id ...
        my $old_resource = $self->get_resource( $id );

        # check it to make sure that the
        # updated resource still has the
        # same version string
        $self->detect_conflict(
            $old_resource,
            $version_to_check
        );
    }

    # check the return value
    # it should be a defined
    # value, undef means the
    # $id was not found
    (defined $self->delete( $id ))
        || confess "404 Resource Not Found for $id";

    return;
}

no Moose::Role; no Moose::Util::TypeConstraints; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Resource::Repository - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Resource::Repository;

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
