package Jackalope::Schema::Compiled;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Clone 'clone';

has 'raw' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'compiled' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { clone( (shift)->raw ) }
);

has 'is_compiled' => (
    traits  => [ 'Bool' ],
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    handles => {
        'mark_as_compiled' => 'set',
    }
);

has 'for_transport' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { clone( (shift)->raw ) }
);

has 'is_compiled_for_transport' => (
    traits  => [ 'Bool' ],
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    handles => {
        'mark_as_compiled_for_transport' => 'set',
    }
);

has 'is_validated' => (
    traits  => [ 'Bool' ],
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    handles => {
        'mark_as_validated' => 'set',
    }
);

has 'validator' => (
    is       => 'ro',
    isa      => 'Jackalope::Schema::Validator',
    required => 1
);

sub validate {
    my ($self, $data) = @_;
    $self->validator->validate( $self->compiled, $data );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Compiled - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Compiled;

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
