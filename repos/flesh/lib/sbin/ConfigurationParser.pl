#! /usr/bin/perl
use strict;
use warnings;

#/*@@
#  @file     ConfigurationParser.pl
#  @date     Tue Feb  8 17:36:48 2000
#  @author   Tom Goodale
#  @desc
#            Parser for configuration.ccl files
#  @enddesc
#  @version  $Header$
#@@*/

my $ccl_file;

#/*@@
#  @routine    CreateConfigurationDatabase
#  @date       Tue Feb  8 17:47:26 2000
#  @author     Tom Goodale
#  @desc
#              Parses the information in all the thorns' configuration.ccl files
#              and creates a database from it
#  @enddesc
#@@*/
sub CreateConfigurationDatabase
{
  my($config_dir, %thorns) = @_;
  my(%cfg) = ();
  my(%thorn_dependencies);

  my $peg_file = "$FindBin::Bin/../../src/piraha/pegs/config.peg";
  my ($grammar,$rule) = piraha::parse_peg_file($peg_file);

  # Loop through each thorn's configuration file.
  foreach my $thorn (sort keys %thorns)
  {
    $ccl_file = "$thorns{$thorn}/configuration.ccl";

    # Get the configuration data from it if it exisits
    &ParseConfigurationCCL($config_dir, $thorn, \%cfg, \%thorns, $ccl_file, $grammar, $rule, $peg_file);

    $cfg{"\U$thorn\E USES THORNS"} = '';

    # Verify that all required thorns are there in the ThornList
    if ($cfg{"\U$thorn\E REQUIRES THORNS"})
    {
        my @missing = ();
        foreach my $required (split (' ', $cfg{"\U$thorn\E REQUIRES THORNS"}))
        {
            push (@missing, $required)
                if ((! $thorns{"$required"}) && (! $thorns{"\U$required\E"}));
        }
        if (@missing == 1)
        {
            &CST_error (0, "Thorn '$thorn' requires thorn '@missing'. " .
                        'Please add this thorn to your ThornList or remove ' .
                        "'$thorn' from it !");
        }
        elsif (@missing > 1)
        {
            &CST_error (0, "Thorn '$thorn' requires thorns '@missing'. " .
                        'Please add these thorns to your ThornList or ' .
                        "remove '$thorn' from it !");
        }

        $cfg{"\U$thorn\E USES THORNS"} .=
            $cfg{"\U$thorn\E REQUIRES THORNS"} . ' ';
    }

    # Output statistics
    print "   $thorn\n";
    if ($cfg{"\U$thorn\E PROVIDES"})
    {
        print "           Provides:          ",
            $cfg{"\U$thorn\E PROVIDES"}, "\n";
    }
    if ($cfg{"\U$thorn\E REQUIRES"})
    {
        print "           Requires:          ",
            $cfg{"\U$thorn\E REQUIRES"}, "\n";
    }
    if ($cfg{"\U$thorn\E OPTIONAL"})
    {
        print "           Optional:          ",
            $cfg{"\U$thorn\E OPTIONAL"}, "\n";
    }
    if ($cfg{"\U$thorn\E OPTIONAL_IFACTIVE"})
    {
        print "           Optional-ifactive: ",
            $cfg{"\U$thorn\E OPTIONAL_IFACTIVE"}, "\n";
    }
    if ($cfg{"\U$thorn\E REQUIRES THORNS"})
    {
        print "           Requires thorns:   ",
            $cfg{"\U$thorn\E REQUIRES THORNS"}, "\n";
    }
  }

  if (defined($ENV{VERBOSE}) and lc($ENV{VERBOSE}) eq "yes") {
    print "\n";
    print "+=========================+\n";
    print "| Config Parsing Complete |\n";
    print "+=========================+\n";
  }

  # Turn optional capabilities into required capabilities, if the
  # capability is provided. This way we don't have to treat required
  # and optional requirements differently.
  my %providedcaps;
  foreach my $thorn (sort keys %thorns)
  {
      if ($cfg{"\U$thorn\E PROVIDES"})
      {
          foreach my $providedcap (split (' ', $cfg{"\U$thorn\E PROVIDES"}))
          {
              $providedcaps{$providedcap} = 1;
          }
      }
  }
  foreach my $thorn (sort keys %thorns)
  {
      if ($cfg{"\U$thorn\E REQUIRES"})
      {
          foreach my $requiredcap (split (' ', $cfg{"\U$thorn\E REQUIRES"}))
          {
              $cfg{"\U$thorn\E ACTIVATES"} .= "$requiredcap ";
          }
      }
  }
  foreach my $thorn (sort keys %thorns)
  {
      if ($cfg{"\U$thorn\E OPTIONAL"})
      {
          foreach my $optionalcap (split (' ', $cfg{"\U$thorn\E OPTIONAL"}))
          {
              if ($providedcaps{$optionalcap})
              {
                  $cfg{"\U$thorn\E REQUIRES"} .= "$optionalcap ";
                  $cfg{"\U$thorn\E ACTIVATES"} .= "$optionalcap ";
              }
          }
      }
      if ($cfg{"\U$thorn\E OPTIONAL_IFACTIVE"})
      {
          foreach my $optionalcap (split (' ', $cfg{"\U$thorn\E OPTIONAL_IFACTIVE"}))
          {
              if ($providedcaps{$optionalcap})
              {
                  $cfg{"\U$thorn\E REQUIRES"} .= "$optionalcap ";
                  # nothing is activated
              }
          }
      }
  }

  foreach my $thorn (sort keys %thorns)
  {
    # verify that all required capabilities are there in the ThornList
    next if (! $cfg{"\U$thorn\E REQUIRES"});

    foreach my $requiredcap (split (' ', $cfg{"\U$thorn\E REQUIRES"}))
    {
      my @found = ();
      foreach my $thorncap (sort keys %thorns)
      {
        foreach my $cap (split (' ', $cfg{"\U$thorncap\E PROVIDES"}))
        {
          push (@found, $thorncap)
            if ("\U$cap\E" eq "\U$requiredcap\E");
        }
      }

      # there must be exactly one thorn providing a required capability
      if (@found == 0)
      {
        &CST_error (0, "Thorn '$thorn' requires the capability " .
                       "'$requiredcap'.\n" .
                       "     Please add a thorn that provides '$requiredcap' " .
                       "to your ThornList or remove '$thorn' from it !")
      }
      elsif (@found > 1)
      {
        &CST_error (0, "More than one thorn provides the capability " .
                       "'$requiredcap'.\n" .
                       "     These thorns are: '@found'.\n" .
                       "     Please use only one !\n");
      }
      elsif ( $cfg{"\U$thorn\E REQUIRES \U$requiredcap\E VERSION"} )
      {
        if ( &CheckForCompatibleVersion(
                $cfg{"\U$found[0]\E PROVIDES \U$requiredcap\E VERSION"},
                $cfg{"\U$thorn\E REQUIRES \U$requiredcap\E VERSION"}) == 0 )
        {
          &CST_error (0, "Thorn '$thorn' requires the capability " .
                       "'$requiredcap' in version ".
                       $cfg{"\U$thorn\E REQUIRES \U$requiredcap\E VERSION"}.
                       ". Thorn ".$found[0]." provides $requiredcap, but ".
                       "in version ".
                       $cfg{"\U$found[0]\E PROVIDES \U$requiredcap\E VERSION"}.
                       ".\n");
        }
        $cfg{"\U$thorn\E USES THORNS"} .= $found[0] . ' ';
      }
      else
      {
        $cfg{"\U$thorn\E USES THORNS"} .= $found[0] . ' ';
      }
    }
  }

  # Translate capability to thorn names
  my %capabilities;
  foreach my $thorn (sort keys %thorns)
  {
      next if ! $cfg{"\U$thorn\E PROVIDES"};
      foreach my $cap (split (' ', $cfg{"\U$thorn\E PROVIDES"}))
      {
          $capabilities{"\U$cap\E"} = $thorn;
      }
  }
  foreach my $thorn (sort keys %thorns)
  {
      my $activates = '';
      foreach my $cap (split (' ', $cfg{"\U$thorn\E ACTIVATES"}))
      {
          my $cap_thorn = $capabilities{"\U$cap\E"};
          $activates .= " $cap_thorn";
      }
      $cfg{"\U$thorn\E ACTIVATES THORNS"} = $activates;
  }

  # Check for cyclic dependencies
  # create a hash with thorn-> used thorns (no prefix)
  foreach my $thorn (sort keys %thorns)
  {
    $thorn_dependencies{uc($thorn)}=$cfg{"\U$thorn\E USES THORNS"};
    $thorn_dependencies{uc($thorn)} =~ s/\b$thorn\b//i;
  }

  my $message = &find_dep_cycles(%thorn_dependencies);
  if ("" ne $message)
  {
    $message =~ s/^\s*//g;
    $message =~ s/\s*$//g;
    $message =~ s/\s+/->/g;
    $message = "Found a cyclic dependency in configuration requirements:$message\n";
    &CST_error(0, $message);
  }

  return \%cfg;
}


