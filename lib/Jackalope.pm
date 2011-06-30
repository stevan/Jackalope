package Jackalope;
use Moose;
use Bread::Board;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::Util;

use Jackalope::Schema::Validator::Core;
use Jackalope::Schema::Validator;
use Jackalope::Schema::Spec;
use Jackalope::Schema::Repository;

extends 'Bread::Board::Container';

has '+name' => ( default => sub { (shift)->meta->name } );

has 'schema_spec_class'    => ( is => 'ro', isa => 'Str' );
has 'validator_class'      => ( is => 'ro', isa => 'Str' );
has 'validator_core_class' => ( is => 'ro', isa => 'Str' );

sub BUILD {
    my $self = shift;
    container $self => as {

        service 'Jackalope::Serializer' => (
            block => sub {
                my $s = shift;
                my $class = load_prefixed_class( $s->param('format'), 'Jackalope::Serializer' );
                $class->new(
                    $s->param('default_params')
                        ? (default_params => $s->param('default_params'))
                        : ()
                );
            },
            parameters => {
                'format'         => { isa => 'Str' },
                'default_params' => { isa => 'HashRef', optional => 1 }
            }
        );

        if (my $spec_class = $self->schema_spec_class) {
            load_class( $spec_class );
            typemap 'Jackalope::Schema::Spec' => infer( class => $spec_class );
        }

        if (my $validator_class = $self->validator_class) {
            load_class( $validator_class );
            typemap 'Jackalope::Schema::Validator' => infer( class => $validator_class );
        }

        if (my $validator_core_class = $self->validator_core_class) {
            load_class( $validator_core_class );
            typemap 'Jackalope::Schema::Validator::Core' => infer( class => $validator_core_class );
        }

        # schema repository, this infers
        # all the other stuff as well, like
        # the spec and the validators
        typemap 'Jackalope::Schema::Repository' => infer( lifecycle => 'Singleton' );
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
