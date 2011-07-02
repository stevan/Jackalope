package Jackalope::Util;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use JSON::XS    ();
use Class::Load ();
use Sub::Exporter;

my @exports = qw/
    true
    false
    encode_json
    decode_json
    load_class
/;

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

=item true

Returns a JSON::XS::true value.

=cut
sub true  () { JSON::XS::true()  }

=item false

Returns a JSON::XS::false value.

=cut
sub false () { JSON::XS::false() }

=item is_bool

Returns a JSON::XS::true value if the argument is true, otherwise returns a
JSON::XS::false value.

=cut
sub is_bool { JSON::XS::is_bool( shift ) }

=item encode_json

Encodes a hashref, using JSON::XS, returning a string of JSON-encoded data. An
optional $params hashref can contain options to be passed directly to JSON::XS.

=cut
sub encode_json {
    my ($data, $params) = @_;
    my $json = JSON::XS->new;
    do { $json->$_( $params->{ $_ } ) foreach keys %$params }
        if defined $params;
    $json->encode( $data )
}

=item decode_json

Decodes a string of JSON-encoded data using JSON::XS, returning a hashref. An
optional $params hashref can contain options to be passed directly to JSON::XS.

=cut
sub decode_json {
    my ($data, $params) = @_;
    my $json = JSON::XS->new;
    do { $json->$_( $params->{ $_ } ) foreach keys %$params }
        if defined $params;
    $json->decode( $data )
}

=item load_class

Loads and returns the specified class. $prefix is optional, and will be ignored
if $class is prepended with a +.

=cut
sub load_class {
    my ($class, $prefix) = @_;
    if ($prefix) {
        unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
            $class = "$prefix\::$class";
        }
    }
    Class::Load::load_class( $class );
    return $class;
}

1;

__END__

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

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
