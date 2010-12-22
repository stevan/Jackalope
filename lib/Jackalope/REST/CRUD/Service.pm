package Jackalope::REST::CRUD::Service;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'Jackalope::REST::Service';

use Jackalope::REST::Router;
use Jackalope::REST::Error::InternalServerError;

use Try::Tiny;
use Class::Load 'load_class';

has 'schema'          => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'compiled_schema' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->schema_repository->register_schema( $self->schema )
    }
);

has 'resource_repository' => (
    is       => 'ro',
    does     => 'Jackalope::REST::Resource::Repository',
    required => 1
);

has 'router' => (
    is      => 'ro',
    isa     => 'Jackalope::REST::Router',
    lazy    => 1,
    builder => 'build_router'
);

has 'rel_to_target_class' => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    default => sub { +{} }
);

sub build_router {
    my $self = shift;
    Jackalope::REST::Router->new(
        uri_base => $self->uri_base,
        schema    => $self->compiled_schema
    );
}

{
    my %REL_TO_TARGET_CLASS = (
        create      => 'Jackalope::REST::CRUD::Service::Target::Create',
        edit        => 'Jackalope::REST::CRUD::Service::Target::Update',
        list        => 'Jackalope::REST::CRUD::Service::Target::List',
        read        => 'Jackalope::REST::CRUD::Service::Target::Read',
        delete      => 'Jackalope::REST::CRUD::Service::Target::Delete',
        describedby => 'Jackalope::REST::Service::Target::DescribedBy',
    );

    sub get_target_for_link {
        my ($self, $link) = @_;

        my %rel_to_target_map = (
            %REL_TO_TARGET_CLASS,
            %{ $self->rel_to_target_class }
        );

        my $target_class = $rel_to_target_map{ lc $link->{'rel'} };

        Jackalope::REST::Error::NotImplemented->throw(
            "No target class found for rel (" . $link->{'rel'} . ")"
        ) unless defined $target_class;

        load_class( $target_class );

        return $target_class->new(
            service => $self,
            link    => $link
        );
    }
}

sub generate_read_link_for_resource {
    my ($self, $resource) = @_;
    $self->router->uri_for( 'read' => { id => $resource->id } )->{'href'};
}

sub generate_links_for_resource {
    my ($self, $resource) = @_;
    $resource->add_links(
        map {
            $self->router->uri_for(
                $_->{'rel'},
                (exists $_->{'uri_schema'}
                    ? { id => $resource->id }
                    : {} )
            )
        } sort {
            $a->{rel} cmp $b->{rel}
        } values %{ $self->compiled_schema->{'links'} }
    );
}

sub to_app {
    my $self = shift;
    sub {
        my $env = shift;
        my ($result, $error);
        try {
            my $match  = $self->router->match( $env->{PATH_INFO}, $env->{REQUEST_METHOD} );
            my $target = $self->get_target_for_link( $match->{'link'} );
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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::CRUD::Service - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::CRUD::Service;

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
