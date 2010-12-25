package Jackalope::REST::Resource::Repository;
use Moose::Role;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::REST::Resource;
use Jackalope::REST::Error::ResourceNotFound;
use Jackalope::REST::Error::BadRequest;
use Jackalope::REST::Error::ConflictDetected;
use Jackalope::REST::Error::MethodNotAllowed;
use Jackalope::REST::Error::NotImplemented;

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

# internal provided methods

sub wrap_data {
    my ($self, $id, $data) = @_;
    return $self->resource_class->new( id => $id, body => $data );
}

sub detect_conflict {
    my ($self, $old, $new) = @_;
    # check it to make sure that the
    # new still has the old version string
    # so we know it has not gone out
    # of sync
    ($old->compare_version( $new ))
        || Jackalope::REST::Error::ConflictDetected->throw("resource submitted has out of date version");
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
        || Jackalope::REST::Error::ResourceNotFound->throw("no resource for id ($id)");
    return $self->wrap_data( $id, $data );
}

sub update_resource {
    my ($self, $id, $updated_resource) = @_;

    ($id eq $updated_resource->id)
        || Jackalope::REST::Error::BadRequest->throw("the id does not match the id of the updated resource");

    # grab the old resource at this id ...
    my $old_resource = $self->get_resource( $id );

    ($old_resource->compare_version( $updated_resource ))
        || Jackalope::REST::Error::ConflictDetected->throw("resource submitted has out of date version");

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
        ($old_resource->compare_version( $version_to_check ))
            || Jackalope::REST::Error::ConflictDetected->throw("resource submitted has out of date version");
    }

    # check the return value
    # it should be a defined
    # value, undef means the
    # $id was not found
    (defined $self->delete( $id ))
        || Jackalope::REST::Error::ResourceNotFound->throw("no resource for id ($id)");

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

This is a role that, when consumed, requires that you implement the
following set of methods, implementing the following type signatures.

  list    : () => Array of [ Id, Data ]
  create  : (Data) => Id
  get     : (Id) => Data
  update  : (Id, Data) => Data
  delete  : (Id) => ()

The role will then wrap these things up in a L<Jackalope::REST::Resource>
accordingly and respond to the methods listed below.

=head2 TESTABILITY

One nice side effect of this approach is that since this is the only
code you write, it is also really the only code you need to test.
So you can focus purely on this knowing that the wrapped *_resource
versions of these methods should work fine.

=head1 METHODS

=over 4

=item B<list_resource>
=item B<create_resource>
=item B<get_resource>
=item B<update_resource>
=item B<delete_resource>

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
