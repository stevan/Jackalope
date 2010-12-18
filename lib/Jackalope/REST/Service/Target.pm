package Jackalope::REST::Service::Target;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Try::Tiny;
use Plack::Request;
use Data::Dump;
use Jackalope::REST::Error::InternalServerError;

has 'service' => (
    is       => 'ro',
    isa      => 'Jackalope::REST::Service',
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

sub throw_server_error {
    my $self = shift;
    Jackalope::REST::Error::InternalServerError->throw( @_ )
}

sub process_operation {
    my ($self, $operation, $r, @args) = @_;

    my ($result, $error);
    try {
        my $params = $self->sanitize_and_prepare_input( $r );
        $result = $self->call_repository_operation( $operation => ( @args, $params ) );
        $self->verify_and_prepare_output( $result );
    } catch {
        $error = $_;
    };

    if ( $error ) {
        if ( $error->isa('Jackalope::REST::Error') ) {
            $error = $error->to_psgi;
        }
        else {
            $error = [ 500, [], [ "Unknown Server Error : $error" ]]
        }
    }

    return ($result, $error);
}

sub sanitize_and_prepare_input {
    my ($self, $r ) = @_;
    $self->check_http_method( $r );
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

# TODO:
# need to make this also support ETags
# - SL
sub process_psgi_output {
    my ($self, $psgi) = @_;
    if ( scalar @{ $psgi->[2] } ) {

        push @{ $psgi->[1] } => ('Content-Type' => $self->serializer->content_type);

        if (ref $psgi->[2]->[0] eq 'ARRAY') {
            # an array of resources
            $psgi->[2]->[0] = $self->serializer->serialize( [ map { $_->pack } @{ $psgi->[2]->[0] } ] );
        }
        elsif (blessed $psgi->[2]->[0]) {
            # a resource
            $psgi->[2]->[0] = $self->serializer->serialize( $psgi->[2]->[0]->pack );
        }
        else {
            # just leave it alone ...
        }
    }
    $psgi;
}

# ...

sub check_http_method {
    my ($self, $r) = @_;
    if (exists $self->link->{'method'}) {
        if ($self->link->{'method'} ne $r->method) {
            Jackalope::REST::Error::MethodNotAllowed->new(
                allowed_methods => [ $self->link->{'method'} ],
                message         => ($r->method . ' method is not allowed, expecting ' . $self->link->{'method'})
            )->throw;
        }
    }
}

sub check_uri_schema {
    my ($self, $r) = @_;
    # look for a uri-schema ...
    if ( exists $self->link->{'uri_schema'} ) {
        my $mapping = $r->env->{'plack.router.match'}->mapping;
        # since we have the 'uri_schema',
        # we can check the mappings against it
        foreach my $key ( keys %{ $self->link->{'uri_schema'} } ) {
            unless (exists $mapping->{ $key }) {
                $self->throw_server_error("Required URI Param $key did not exist")
            }
            my $result = $self->schema_repository->validate( $self->link->{'uri_schema'}->{ $key }, $mapping->{ $key } );
            if ($result->{'error'}) {
                $self->throw_server_error("URI Params failed to validate against uri_schema because : " . (Data::Dump::dump $result));
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
            $self->throw_server_error("Params failed to validate against data_schema because : " . (Data::Dump::dump $result));
        }
    }

    return $params;
}

sub call_repository_operation {
    my ($self, $operation, @args) = @_;
    my $error;
    my $result = try {
        $self->resource_repository->$operation( @args );
    } catch {
        $error = $_;
    };

    if ( $error ) {
        if ( $error->isa('Jackalope::REST::Error') ) {
            die $error;
        }
        else {
            $self->throw_server_error("repository operation ($operation) failed, because $error")
        }
    }

    return $result;
}

sub check_target_schema {
    my ($self, $result) = @_;
    # if we have a target_schema
    # then we are expecting output
    if ( exists $self->link->{'target_schema'} ) {
        # check the output against the target_schema
        my $result = $self->schema_repository->validate( $self->link->{'target_schema'}, $result );
        if ($result->{'error'}) {
            $self->throw_server_error("Output failed to validate against target_schema because : " . (Data::Dump::dump $result));
        }
    }
}

requires 'execute';

sub to_app {
    my $self = shift;
    return sub {
        my $env = shift;
        $self->execute(
            Plack::Request->new( $env ),
            @{ $env->{'plack.router.match.args'} }
        );
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
