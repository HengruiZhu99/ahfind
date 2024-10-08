#/*@@
#  @file      CSTUtils.pl
#  @date      4 July 1999
#  @author    Gabrielle Allen
#  @desc 
#  Various utility routines.
#  @enddesc
#  @version $Header$ 
#@@*/

use strict;
use warnings;
use Carp;
use File::stat;
use File::Path qw{ mkpath };

#############################################################################
###### Package variables ####################################################
#############################################################################

#/*@@
#  @routine   CST_error
#  @date      4 July 1999
#  @author    Gabrielle Allen
#  @desc 
#  Print an error or warning message
#  @enddesc 
#@@*/

sub CST_error
{
    my($level,$mess,$help,$line,$file) = @_;
    my($error);
    our($CST_errors, $error_string);

    my $full_warnings = 1 if(defined($line) or defined($file));

    $line = '' unless defined($line);
    $file = '' unless defined($file);

    if (not defined($help))
    {
      $help = '';
    }
    elsif ($help !~ /^\s*$/)
    {
      $help = "     HINT: $help\n";
    }

    if ($full_warnings)
    {
        if ($level == 0)
        {
            $CST_errors++;
            $error = "\nCST error in $file (at $line)\n  -> $mess\n";
            print STDERR "$error\n";
            $error_string .= "$error$help\n";
        }
        else
        {
            $error = "\nCST warning in $file (at $line)\n  -> $mess\n";
            print STDERR "$error\n";
            $error_string .= "$error$help\n";
        }
    }
    else
    {
        if ($level == 0)
        {
            $CST_errors++;
            $error = "\nCST error $CST_errors:\n  -> $mess\n";
            print STDERR "$error\n";
            $error_string .= "$error$help\n";
        }
        else
        {
            $error = "\nCST warning:\n  -> $mess\n";
            print STDERR "$error\n";
            $error_string .= "$error$help\n";
        }           
    }

    return;
}


#/*@@
#  @routine   CST_PrintErrors
#  @date      5 December 1999
#  @author    Gabrielle Allen
#  @desc 
#  Print all the errors and warnings from the CST
#  @enddesc 
#  @version $Id$
#@@*/

sub CST_PrintErrors
{
  our ($error_string);
  if($error_string)
  {
    print "\n\n------------------------------------------------------\n";
    print "Warnings were generated during execution of the CST\n";
    print "------------------------------------------------------\n\n";
    print "$error_string";
    print "------------------------------------------------------\n\n";
  }
}


#/*@@
#  @routine    read_file
#  @date       Wed Sep 16 11:54:38 1998
#  @author     Tom Goodale
#  @desc 
#  Reads a file deleting comments and blank lines. 
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#  @hdate Fri Sep 10 10:25:47 1999 @hauthor Tom Goodale
#  @hdesc Allows a \ to escape the end of a line. 
#  @endhistory 
#@@*/

sub read_file
{
  my($file) = @_;
  my(@indata);
  my($line);

  open(IN, "<$file") || die("Can't open $file\n");
  
  $line = "";

  while(<IN>)
  {
    chomp;

    # Add to the currently processed line.
    $line .= $_;

    # Check if this line will be continued
    if($line =~ m:[^\\]\\$:)
    {
      $line =~ s:\\$::;
      next;
    }
      
    # Remove comments.
    $line = &RemoveComments($line, $file);
    
    # Ignore empty lines.
    if($line !~ m/^\s*$/)
    {
      push(@indata, $line);
    }
 
    $line = "";
  }
  
  # Make sure to dump out the last line, even if it ends in a \
  if($line ne "")
  {
    push(@indata, $line);
  }

  close IN;
  
  return @indata;
}

#/*@@
#  @routine    WriteFile
#  @date       Tue Oct 19 21:09:12 CEST 1999 
#  @author     Gabrielle Allen
#  @desc 
#  Writes a file only if the contents haven't changed
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
# 
#  @endhistory 
#@@*/

sub WriteFile
{
  my ($filename,$rdata) = @_;
  my ($data_in);

# Strip any matching quotes from filename
  $filename =~ s/^\s*\"(.*)\"\s*$/$1/;
  $filename =~ s/^\s*\'(.*)\'\s*$/$1/;

# Set this to an illegal value,
# so that the comparison later is guaranteed to fail if this is not changed
  $data_in = undef;

# Read in file
  if (-e $filename) 
  {
    # only read the file if it its size equals the length of the rdata string
    my $filesize = -s $filename;
    if ($filesize == length ($$rdata))
    {
      open(IN, "< $filename");
      $data_in = join ('', <IN>);
      close IN;
    }
  }

  if (not defined $data_in or $$rdata ne $data_in)
  {
#    print "Creating new file $filename\n";
    open(OUT, ">$filename") || die("Can't open $filename\n");
    print OUT $$rdata;
    close OUT;
  }

}

