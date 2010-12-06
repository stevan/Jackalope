package Jackalope::Script::GenerateSpec;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Class::Load 'load_class';
use Data::Visitor::Callback;

with 'MooseX::Getopt';

has 'target' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    required => 1
);

has 'format' => (
    is      => 'ro',
    isa     => 'Str', # enum([qw[ JSON ]]), # eventually this will have more
    lazy    => 1,
    default => 'JSON'
);

has 'spec_class' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Jackalope::Schema::Spec'
);

has '_spec' => (
    is      => 'ro',
    isa     => 'Jackalope::Schema::Spec',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $class = $self->spec_class;
        load_class($class);
        $class->new
    },
);

has '_serializer' => (
    traits  => [ 'NoGetopt' ],
    is      => 'ro',
    does    => 'Jackalope::Serializer',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $class = 'Jackalope::Serializer::' . $self->format;
        load_class($class);
        $class->new
    },
);

sub run {
    my $self = shift;

    # clean up the description strings too
    my $schemas = Data::Visitor::Callback->new(
        hash => sub {
            my ($v, $data) = @_;
            if (exists $data->{'description'} && not ref $data->{'description'}) {
                $data->{'description'} =~ s/^\n\s+//;
                $data->{'description'} =~ s/\n\s*/\n/g;
            }
            return $data;
        }
    )->visit( $self->_spec->get_spec );

    my $fh = $self->target->openw;
    $fh->print( $self->_serializer->serialize( $schemas, { pretty => 1 } ) );
    $fh->close;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::Script::GenerateSpec - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::Script::GenerateSpec;

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
