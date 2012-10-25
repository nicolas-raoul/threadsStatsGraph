#!/usr/bin/perl

undef $/;
$_ = <>;
$n = 0;

for $match (split(/(?=\n\n)/)) {
      open(O, '>' . $ARGV[0] . '_' . ++$n);
      print O $match;
      close(O);
}


