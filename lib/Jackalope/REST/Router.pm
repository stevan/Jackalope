package Jackalope::REST::Router;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::REST::Error::MethodNotAllowed;
use Jackalope::REST::Error::ResourceNotFound;

use File::Spec::Unix;

has 'schema' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1
);

has 'routes' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => 'build_routes'
);

sub build_routes {
    my $self   = shift;
    my $schema = $self->schema;
    my %routes;
    foreach my $link ( values %{ $schema->{'links'} } ) {
        if ( not exists $routes{ $link->{'href'} } ) {
            $routes{ $link->{'href'} } = {
                matcher => $self->generate_matcher_for( $link->{'href'} ),
                methods => {}
            };
        }

        if ( not exists $routes{ $link->{'href'} }->{'methods'}->{ $link->{'method'} } ) {
            $routes{ $link->{'href'} }->{'methods'}->{ $link->{'method'} } = $link;
        }
        else {
            die "Duplicate method (" . $link->{'method'} . ") for href (" . $link->{'href'} . ")";
        }
    }
    return \%routes;
}

sub generate_matcher_for {
    my ($self, $href) = @_;

    my @href = split '/' => $href;

    if ( ((scalar @href) == 0) || ((scalar grep { /^\:/ } @href) == 0) ) {
        return sub {
            my $uri = File::Spec::Unix->canonpath( $_[0] );
            $href eq $uri ? [] : undef
        }
    }
    else {
        return sub {
            my ($uri) = @_;

            my @uri = split '/' => File::Spec::Unix->canonpath( $uri );
            return undef unless (scalar @uri) == (scalar @href);

            my @mapping;
            foreach my $el (@href) {
                my $x = shift @uri;
                if ($el =~ /^\:(.*)/) {
                    my $key = $1;
                    push @mapping => { $key => $x };
                }
                else {
                    return undef unless $el eq $x;
                }
            }

            return \@mapping;
        }
    }
}

sub match {
    my ($self, $uri, $method) = @_;

    my $routes = $self->routes;

    # NOTE:
    # not sure if this sort is really
    # the right way, should check this
    # tomorrow when i am sober.
    # - SL
    foreach my $href ( sort { $a =~ /\:/ ? 1 : ( $b =~ /\:/ ? -1 : 1) } keys %$routes ) {

        my $route = $routes->{ $href };

        if ( my $mapping = $route->{'matcher'}->( $uri ) ) {

            my $method_map = $route->{'methods'};

            if ( my $link = $method_map->{ $method } ) {
                return +{
                    link    => $link,
                    mapping => $mapping
                };
            }
            else {
                Jackalope::REST::Error::MethodNotAllowed->new(
                    allowed_methods => [ keys %$method_map ],
                    message         => "Method Not Allowed"
                )->throw
            }
        }
    }

    Jackalope::REST::Error::ResourceNotFound->throw(
        "Could not find resource at ($uri) with method ($method)"
    )
}

sub uri_for {
    my ($self, $linkrel, $mapping) = @_;

    my $link = $self->schema->{'links'}->{ $linkrel };

    (defined $link)
        || confess "Could not find link for $linkrel";

    my @path = split '/' => $link->{'href'};

    if ( ((scalar @path) == 0) || ((scalar grep { /^\:/ } @path) == 0) ) {
        return +{
            rel    => $link->{'rel'},
            href   => $link->{'href'},
            method => $link->{'method'},
        }
    }
    else {
        my @href;
        foreach my $el (@path) {
            if ($el =~ /^\:(.*)/) {
                my $key = $1;

                (defined $mapping->{ $key })
                    || confess "Mapping for $linkrel missing $key";

                push @href => $mapping->{ $key };
            }
            else {
                push @href => $el;
            }
        }

        return +{
            rel    => $link->{'rel'},
            href   => (join "/" => @href),
            method => $link->{'method'},
        }
    }
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Jackalope::REST::Router - A Moosey solution to this problem

=head1 SYNOPSIS

  use Jackalope::REST::Router;

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
