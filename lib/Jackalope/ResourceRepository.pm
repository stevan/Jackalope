package Jackalope::ResourceRepository;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'serializer' => (
    is       => 'ro',
    isa      => 'Jackalope::Serializer',
    required => 1,
);

# external API, for service objects
# using an instance of the repository

# internal API, for consumers of this role

requires 'list';    # () => Array[ Data ]
requires 'create';  # (Data) => Id
requires 'read';    # (Id) => Data
requires 'update';  # (Id, Data) => Data
requires 'delete';  # (Id) => ()

sub get_digest {
    my ($self, $serialized_resource) = @_;
}

## error handlers

sub resource_not_found {
    my ($self, $message) = @_;
    die "404 Resource Not Found : $message"
}

sub conflict_detected {
    my ($self, $message) = @_;
    die "409 Conflict Detected : $message"
}

sub invalid_request {
    my ($self, $message) = @_;
    die "400 Bad Request : $message"
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Jackalope::ResourceRepository - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::ResourceRepository;

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