#/*@@
#  @routine    TestName
#  @date       Sat Dec 16 1.48
#  @author     Gabrielle Allen
#  @desc 
#  Check thorn/arrangement name is valid
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#@@*/

sub TestName
{
  my($thorn,$name) = @_;
  my($valid);

  $valid = 1;

  if (!$name)
  {
    $valid = 0;
  }
  elsif ($name !~ /^[a-zA-Z]/)
  {
    print STDERR "Name must begin with a letter!\n\n";
    $valid = 0;
  }
  elsif ($name !~ /^[a-zA-Z0-9_]*$/)
  {
    print STDERR "Name can only contain letters, numbers or underscores!\n\n";
    $valid = 0;
  }

  if ($thorn && length($name)>27)
  {
    print STDERR "Thorn names must be 27 characters or less!\n\n";
    $valid = 0;
  }

  if ($thorn && $name eq "doc")
  {
    print STDERR "Thorn name doc is not allowed!\n\n";
    $valid = 0;
  }

  return $valid;
}

#/*@@
#  @routine    SplitWithStrings
#  @date       Tue May 21 23:45:54 2002
#  @author     Tom Goodale
#  @desc 
#  Splits a string on spaces and = ignoring
#  any occurence of these in strings.
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#
#  @var     expression
#  @vdesc   Expression to split
#  @vtype   string
#  @vio     in
#  @endvar 
#
#  @returntype list
#  @returndesc
#    Split representation of input expression.
#  @endreturndesc
#@@*/
sub SplitWithStrings
{
  my ($expression, $thorn) = @_;

  my $insstring = 0;
  my $indstring = 0;
  my $escaping = 0;

  my @tokens = ();

  my $token="";

  # First split the string into string tokens and split tokens we are
  # allowed to split.

  for my $i (split(//,$expression))
  {
    if($i eq '\\')
    {
      if($escaping)
      {
        $token .= $i;
      }
      
      $escaping = 1 - $escaping;
    }
    elsif($i eq '"' && ! $insstring && ! $escaping)
    {
      if(length $token > 0 || $indstring)
      {
        push(@tokens, $token);
      }

      $token = "";
      $indstring = 1 - $indstring;
    }
    elsif($i eq "'" && ! $indstring && ! $escaping)
    {
      if(length $token > 0 || $insstring)
      {
        push(@tokens, $token);
      }

      $token = "";

      $insstring = 1 - $insstring;
    }
    elsif($i =~ /^\s+$/ && ! $insstring && ! $indstring && ! $escaping)
    {
      if(length $token > 0 || $insstring)
      {
        push(@tokens, $token);
      }

      $token = "";
    }
    elsif($i eq '=' && ! $insstring && ! $indstring && ! $escaping)
    {
      if(length $token > 0 || $insstring)
      {
        push(@tokens, $token);
      }

      $token = "";
    }
    else
    {
      if($escaping)
      {
        $token .= "\\";
        $escaping = 0; 
      }
      $token .= "$i";
    }
  }

  if($insstring || $indstring)
  {
    print "Error: Unterminated string while parsing interface for thorn : $thorn\n"
  }

  if($escaping)
  {
    $token .= '\\';
  }
  
  if(length $token > 0)
  {
    push(@tokens, $token);
  }
  
  return @tokens;

}

#/*@@
#  @routine    trim_quotes
#  @date
#  @author     Steven Brandt
#  @desc
#  Remove single or double quotes surrounding a string
#  @enddesc
#  @calls
#  @calledby
#  @history
#
#  @endhistory
#
#  @var     line
#  @vdesc   line to remove quotes from
#  @vtype   string
#  @vio     in
#  @endvar
#
#  @returntype line
#  @returndesc
#    line without quotes
#  @endreturndesc
#@@*/
sub trim_quotes
{
  my $str = shift;
  $str =~ s/^(["'])(.*)\1$/$2/s;
  return $str;
}

#/*@@
#  @routine    RemoveComments
#  @date       
#  @author     Tom Goodale, Yaakoub El Khamra
#  @desc 
#  Removes comments from lines
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#
#  @var     line
#  @vdesc   line to remove comments from
#  @vtype   string
#  @vio     in
#  @endvar 
#
#  @returntype line
#  @returndesc
#    line without comments
#  @endreturndesc
#@@*/
sub RemoveComments
{
  my ($line, $filename) = @_;
  my $nocomment = $line;
  my $insstring = 0;
  my $indstring = 0;
  my $escaping = 0;
  my $token="";

  die "Incorrect number of parameters : " . scalar @_ if scalar @_ != 2;

  for my $i (split(//,$line))
  {

    if($i eq '\\')
    {
      if($escaping)
      {
        $token .= $i;
      }
      
      $escaping = 1 - $escaping;
    }
    elsif($i eq '"' && ! $insstring && ! $escaping)
    {
      $token = "";
      $indstring = 1 - $indstring;
    }
    elsif($i eq "'" && ! $indstring && ! $escaping)
    {
      $token = "";
      $insstring = 1 - $insstring;
    }
    elsif($i =~ /^\s+$/ && ! $insstring && ! $indstring && ! $escaping)
    {
      $token = "";
    }
    elsif($i eq '=' && ! $insstring && ! $indstring && ! $escaping)
    {
      $token = "";
    }
    elsif($i eq '#' && ! $insstring && ! $indstring && ! $escaping)
    {
      $nocomment =~ s/\#.*//;
      return $nocomment;
    }
    else
    {
      if($escaping)
      {
        $token .= "\\";
        $escaping = 0; 
      }
      $token .= "$i";
    }
  }

  if($insstring || $indstring)
  {
    print "Error: Unterminated string while parsing file : $filename\n";
    print $nocomment;
  }

  if($escaping)
  {
    $token .= '\\';
  }
  
  return $nocomment;
}

#/*@@
#  @routine    TestConfigEnv
#  @date       Thu Aug 26 15:59:41 2004
#  @author     Tom Goodale
#  @desc 
#  Tests the routines for finding the new configuration environment
#  and updating the config-info file.
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#
#@@*/
sub TestConfigEnv
{
  my ($in,$out) = @_;

  my @allowed_opts = ("foo", "bar", "baz");

  my $env;
  my $optfile;
  my $configinfo;
  my $headers;

  ($configinfo,$headers) = ParseConfigInfo($in);

  if($ENV{"options"})
  {
    $optfile = ParseOptionsFile($ENV{"options"})
  }
  else
  {
    $optfile = {};
  }

  $env = GetOptionsFromEnv(\%ENV, \@allowed_opts);

  my $modified = AmalgamateOptions($env,$optfile,$configinfo,\@allowed_opts);

  if($modified)
  {
    print "Configuration was modified\n\n";
  }

  my $option;

  foreach $option (sort keys %$configinfo)
  {
    print "$option=$configinfo->{$option}\n"
  }

  WriteNewConfigInfo($out,$headers,$configinfo);

}
  

#/*@@
#  @routine    WriteNewConfigInfo
#  @date       Thu Aug 26 15:53:30 2004
#  @author     Tom Goodale
#  @desc 
#  Writes a new configuration file
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#
#@@*/
sub WriteNewConfigInfo
{
  my ($file,$headers,$options) = @_;
  my $line;
  my $option;

  open(OUTFILE, "> $file") || CST_error(0,"Cannot open config-info file '$file' for writing\n",
                                        "",__LINE__,__FILE__);
  
  foreach $line (@$headers)
  {
    if($line ne "# CONFIG-OPTIONS :")
    {
      print OUTFILE "$line\n";
    }
  }

  print OUTFILE "# CONFIG-MODIFIED: " . gmtime(time()) . " (GMT)\n";
  print OUTFILE "# CONFIG-OPTIONS :\n";

  foreach $option (sort keys %$options)
  {
    print OUTFILE "$option=$options->{$option}\n";
  }

  close(OUTFILE);
}

#/*@@
#  @routine    AmalgamateOptions
#  @date       Thu Aug 26 15:53:30 2004
#  @author     Tom Goodale
#  @desc 
#  Creates a hash table of option settings, giving
#  priority to ones from the environment, then to
#  ones from an options file, and finally to ones
#  which already exist in a config-info file.
#
#  It only adds or replaces options from a defined list.
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#
#@@*/
sub AmalgamateOptions
{
  my($env,$optfile,$configinfo,$allowed_options) = @_;

  my $option;

  my $modified = 0;

  foreach $option (@$allowed_options)
  {
    if($env->{$option})
    {
      # Environment (command line) has highest priority
      $configinfo->{$option} = $env->{$option};
      $modified = 1;
    }
    elsif($optfile->{$option})
    {
      # Then a new options file
      $configinfo->{$option} = $optfile->{$option};
      $modified = 1;
    }
  }

  return $modified;
}

#/*@@
#  @routine    ParseConfigInfo
#  @date       Thu Aug 26 15:56:15 2004
#  @author     Tom Goodale
#  @desc 
#  Parses a config-info file.  Returns a hash of the options
#  and an array containing pre-existing header lines.
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#
#@@*/
sub ParseConfigInfo
{
  my($file) = @_;
  my(%options);
  my @headers = ();
  my $line_number = 0;

  open(INFILE, "< $file") || CST_error(0,"Cannot open config-info file '$file' for reading\n",
                                       "",__LINE__,__FILE__);

  while(<INFILE>)
  {
    chomp;

    $line_number++;

    if(m/^#/)
    {
      push(@headers,$_);
    }
    elsif (m/^\s*(\w+)[=\s]+(.*)\s*/)
    {
      if(! $options{$1})
      {
        $options{$1} = $2;
      }
      else
      {
        CST_error(0,"corrupt config-info file; duplicate entry on line $line_number",
                  "",__LINE__,__FILE__);
      }
    }
  }

  close(INFILE);

  return \%options, \@headers;
}

#/*@@
#  @routine    ParseOptionsFile
#  @date       Thu Aug 26 15:57:58 2004
#  @author     Tom Goodale
#  @desc 
#  Parses a configuration options file.
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#
#@@*/
sub ParseOptionsFile
{
  my($file) = @_;
  my $line_number = 0;
  my %options;

  open(INFILE, "< $file") || CST_error(0,"Cannot open configuration options file '$file'\n",
                                       "",__LINE__,__FILE__);

  while(<INFILE>)
  {
    $line_number++;

    chomp;

    #Ignore comments.
    s/\#(.*)$//g;

    #Remove spaces at end of lines
    s/\s*$//;

    #Ignore blank lines
    next if (m:^\s*$:);

    # Match lines of the form
    #     keyword value
    # or  keyword = value
    if (/^\s*(\w+)[=\s]+(.*)\s*/)
    {
      # only set it if it wasn't already
      if(! $options{$1})
      {
        # Remember it for writing to config-info
        $options{$1} = $2;
      }
    }
    else
    {
      CST_error(0,"Could not parse configuration line $file:$line_number...\n'$_'\n",
                "",__LINE__,__FILE__);
     
    }
  }
  close(INFILE);

  return \%options;
}

#/*@@
#  @routine    GetOptionsFromEnv
#  @date       Thu Aug 26 15:58:26 2004
#  @author     Tom Goodale
#  @desc 
#  Gets options from the environment.
#  @enddesc 
#  @calls     
#  @calledby   
#  @history 
#
#  @endhistory 
#
#@@*/
sub GetOptionsFromEnv
{
  my($env, $allowed_options) = @_;
  my %options;

  my $option;

  foreach $option (@$allowed_options)
  {
   if($env->{$option})
   {
     $options{$option} = $env->{$option};
   }
  }

  return \%options;
}

#/*@@
#  @routine find_dep_cycles
#  @date    Fri Apr 15 20:47:00 2005
#  @author  Josh Abadie
#  @desc
#           Iterates over all the thorns, and finds out if there are any cycles
#           This function is the wrapper around the recursive one.
#  @enddesc
#@@*/
sub find_dep_cycles
{
  my(%thorns) = @_;
  my(%visited);
  my($stack,$keyu,$returned);
  my $debug = 0;

  foreach my $key (sort keys %thorns)
  {
    #next if($visted{$key} && 1 == $visted{$key});
    next if $visited{$key};
    print "testing $key for deps\n" if (1 == $debug);
    $stack = uc $key." ";
    $returned = &recurse_deps($key, \%thorns, $stack, \%visited);
    $visited{uc $key} = 1;
    if("" ne $returned)
    {
      print "Found cycle while testing $key for deps.[$returned]\n" if (1 == $debug);
      return $returned;
    }
  }
  return "";
}

#/*@@
#  @routine recurse_deps
#  @date    Fri Apr 15 20:47:00 2005
#  @author  Josh Abadie
#  @desc
#           Iterates over all the thorns, and finds out if there are any cycles
#           
#  @enddesc
#@@*/
sub recurse_deps
{
  my($key, $thornsTemp,$stack, $visitedTemp) = @_;
  my %thorns = %$thornsTemp;
  my %visited = %$visitedTemp;
  my($depThorn,$loop,$returned,$temp); 
  my (@arr)=();
  my $debug = 0;

  return "" if not $thorns{$key};
        
  # Iterates over all thorns this one depends on, and checks to see if any
  # form a cycle.
  foreach $depThorn (split(" ", $thorns{$key}))
  {
    if($stack =~ /\b$depThorn\b/i)
    {
      $stack =~ /.*\b($depThorn\b.*)$/i;
      $loop = uc($1.$depThorn);
      return $loop;
    }
    else
    {
      # We don't have a cycle yet, so let's recurse on this thorn's deps.
      $stack = $stack.uc($depThorn). ' ';
      print "Recursing into $depThorn.  Stack is [$stack]\n" if (1 == $debug);
      $returned = &recurse_deps($depThorn, \%thorns, $stack, \%visited);
      if("" ne $returned)
      {
        return $returned;
      }
      $visited{uc $depThorn} = 1;
      $temp = $";
      $" = " ";
      $stack =~ s/^(.*)\s*$/$1/;
      $stack =~ s/^\s*(.*)$/$1/;
      @arr = split(" ", $stack);
      pop(@arr);
      $stack = "@arr ";
      $" = $temp;
    }
  }
  $visited{uc $key} = 1;
  return "";
}

sub print_database
{
  my($type, $database) = @_;
  my($field);
  print "$type database dump:\n";

  foreach $field ( sort keys %$database )
  {
    print "$field has value $database->{$field}\n";
  }
}

sub save_database
{
  my($type, $database) = @_;
  my($field);

  if ($type !~ /[a-zA-Z.]+/) {
    die "first parameter of save_database contains forbidden characters";
  }
  open SAVE_DATABASE, ">${type}_database";
  foreach $field ( sort keys %$database )
  {
    print SAVE_DATABASE "$field has value $database->{$field}\n";
  }
  close SAVE_DATABASE;
}

#/*@@
#  @routine parse_ccl
#  @date    Thu May 15, 2017
#  @author  Steven R. Brandt
#  @desc
#           Parses any of the given ccl files.
#           It checks if the file has been previously
#           parsed and uses the cached parse tree if
#           possible.
#  @enddesc
#@@*/
sub parse_ccl
{
  my $grammar = shift;
  my $rule = shift;
  my $ccl_file = shift;
  my $peg_file = shift;
  $ccl_file =~ s{//+}{/}g; # remove double slashes
  croak "bad ccl file '$ccl_file'" unless($ccl_file =~ m{([^/]+)/([^/]+)/(\w+)\.ccl$});
  my ($arr,$thorn,$ccl)=($1,$2,$3);
  my $ccl_cache = undef;
  if(defined $main::piraha_cache_dir) {
    my $ccl_dir = "$main::piraha_cache_dir/$arr/$thorn";
    mkpath($ccl_dir);
    $ccl_cache = "$ccl_dir/$ccl.cache";
  }

  # If the cache file exists and is newer than the
  # ccl file Use it instead.
  my $gr = undef;
  my $ccl_tm = stat($ccl_file)->mtime;
  my $peg_tm = stat($peg_file)->mtime;
  my $tm = $ccl_tm < $peg_tm ? $peg_tm : $ccl_tm;
  if(defined $ccl_cache and -r $ccl_cache and stat($ccl_cache)->mtime > $tm) {
    $gr = piraha::load_tree($ccl_cache);
  }
  if(!defined($gr)) {
    my $p=piraha::parse_src($grammar,$rule,$ccl_file);
    my $m = $p->matches();
    if($m) {
      piraha::store_tree($ccl_cache,$p->{gr}) if defined $ccl_cache;
      $gr = $p->{gr};
    } else {
      my $help = $p->showError();
      $help =~ /LINE\s+(\d+)/;
      my $line = $1;
      &CST_error(0,"SYNTAX ERROR",$help,$line,$ccl_file);
      return {};
    }
  }
  # Debugging
  if(defined($ENV{CCTK_MAKE_TREE})) {
    my $fd = new FileHandle;
    open($fd,">tree.txt");
    print $fd $ccl_file,"\n";
    print $fd "=" x 50,"\n";
    print $fd $gr->dump(),"\n";
    close($fd);
  }
  return $gr;
}


1;
