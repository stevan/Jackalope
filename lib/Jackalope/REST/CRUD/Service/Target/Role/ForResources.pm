package Jackalope::REST::CRUD::Service::Target::Role::ForResources;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'Jackalope::REST::Service::Target';

requires 'get_links_for_resource';

# NOTE:
# This is not ideal, I would rather do a
# +service in the attribute, but that is
# not allowed since this is a role. While
# we could switch this to a class, we would
# then load the 'requires' above. The other
# option is to make Jackalope::REST::Service::Target
# a parameterized role which can take a service
# type, however, that seems perhaps like
# overkill. Either way, this works for now.
# - SL
sub BUILD {}
after BUILD => sub {
    ((shift)->service->isa('Jackalope::REST::CRUD::Service'))
        || confess "The service must be a 'Jackalope::REST::CRUD::Service'";
};

around 'process_psgi_output' => sub {
    my $next = shift;
    my ($self, $psgi) = @_;

    return $psgi unless scalar @{ $psgi->[2] };

    # TODO:
    # need to make this also support ETags
    # in the headers based on the resource
    # version that we find
    # - SL

    if ( $self->_is_resource_collection( $psgi->[2]->[0] ) ) {
        # an array of resources
        $psgi->[2]->[0] = [ map { $_->pack } @{ $psgi->[2]->[0] } ];
    }
    elsif ( blessed $psgi->[2]->[0] && $psgi->[2]->[0]->isa('Jackalope::REST::Resource')) {
        # a resource
        $psgi->[2]->[0] = $psgi->[2]->[0]->pack;
    }

    $self->$next( $psgi );
};

# input and output processing

sub verify_and_prepare_output {
    my ($self, $result) = @_;

    if ( $self->_is_resource_collection( $result ) ) {
        $self->check_target_schema( [ map { $_->pack } @$result ] );
    }
    elsif ( blessed $result && $result->isa('Jackalope::REST::Resource') ) {
        $self->check_target_schema( $result->pack );
    }
    else {
        $self->check_target_schema( $result );
    }

    $result;
}

sub generate_links_for_output {
    my ($self, $result) = @_;

    if ( $self->_is_resource_collection( $result ) ) {
        foreach my $resource ( @$result) {
            $self->service->generate_links_for_resource(
                $resource,
                $self->get_links_for_resource
            )
        }
    }
    elsif ( blessed $result && $result->isa('Jackalope::REST::Resource') ) {
        $self->service->generate_links_for_resource(
            $result,
            $self->get_links_for_resource
        );
    }

    $result;
}

sub _is_resource_collection {
    my ($self, $result) = @_;
    (ref $result eq 'ARRAY' && (scalar grep { blessed $_ && $_->isa('Jackalope::REST::Resource') } @$result) != 0) ? 1 : 0
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::CRUD::Service::Target::Role::ForResources - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::CRUD::Service::Target::Role::ForResources;

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
