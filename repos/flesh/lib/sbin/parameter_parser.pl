#! /usr/bin/perl -w
#/*@@
#  @file      parameter_parser.pl
#  @date      Mon 25 May 08:07:40 1998
#  @author    Tom Goodale
#  @desc
#  Parser for param.ccl files
#  @enddesc
#  @version $Header$
#@@*/

#%implementations = ("flesh", "flesh", "test1", "test1", "test2", "test2");

#%parameter_database = create_parameter_database(%implementations);
use strict;
use warnings;
use FindBin;
use Carp;
use Piraha;
my $ccl_file;

#/*@@
#  @routine    create_parameter_database
#  @date       Wed Sep 16 11:45:18 1998
#  @author     Tom Goodale
#  @desc
#  Creates a database of all the parameters
#  @enddesc
#@@*/

sub create_parameter_database
{
  my(%thorns) = @_;
  my($thorn, @indata);
  my(@new_parameter_data);
  my(@parameter_data);

  my $peg_file = "$FindBin::Bin/../../src/piraha/pegs/param.peg";
  my ($grammar,$rule) = piraha::parse_peg_file($peg_file);

  # Loop through each implementation's parameter file.
  foreach $thorn (sort keys %thorns)
  {
    print "   $thorn\n";
    #       Read the data
    $ccl_file = "$thorns{$thorn}/param.ccl";
    my $gr = parse_ccl($grammar,$rule,$ccl_file,$peg_file);

    # Get the parameters from it
    @new_parameter_data = &parse_param_ccl($thorn, $gr);

    &PrintParameterStatistics($thorn, @new_parameter_data);

    # Add the parameters to the master parameter database
    push (@parameter_data, @new_parameter_data);
  }

  @parameter_data = &cross_index_parameters(scalar(keys %thorns), (sort keys %thorns), @parameter_data);

  if (defined($ENV{VERBOSE}) and lc($ENV{VERBOSE}) eq "yes") {
    print "\n";
    print "+========================+\n";
    print "| Param Parsing Complete |\n";
    print "+========================+\n";
  }

  return @parameter_data;
}

