# holidays #

공휴일 API 서비스

## Requirements ##

    $ cpanm --installdeps .

## Run ##

    $ MOJO_CONFIG=holiday.conf morbo -m development ./script/holiday
    Server available at http://127.0.0.1:3000

## API ##

### Get original holidays ###

    $ curl http://localhost:3000/kr
    $ curl http://localhost:3000/kr?year=2012
    $ curl http://localhost:3000/kr?verbose

### Create custom holidays ###

```
$ curl -X POST \
       -d "password=password to modify later" \
       -d "ymd=2018-07-07" \
       -d "desc=칠월칠석" \
       -d "ymd=2018-10-01" \  # multiple values possible
       -d "desc=국군의 날" \
       http://localhost:3000/kr

http://localhost:3000/kr/1
```

### Get custom holidays ###

    $ curl http://localhost:3000/kr/1
    $ curl http://localhost:3000/kr/1?year=2012
    $ curl http://localhost:3000/kr/1?verbose

### Update custom holidays ###

Add holidays.

```
$ curl -X PUT \
       -d "password=password to modify later" \
       -d "ymd=2018-05-04" \
       -d "desc=어린이날 전날" \
       -d "ymd=2018-05-06" \  # multiple values possible
       -d "desc=어린이날 다음날" \
       http://localhost:3000/kr/1

http://localhost:3000/kr/1
```

Delete a exists extra holiday.

```
$ curl -X DELETE \
       -d "password=password to modify later" \
       -d "ymd=2018-05-04" \
       -d "ymd=2018-05-06" \  # multiple values possible
       http://localhost:3000/kr/1

http://localhost:3000/kr/1
```

## Docker ##

### Build docker image ###

    $ docker build -f Dockerfile -t aanoaa/holiday .

### Run container ###

    $ docker run --name "holiday" --rm -d -p "5000:5000" aanoaa/holiday

    # for verbose stdout
    $ docker run --name "holiday" --rm -d -p "5000:5000" aanoaa/holiday morbo
