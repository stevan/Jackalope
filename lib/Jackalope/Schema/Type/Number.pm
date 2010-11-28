package Jackalope::Schema::Type::Number;
use Moose;
use Moose::Util::TypeConstraints 'find_type_constraint';
use MooseX::StrictConstructor;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Jackalope::Schema::Type::Any';

has '+type' => ( default => 'number' );

has [ 'minimum', 'maximum' ] => ( is => 'ro', isa => 'Num' );

has 'exclusiveMinimum' => ( reader => 'exclusive_minimum', isa => 'Bool' );
has 'exclusiveMaximum' => ( reader => 'exclusive_maximum', isa => 'Bool' );

# TODO:
# Need to implement enums
# - SL

sub _build_type_constraint {
    find_type_constraint('Num')
}

override 'validate' => sub {
    my ($self, $data) = @_;

    return 0 unless super();

    if (my $min = $self->minimum) {
        if ($self->exclusive_minimum) {
            return 0 if $data <= $min;
        }
        else {
            return 0 if $data < $min;
        }
    }

    if (my $max = $self->maximum) {
        if ($self->exclusive_maximum) {
            return 0 if $data >= $max;
        }
        else {
            return 0 if $data > $max;
        }
    }

    return 1;
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Type::Number - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Type::Number;

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
