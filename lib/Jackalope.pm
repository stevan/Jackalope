package Jackalope;
use Moose;
use Bread::Board;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Class::Load 'load_class';

use Jackalope::Schema::Validator::Core;
use Jackalope::Schema::Validator;
use Jackalope::Schema::Spec;
use Jackalope::Schema::Repository;

extends 'Bread::Board::Container';

has '+name' => ( default => sub { (shift)->meta->name } );

sub BUILD {
    my $self = shift;
    container $self => as {

        service 'Jackalope::Serializer' => (
            block => sub {
                my $s = shift;
                my $class = 'Jackalope::Serializer::' . $s->param('format');
                load_class( $class );
                $class->new;
            },
            parameters => {
                'format' => { isa => 'Str' }
            }
        );

        # schema repository, this infers
        # all the other stuff as well, like
        # the spec and the validators
        typemap 'Jackalope::Schema::Repository' => infer;
    };
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope;

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
