package Jackalope::REST::Service::Directory;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::REST::Service;
use Jackalope::REST::Error::ResourceNotFound;

has 'services' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[ Jackalope::REST::Service ]',
    lazy    => 1,
    default => sub { [] },
    handles => {
        'all_services' => 'elements',
    }
);

has 'service_map' => (
    is      => 'ro',
    isa     => 'HashRef[ Jackalope::REST::Service ]',
    lazy    => 1,
    builder => 'build_service_map'
);

sub build_service_map {
    my $self = shift;
    return +{
        map {
            my $uri_base = $_->uri_base
                || confess "Services in a Service::Directory must have a uri-base";
            ($uri_base => $_)
        } $self->all_services
    };
}

sub to_app {
    my $self        = shift;
    my %service_map = %{ $self->build_service_map };
    return sub {
        my $env  = shift;
        my $path = $env->{PATH_INFO};
        foreach my $uri_base ( sort { $a cmp $b } keys %service_map ) {
            if ($path =~ /^$uri_base/) {
                return $service_map{ $uri_base }->to_app->( $env );
            }
        }
        Jackalope::REST::Error::ResourceNotFound->new(
            message => "No service found at $path"
        )->to_psgi(
            # NOTE:
            # this isn't ideal, but we
            # don't really have a simpler
            # way to go about it yet. The
            # worst (but unlikely) case is
            # that the services have different
            # serializers and this sends back
            # the wrong type.
            # - SL
            $self->services->[0]->serializer
        );
    };
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Service::Directory - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Service::Directory;

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
