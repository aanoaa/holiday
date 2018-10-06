package Holiday::Plugin::Helpers;

use Mojo::Base 'Mojolicious::Plugin';

use Date::Holidays::KR ();

=encoding utf8

=head1 NAME

Holiday::Plugin::Helpers - Holiday default helpers

=head1 SYNOPSIS

    # Mojolicious::Lite
    plugin 'Holiday::Plugin::Helpers';

    # Mojolicious
    $self->plugin('Holiday::Plugin::Helpers');

=cut

sub register {
    my ($self, $app, $conf) = @_;
    $app->helper( log      => sub { shift->app->log } );
    $app->helper( abort    => \&abort );
    $app->helper( holidays => \&holidays );
}

=head1 HELPERS

=head2 abort

    $app->abort(400, "oops something wrong", { extra => { foo => 'bar' } });
    {
      "error": "oops something wrong",
      "extra": {
        "foo": "bar"
      }
    }

=cut

sub abort {
    my ($self, $http_code, $err_msg, $extra) = @_;
    my $data = { error => $err_msg };
    for my $key (keys %$extra) {
        if ($key eq 'error') {
            $self->log->info("ignore 'error' key in extra data response");
            next;
        }

        $data->{$key} = $extra->{$key};
    }

    $self->render(json => $data, status => $http_code);
    return;
}

=head2 holidays($country_code, $year, $opts)

    my @holidays = $app->holidays('kr', 2018, $opts);

=head3 options

=over

=item *

C<verbose>: boolean

=back

=cut

sub holidays {
    my ($self, $code, $year, $opts) = @_;

    my $holidays = Date::Holidays::KR::holidays($year);
    if ($opts->{verbose}) {
        my %holidays;
        for my $mmdd (sort keys %$holidays) {
            my $desc = $holidays->{$mmdd};
            my $mm = substr $mmdd, 0, 2;
            my $dd = substr $mmdd, 2;
            $holidays{"$year-$mm-$dd"} = $desc;
        }

        return \%holidays;
    }

    my @holidays;
    for my $mmdd (sort keys %$holidays) {
        my $mm = substr $mmdd, 0, 2;
        my $dd = substr $mmdd, 2;
        push @holidays, "$year-$mm-$dd";
    }

    return \@holidays;
}

=head1 LISENSE

MIT

=head1 AUTHOR

Hyungsuk Hong

=cut

1;