#/*@@
#  @routine    CompareVersionStrings
#  @date       Tue Oct 20 23:17:18 2015
#  @author     Frank Loeffler
#  @desc
#  Compares two version strings: first non-numeric prefix lexically, next
#  numeric prefix of remainder numerically, and so on.
#  @enddesc
#@@*/
sub CompareVersionStrings
{ 
  my($v1, $v2) = @_;
  my($nan1, $nan2, $num1, $num2, $ret);
  # the loop body strips recognized parts from the strings
  while($v1 ne "" or $v2 ne "") {
    # compare non-numeric prefix followed by numeric value if they exist
    # remove found sub-string from input
    $v1 =~ s/^([^0-9]*)([0-9]*)(.*)/$3/;
    $nan1 = $1;
    $num1 = $2;
    $v2 =~ s/^([^0-9]*)([0-9]*)(.*)/$3/;
    $nan2 = $1;
    $num2 = $2;
    $ret = ($nan1 cmp $nan2) || ($num1 <=> $num2);
    return $ret if ($ret != 0);
  }
  return 0;
}

#/*@@
#  @routine    CheckForCompatibleVersion
#  @date       Tue Oct 20 23:17:18 2015
#  @author     Frank Loeffler
#  @desc
#  Checks that two versions strings are compatible. The first argument is a raw
#  version string, the second argument has also an operator as prefix, which is
#  used to determine if these two match. Returns 1 for success and 0 for failure.
#  @enddesc
#@@*/
sub CheckForCompatibleVersion
{
  my($v1,$fv2) = @_;
  my($op, $v2, $cmp);
  $fv2 =~ m/(<<|<=|=|>=|>>)(.*)/;
  $op = $1;
  $v2 = $2;
  $cmp = &CompareVersionStrings($v1, $v2);
  return 1 if ($op eq '<<' and $cmp <  0);
  return 1 if ($op eq '<=' and $cmp <= 0);
  return 1 if ($op eq '='  and $cmp == 0);
  return 1 if ($op eq '>=' and $cmp >= 0);
  return 1 if ($op eq '>>' and $cmp >  0);
  return 0;
}

