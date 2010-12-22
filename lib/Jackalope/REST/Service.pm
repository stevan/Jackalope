package Jackalope::REST::Service;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'uri_base' => ( is => 'ro', isa => 'Str', default => '' );

has 'schema_repository' => (
    is       => 'ro',
    isa      => 'Jackalope::Schema::Repository',
    required => 1
);

has 'serializer' => (
    is       => 'ro',
    does     => 'Jackalope::Serializer',
    required => 1
);

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Service - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Service;

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
