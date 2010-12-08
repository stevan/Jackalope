package Jackalope::Web::Service;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::Web::RouterBuilder;

has 'schema' => (
    is       => 'ro',
    writer   => '_schema',
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

has 'router_builder' => (
    is      => 'ro',
    isa     => 'Jackalope::Web::RouterBuilder',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $repo = $self->service->param('repo');

                                                                # FIXME
        $self->_schema( $repo->register_schema( $self->schema )->{'compiled'} );

        Jackalope::Web::RouterBuilder->new(
            schema  => $self->schema,
            service => $self->service
        )
    },
    handles => {
        'get_router' => 'compile_router'
    }
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;

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
