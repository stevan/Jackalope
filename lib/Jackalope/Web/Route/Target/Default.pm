package Jackalope::Web::Route::Target::Default;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Data::Dump 'dump';

with 'Jackalope::Web::Route::Target';

has 'repo'       => ( is => 'ro', isa => 'Jackalope::Schema::Repository', required => 1 );
has 'serializer' => ( is => 'ro', does => 'Jackalope::Serializer', required => 1 );
has 'controller' => ( is => 'ro', isa => 'Object', required => 1 );
has 'action'     => ( is => 'ro', isa => 'CodeRef', required => 1 );

sub execute {
    my ($self, $r, @args) = @_;

    my $link       = $self->link;
    my $repo       = $self->repo;
    my $serializer = $self->serializer;
    my $controller = $self->controller;
    my $action     = $self->action;

    # look for a uri-schema ...
    if ( exists $link->{uri_schema} ) {
        my $mapping = $r->env->{'plack.router.match'}->mapping;
        # since we have the 'uri_schema',
        # we can check the mappings against it
        my $result = $repo->validate( $link->{uri_schema}, $mapping );
        if ($result->{error}) {
            warn dump $result;
            return [ 500, [], [ "URI Params failed to validate"] ];
        }
    }

    my $params;
    # we know we are expecting data
    # if there is a 'schema' in the
    # link description, so we extract
    # the parameters based on the
    # 'method' specified
    if ( exists $link->{schema} ) {
        # should this default to GET?
        if ( $link->{method} eq 'GET' ) {
            $params = $r->query_parameters->as_hashref_mixed;
        }
        elsif ( $link->{method} eq 'POST' || $link->{method} eq 'PUT' ) {
            $params = $serializer->deserialize( $r->content );
        }

        # then, since we have the 'schema'
        # key, we can check the set of
        # params against it
        my $result = $repo->validate( $link->{schema}, $params );
        if ($result->{error}) {
            warn dump $result;
            return [ 500, [], [ "Params failed to validate"] ];
        }
    }

    # now run it through the controller/action
    # with the router args first, followed by
    # the set of validated query or post params
    # in a hash ref
    my $output = $controller->$action( @args, $params || () );

    # if we have a target_schema
    # then we are expecting output
    if ( exists $link->{target_schema} ) {
        # check the output against the target_schema
        my $result = $repo->validate( $link->{target_schema}, $output );
        if ($result->{error}) {
            warn dump $result;
            return [ 500, [], [ "Output didn't match the target_schema"] ];
        }
    }

    # creation should not return data
    # but should just return the status
    # of '201 Created'
    if ( $link->{relation} eq 'create' ) {
        # 201 Created
        return [ 201, [], [] ];
    }
    # posting data and getting no
    # output back means we just send
    # the '202 Accepted' status
    elsif ( (not defined $output) && $link->{method} eq 'POST' ) {
        # 202 Accepted
        return [ 202, [], [] ];
    }
    # all other returns are just 200
    # with the data serialized
    else {
        return [
            200,
            [ 'Content-Type' => $serializer->content_type ],
            [ $serializer->serialize( $output ) ]
        ];
    }
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Web::Route::Target::Default - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Web::Route::Target::Default;

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
