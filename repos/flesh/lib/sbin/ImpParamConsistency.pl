#/*@@
#  @file      ImpParamConsistency.pl
#  @date      Tue Mar  9 12:34:54 1999
#  @author    Tom Goodale
#  @desc 
#  Consistency checking for interface and parameter databases.
#  @enddesc 
#@@*/

use strict;
use warnings;

sub CheckImpParamConsistency
{
  my($n_interface_data, @indata) = @_;
  my(%interface_database);
  my(%parameter_database);
  my(@thorns);
  my($thorn, $friend, $implementation, $other_thorn);
  my($range);

  # Extract the arguments
  %interface_database = @indata[0..2*$n_interface_data-1];
  %parameter_database = @indata[2*$n_interface_data..$#indata];
  
  @thorns = split(" ", $interface_database{"THORNS"});

  foreach $thorn (@thorns)
  {
#    print "Processing thorn $thorn\n";

    foreach $friend (split(" ", $parameter_database{"\U$thorn\E SHARES implementations"}))
    {
#      print "Friend is $friend\n";
      # Find a thorn providing this implementation
      ($other_thorn) = split(" ", $interface_database{"IMPLEMENTATION \U$friend\E THORNS"});

      # Check the other implementation exists.
      if($other_thorn =~ m:^\s*$:)
      {
        &CST_error(0,"Thorn '$thorn' SHARES from non-existing implementation '$friend'",'',__LINE__,__FILE__);
        next;
      }

#      print "Other thorn is $other_thorn\n";

      foreach my $parameter (split(" ", $parameter_database{"\U$thorn SHARES $friend\E variables"}))
      {
#       print "Parameter is $parameter\n";

        my $realname = $parameter_database{"\U$thorn $parameter\E realname"};
        my $type = $parameter_database{"\U$thorn $parameter\E type"};

        # Check if the parameter exists in the other thorn
        if($parameter_database{"\U$other_thorn $realname\E type"})
        {
          my $othertype = $parameter_database{"\U$other_thorn $realname\E type"};
          # Check that the parameter is in the restricted block.
          if($parameter_database{"\U$other_thorn RESTRICTED\E variables"} =~ m:\b$realname\b:i)
          {
            # Check that the parameter types agree
            if($othertype =~ m/\b$type\b/i)
            {

#   This lot is done by C now, and SHOULD NOT BE DONE by the perl
#           # Loop through all the added ranges.
#           for($range=1; 
#               $range <= $parameter_database{"\U$thorn $parameter\E ranges"}; 
#               $range++)
#           {
#             # Increment the number of ranges for the extended parameter
#             $parameter_database{"\U$other_thorn $parameter\E ranges"}++;

              # Add in the range
#             $parameter_database{"\U$other_thorn $parameter\E range $parameter_database{\"\U$other_thorn $parameter\E ranges\"} range"} = $parameter_database{"\U$thorn $parameter\E range $range range"};

              # Add in the range description
#             $parameter_database{"\U$other_thorn $parameter\E range $parameter_database{\"\U$other_thorn $parameter\E ranges\"} description"} = $parameter_database{"\U$thorn $parameter\E range $range description"};
#           }
            }
            else
            {
              my $message = "Thorn \"$thorn\" attempted to EXTEND or USE parameter \"$realname\" from implementation \"$friend\" having type \"$othertype\" using incorrect type \"$type\"";
              &CST_error(0,$message,"",__LINE__,__FILE__);
            }
          }
          else
          {
              my $message = "Thorn \"$thorn\" attempted to EXTEND or USE non-restricted parameter \"$realname\" from implementation \"$friend\"";
              &CST_error(0,$message,"",__LINE__,__FILE__);
          }
        }
        else
        {
          my $message = "Thorn \"$thorn\" attempted to EXTEND or USE non-existent parameter \"$realname\" from implementation \"$friend\"";
          &CST_error(0,$message,"",__LINE__,__FILE__);
        }
      }
    }
  }

  return %parameter_database;
}

1;
