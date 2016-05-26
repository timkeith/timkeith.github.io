#!/usr/bin/env perl
use strict;
use warnings;
sub close_outfile($);
sub open_outfile($);

if(@ARGV != 1) {
    die "Usage: $0 <output-file.coffee>\n";
}
my($outfile) = @ARGV;
my $tmp = "$outfile.tmp";
my $outfh = open_outfile($tmp);

my $count = 0;
my $fh;
open($fh, '<', '/etc/dictionaries-common/words') || die $!;
while(<$fh>) {
    chomp;
    next unless /^[a-z]{3,8}$/;
    tr/[a-z]/[A-Z]/;
    print $outfh " '$_'\n";
    $count += 1;
}
close($fh);

close_outfile($outfh);
rename($tmp, $outfile);

print "Generated $outfile with $count words\n";

exit;

sub open_outfile($) {
    my($tmp) = @_;
    my $outfh;
    open($outfh, '>', $tmp);
    print $outfh "module.exports = [\n";
    return $outfh;
}

sub close_outfile($) {
    my($outfh) = @_;
    print $outfh "]\n";
    close($outfh);
}

