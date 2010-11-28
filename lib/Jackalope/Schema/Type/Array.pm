package Jackalope::Schema::Type::Array;
use Moose;
use Moose::Util::TypeConstraints 'find_type_constraint';
use MooseX::StrictConstructor;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use List::AllUtils 'uniq';

extends 'Jackalope::Schema::Type::Any';

has '+type' => ( default => 'array' );

has 'items' => ( traits => [ 'Clone' ], is => 'ro', isa => 'Jackalope::SchemaOrRef' );

has 'minItems'    => ( reader => 'min_items',    isa => 'Int' );
has 'maxItems'    => ( reader => 'max_items',    isa => 'Int' );
has 'uniqueItems' => ( reader => 'unique_items', isa => 'Bool' );

# TODO:
# Most of the validate stuff
# can easily be compiled into
# the type constraint, whcih
# would save a pretty good amount
# of overhead.
# - SL

sub _build_type_constraint {
    find_type_constraint('ArrayRef')
}

override 'validate' => sub {
    my ($self, $data) = @_;

    return 0 unless super();

    if (my $min = $self->min_items) {
        return 0 if (scalar @$data) <= ($min - 1);
    }

    if (my $max = $self->max_items) {
        return 0 if (scalar @$data) >= ($max + 1);
    }

    # NOTE:
    # no need to continue
    # if the array is empty
    # - SL
    return 1 if (scalar @$data) == 0;

    if ($self->unique_items) {
        return 0 if (scalar @$data) != (scalar uniq @$data);
    }

    if (my $item_schema = $self->items) {
        return 0 if scalar map { $item_schema->validate( $_ ) ? () : 1  } @$data;
    }

    return 1;
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Type::Array - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Type::Array;

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
