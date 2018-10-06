package Holiday::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

use Digest::SHA qw/sha256_hex/;

=head1 NAME

Holiday::Controller::Root - Root controller of Holiday app

=head1 ATTRIBUTES

=cut

has sqlite => sub { shift->app->sqlite };

=head1 METHODS

=head2 index

    GET /

=cut

sub index {
    my $self = shift;
    $self->redirect_to(
        'holiday.origin',
        code => $self->config->{default_code}
    );
}

=head2 origin

    # holiday.origin
    GET /:code
    {
      year    : optional
      verbose : optional; boolean
    }

    GET /kr            # response as array of json
    GET /kr?year=2018
    GET /kr?verbose    # response as object of json

C<:code> is country code.
Default C<year> param is this year.

=cut

sub origin {
    my $self = shift;
    my $code = $self->param('code');
    my $year = $self->param('year') || (localtime)[5] + 1900;
    my $verbose = defined $self->param('verbose');

    my $holidays = $self->holidays($code, $year, { verbose => $verbose });
    $self->render(json => $holidays);
}

=head2 custom

    # holiday.custom
    GET /:code/:extra_id
    {
      year    : optional
      verbose : optional; boolean
    }

    GET /kr/1            # response as array of json
    GET /kr/1?year=2018
    GET /kr/1?verbose    # response as object of json

C<:code> is country code.
Default C<year> param is this year.

=cut

sub custom {
    my $self     = shift;
    my $code     = $self->param('code');
    my $extra_id = $self->param('extra_id');

    my $db = $self->sqlite->db;
    my ($stmt, @bind) = $self->sqlite->abstract->where({ id => $extra_id });
    my $rs = $db->query('SELECT * FROM extra' . $stmt, @bind);
    return $self->abort(404, "ID not found: $extra_id") unless $rs->hash;

    my $year     = $self->param('year') || (localtime)[5] + 1900;
    my $verbose  = defined $self->param('verbose');
    my $holidays = $self->holidays($code, $year, { verbose => $verbose });

    ($stmt, @bind) = $self->sqlite->abstract->where({ extra_id => $extra_id, year => $year });
    $rs = $db->query('SELECT * FROM extra_holiday' . $stmt, @bind);
    while (my $extra = $rs->hash) {
        my $ymd  = $extra->{holiday};
        my $desc = $extra->{description};
        if ($verbose) {
            $holidays->{$ymd} = $desc;
        } else {
            push @$holidays, $ymd;
        }
    }

    $holidays = [sort @$holidays] unless $verbose;
    $self->render(json => $holidays);
}

=head2 create

    POST /:code
    {
      password : required
      ymd      : required; yyy-mm-dd; multiple values possible
      desc     : required; multiple values possible
    }

=cut

sub create {
    my $self = shift;
    my $code = $self->param('code');

    my $v = $self->validation;
    $v->required('password');
    $v->required('ymd')->like(qr/^\d{4}-\d{2}-\d{2}$/);
    $v->required('desc');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->abort( 400, 'Parameter validation failed: ' . join( ', ', @$failed ) );
    }

    my $password   = $v->param('password');
    my $every_ymd  = $v->every_param('ymd');
    my $every_desc = $v->every_param('desc');

    my $db = $self->sqlite->db;
    my $extra_id;
    eval {
        my $tx     = $db->begin;
        my $salt   = substr(time, 0, 10);
        my $secret = sha256_hex($password . $salt) . $salt;
        $extra_id  = $db->insert('extra', {
            code     => $code,
            password => $secret,
        })->last_insert_id;

        for (my $i = 0; $i < @$every_ymd; $i++) {
            my $ymd  = $every_ymd->[$i];
            my $desc = $every_desc->[$i];
            my $year = substr $ymd, 0, 4;
            $db->insert('extra_holiday', {
                extra_id    => $extra_id,
                year        => $year,
                holiday     => $ymd,
                description => $desc,
            });
        }

        $tx->commit;
    };

    if ($@) {
        return $self->abort(500, "Failed to create a extra holidays: $@");
    }

    $self->redirect_to(
        'holiday.custom',
        code     => $code,
        extra_id => $extra_id
    );
}

1;
