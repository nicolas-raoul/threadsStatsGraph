#!/usr/bin/perl

undef $/;
$_ = <>;
$n = 0;

for $match (split(/(?=Full )/)) {
      open(O, '>data/threaddump' . ++$n);
      print O $match;
      close(O);
}