#/*@@
#  @routine    ParseConfigurationCCL
#  @date       Tue Feb  8 19:23:18 2000
#  @author     Tom Goodale
#  @desc
#  Parses a configuration.ccl file and generates a database of the values
#  @enddesc
#@@*/
sub ParseConfigurationCCL
{
  my($config_dir, $thorn, $cfg, $thorns, $filename, $grammar, $rule, $peg_file) = @_;
  my(@data);
  my($line_number, $line);
  my($provides, $script, $lang, $options);
  my($optional, $define, $version);
  my(@req_thorns);
  
  $version = "0.0.1";

  # Initialise some stuff to prevent perl -w from complaining.

  $cfg->{"\U$thorn\E PROVIDES"} = '';
  $cfg->{"\U$thorn\E REQUIRES"} = '';
  $cfg->{"\U$thorn\E USES THORNS"} = '';
  $cfg->{"\U$thorn\E REQUIRES THORNS"} = '';
  $cfg->{"\U$thorn\E OPTIONAL"} = '';
  $cfg->{"\U$thorn\E OPTIONAL_IFACTIVE"} = '';
  $cfg->{"\U$thorn\E ACTIVATES"} = '';
  $cfg->{"\U$thorn\E OPTIONS"}  = '';

  return if not -r $ccl_file;

  my $gr = parse_ccl($grammar,$rule,$ccl_file,$peg_file);

  for my $node (@{$gr->{children}}) {
    if($node->is("requires")) {
      for my $ch (@{$node->{children}}) {
        if($ch->is("name_with_ver")) {
          my $rname = $ch->group(0,"name")->substring();
          my $key = "\U$thorn\E REQUIRES";
          $cfg->{$key} .= $rname." ";
          if($ch->has(1,"vop") and $ch->has(2,"vname")) {
            $version = $ch->group(1)->substring() . $ch->group(2)->substring();
            $cfg->{"\U$thorn REQUIRES $rname VERSION\E"} = $version;
          }
        } elsif($ch->is("name")) {
          my $rname = $ch->substring();
          my $key = "\U$thorn\E REQUIRES";
          $cfg->{$key} .= $rname." ";
        } elsif($ch->is("thorns")) {
          for my $n (@{$ch->{children}}) {
            my $key = "\U$thorn\E REQUIRES THORNS";
            $cfg->{$key} .= $n->substring()." ";
            push @req_thorns, $n->substring();
          }
        }
      }
    } elsif($node->is("provopt")) {
      my $key = uc($node->group(0,"key")->substring());
      my $name = $node->group(1,"name")->substring();
      if($key eq "PROVIDES") {
        $cfg->{"\U$thorn PROVIDES $name OPTIONS"}=[];
        for my $ch (@{$node->{children}}) {
          if($ch->is("name")) {
            my $pname = $ch->substring();
            my $key = "\U$thorn\E PROVIDES";
            $cfg->{$key} .= $pname." ";
          } elsif($ch->is("version") and $ch->has(0)) {
            $version = $ch->group(0,"vname")->substring();
          } elsif($ch->is("lang") and $ch->has(0)) {
            my $key = "\U$thorn PROVIDES $name LANG";
            $cfg->{$key} = $ch->group(0,"name")->substring();
          } elsif($ch->is("script") and $ch->has(0)) {
            my $key = "\U$thorn PROVIDES $name SCRIPT";
            $cfg->{$key} = $thorns->{$thorn}."/".$ch->group(0,"pname")->substring();
          } elsif($ch->is("options")) {
            my $key= "\U$thorn PROVIDES $name OPTIONS";
            my $ropts = [];
            $ropts = $cfg->{$key} if(defined($cfg->{$key}));
            my @opts = @{$cfg->{$key}};
            for my $n (@{$ch->{children}}) {
              push @opts, $n->substring();
            }
            $cfg->{$key} = \@opts;
          }
        }
        $cfg->{"\U$thorn PROVIDES $name VERSION\E"} = $version;
      } elsif($key eq "OPTIONAL" or $key eq "OPTIONAL_IFACTIVE") {
        for my $ch (@{$node->{children}}) {
          if($ch->is("name")) {
            my $pname = $ch->substring();
            my $key = "\U$thorn\E $key";
            $cfg->{$key} .= $pname." ";
          }
        }
      }
    }
  }
  $cfg->{"\U$thorn\E REQUIRES THORNS"} = join(" ",sort @req_thorns);
}

