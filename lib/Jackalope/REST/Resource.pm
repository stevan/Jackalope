package Jackalope::REST::Resource;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Digest;
use Jackalope::Util 'encode_json';

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'body' => (
    is       => 'rw',
    isa      => 'Any',
    required => 1,
);

has 'version' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => 'generate_version',
    clearer => 'recalculate_version'
);

has 'links' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    lazy    => 1,
    default => sub { [] },
    handles => {
        'add_links' => 'push'
    }
);

# force the generation
# of the version
sub BUILD { (shift)->version }

sub generate_version {
    my $self = shift;
    Digest->new("SHA-256")
          ->add( encode_json( $self->body, { canonical => 1 } ) )
          ->hexdigest
}

sub compare_version {
    my ($self, $other) = @_;
    # accept strings as well, we won't
    # always have the full object
    ($self->version eq (blessed $other ? $other->version : $other)) ? 1 : 0
}

sub pack {
    my $self = shift;
    return +{
        # NOTE:
        # make sure to force a string here,
        # not sure we actually need it though
        # - SL
        id      => "" . $self->id,
        body    => $self->body,
        version => $self->version,
        links   => $self->links
    };
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Resource - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Resource;

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
