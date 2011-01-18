package Jackalope::REST::CRUD::Service::Target::Role::RepositoryOperation;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'Jackalope::REST::CRUD::Service::Target::Role::ForResources';

requires 'repository_operation';
requires 'operation_callback';

sub resource_repository { (shift)->service->resource_repository }

sub execute {
    my ($self, $r, @args) = @_;
    $self->process_operation(
        $self->repository_operation,
        $r,
        \@args
    )
}

sub process_operation {
    my ($self, $operation, $r, $args) = @_;
    my $params = $self->sanitize_and_prepare_input( $r );
    my $result = $self->resource_repository->$operation( @$args, $params );
    $self->verify_and_prepare_output( $result );
    $self->generate_links_for_output( $result );
    return $self->process_psgi_output( $self->operation_callback( $result ) );
}

sub get_links_for_resource {
    (shift)->service->get_all_non_enpoint_links_from_schema
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::CRUD::Service::Target::Role::RepositoryOperation - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::CRUD::Service::Target::Role::RepositoryOperation;

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
