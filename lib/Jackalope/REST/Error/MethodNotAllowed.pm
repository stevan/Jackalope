package Jackalope::REST::Error::MethodNotAllowed;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Jackalope::REST::Error';

has '+code' => (default => 405);
has '+desc' => (default => 'Method Not Allowed');

has 'allowed_methods' => ( is => 'ro', isa => 'ArrayRef' );

# The method specified in the Request-Line is not allowed for the resource
# identified by the Request-URI. The response MUST include an Allow header
# containing a list of valid methods for the requested resource.

sub to_psgi {
    my $self = shift;
    [
        $self->code,
        [ 'Allow' => join "," => sort @{ $self->allowed_methods } ],
        [ $self->as_string ]
    ];
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Error::MethodNotAllowed - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Error::MethodNotAllowed;

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
