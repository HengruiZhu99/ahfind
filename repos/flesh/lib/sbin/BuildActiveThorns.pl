#! /usr/bin/perl
#/*@@
#  @file      BuildActiveThorns.pl
#  @date      Tue Jan 19 14:02:07 1999
#  @author    Tom Goodale
#  @desc 
#  Creates an ActiveThornsList
#  @enddesc 
#  @version $Id$
#@@*/

use FindBin;
use lib "$FindBin::Bin";
BEGIN {
my $sbin_dir = $FindBin::Bin;
}

require "MakeUtils.pl";

$package_dir = shift(@ARGV);

%info = &buildthorns($package_dir,"thorns");

printf("# arrangement/thorn %-14s # implements (inherits) [friend] {shares} <requires>\n#\n");

foreach $thorn (sort keys %info)
{
  printf("%-34s # %s\n",$thorn,$info{$thorn});
}
