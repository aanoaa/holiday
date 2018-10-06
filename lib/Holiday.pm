package Holiday;
use Mojo::Base 'Mojolicious';

use Mojo::SQLite;

has sqlite => sub {
    my $self = shift;
    my $sqlite = Mojo::SQLite->new($self->config->{dsn});
    $sqlite->auto_migrate(1)->migrations->name('holiday')->from_data;
    return $sqlite;
};

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->plugin('Config');
    $self->plugin('Holiday::Plugin::Helpers');

    my $r = $self->routes;
    $r->get('/')                ->to('root#index');
    $r->get('/:code')           ->to('root#origin')->name('holiday.origin');
    $r->get('/:code/:extra_id') ->to('root#custom')->name('holiday.custom');
    $r->post('/:code')          ->to('root#create');
}

1;

__DATA__

@@ holiday
-- 1 up
CREATE TABLE IF NOT EXISTS extra (
  id         INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  code       TEXT    NOT NULL,
  password   TEXT    NOT NULL,
  created_at TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS extra_holiday (
  extra_id    INTEGER NOT NULL,
  year        TEXT NOT NULL,
  holiday     TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(extra_id) REFERENCES extra(id)
);

-- 1 down
DROP TABLE IF EXISTS extra;
DROP TABLE IF EXISTS extra_holiday;
