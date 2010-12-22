package Jackalope::REST::Router;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Jackalope::REST::Error::MethodNotAllowed;
use Jackalope::REST::Error::ResourceNotFound;

use File::Spec::Unix;

has 'uri_base' => ( is => 'ro', isa => 'Str',     default => '' );
has 'schema'    => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'routes'    => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => 'build_routes'
);

sub build_routes {
    my $self   = shift;
    my $schema = $self->schema;

    # NOTE:
    # construct a data structure where matching HREF values
    # are collected and then a hash of HTTP methods are placed
    # under them. This will allow us to more easily capture
    # the other allowed methods for a given URI.
    # - SL

    my %routes;
    foreach my $link ( values %{ $schema->{'links'} } ) {
        my $href = $self->uri_base . $link->{'href'};
        if ( not exists $routes{ $href } ) {
            $routes{ $href } = {
                matcher => $self->generate_matcher_for( $href ),
                methods => {}
            };
        }
        if ( not exists $routes{ $href }->{'methods'}->{ $link->{'method'} } ) {
            $routes{ $href }->{'methods'}->{ $link->{'method'} } = $link;
        }
        else {
            die "Duplicate method (" . $link->{'method'} . ") for href (" . $href . ")";
        }
    }
    return \%routes;
}

sub generate_matcher_for {
    my $self = shift;
    my $href = File::Spec::Unix->canonpath( shift );

    my @href = split '/' => $href;

    if ( (scalar grep { /^\:/ } @href) == 0 ) {
        return sub {
            my $uri = File::Spec::Unix->canonpath( $_[0] );
            #warn "$_[0] => $uri => $href";
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

    # NOTE:
    # we want to sort the routes
    # here so that literal hrefs
    # (no variables) are tested
    # first, this will eliminate
    # the possibility of a variable
    # href matching a literal one.
    # - SL
    foreach my $href ( sort { $a =~ /\:/ ? 1 : ( $b =~ /\:/ ? -1 : ( $a cmp $b )) } keys %{ $self->routes } ) {

        #warn "attempting to match $uri to $href";

        my $route = $self->routes->{ $href };

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
            href   => $self->uri_base . $link->{'href'},
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
            href   => $self->uri_base . (join "/" => @href),
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
