package Jackalope::Web::Service;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Router;
use Jackalope::Web::Route::Target::Default;

# NOTE:
# Normally this is a resolved Bread::Board::Service,
# however there is no need to hard code that
# - SL
has 'service' => (
    is       => 'ro',
    isa      => duck_type([ 'param' ]),
    required => 1
);

# these are the original uncompiled schemas
# that can be used for sending to the client
has 'schemas' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    lazy    => 1,
    default => sub { [] },
    handles => {
        'get_all_schemas' => 'elements',
        'add_schema'      => 'push'
    }
);

has 'router' => (
    is      => 'ro',
    isa     => 'Path::Router',
    lazy    => 1,
    builder => 'build_router',
);

sub build_router {
    my $self       = shift;
    my $router     = Path::Router->new;
    my $serializer = $self->service->param( 'serializer' );
    my $repo       = $self->service->param( 'repo' );
    my @schemas    = map { $repo->register_schema( $_ ) } $self->get_all_schemas;

    foreach my $schema ( @schemas ) {
        foreach my $link ( @{ $schema->{links} } ) {

            my $controller   = $self->service->param( $link->{'metadata'}->{'controller'} );
            my $action       = $controller->can( $link->{'metadata'}->{'action'} );
            my $target_class = $link->{'metadata'}->{'target_class'} || 'Jackalope::Web::Route::Target::Default';

            $router->add_route(
                $link->{'href'},
                target  => $target_class->new(
                    link       => $link,
                    repo       => $repo,
                    serializer => $serializer,
                    controller => $controller,
                    action     => $action
                )
            );
        }
    }

    $router;
}

__PACKAGE__->meta->make_immutable;

no Moose; no Moose::Util::TypeConstraints; 1;

__END__

=pod

=head1 NAME

Jackalope::Web::Service - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Web::Service;

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
