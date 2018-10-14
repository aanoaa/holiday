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
        "/name" => "original",
    )->json_is(
        "/dates/$year-01-01" => "신정",
        'got description with verbose param'
    );

$t->post_ok('/kr' => form => {
    name     => 'the first custom holidays',
    password => 'secret',
    ymd      => "$year-07-07",
    desc     => '칠월칠석',
})->status_is(201)
    ->content_like(qr/^http/, "response absolute path as text");

$t->get_ok('/kr/1?verbose')
    ->status_is(200)
    ->json_is(
        "/name" => "the first custom holidays"
    )
    ->content_like(qr/07\-07/)
    ->content_like(qr/칠월칠석/, "Added custom holiday");

$t->put_ok('/kr/1' => form => {
    password => 'wrong password',
    ymd      => "$year-10-01",
    desc     => '국군의 날',
})->status_is(400)
    ->json_like('/error' => qr/password/i);

$t->put_ok('/kr/1' => form => {
    password => 'secret',
    ymd      => "$year-10-01",
    desc     => '국군의 날',
})->status_is(200)
    ->content_like(qr/^http/, "response absolute path as text");

$t->get_ok('/kr/1?verbose')
    ->status_is(200)
    ->content_like(qr/10\-01/)
    ->content_like(qr/국군의 날/, "Updated custom holiday");

$t->delete_ok('/kr/1' => form => {
    password => 'secret',
    ymd      => "$year-10-01",
})->status_is(200)
    ->content_like(qr/^http/, "response absolute path as text");

$t->get_ok('/kr/1?verbose')
    ->status_is(200)
    ->content_unlike(qr/10\-01/)
    ->content_unlike(qr/국군의 날/, "Deleted custom holiday");

done_testing();
