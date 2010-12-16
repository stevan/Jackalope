package Jackalope::REST::Service;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use List::AllUtils 'first';
use Try::Tiny;
use Class::Load 'load_class';
use Path::Router;

has 'schema_repository' => (
    is       => 'ro',
    isa      => 'Jackalope::Schema::Repository',
    required => 1
);

has 'resource_repository' => (
    is       => 'ro',
    does     => 'Jackalope::REST::Resource::Repository',
    required => 1
);

has 'serializer' => (
    is       => 'ro',
    does     => 'Jackalope::Serializer',
    required => 1
);

has 'schema' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1
);

has 'compiled_schema' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->schema_repository->register_schema( $self->schema )
    }
);

has 'router' => (
    is      => 'ro',
    isa     => 'Path::Router',
    lazy    => 1,
    builder => 'build_router',
    writer  => 'update_router',
);

my %REL_TO_TARGET_CLASS = (
    create      => 'Jackalope::REST::Service::Target::Create',
    edit        => 'Jackalope::REST::Service::Target::Edit',
    list        => 'Jackalope::REST::Service::Target::List',
    read        => 'Jackalope::REST::Service::Target::Read',
    delete      => 'Jackalope::REST::Service::Target::Delete',
    describedby => 'Jackalope::REST::Service::Target::DescribedBy',
);

sub get_target_for_link {
    my ($self, $link) = @_;

    my $target_class;
    if (exists $REL_TO_TARGET_CLASS{ lc $link->{'rel'} }) {
        $target_class = $REL_TO_TARGET_CLASS{ lc $link->{'rel'} };
    }
    else {
        $target_class = join '::' => map { ucfirst $_ } split '/' => $link->{'rel'};
    }

    (defined $target_class)
        || confess "No target class found for rel (" . $link->{'rel'} . ")";

    load_class( $target_class );

    return $target_class->new(
        service => $self,
        link    => $link
    );
}

sub build_router {
    my $self   = shift;
    my $router = Path::Router->new;
    my $schema = $self->compiled_schema;

    foreach my $link ( @{ $schema->{'links'} }) {
        $router->add_route(
            $link->{'href'},
            defaults => {
                rel    => $link->{'rel'},
                method => $link->{'method'},
                schema => $schema->{'id'}
            },
            target  => $self->get_target_for_link( $link )->to_app
        );
    }

    $router;
}

sub generate_read_link_for_resource {
    my ($self, $resource) = @_;
    my $schema = $self->compiled_schema;
    my $link   = first { $_->{'rel'} eq 'read' } @{ $schema->{'links'} };
    # FIXME
    # This should just return undef or something
    # throwing an exception is kinda extreme
    # - SL
    (defined $link)
        || confess("Could not generate read link for id (" . $resource->id . ")");
    $self->router->uri_for(
        rel    => $link->{'rel'},
        method => $link->{'method'},
        schema => $schema->{'id'},
        id     => $resource->id
    )
}

sub generate_links_for_resource {
    my ($self, $resource) = @_;
    my $schema = $self->compiled_schema;
    $resource->add_links(
        map {
            +{
                rel    => $_->{'rel'},
                method => $_->{'method'},
                href   => $self->router->uri_for(
                    rel    => $_->{'rel'},
                    method => $_->{'method'},
                    schema => $schema->{'id'},
                    (exists $_->{'uri_schema'}
                        ? ( id => $resource->id )
                        : ())
                )
            }
        } @{ $schema->{'links'} }
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Service - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Service;

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
