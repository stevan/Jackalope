package Jackalope::REST::Error;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Throwable::Error';

has 'code' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'desc' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

around 'as_string' => sub {
    my $next = shift;
    my $self = shift;
    $self->code . " " . $self->desc . " : " . $self->message;
};

sub pack {
    my $self = shift;
    {
        code    => $self->code,
        desc    => $self->desc,
        message => $self->message,
    }
}

sub to_psgi {
    my ($self, $serializer) = @_;
    [
        $self->code,
        [],
        [ $serializer->serialize( $self->pack, { canonical => 1 } ) ]
    ];
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Error - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Error;

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
