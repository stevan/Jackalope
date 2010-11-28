package Jackalope::Schema::Type::Object;
use Moose;
use Moose::Util::TypeConstraints 'find_type_constraint';
use MooseX::StrictConstructor;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Jackalope::Schema::Type::Any';

has '+type' => ( default => 'object' );

has 'properties' => (
    traits => [ 'Clone' ],
    is     => 'ro',
    isa    => 'Jackalope::SchemaMap'
);

has 'additionalProperties' => (
    traits => [ 'Clone' ],
    reader => 'additional_properties',
    isa    => 'Jackalope::SchemaMap'
);

# TODO:
# Most of the validate stuff
# can easily be compiled into
# the type constraint, whcih
# would save a pretty good amount
# of overhead.
# - SL

sub _build_type_constraint {
    find_type_constraint('HashRef')
}

override 'validate' => sub {
    my ($self, $data) = @_;

    return 0 unless super();

    if (my $props = $self->properties) {

        return 0 if (scalar keys %$props) != (scalar keys %$data);

        foreach my $k (keys %$props) {
            my $v = $props->{ $k };

            return 0 if not exists $data->{ $k };

            my $d = $data->{ $k };

            return 0 unless $v->validate( $d );
        }
    }

    if ($self->additional_properties) {
        confess "additional_properties doesnt make sense to me yet, so I am going to punt here.";
    }

    return 1;
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Type::Object - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Type::Object;

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
