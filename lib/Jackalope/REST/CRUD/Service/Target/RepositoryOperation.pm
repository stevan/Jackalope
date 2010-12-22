package Jackalope::REST::CRUD::Service::Target::RepositoryOperation;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Try::Tiny;

with 'Jackalope::REST::Service::Target';

requires 'repository_operation';
requires 'operation_callback';

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

    my ($result, $error);
    try {
        my $params = $self->sanitize_and_prepare_input( $r );
        $result = $self->resource_repository->$operation( @$args, $params );
        $self->verify_and_prepare_output( $result );
    } catch {
        $error = $_;
    };

    if ( $error ) {
        if ( $error->isa('Jackalope::REST::Error') ) {
            return $error->to_psgi( $self->serializer );
        }
        else {
            return [ 500, [], [ "Unknown Server Error : $error" ]]
        }
    }

    return $self->process_psgi_output( $self->operation_callback( $result ) );
}

around 'process_psgi_output' => sub {
    my $next = shift;
    my ($self, $psgi) = @_;

    return $psgi unless scalar @{ $psgi->[2] };

    # TODO:
    # need to make this also support ETags
    # in the headers based on the resource
    # version that we find
    # - SL

    if (ref $psgi->[2]->[0] eq 'ARRAY') {
        # an array of resources
        $psgi->[2]->[0] = [ map { $_->pack } @{ $psgi->[2]->[0] } ];
    }
    elsif (blessed $psgi->[2]->[0]) {
        # a resource
        $psgi->[2]->[0] = $psgi->[2]->[0]->pack;
    }

    $self->$next( $psgi );
};

# input and output processing

sub sanitize_and_prepare_input {
    my ($self, $r ) = @_;
    $self->check_uri_schema( $r );
    $self->check_data_schema( $r );
}

sub verify_and_prepare_output {
    my ($self, $result) = @_;

    if (ref $result eq 'ARRAY') {
        foreach my $resource ( @$result) {
            $self->service->generate_links_for_resource( $resource );
        }
        $self->check_target_schema( [ map { $_->pack } @$result ] );
    }
    elsif (blessed $result) {
        $self->service->generate_links_for_resource( $result );
        $self->check_target_schema( $result->pack );
    }

    $result;
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::CRUD::Service::Target::RepositoryOperation - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::CRUD::Service::Target::RepositoryOperation;

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
