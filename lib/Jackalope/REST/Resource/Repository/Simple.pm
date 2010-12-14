package Jackalope::REST::Resource::Repository::Simple;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'Jackalope::REST::Resource::Repository';

my %ID_COUNTERS;

has 'db' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} }
);

sub get_next_id { ++$ID_COUNTERS{ $_[0] . "" } }

sub list {
    my $self = shift;
    return [ map { [ $_, $self->db->{ $_ } ] } sort keys %{ $self->db } ]
}

sub create {
    my ($self, $data) = @_;
    my $id = $self->get_next_id;
    $self->db->{ $id } = $data;
    return ( $id, $data );
}

sub get {
    my ($self, $id) = @_;
    return $self->db->{ $id };
}

sub update {
    my ($self, $id, $updated_data) = @_;
    $self->db->{ $id } = $updated_data;
}

sub delete {
    my ($self, $id) = @_;
    delete $self->db->{ $id };
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Resource::Repository::Simple - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Resource::Repository::Simple;

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
