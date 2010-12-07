package Jackalope::Web::RouterBuilder;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Router;

has 'schema' => (
    is       => 'ro',
    isa      => subtype('HashRef', where { exists $_->{links} ? 1 : 0 }),
    required => 1
);

# NOTE:
# Normally this is a resolved
# Bread::Board::Service, however
# there is no need to hard code
# that, it should work with other
# things too.
# - SL
has 'service' => (
    is       => 'ro',
    isa      => duck_type([ 'param' ]),
    required => 1
);

sub compile_router {
    my $self       = shift;
    my $router     = Path::Router->new;
    my $serializer = $self->service->param( 'serializer' );
    my $repo       = $self->service->param( 'repo' );

    foreach my $link ( @{ $self->schema->{links} } ) {

        my $controller = $self->service->param( $link->{metadata}->{controller} );
        my $action     = $controller->can( $link->{metadata}->{action} );

        $router->add_route(
            $link->{href},
            # Accept the defaults
            # in the metadata hash
            (exists $link->{metadata}->{defaults}
                ? (defaults => $link->{metadata}->{defaults})
                : ()),
            # Accept the validations
            # in the metadata hash
            (exists $link->{metadata}->{validations}
                ? (validations => $link->{metadata}->{validations})
                : ()),
            target  => sub {
                my $r    = shift;
                my @args = @_;

                my $params = {};
                # we know we are expecting data
                # if there is a 'schema' in the
                # link description, so we extract
                # the parameters based on the
                # 'method' specified
                if ( exists $link->{schema} ) {
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
                        return [ 500, [], [ "Params failed to validate"] ];
                    }
                }

                my $output = $controller->$action( @args, $params );

                if ( exists $link->{target_schema} ) {
                    my $result = $repo->validate( $link->{target_schema}, $output );
                    if ($result->{error}) {
                        return [ 500, [], [ "Output didn't match the target_schema"] ];
                    }
                }

                return [
                    200,
                    [ 'Content-Type' => $serializer->content_type ],
                    [ $serializer->serialize( $output ) ]
                ];
            }
        );
    }

    $router;
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Web::RouteBuilder - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Web::RouteBuilder;

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
