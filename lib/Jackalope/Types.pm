package Jackalope::Types;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

subtype 'Jackalope::JSONType'
    => as 'Undef | Str | Num | ArrayRef | HashRef';

class_type 'Jackalope::Schema::Core::Ref';
class_type 'Jackalope::Schema::Type::Any';

subtype 'Jackalope::SchemaOrRef'
    => as 'Jackalope::Schema::Type::Any | Jackalope::Schema::Core::Ref';

subtype 'Jackalope::SchemaMap'
    => as 'HashRef[ Jackalope::SchemaOrRef ]';

subtype 'Jackalope::SchemaLinks'
    => as 'ArrayRef[ Jackalope::Core::Hyperlink ]';

subtype 'Jackalope::Uri'
    => as 'Str';

enum 'Jackalope::HTTPMethod' => qw[
    GET
    POST
    PUT
    DELETE
];

no Moose::Util::TypeConstraints; 1;

__END__

=pod

=head1 NAME

Jackalope::Types - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Types;

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
