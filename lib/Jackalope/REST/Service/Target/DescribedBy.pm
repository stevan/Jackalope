package Jackalope::REST::Service::Target::DescribedBy;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Try::Tiny;

with 'Jackalope::REST::Service::Target';

sub execute {
    my ($self, $r, @args) = @_;

    my $error;
    try   { $self->check_http_method( $r ) }
    catch { $error = $_ };

    if ( $error ) {
        if ( $error->isa('Jackalope::REST::Error') ) {
            return $error->to_psgi;
        }
        else {
            return [ 500, [], [ "Unknown Server Error : $error" ]]
        }
    }

    return $self->process_psgi_output([
        200,
        [],
        [ $self->serializer->serialize( $self->service->schema ) ]
    ]);
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Service::Target::DescribedBy - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Service::Target::DescribedBy;

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
