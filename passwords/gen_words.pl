#!/usr/bin/env perl
use strict;
use warnings;

my $WORDS_PER_LINE = 8;

if(@ARGV != 1) {
    die "Usage: $0 <output-file.js>\n";
}
my($outfile) = @ARGV;

my %words = ();
my $fh;
open($fh, '<', '/etc/dictionaries-common/words') || die $!;
while(<$fh>) {
    chomp;
    next unless /^[a-z]{4,8}$/;
    next if /^(.*e)(d)/ && $words{$1};
    next if /^(.*)(s)/ && $words{$1};
    next if /^(.*)(es|ed|ing)/ && $words{$1};
    $words{$_} = 1;
    #print "$_\n";
}
close($fh);

my @words = sort keys %words;
my $count = int(@words);
print "Generating $outfile with $count words\n";

my $tmp = "$outfile.tmp";
my $outfh;
open($outfh, '>', $tmp);
print $outfh "module.exports = [\n";
for(my $i = 0; $i < $count; ) {
    my @x = @words[$i .. $i+$WORDS_PER_LINE-1];
    $i += $WORDS_PER_LINE;
    if ($i >= $count) {
        my $out = '"' . join('","',  grep { defined } @x) . "\"\n";
        $out =~ s/,("",)*$//;  # handle incomplete last line and trailing comma
        print $outfh $out;
        last;
    }
    my $out = '"' . join('","',  @x) . "\",\n";
    print $outfh $out;
}
print $outfh "];\n";
close($outfh);
rename($tmp, $outfile);
