#!/usr/bin/perl
use Carp;
use strict;
use FileHandle;
my $src = $ARGV[0];
my $dest = $ARGV[1];

my $fdr = new FileHandle;
my $fdw = new FileHandle;

open($fdr,$src) or confess "cannot open $src";
open($fdw,">$dest") or confess "cannot open $dest";

print $fdw 'const char *par_file_src =',"\n";
while(my $line=<$fdr>) { 
  $line =~ s/\s+$//;
  $line =~ s/[\\"]/\\$&/g;
  print $fdw "\"$line\\n\"\n";
}
print $fdw ";\n";
close($fdw);
close($fdr);
