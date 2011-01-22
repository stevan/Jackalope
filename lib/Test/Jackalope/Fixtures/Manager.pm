package Test::Jackalope::Fixtures::Manager;
use Moose;
use MooseX::Types::Path::Class;
use Resource::Pack;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Class ();

extends 'Resource::Pack::Resource';

has '+name' => ( default => __PACKAGE__ );

has 'fixtures_root' => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    lazy    => 1,
    default => sub { Path::Class::File->new(__FILE__)->parent },
);

sub BUILD {
    my $self = shift;
    resource $self => as {
        resource 'Core' => as {
            install_from( $self->fixtures_root->subdir('Core') );

            file 'any'       => 'any.json';
            file 'null'      => 'null.json';
            file 'boolean'   => 'boolean.json';
            file 'number'    => 'number.json';
            file 'integer'   => 'integer.json';
            file 'string'    => 'string.json';
            file 'array'     => 'array.json';
            file 'object'    => 'object.json';

            file 'hyperlink' => 'hyperlink.json';
            file 'linkrel'   => 'linkrel.json';
            file 'ref'       => 'ref.json';
        };
    };
}

__PACKAGE__->meta->make_immutable;

no Moose; no Resource::Pack; 1;

__END__

=pod

=head1 NAME

Test::Jackalope::Fixtures::Manager - A Moosey solution to this problem

=head1 SYNOPSIS

  use Test::Jackalope::Fixtures::Manager;

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

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
