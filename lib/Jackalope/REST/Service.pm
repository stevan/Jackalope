package Jackalope::REST::Service;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

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

has 'schemas' => (
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    required => 1
);

has 'compiled_schemas' => ( is => 'ro', writer => '_set_compiled_schemas' );

has 'router' => (
    is      => 'ro',
    isa     => 'Path::Router',
    lazy    => 1,
    builder => 'build_router'
);

sub BUILD {
    my ($self, $params) = @_;

    my @schemas;
    my $repo = $self->schema_repository;
    foreach my $schema (@{ $self->schemas }) {
        push @schemas => $repo->register_schema( $schema );
    }

    $self->_set_compiled_schemas(\@schemas);
}

sub build_router {
    my $self   = shift;
    my $router = Path::Router->new;

    foreach my $schema (@{ $self->compiled_schemas }) {
        next unless exists $schema->{'links'};
        foreach my $link ( @{ $schema->{'links'} }) {

            my $target_class = 'Jackalope::REST::Service::Target::' . (ucfirst $link->{'rel'});
            load_class($target_class);

            $router->add_route(
                $link->{'href'},
                defaults => {
                    rel    => $link->{'rel'},
                    method => $link->{'method'} || 'GET',
                },
                target  => $target_class->new(
                    service => $self,
                    link    => $link
                )
            );
        }
    }

    $router;
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
