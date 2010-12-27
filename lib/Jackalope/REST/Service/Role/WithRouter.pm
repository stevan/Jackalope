package Jackalope::REST::Service::Role::WithRouter;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::REST::Router;
use Jackalope::REST::Error::InternalServerError;

use Try::Tiny;
use Class::Load 'load_class';

requires 'uri_base';
requires 'get_all_linkrels';

has 'router' => (
    is      => 'ro',
    isa     => 'Jackalope::REST::Router',
    lazy    => 1,
    builder => 'build_router'
);

sub build_router {
    my $self = shift;
    Jackalope::REST::Router->new(
        uri_base => $self->uri_base,
        linkrels => $self->get_all_linkrels
    );
}

has 'linkrels_to_target_class' => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    default => sub { +{} }
);

sub get_linkrels_to_target_map { (shift)->linkrels_to_target_class }
sub get_target_for_linkrel {
    my ($self, $link) = @_;

    my $target_class = $self->get_linkrels_to_target_map->{ lc $link->{'rel'} };

    Jackalope::REST::Error::NotImplemented->throw(
        "No target class found for rel (" . $link->{'rel'} . ")"
    ) unless defined $target_class;

    load_class( $target_class );

    return $target_class->new(
        service => $self,
        link    => $link
    );
}

sub to_app {
    my $self = shift;
    sub {
        my $env = shift;
        my ($result, $error);
        try {
            my $match  = $self->router->match( $env->{PATH_INFO}, $env->{REQUEST_METHOD} );
            my $target = $self->get_target_for_linkrel( $match->{'link'} );
            $env->{'jackalope.router.match.mapping'} = $match->{'mapping'};
            $result = $target->to_app->( $env );
        } catch {
            if (blessed $_) {
                # assume this is one of ours
                $error = $_;
            }
            else {
                # otherwise wrap it up in one of ours
                $error = Jackalope::REST::Error::InternalServerError->new(
                    message => $_
                );
            }
        };
        return $error->to_psgi( $self->serializer ) if $error;
        return $result;
    };
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Service::Role::WithRouter - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Service::Role::WithRouter;

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