#/*@@
#  @routine    ParseProvidesBlock
#  @date       Mon May  8 15:52:40 2000
#  @author     Tom Goodale
#  @desc
#  Parses the PROVIDES block in a configuration.ccl file.
#  @enddesc
#@@*/
sub ParseProvidesBlock
{
  my ($line_number, $data) = @_;
  my ($provides, $script, $lang, $options, $version);

  $provides = "";
  $script   = "";
  $lang     = "";
  $version  = "0.0.1";
  $options  = [];

  $data->[$line_number] =~ m/^\s*PROVIDES\s*(.*)/i;

  $provides = $1;

  $line_number++;
  if($data->[$line_number] !~ m/^\s*\{\s*$/)
  {
    &CST_error (0, "Error parsing provides block line '$data->[$line_number]' $ccl_file:$line_number ".
                   'Missing { at start of block');
    $line_number++ while(defined($data->[$line_number]) and $data->[$line_number] !~ m:\s*\}\s*:);
  }
  else
  {
    while(defined($data->[$line_number]) and $data->[$line_number] !~ m:\s*\}\s*:)
    {
      $line_number++;
      if($data->[$line_number] =~ m/^\s*SCRIPT\s*(.*)$/i)
      {
        $script = $1;
        next;
      }
      elsif($data->[$line_number] =~ m/^\s*LANG[^\s]*\s*(.*)$/i)
      {
        $lang = $1;
        next;
      }
      elsif($data->[$line_number] =~ m/^\s*OPTIONS[^\s]*\s*(.*)$/i)
      {
        push(@$options, split(' ',$1));
        next;
      }
      elsif($data->[$line_number] =~ m/^\s*VERSION\s+(.+)$/i)
      {
        $version = $1;
        if ($1 !~ m/[0-9]([0-9a-z.+-:]*)/i)
        {
          print STDERR "Error in version specification '"+$version+"'. "+
                       "Only alphanumeric characters and . + - : are allowed, "+
                       "and a version has to start with a digit.";
          &CST_error (0, 'Unrecognised version');
        }
        next;
      }
      elsif($data->[$line_number] =~ m:\s*\}\s*:)
      {
        # do nothing.
      }
      else
      {
        print STDERR "Error parsing provides block line '$data->[$line_number]'\n";
        &CST_error (0, 'Unrecognised statement');
      }
    }
  }

  return ($provides, $script, $lang, $options, $line_number, $version);
}


