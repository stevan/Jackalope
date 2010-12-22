package Jackalope::REST::Service::Target;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::REST::Error::BadRequest;
use Jackalope::REST::Error::BadRequest::ValidationError;

use Plack::Request;

has 'service' => (
    is       => 'ro',
    isa      => 'Jackalope::REST::CRUD::Service',
    required => 1,
    handles  => [qw[
        resource_repository
        schema_repository
        serializer
        router
    ]]
);

has 'link' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1
);

requires 'execute';

sub to_app {
    my $self = shift;
    return sub {
        my $env = shift;
        $self->execute(
            Plack::Request->new( $env ),
            map { values %{ $_ } } @{ $env->{'jackalope.router.match.mapping'} }
        );
    }
}

sub process_psgi_output {
    my ($self, $psgi) = @_;

    return $psgi unless scalar @{ $psgi->[2] };

    push @{ $psgi->[1] } => ('Content-Type' => $self->serializer->content_type);

    $psgi->[2]->[0] = $self->serializer->serialize( $psgi->[2]->[0] );

    $psgi;
}

## Schema Checking

sub check_uri_schema {
    my ($self, $r) = @_;
    # look for a uri-schema ...
    if ( exists $self->link->{'uri_schema'} ) {
        my $mapping = +{ map { %{ $_ } } @{ $r->env->{'jackalope.router.match.mapping'} } };
        # since we have the 'uri_schema',
        # we can check the mappings against it
        foreach my $key ( keys %{ $self->link->{'uri_schema'} } ) {
            unless (exists $mapping->{ $key }) {
                Jackalope::REST::Error::BadRequest->throw(
                    "Required URI Param '$key' did not exist"
                );
            }
            my $result = $self->schema_repository->validate(
                $self->link->{'uri_schema'}->{ $key },
                $mapping->{ $key }
            );
            if ($result->{'error'}) {
                Jackalope::REST::Error::BadRequest::ValidationError->new(
                    validation_error => $result,
                    message          => "URI Params failed to validate against uri_schema"
                )->throw;
            }
        }
    }
}

sub check_data_schema {
    my ($self, $r) = @_;

    my $params;
    # we know we are expecting data
    # if there is a 'schema' in the
    # link description, so we extract
    # the parameters based on the
    # 'method' specified
    if ( exists $self->link->{'data_schema'} ) {
        # should this default to GET?
        if ( $self->link->{'method'} eq 'GET' ) {
            $params = $r->query_parameters->as_hashref_mixed;
        }
        elsif ( $self->link->{'method'} eq 'POST' || $self->link->{'method'} eq 'PUT' ) {
            $params = $self->serializer->deserialize( $r->content );
        }

        # then, since we have the 'schema'
        # key, we can check the set of
        # params against it
        my $result = $self->schema_repository->validate( $self->link->{'data_schema'}, $params );
        if ($result->{'error'}) {
            Jackalope::REST::Error::BadRequest::ValidationError->new(
                validation_error => $result,
                message          => "Params failed to validate against data_schema"
            )->throw;
        }
    }

    return $params;
}

sub check_target_schema {
    my ($self, $result) = @_;
    # if we have a target_schema
    # then we are expecting output
    if ( exists $self->link->{'target_schema'} ) {
        # check the output against the target_schema
        my $result = $self->schema_repository->validate( $self->link->{'target_schema'}, $result );
        if ($result->{'error'}) {
            Jackalope::REST::Error::BadRequest::ValidationError->new(
                validation_error => $result,
                message          => "Output failed to validate against target_schema"
            )->throw;
        }
    }
}


no Moose::Role; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Service::Target - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Service::Target;

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