sub cross_index_parameters
{
  my($n_thorns, @indata) = @_;
  my(@thorns);
  my(%parameter_database);
  my(@module_file);
  my($line);
  my(@data);
  my($thorn);
  my(%public_parameters);

  @thorns = @indata[0..$n_thorns-1];
  %parameter_database = @indata[$n_thorns..$#indata];

  $parameter_database{"GLOBAL PARAMETERS"} = "";

  foreach $thorn (@thorns)
  {
    foreach my $parameter (split(/ /, $parameter_database{"\U$thorn\E GLOBAL variables"}))
    {
      if($public_parameters{"\U$parameter\E"})
      {
        &CST_error(0, "Duplicate public parameter $parameter, defined in " .
                      "$thorn and " . $public_parameters{"\Uparameter\E"},
                   '', __LINE__, __FILE__);
      }
      else
      {
        $public_parameters{"\Uparameter\E"} = "$thorn";
        $parameter_database{"GLOBAL PARAMETERS"} .= "$thorn\::$parameter ";
      }
    }
  }

  return %parameter_database;
}

#/*@@
#  @routine    parse_param_ccl
#  @date       Wed Sep 16 11:55:33 1998
#  @author     Tom Goodale
#  @desc
#  Parses a param.ccl file and generates a database of the values.
#  @enddesc
#@@*/

sub parse_param_ccl
{
  my($thorn, $group) = @_;
  my($line_number, $line, $block, $type, $variable, $description);
  my($current_friend, $new_ranges, $new_desc);
  my(%parameter_db);
  my(%friends);
  my(%defined_parameters);
  my($use_or_extend, $use_clause, $skip_range_block);
  my($message);
  my($share);
  my(%shares_implementations);

  #   The default block is private.
  $block = 'PRIVATE';


  $parameter_db{"\U$thorn PRIVATE\E variables"} = '';
  $parameter_db{"\U$thorn RESTRICTED\E variables"} = '';
  $parameter_db{"\U$thorn GLOBAL\E variables"} = '';

  for my $gr (@{$group->{children}}) {
    if($gr->{name} eq "access") {
      if($gr->has(0,"access_spec")) {
        $block = uc($gr->group(0)->substring());
      }
      if($gr->{children}->[0]->{name} eq "share") {
        $share = uc $gr->group(0,"share")->group(0,"name")->substring();
        $parameter_db{"\U$thorn SHARES\E $share variables"} .= "";
        $shares_implementations{$share} = 1;
      }
    } else {
      my $uses_or_extends = "";
      my $n=0;
      if($gr->has(0,"uses_or_extends")) {
        $uses_or_extends = lc($gr->group(0)->substring());
        $n=1;
      }
      my $guts = $gr->group($n);
      my $name_num = $guts->group(0,"name_num");
      my $name = $name_num->group(0,"name")->substring();
      my $as_name = $name;
      my $num;
      if($name_num->has(1)) {
        $num = $name_num->group(1,"num")->substring();
        $parameter_db{"\U$thorn $as_name\E array_size"} = $num;
      }
      my $gutpars;
      if($guts->has(2,"gutpars")) {
        $gutpars = $guts->group(2);
      } else {
        $gutpars = $guts->group(1,"gutpars");
      }
      my %keys = ();
      for my $child (@{$gutpars->{children}}) {
        my $cname = $child->{name};
        if($cname eq "as") {
          my $val = $child->group(0,"name")->substring();
          $as_name = $val;
        }
      }
      if(defined($parameter_db{"\U$thorn $as_name\E realname"})) {
        &CST_error(1, "Duplicate parameter $as_name in thorn $thorn. " .
                   "Ignoring second definition", '',$name_num->linenum(), $ccl_file);
        next;
      }
      for my $child (@{$gutpars->{children}}) {
        my $cname = $child->{name};
        $keys{$cname}++;
        if($cname eq "steerable") {
          my $val = $child->substring();
          $parameter_db{"\U$thorn $as_name\E steerable"}=$val;
        } elsif($cname eq "accumexpr") {
          my $val = $child->substring();
          $parameter_db{"\U$thorn $as_name\E accumulator-expression"}=$val;
        } elsif($cname eq "accname") {
          my $val = $child->substring();
          $parameter_db{"\U$thorn $as_name\E accumulator-base"}=$val;
        }
      }
      my $desc = $guts->group(1,"description")->substring();
      $desc =~ s/\\\n//g;
      if($desc eq "" and $uses_or_extends eq "") {

          my $hint = "Each parameter definition must have " .
            "the syntax <TYPE> <NAME> <\"DESCRIPTION\">";

          &CST_error(0, "Missing description for parameter $name " .
                        "param.ccl for thorn $thorn",
                     $hint, $guts->linenum(), $ccl_file);
      }
      if($gr->is("keywordpar")) {
        $parameter_db{"\U$thorn $as_name\E type"}="KEYWORD";
        my $item_count = 1;
        my @items = ();
        for(my $i=0;$i < $gr->groupCount();$i++) {
          my $item = $gr->group($i);
          if($item->{name} eq "keywordset") {
            my $item_desc = "";
            my $end = $item->groupCount()-1;
            if($item->has($end,"quote"))
            {
              $item_desc = $item->group($end)->substring();
              $item_desc =~ s/\\\n//g;
              $end--;
            }
            for(my $i=0;$i<=$end;$i++) {
              $parameter_db{"\U$thorn $as_name\E range $item_count description"} = $item_desc;
              $parameter_db{"\U$thorn $as_name\E range $item_count range"} = trim_quotes($item->group($i)->substring());
              $item_count++;
            }
          }
        }
        $parameter_db{"\U$thorn $as_name\E ranges"} = $item_count-1;
      } elsif($gr->is("intpar")) {
        my $item_count = 1;
        my @items = ();
        for(my $i=$n+1;$i < $gr->groupCount()-1;$i++) {
          my $item = $gr->group($i);
          if($item->is("intset")) {
            my $item_desc = "";
            $item_desc = $item->group(1)->substring()
              if($item->has(1,"quote"));
            $item_desc =~ s/\\\n//g;
            $parameter_db{"\U$thorn $as_name\E range $item_count description"} = $item_desc;
            my $intrange = $item->group(0,"intrange");
            my $intrange_str = "";
            if($intrange->has(0,"intbound")) {
              $intrange_str = $intrange->group(0)->substring();
            } else {
              $intrange_str = $intrange->group(0,"lbound")->substring();
              $intrange_str .= $intrange->group(1,"intbound")->substring();
              $intrange_str .= ":";
              $intrange_str .= $intrange->group(2,"intbound")->substring();
              if($intrange->has(3,"rbound")) {
                $intrange_str .= $intrange->group(3,"rbound")->substring();
              } else {
                $intrange_str .= ":".$intrange->group(3,"intbound")->substring();
              }
            }
            $parameter_db{"\U$thorn $as_name\E range $item_count range"} = $intrange_str;
            $item_count++;
          }
        }
        $parameter_db{"\U$thorn $as_name\E ranges"} = $item_count-1;
        $parameter_db{"\U$thorn $as_name\E type"} = "INT";
      } elsif($gr->is("realpar")) {
        my $item_count = 1;
        my @items = ();
        # Parses the realpar element
        for(my $i=$n+1;$i < $gr->groupCount()-1;$i++) {
          my $item = $gr->group($i);
          if($item->is("realset")) {
            my $item_desc = "";
            $item_desc = $item->group(1)->substring()
              if(defined($item->has(1,"quote")));
            $item_desc =~ s/\\\n//g;
            $parameter_db{"\U$thorn $as_name\E range $item_count description"} = $item_desc;
            my $realrange = $item->group(0,"realrange");
            my $realrange_str = "";
            if($realrange->has(0,"realbound")) {
              $realrange_str .= $realrange->group(0)->substring();
            } else {
              $realrange_str = $realrange->group(0,"lbound")->substring();
              $realrange_str .= $realrange->group(1,"realbound")->substring();
              $realrange_str .= ":";
              $realrange_str .= $realrange->group(2,"realbound")->substring();
              $realrange_str .= $realrange->group(3,"rbound")->substring();
            }
            $parameter_db{"\U$thorn $as_name\E range $item_count range"} = $realrange_str;
            $item_count++;
          }
        }
        $parameter_db{"\U$thorn $as_name\E ranges"} = $item_count-1;
        $parameter_db{"\U$thorn $as_name\E type"} = "REAL";
      } elsif($gr->is("stringpar")) {
        $parameter_db{"\U$thorn $as_name\E type"}="STRING";
        $parameter_db{"\U$thorn $as_name\E ranges"}=0;
        my $item_count = 1;
        my @items = ();
        for(my $i=$n+1;$i < $gr->groupCount()-1;$i++) {
          my $item = $gr->group($i);
          if($item->is("stringset")) {
            my $item_desc = "";
            my $end = $item->groupCount()-1;
            if($item->has($end,"quote")) {
              $item_desc = $item->group($end)->substring();
              $item_desc =~ s/\\\n//g;
              $end--;
            }
            for(my $i=0;$i<=$end;$i++) {
              $parameter_db{"\U$thorn $as_name\E range $item_count description"} = $item_desc;
              my $range = $item->group($i)->group(0);
              confess "Bad range '".$range->{name}."'"
                unless($range->is("quote") or $range->is("char_seq"));
              $parameter_db{"\U$thorn $as_name\E range $item_count range"} =
                trim_quotes($range->substring());
              $parameter_db{"\U$thorn $as_name\E ranges"}++;
              $item_count++;
            }
          }
        }
        $parameter_db{"\U$thorn $as_name\E ranges"}=$item_count-1;
      } elsif($gr->{name} eq "boolpar") {
        $parameter_db{"\U$thorn $as_name\E ranges"} = 0;
        $parameter_db{"\U$thorn $as_name\E type"} = "BOOLEAN";
        my @children = @{$gr->{children}};
        my $item_count = 1;
        my @items = ();
        for(my $i=$n+1;$i < $#children;$i++) {
          my $item = $gr->{children}->[$i];
          if($item->{name} eq "boolset") {
            my $item_desc = "";
            $item_desc = $item->{children}->[1]->substring()
              if(defined($item->{children}->[1]));
            $item_desc =~ s/\\\n//g;
            $parameter_db{"\U$thorn $as_name\E range $item_count description"} = $item_desc;
            my $bool = trim_quotes($item->group(0,"bool")->substring());
            $parameter_db{"\U$thorn $as_name\E range $item_count range"} = $bool;
            $item_count++;
          }
        }
        $parameter_db{"\U$thorn $as_name\E ranges"} = $item_count-1;
      }
      $parameter_db{"\U$thorn $as_name\E realname"} = $name;
      if($uses_or_extends eq "uses") {
        confess("share not set") if("$share" eq "");
        $parameter_db{"\U$thorn SHARES $share\E variables"} .= $as_name . " ";
      } elsif($uses_or_extends eq "extends") {
        confess("share not set") if("$share" eq "");
        $parameter_db{"\U$thorn SHARES $share\E variables"} .= $as_name . " ";
      } elsif($uses_or_extends eq "") {
        $parameter_db{"\U$thorn $block\E variables"} .= $as_name." ";
        my @children = @{$gr->{children}};
        my $default = trim_quotes($children[$#children]->substring());
        $default =~ s/\\\n//g;
        $parameter_db{"\U$thorn $as_name\E default"} = $default;
      }
      $parameter_db{"\U$thorn $as_name\E description"} = $desc;
    }
  }
  $parameter_db{"\U$thorn SHARES\E implementations"} = 
    join(" ",sort keys %shares_implementations);

  return %parameter_db;
}

#/*@@
#  @routine    PrintParameterStatistics
#  @date       Sun Sep 19 13:04:18 1999
#  @author     Tom Goodale
#  @desc
#  Prints out some statistics about a thorn's param.ccl
#  @enddesc
#@@*/
sub PrintParameterStatistics
{
  my($thorn, %parameter_database) = @_;
  my($block);
  my($sep);

  if($parameter_database{"\U$thorn SHARES\E implementations"} ne "")
  {
    print "           Shares: " . $parameter_database{"\U$thorn SHARES\E implementations"} . "\n";
  }

  $sep = "          ";
  foreach $block ("Global", "Restricted", "Private")
  {
    my @vars = split(/ /, $parameter_database{"\U$thorn $block\E variables"});
    print $sep . scalar(@vars) . " $block";
    $sep = ", ";
  }

  print " parameters\n";
}


#/*@@
#  @routine    CheckParameterDefault
#  @date       Sun Dec 17 18.20
#  @author     Gabrielle Allen
#  @desc
#  Check default in allowed range
#  @enddesc
#@@*/

sub CheckParameterDefault
{
  my($thorn,$variable,$default,%parameter_db) = @_;
  my($foundit,$i,$range);

  $foundit = 0;

  # Check that boolean default is correct
  if ($parameter_db{"\U$thorn $variable\E type"} =~ /BOOLEAN/)
  {
    if ($default !~ m:^yes|no|y|n|1|0|t|f|true|false$:i)
    {
      &CST_error(0, "Default ($default) for boolean parameter '$variable' " .
                    "is incorrect in param.ccl for thorn $thorn",
                 "The default value for a boolean parameter must be one of " .
                    "yes,no,y,n,1,0,t,f,true,false",
                 __LINE__, __FILE__);
    }
  }
  elsif ($parameter_db{"\U$thorn $variable\E type"} =~ /KEYWORD/)
  {
    my $nranges=$parameter_db{"\U$thorn $variable\E ranges"};
    for ($i=1; $i<=$nranges; $i++)
    {
      # Keywords don't use pattern matching but are case insensitive
      $range = $parameter_db{"\U$thorn $variable\E range $i range"};
      $foundit = 1 if ("\U$default\E" eq "\U$range\E");
    }
    if ($foundit == 0)
    {
      &CST_error(0, "Default ($default) for keyword parameter '$variable' " .
                    "is incorrect in param.ccl for thorn $thorn",
                 "The default value for a parameter must lie within the " .
                    "allowed range",
                 __LINE__, __FILE__);
    }
  }
  elsif ($parameter_db{"\U$thorn $variable\E type"} =~ /STRING/)
  {
    my $nranges=$parameter_db{"\U$thorn $variable\E ranges"};
    for ($i=1; $i<=$nranges; $i++)
    {
      $range = $parameter_db{"\U$thorn $variable\E range $i range"};
      eval { "" =~ m:$range:i; };
      if ($@)
      {
        &CST_error(0, "Invalid regular expression '$range' for string " .
                      "parameter '$variable': $@",
                   __LINE__, __FILE__);
      }

      # An empty regular expression should match everything.
      # Instead, perl returns the result of the last match.
      # Therefore, prevent using empty patterns.
      $foundit = 1 if ($range eq '' || $default =~ m:$range:i);
    }
    if ($foundit == 0)
    {
      &CST_error(0, "Default ($default) for string parameter '$variable' " .
                    "is incorrect in param.ccl for thorn $thorn",
                 "The default value for a parameter must lie within an " .
                    "allowed range",
                 __LINE__, __FILE__);
    }
  }
  elsif ($parameter_db{"\U$thorn $variable\E type"} =~ /INT/)
  {
    my $nranges=$parameter_db{"\U$thorn $variable\E ranges"};
    for (my $i=1; $i<=$nranges; $i++)
    {
      $range = $parameter_db{"\U$thorn $variable\E range $i range"};
      $range =~ /^([\(]?)([\s\*0-9]*):([\s\*0-9]*)([\)]?)/;
      my $lower_bounds_excluded = $1 eq '(';
      my $min = $2;
      my $max = $3;
      my $upper_bounds_excluded = $4 eq ')';
      $foundit = 1 if ($min =~ /^\s*[\*\s]*\s*$/ or
                       ($lower_bounds_excluded ? $default >  $min :
                                                 $default >= $min))
                      and
                      ($max =~ /^\s*[\*\s]*\s*$/ or
                       ($upper_bounds_excluded ? $default <  $max :
                                                 $default <= $max));
    }
    if ($nranges > 0 && $foundit == 0)
    {
      &CST_error(0, "Default ($default) for integer parameter '$variable' " .
                    "is incorrect in param.ccl for thorn $thorn",
                 "The default value for a parameter must lie within the " .
                    "allowed range",
                 __LINE__, __FILE__);
    }
  }
  elsif ($parameter_db{"\U$thorn $variable\E type"} =~ /REAL/)
  {
    my $nranges=$parameter_db{"\U$thorn $variable\E ranges"};
    for (my $i=1; $i<=$nranges; $i++)
    {
      $range = $parameter_db{"\U$thorn $variable\E range $i range"};
      $range =~ /^([\(]?)([\s\*0-9\.eE+-]*):([\s\*0-9\.eE+-]*)([\)]?)/;
      my $lower_bounds_excluded = $1 eq '(';
      my $min = $2;
      my $max = $3;
      my $upper_bounds_excluded = $4 eq ')';
      $foundit = 1 if ($min =~ /^\s*[\*\s]*\s*$/ or
                       ($lower_bounds_excluded ? $default >  $min :
                                                 $default >= $min))
                      and
                      ($max =~ /^\s*[\*\s]*\s*$/ or
                       ($upper_bounds_excluded ? $default <  $max :
                                                 $default <= $max));
    }
    if ($nranges > 0 && $foundit == 0)
    {
      &CST_error(0, "Default ($default) for real parameter '$variable' " .
                    "is incorrect in param.ccl for thorn $thorn",
                 "The default value for a parameter must lie within the " .
                    "allowed range",
                 __LINE__, __FILE__);
    }
  }
}

#/*@@
#  @routine    CheckExpression
#  @date       Fri May 17 21:26:52 2002
#  @author     Tom Goodale
#  @desc
#  Checks that an accumulator parameter's expression is valid.
#  The expression should commute when applied twice
#  I.e. if a is the original value of the parameter,
#          b the first value to add
#          c the second parameter to add
#      and L(x,y) the operation
#  The expression
#      L(L(a,b),c) = L(L(a,c),b)
#  should be true.
#  @enddesc
#
#  @var     expression
#  @vdesc   The expression to verify
#  @vtype   string
#  @vio     in
#  @endvar
#
#  @returntype int
#  @returndesc
#  0 -- success
#  1 -- expression contains invalid characters
#  2 -- expression could not be evaluated
#  3 -- expression can produce infinite result
#  4 -- expression does not commute
#  @endreturndesc
#@@*/
sub CheckExpression
{
  my ($expression) = @_;
  my $retcode;
  my $retval;

  # Don't limit accumulators to x and y
  if($expression =~ m,^[-\d/*()+a-z^!<>=:?]+$, &&
     $expression =~ m/\bx\b/            &&
     $expression =~ m/\by\b/            &&
     $expression !~ m/\wx/              &&
     $expression !~ m/x\w/              &&
     $expression !~ m/\wy/              &&
     $expression !~ m/y\w/)
  {

    # Pick some numbers to do the test with.
    my $a = 37;
    my $b = 53;
    my $c = 59;

    # Convert to Perl's exponentiation operator syntax.
    $expression =~ s/\^/**/;

    # Convert x and y to Perl variables.
    $expression =~ s/x/\$x/g;
    $expression =~ s/y/\$y/g;

    # Calculate L(L(a,b),c).
    my $answer1 = &EvalExpression(&EvalExpression($a,$b,"$expression"),$c,$expression);

#    print "$answer1\n" if defined $answer1;

    # Calculate L(L(a,c),b).
    my $answer2 = &EvalExpression(&EvalExpression($a,$c,"$expression"),$b,$expression);

#    print "$answer2\n" if defined $answer2;

    if( !defined $answer1 || ! defined $answer2)
    {
      $retval = 2;
    }
    elsif($answer1 eq "inf" || $answer2 eq "inf")
    {
      $retval = 3;
    }
    elsif(abs($answer1 - $answer2) > 1.0e-17)
    {
      $retval = 4;
    }
    else # if($answer1 == $answer2)
    {
      $retval = 0;
    }
  }
  else
  {
    $retval = 1;
  }

  return $retval;
}


#/*@@
#  @routine    EvalExpression
#  @date       Fri May 17 21:34:18 2002
#  @author     Tom Goodale
#  @desc
#  Takes an expression involving $x and $y
#  and evaluates it.
#  @enddesc
#
#  @var     x
#  @vdesc   An argument in the expression
#  @vtype   scalar
#  @vio     in
#  @endvar
#  @var     y
#  @vdesc   An argument in the expression
#  @vtype   scalar
#  @vio     in
#  @endvar
#  @var     expression
#  @vdesc   The expression to evaluate
#  @vtype   string
#  @vio     in
#  @endvar
#
#  @returntype scalar
#  @returndesc
#    The value of the evaluation.
#  @endreturndesc
#@@*/
sub EvalExpression
{
  my ($x, $y, $expression) = @_;

  my $answer = eval "$expression";

  return $answer;
}


1;
