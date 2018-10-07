FROM perl:5

RUN apt-get update && apt-get install -y libssl-dev \
    sqlite3 \
    && apt-get clean

RUN cpanm --notest \
    DBI \
    IO::Socket::SSL \
    Net::SSLeay

RUN groupadd holiday && useradd -g holiday holiday

WORKDIR /tmp
COPY cpanfile cpanfile
RUN cpanm --notest \
    --installdeps .

WORKDIR /home/holiday/app
COPY . .
RUN chown -R holiday:holiday .

USER holiday
ENV MOJO_HOME=/home/holiday/app
ENV MOJO_CONFIG=holiday.conf

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["hypnotoad"]

EXPOSE 5000
