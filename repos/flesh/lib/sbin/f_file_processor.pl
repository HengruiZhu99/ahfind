#!/usr/bin/perl -sw
#/*@@
#  @file      f_file_processor.pl
#  @date      Jan 22 1995
#  @author    Paul Walker
#  @desc
#  Postprocessor for Fortran files.
#
#  Reads STDIN, writes to STDOUT.
#
#  removes all comments
#  replaces && with newline and tab to col 7
#  Breaks lines greater than 72 or 132 cols
#     (depending on fixed or free format)
#  Does this using multi-line matching!
#
#  If run with -free_format, chooses free-format line splitting.
#
#  @enddesc
#  @version $Header$
#@@*/

# Possible command line options:
#    -free-format
#    -line_directives=[yes|no]
#    -source_file_name=[filename]
# Reads input from stdin.
# The result will be printed to stdout.

# Do we want line directives?
$line_directives = $line_directives eq 'yes';

# Maximum line length for free form Fortran
$max_line_length = 132;
# Indentation for continued free form Fortran
$indentation = 2;
$indent = " " x $indentation;

# Loop over all lines.
$line = 1;
$file = "";
$autoline = 1;
$autofile = "";
$stringdelim = undef;
while (<>)
{
  # Handle directives
  if (/^\#/)
  {
    if ($line_directives)
    {
      # Handle line directives
      if (/^\#\s*(\d+)\s*"([^"]*)"/)
      {
        $line = $1;
        $file = $2;
        if ($file eq '<stdin>')
        {
          $file = $source_file_name;
        }
      } else {
        ++$line;
      }
      next;
    }
    else
    {
      # Ignore directives
      next;
    }
  }

  # remove comments
  if ($free_format)
  {
    # handle comment markers in strings even through line continuation in strings,
    # adapted from Fokke Dijkstra's code
    while (m/(["'!])/g)
    {
      # keep track of position for substr
      $position = pos() - 1;

      if ($stringdelim)
      {
        $stringdelim = undef if $1 eq $stringdelim;
      }
      elsif ($1 eq "!")
      {
        unless (m/\G\$(omp|hpf)/i)
        {
          $_ = substr ($_, 0, $position) . "\n";
        }
        pos = 0; # reset global match on $_
        last;
      }
      else
      {
        $stringdelim = $1;
      }
    }
  }
  else
  {
    if (not $stringdelim and m/^[c!*]/)
    {
      $_ = "c\n" unless m/^[c!*]\$(omp|hpf)/;
    }
    else
    {
      while (m/(["'])/g)
      {
        if ($stringdelim)
        {
          $stringdelim = undef if $1 eq $stringdelim;
        }
        else
        {
          $stringdelim = $1;
        }
      }
    }
  }

  # Put in the line breaks (&&)
  if($free_format)
  {
    s/\s*\&\&\s*/\n$indent/g;
  }
  else
  {
    s/\s*\&\&\s*/\n      /g;
  }

  while (m/(.*)\n/g)
  {
    &splitline($1);
  }

  ++$line;
}

#/*@@
#  @routine    splitline
#  @date       Wed Nov 24 12:14:55 1999
#  @author     Tom Goodale
#  @desc
#  Chooses the correct routine to split lines.
#  @enddesc
#@@*/
sub splitline
{
  my ($LINE) = @_;

  if($free_format)
  {
    &free_format_splitline($LINE);
  }
  else
  {
    &fixed_format_splitline($LINE);
  }

}

#/*@@
#  @routine    fixed_format_splitline
#  @date       1995
#  @author     Paul Walker
#  @desc
#  Splits lines for F77 or fixed-format F90
#  @enddesc
#@@*/
sub fixed_format_splitline
{
  my ($LINE) = @_;

  # Note the new treatement of comments with \S
  if ($LINE =~ /^([^\S].{71,71})/m)
  {
    &printline ($1);
    $LINE =~ s/.{72,72}//m;
    while ($LINE =~ /^(.{66,66})/m)
    {
      &printline ("     &$1");
      $LINE =~ s/.{66,66}//m;
    }
    &printline ("     &$LINE");
  }
  else
  {
    &printline ($LINE);
  }

}

#/*@@
#  @routine    free_format_splitline
#  @date       Thu Sep 30 12:05:36 1999
#  @author     Erik Schnetter
#  @desc
#  Splits lines for free-format Fortran 90.
#  @enddesc
#@@*/
sub free_format_splitline
{
  my ($LINE) = @_;
  my $OUT;
  my $maxlen = $max_line_length - 1;
  my $sentinel = "";

  # assuming correct input then a "&" must only occur at the end or at the
  # beginning (possibly after a sentinel) of the line, not in the bulk of it
  #
  # ifort and gfortran handle OMP continuations with only space differently.
  # ifort will not accept something like "!$OMP&   &" ie only spaces between
  # the & while gfortran will not accept "!$OMP  " ie only spaces.
  # This triggers when breaking up constructs like:
  # $!OMP parallel private(i)
  # that need to be rendered as (gfortran):
  # $!OMP parallell&
  # $!OMP& &
  # $!OMP&private(i)
  # and (ifort)
  # $!OMP parallell&
  # $!OMP
  # $!OMP&private(i)
  # neither of which the other one accepts.
  #
  # We avoid this by remoiving multi-space sections from OMP lines where they
  # are equivalent to a single space which avoids most instance of the issue of
  # producing space only continuations except at the very end of a line "!$OMP
  # parallel &" if the desired split point is just before the last space, which
  # we handle explictly below.
  if ($LINE =~ m/^(\s*(!\$(?:omp|hpf)))(.*)/i)
  {
    $head = $1;
    $sentinel = $2;
    $tail = $3;

    $tail =~ s/\s+/ /g;
    $LINE = "$head$tail";
  }

  # any piece longer than the allowed F90 length
  while ($LINE =~ s/^(.{$maxlen,$maxlen})(..)/$2/)
  {
    $OUT = $1;
    if ($sentinel and $LINE =~ m/^\s&$/)
    {
      $OUT =~ s/^(.*)(.)$/$1/;
      $tail = $2;
      die "Internal error: could not split '$OUT'" unless $tail =~ m/\S/;
      $LINE = "$tail$LINE";
    }
    $OUT = "$OUT&";
    &printline ($OUT);

    $LINE = "$indent$sentinel&$LINE";
  }
  # any leftover piece
  &printline ($LINE);
}



# Print a line and append a newline
# Emit line number and file name directives if necessary
sub printline
{
  my ($LINE) = @_;
  
  if ($line_directives) {
    if ($file ne $autofile) {
      print "# $line \"$file\"\n";
      $autoline = $line;
      $autofile = $file;
    } elsif ($line ne $autoline) {
      if ($line>$autoline && $line<=$autoline+3) {
        while ($autoline!=$line) {
          print "\n";
          ++$autoline;
        }
      } else {
        # print "# $line \"$file\"\n";
        print "# $line\n";
        $autoline = $line;
        $autofile = $file;
      }
    }
  }
  print "$LINE\n";
  ++$autoline;
}
