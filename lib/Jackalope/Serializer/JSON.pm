package Jackalope::Serializer::JSON;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Try::Tiny;
use Devel::PartialDump 'dump';
use Jackalope::Util;

with 'Jackalope::Serializer';

sub content_type { 'application/json' };
sub has_canonical_support { 1 }

sub serialize {
    my ($self, $data, $params) = @_;

    $params = { %{ $self->default_params }, %{ $params || {} } }
        if $self->has_default_params;

    try   { encode_json( $data, $params ) }
    catch {
        confess "Failed to serialize\n"
              . "... JSON::XS said : $_"
              . "... for data : " . (dump $data);
    }
}

sub deserialize {
    my ($self, $json, $params) = @_;

    $params = { %{ $self->default_params }, %{ $params || {} } }
        if $self->has_default_params;

    try   { decode_json( $json, $params ) }
    catch {
        confess "Failed to deserialize\n"
              . "... JSON::XS said : $_"
              . "... for json : $json";
    }
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Serializer::JSON - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Serializer::JSON;

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
