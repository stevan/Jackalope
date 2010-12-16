package Test::Jackalope::Fixtures;
use Moose;
use MooseX::Types::Path::Class;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::Util;
use Test::Jackalope;
use Devel::PartialDump 'dump';

has 'fixture_dir' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1
);

has 'repo' => (
    is       => 'ro',
    isa      => 'Jackalope::Schema::Repository',
    required => 1
);

sub run_fixtures_for_type {
    my ($self, $type) = @_;

    $type =~ s/\//_/g if $type =~ /\//;

    my $repo     = $self->repo;
    my $fixtures = decode_json( scalar $self->fixture_dir->file( $type . '.json' )->slurp );

    foreach my $fixture (@$fixtures) {

        my $schema = $fixture->{schema};

        foreach my $data (@{ $fixture->{pass} }) {
            validation_pass(
                $repo->validate( $schema, $data ),
                '... validation passed for ' . (dump $data) . ' against ' . $type
            );
        }

        foreach my $data (@{ $fixture->{fail} }) {
            validation_fail(
                $repo->validate( $schema, $data ),
                '... validation failed for ' . (dump $data) . ' against ' . $type
            );
        }
    }

}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Test::Jackalope::Fixtures - A Moosey solution to this problem

=head1 SYNOPSIS

  use Test::Jackalope::Fixtures;

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
