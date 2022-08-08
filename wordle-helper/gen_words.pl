#!/usr/bin/env perl
use strict;
use warnings;

my $DICT = 'words.txt';
my $WORDS_PER_LINE = 10;

open(my $fh, '<', $DICT) || die "$0: can't read $DICT: $!";
my @words = map { chomp; $_ } <$fh>;
close($fh);

my $count = int(@words);

print "Words = [";
for my $i (0 .. $#words) {
    print "\n  " if $i % $WORDS_PER_LINE == 0;
    print "'$words[$i]',";
}
print "\n]\n";
print "module.exports = Words\n";
