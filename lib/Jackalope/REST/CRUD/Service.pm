package Jackalope::REST::CRUD::Service;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'Jackalope::REST::Service';

use Jackalope::REST::Router;

use Plack::Request;
use Try::Tiny;
use List::AllUtils 'first';
use Class::Load 'load_class';

has 'resource_repository' => (
    is       => 'ro',
    does     => 'Jackalope::REST::Resource::Repository',
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
    isa     => 'Jackalope::REST::Router',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Jackalope::REST::Router->new( schema => $self->compiled_schema )
    }
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

sub to_app {
    my $self = shift;
    sub {
        my $r = Plack::Request->new( +shift );

        my ($match, $error);
        try   { $match = $self->router->match( $r->path_info, $r->method ) }
        catch { $error = $_ };

        return $error->to_psgi if $error;

        my $target = $self->get_target_for_link( $match->{'link'} );
        $r->env->{'jackalope.router.match.mapping'} = $match->{'mapping'};
        return $target->to_app->( $r->env );
    }
}

sub generate_read_link_for_resource {
    my ($self, $resource) = @_;
    $self->router->uri_for( 'read' => { id => $resource->id } )->{'href'};
}

sub generate_links_for_resource {
    my ($self, $resource) = @_;
    my $schema = $self->compiled_schema;
    $resource->add_links(
        map {
            $self->router->uri_for(
                $_->{'rel'},
                (exists $_->{'uri_schema'} ? { id => $resource->id } : {} )
            )
        } sort { $a->{rel} cmp $b->{rel} } values %{ $schema->{'links'} }
    );
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