#/*@@
#  @routine    ParseOptionalBlock
#  @date       Mon May  8 15:52:40 2000
#  @author     Tom Goodale
#  @desc
#  Parses the OPTIONAL or OPTIONAL_IFACTIVE block in a configuration.ccl file.
#  @enddesc
#@@*/
sub ParseOptionalBlock
{
  my ($file_name, $line_number, $data) = @_;
  my ($optional, $define);

  $data->[$line_number] =~ m/^\s*OPTIONAL(_IFACTIVE)?\s*(.*)/i;

  $optional = $2;

  $define = "";

  $line_number++;

  if($data->[$line_number] !~ m/^\s*\{\s*$/)
  {
    &CST_error (0, "Error parsing optional block line '$data->[$line_number]' $file_name:$line_number".
                ' Missing { at start of block.');
    $line_number++ while(defined($data->[$line_number]) and $data->[$line_number] !~ m:\s*\}\s*:);
  }
  else
  {
    while(defined($data->[$line_number]) and $data->[$line_number] !~ m:\s*\}\s*:)
    {
      $line_number++;
      if($data->[$line_number] =~ m/^\s*DEFINE\s*(.*)$/i)
      {
        if($define eq "")
        {
          $define = $1;
          next;
        }
        else
        {
          &CST_error (0, "Error parsing optional block line '$data->[$line_number]' " . 'Only one define allowed.');
        }
      }
      elsif($data->[$line_number] =~ m:\s*\}\s*:)
      {
        # do nothing.
      }
      else
      {
        &CST_error (0, "Error parsing provides block line '$data->[$line_number]' " . 'Unrecognised statement.');
      }
    }
  }

  return ($optional, $define, $line_number);
}

1;
