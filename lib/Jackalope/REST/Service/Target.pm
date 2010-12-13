package Jackalope::REST::Service::Target;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Try::Tiny;
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
        $self->throw_server_error("repository operation ($operation) failed, because $error")
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

sub generate_read_link_for_resource {
    my ($self, $resource) = @_;
    # TODO:
    # this should be more dynamic too
    # - SL
    $self->router->uri_for( rel => 'read', method => 'GET', id => $resource->id )
}

sub generate_links_for_resource {
    my ($self, $resource) = @_;
    # TODO:
    # pull this information out of the
    # schema instead, we should be
    # doing this more dynamically.
    # - SL
    $resource->add_links(
        {
            rel    => 'list',
            method => 'GET',
            href   => $self->router->uri_for( rel => 'list', method => 'GET' )
        },
        {
            rel    => 'create',
            method => 'POST',
            href   => $self->router->uri_for( rel => 'create', method => 'POST' )
        },
        {
            rel    => 'read',
            method => 'GET',
            href   => $self->router->uri_for( rel => 'read', method => 'GET', id => $resource->id )
        },
        {
            rel    => 'edit',
            method => 'PUT',
            href   => $self->router->uri_for( rel => 'edit', method => 'PUT', id => $resource->id )
        },
        {
            rel    => 'delete',
            method => 'DELETE',
            href   => $self->router->uri_for( rel => 'delete', method => 'DELETE', id => $resource->id )
        }
    );
}

requires 'execute';

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
