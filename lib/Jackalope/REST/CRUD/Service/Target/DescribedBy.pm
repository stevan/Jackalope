package Jackalope::REST::CRUD::Service::Target::DescribedBy;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::REST::Resource;

with 'Jackalope::REST::CRUD::Service::Target::Role::ForResources';

sub execute {
    my ($self, $r, @args) = @_;

    my $schema_id        = $self->service->compiled_schema->{'id'};
    my $transport_schema = $self->service->schema_repository->get_schema_compiled_for_transport( $schema_id );
    my $resource         = $self->service->resource_repository->wrap_data(
        $schema_id,
        $transport_schema
    );

    $self->verify_and_prepare_output( $resource );
    $self->generate_links_for_output( $resource );
    return $self->process_psgi_output( [ 200, [], [ $resource ] ] );
}

sub get_links_for_resource {
    (shift)->service->get_all_enpoint_links_from_schema
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::CRUD::Service::Target::DescribedBy - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::CRUD::Service::Target::DescribedBy;

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
