package Jackalope::Schema::Type::Any;
use Moose;
use Moose::Util::TypeConstraints 'find_type_constraint';
use MooseX::StrictConstructor;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::Types;

with 'MooseX::Clone';

has 'type' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'Str',
    default  => 'any',
);

has 'id'          => ( is => 'ro', isa => 'Jackalope::Uri' );
has 'title'       => ( is => 'ro', isa => 'Str' );
has 'description' => ( is => 'ro', isa => 'Str' );
has 'extends'     => ( traits => [ 'Clone' ], is => 'ro', isa => 'Jackalope::SchemaOrRef' );
has 'links'       => ( traits => [ 'Clone' ], is => 'ro', isa => 'Jackalope::SchemaLinks' );

# TODO
# figure out how extends works
# - SL

has '_type_constraint' => (
    is        => 'ro',
    isa       => 'Moose::Meta::TypeConstraint',
    lazy      => 1,
    builder   => '_build_type_constraint'
);

sub validate {
    my ($self, $data) = @_;
    return 0 unless $self->_type_constraint->check( $data );
    return 1;
}

sub _build_type_constraint {
    find_type_constraint('Any')
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Type::Any - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Type::Any;

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
