use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Holiday', {
    dsn          => ':memory:',
    default_code => 'kr',
    secret       => time
});

my $year = (localtime)[5] + 1900; # this year

$t->get_ok('/')
    ->status_is(302)
    ->header_is(
        'Location' => '/kr',
        'redirect to default country code'
    );

$t->get_ok('/kr')
    ->status_is(200)
    ->json_is(
        '/0' => "$year-01-01",
        "got holidays"
    );

$t->get_ok('/kr?year=2017')
    ->status_is(200)
    ->json_is(
        '/0' => "2017-01-01",
        'got holidays with year param'
    );

$t->get_ok('/kr?verbose')
    ->status_is(200)
    ->json_is(
        "/$year-01-01" => "신정",
        'got description with verbose param'
    );

$t->post_ok('/kr' => form => {
    password => 'secret',
    ymd      => "$year-07-07",
    desc     => '칠월칠석',
})->status_is(201)
    ->content_like(qr/^http/, "response absolute path as text");

$t->get_ok('/kr/1?verbose')
    ->status_is(200)
    ->content_like(qr/07\-07/, "Added custom holiday")
    ->content_like(qr/칠월칠석/, "Added custom holiday");

done_testing();
