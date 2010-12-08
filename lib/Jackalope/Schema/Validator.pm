package Jackalope::Schema::Validator;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'validator' => (
    is       => 'ro',
    isa      => 'Jackalope::Schema::Validator::Core',
    required => 1,
);

sub validate {
    my ($self, $schema, $data) = @_;
    my $validator = $self->validator;
    my $method    = $validator->can( $schema->{'type'} ) || confess "Could not find validator for $schema->{type}";
    return $validator->$method( $schema, $data );
}

sub has_validator_for {
    my ($self, $type) = @_;
    $self->validator->can( $type ) ? 1 : 0
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Schema::Validator - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Schema::Validator;

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
