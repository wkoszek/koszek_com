#!/bin/sh
# Copyright 2017 Wojciech Adam Koszek <wojciech@koszek.com>

DOMAINS=""
DOMAINS="$DOMAINS -d koszek.us -d www.koszek.us"
DOMAINS="$DOMAINS -d koszek.co -d www.koszek.co"
DOMAINS="$DOMAINS -d koszek.tv -d www.koszek.tv"
DOMAINS="$DOMAINS -d koszek.org -d www.koszek.org"
DOMAINS="$DOMAINS -d koszek.net -d www.koszek.net"
#DOMAINS="$DOMAINS -d koszek.com -d www.koszek.com"

letsencrypt --non-interactive --keep-until-expiring --agree-tos --expand \
  --standalone --email wojciech@koszek.com \
  certonly \
  $DOMAINS
