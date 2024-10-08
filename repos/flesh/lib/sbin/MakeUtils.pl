#/*@@
#  @file      MakeUtils.pl
#  @date      July 1999
#  @author    Tom Goodale
#  @desc
#  Utility perl routines needed by the Makefile.
#  @enddesc
#  @version $Header$
#@@*/

use strict;
use warnings;
use Cwd;


#/*@@
#  @routine   buildthorns
#  @date      Tue Jan 19 14:02:07 1999
#  @author    Tom Goodale
#  @desc
#  Creates an compiled ThornList
#  @enddesc
#  @version $Id$
#@@*/

sub buildthorns
{
  my($arrangement_dir,$choice) = @_;
  my(@arrangements);
  my(%info);


  opendir(my $ARRANGEMENTS, $arrangement_dir) or
    die "Cannot open arrangements directory '$arrangement_dir': $!";

  foreach (sort readdir $ARRANGEMENTS)
  {
    # Ignore CVS and backup stuff
    next if (m:^CVS$:);
    next if (m:^\#:);
    next if (m:~$:);
    next if (m:\.bak$:i);
    next if (m:^\.:);

    # Just pick directories
    if( -d "$arrangement_dir/$_")
    {
      push (@arrangements, $_);
    }
  }

  closedir $ARRANGEMENTS or
    die "Cannot close arrangements directory '$arrangement_dir': $!";

  my @total_list;
  if ($choice =~ "thorns")
  {

    foreach my $arrangement (@arrangements)
    {
      opendir(my $THORNLIST, "$arrangement_dir/$arrangement") or
        die "Cannot open arrangement directory '$arrangement_dir/$arrangement': $!";

      foreach (sort readdir $THORNLIST)
      {
        # Ignore CVS and backup stuff
        next if (m:^CVS$:);
        next if (m:^\#:);
        next if (m:~$:);
        next if (m:\.bak$:i);
        next if (m:^\.:);

        # Allow each arrangement to have a documentation directory.
        next if (m:^doc$:);

        # Just pick directories
        if( -d "$arrangement_dir/$arrangement/$_")
        {
          push(@total_list, "$arrangement/$_");
        }
      }
      closedir $THORNLIST or
        die "Cannot close arrangement directory '$arrangement_dir/$arrangement': $!";
    }

  }
  else
  {
    @total_list = @arrangements;
  }

  if($choice =~ "thorns")
  {
    foreach my $thorn (@total_list)
    {
      # don't check for {interface,param}.ccl files
      # when compiling a list of thorns to be updated
      if( $choice eq 'thorns-to-update' )
      {
        # include this thorn with no further thorn info
        # (only the keys are needed by the calling routine)
        $info{$thorn} = 1;
      }
      elsif ( -r "$arrangement_dir/$thorn/interface.ccl" && -r "$arrangement_dir/$thorn/param.ccl" )
      {
        $info{$thorn} = &ThornInfo("$arrangement_dir/$thorn");
      }
#      print "$thorn \# $info{$thorn}\n";
    }
  }
  else
  {
    foreach my $arrangement (@total_list)
    {
      $info{$arrangement} = 1;
    }
  }

  return %info;
}

#/*@@
#  @routine    ThornInfo
#  @date       Sun Oct 17 15:57:44 1999
#  @author     Tom Goodale
#  @desc
#  Determines some info about a thorn.
#  @enddesc
#@@*/
sub ThornInfo
{
  my($thorn) = @_;
  my($implementation) = "";
  my($friends) = "";
  my($inherits) = "";
  my($shares) = "";
  my($requires) = "";

  open(INTERFACE, "<$thorn/interface.ccl") || die "Unable to open $thorn/interface.ccl";

  while(<INTERFACE>)
  {
    chomp;
    if (m/^\s*IMPLEMENTS\s*:\s*([a-z]+[a-z_0-9]*)\s*$/i)
    {
      $implementation = $1;
    }
    elsif (m/^\s*INHERITS\s*:((\s*[a-zA-Z]+[a-zA-Z_0-9,]*)*\s*)$/i)
    {
      $inherits = $1;
    }
    elsif (m/^\s*FRIEND\s*:((\s*[a-zA-Z]+[a-zA-Z_0-9,]*)*\s*)$/i)
    {
      $friends = $1;
    }
  }

  close(INTERFACE);

  open(PARAM, "<$thorn/param.ccl") || die "Unable to open $thorn/param.ccl";

  while(<PARAM>)
  {
    chomp;
    if(m/SHARES\s*:(.*)/i)
    {
      $shares .= " $1";
    }
  }

  close(PARAM);

  if (-e "$thorn/configuration.ccl") {
    open(CONFIG, "<$thorn/configuration.ccl") || die "Unable to open $thorn/configuration.ccl";

    while(<CONFIG>)
    {
      chomp;
      if (m/^\s*REQUIRES THORNS\s*:\s*(([a-zA-Z]+[a-zA-Z_0-9]*(\s+|$))*)/i or
          m/^\s*REQUIRES\s+((([a-zA-Z]+[a-zA-Z_0-9]*(\([^()]*\))?)(\s+|$))*)/i)
      {
        $requires .= " $1";
      }
    }

    close(CONFIG);
  }

  if($inherits =~ /^[\s\t\n]*$/)
  {
    $inherits = " ";
  }
  else
  {
    $inherits =~ s:^\s*::;
    $inherits =~ s:\s*$::;
    $inherits =~ s:,: :g;
    $inherits =~ s:[\s\t\n]+:,:g;
  }


  if($friends =~ /^[\s\t\n]*$/)
  {
    $friends = " ";
  }
  else
  {
    $friends =~ s:^\s*::;
    $friends =~ s:\s*$::;
    $friends =~ s:,: :g;
    $friends =~ s:[\s\t\n]+:,:g;
  }
  if($shares =~ /^[\s\t\n]*$/)
  {
    $shares = " ";
  }
  else
  {
    $shares =~ s:^\s*::;
    $shares =~ s:\s*$::;
    $shares =~ s:,: :g;
    $shares =~ s:[\s\t\n]+:,:g;
  }
  if($requires =~ /^[\s\t\n]*$/)
  {
    $requires = " ";
  }
  else
  {
    $requires =~ s:^\s*::;
    $requires =~ s:\s*$::;
    $requires =~ s:[\s\t\n]+:,:g;
    # remove duplicates for thorns listed both in REQUIRES and REQUIRES THORNS:
    $requires = join(",", sort keys %{ {map {$_, 1} split ",", $requires} });
  }

  return "$implementation ($inherits) [$friends] {$shares} <$requires>";
}


#/*@@
#  @routine    ThornInfo
#  @date       Wed Sep 5 14:04:07 CEST 2001
#  @author     Ian Kelley
#  @desc
#  Reads in a thornlist and returns the arrangements/thorns,
#  strips out all the comments/etc.
#  @enddesc
#@@*/
sub ReadThornlist
{
   my ($thornlist) = shift;
   my (@temp);
   my (%tl);

   open (TL, "$thornlist")
      || die "\nCannot open thornlist ($thornlist) for reading: $!";

   while (<TL>)
   {
      next if m:^!.*:;
      s/(.*?)#.*/$1/;            # read up to the first "#"
      s/\s+//g;                  # replace any spaces with nothing
      if (/\w+/)
      {
         push @temp, $_;         # add to array if something is left
      }
   }

   foreach (@temp)      # see if docs exist for these thorns
   {
      $tl{$_} = "thorn";
   }

   return %tl;
}

1;
