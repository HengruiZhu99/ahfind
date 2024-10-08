#! /usr/bin/perl
#/*@@
#  @file      ScheduleParser.pl
#  @date      Thu Sep 16 19:13:05 1999
#  @author    Tom Goodale
#  @desc
#             New schedule parser
#  @enddesc
#  @version   $Header$
#@@*/
use strict;
use warnings;

# The known schedule bins
our @schedule_bins = (
    # Cactus startup
    'STARTUP',
    'WRAGH',
    'PARAMCHECK',
    # Initialisation
    'PREREGRIDINITIAL',
    'POSTREGRIDINITIAL',
    'BASEGRID',
    'INITIAL',
    'POSTRESTRICTINITIAL',
    'POSTINITIAL',
    'POSTPOSTINITIAL',
    # Recovery
    'RECOVER_VARIABLES',
    'POST_RECOVER_VARIABLES',
    'RECOVER_PARAMETERS',
    'CPINITIAL',
    # Evolution
    'PREREGRID',
    'POSTREGRID',
    'PRESTEP',
    'EVOL',
    'POSTRESTRICT',
    'POSTSTEP',
    'CHECKPOINT',
    'ANALYSIS',
    # Shutdown
    'TERMINATE',
    'SHUTDOWN');
# A regular expression matching all possible schedule bins, including
# a CCTK prefix and in upper case
our $schedule_bin_regexp = '\bCCTK_(' . join ('|', @schedule_bins) . ')\b';
our $time_bin_info = {};

# Check that the schedule bin exists
my %schedule_bins = ();
for my $s (@schedule_bins) {
  $schedule_bins{"CCTK_$s"}++;
  $schedule_bins{$s}++;
}

my $ccl_file = undef;

use FindBin;
use Carp;
use FileHandle;
use Data::Dumper;
use Piraha;

#/*@@
#  @routine    create_schedule_database
#  @date       Thu Sep 16 23:31:00 1999
#  @author     Tom Goodale
#  @desc
#  Parses the schedule files for all thorns.
#  @enddesc
#  @calls
#  @calledby
#  @history
#
#  @endhistory
#
#@@*/
sub create_schedule_database
{
  my(%thorns) = @_;
  my($thorn, @indata);
  my(@new_schedule_data);
  my(@schedule_data);

  my $peg_file = "$FindBin::Bin/../../src/piraha/pegs/schedule.peg";
  my($grammar,$rule)=piraha::parse_peg_file($peg_file);

  #  Loop through each implementation's schedule file.
  foreach $thorn (sort keys %thorns)
  {
    print "   $thorn\n";
    #       Read the data
    $ccl_file = "$thorns{$thorn}/schedule.ccl";
    my $gr = parse_ccl($grammar,$rule,$ccl_file,$peg_file);


    #       Get the schedule stuff from it
    @new_schedule_data = &parse_schedule_ccl($thorn, $gr);

    &PrintScheduleStatistics($thorn, @new_schedule_data);

    #       Add the schedule stuff to the master schedule database
    push (@schedule_data, @new_schedule_data);

  }

  if (defined($ENV{VERBOSE}) and lc($ENV{VERBOSE}) eq "yes") {
    print "+===========================+\n";
    print "| Schedule Parsing Complete |\n";
    print "+===========================+\n";
  }

#  @schedule_data = &cross_index_schedule_data(scalar(keys %thorns), (sort keys %thorns), @schedule_data);

  return @schedule_data;
}

# Process a parse tree element named "vname"
sub vname
{
  my $vname = shift;
  my $out = "";
  confess("not a uname/vname ".$vname->dump()) unless($vname->isre('^[uv]name$'));
  for my $v (@{$vname->{children}}) {
    if($v->is("name")) {
      $out .= "::" unless($out eq "");
      $out .= $v->substring();
    } else {
      # This will be an expression
      $out .= "[" . $v->substring() . "]";
    }
  }
  return $out;
}

# Process a parse tree element named "qrname"
sub qrname
{
  my $qrname = shift;
  my $out = "";
  confess("not a qrname ".$qrname->dump()) unless($qrname->is("qrname"));
  for my $v (@{$qrname->{children}}) {
    if($v->is('vname')) {
      $out .= vname($v);
    } elsif($v->is("region")) {
      $out .= "(" . $v->substring() . ")";
    }
  }
  return $out;
}

sub parse_schedule_statement
{
  my $group = shift;
  my $schedule_db = shift;
  my $n_blocks = shift;
  my $n_statements = shift;
  my $buffer = shift;
  my $thorn = shift;
  for my $statement (@{$group->{children}}) {
    if($statement->is("statement")) {
      my ($name, $as, $type, $description, $where, $language,
       $mem_groups, $comm_groups, $trigger_groups, $sync_groups,
       $options, $tags, $before_list, $after_list,
       $writes_list, $reads_list, $invalidates_list, $while_list, $if_list,$qthorn);
      for my $schedule (@{$statement->{children}}) {
        my $nm = $schedule->{name};
        if($nm eq "schedule") {
          my @children = @{$schedule->{children}};
          $name = $schedule->group(1,"name")->substring();
          $as = undef;
          if($schedule->group(0)->is("nogroup")) {
            $type = "FUNCTION"
          } else {
            $type = "GROUP"
          }
          # parse prepositions
          for my $prep (@{$schedule->group(2,"prepositions")->{children}}) {
            my $prep_name = lc($prep->group(0,"par")->substring());
            if($prep_name eq "after") {
              for my $item (@{$prep->group(1)->{children}}) {
                $after_list .= "," if(defined($after_list));
                $after_list .= vname($item);
              }
            } elsif($prep_name eq "before") {
              for my $item (@{$prep->group(1)->{children}}) {
                $before_list .= "," if(defined($before_list));
                $before_list .= vname($item);
              }
            } elsif($prep_name eq "at") {
              $where = uc($prep->group(1,"pararg")->group(0,'uname')->substring());
              $where =~ s/^(CCTK_|)/CCTK_/gi;
              if($where !~ $schedule_bin_regexp) {
						  my $hint="If this routine should be scheduled check the spelling of the group or timebin name. Note that scheduling IN must be used to schedule a routine to run in a thorn-defined schedule group, whereas scheduling AT is used for a usual timebin. (Schedule IN may also be used with the usual timebins, but in this case the full name of the bin must be used, e.g. CCTK_EVOL and not EVOL";
						  &CST_error(0,"Scheduling routine $name from thorn $thorn in non-existent group or timebin $where",$hint,$prep->linenum(),$ccl_file);
              }
            } elsif($prep_name eq "in") {
              $where = $prep->group(1,"pararg")->group(0,'uname')->substring();
              $time_bin_info->{$thorn}->{$name}->{$where} = {
                  line  => $prep->linenum(),
                  file  => $ccl_file,
              };
            } elsif($prep_name eq "while") {
              $while_list = "";
              for my $w (@{$prep->group(1)->{children}}) {
                $while_list .= "," unless($while_list eq "");
                $while_list .= vname($w);
              }
            } elsif($prep_name eq "if") {
              $if_list = "";
              for my $w (@{$prep->group(1)->{children}}) {
                $if_list .= "," unless($if_list eq "");
                $if_list .= vname($w);
              }
            } elsif($prep_name eq "as") {
              my $ngas = $prep->group(1,"pararg")->group(0,"uname");
              my $nas = $ngas->substring();
              if(defined($as)) {
                CST_error(0,
                  "Multiple values for 'as' keyword for schedule item $name: '$as' and '$nas'",
                  "Try removing one of the 'as' directives",
                  $ngas->linenum(),$ccl_file);
                last;
              }
              $as = $nas;
            } else {
              # Should be impossible to get here.
              CST_error(0,
                "Unknown preposition '$prep_name'",
                "Should be before, after, while, etc., see docs",
                $prep->linenum(),$ccl_file);
            }
          }
          $as = $name unless(defined($as));
          for my $child (@children[3..$#children-1]) {
            if($child->is("lang")) {
              $language = $child->group(0,"name")->substring();
              if(lc($language) ne "c" and lc($language) ne "fortran") {
                CST_error(0,
                "Invalid language: '$language'. Must be C or Fortran.",
                undef,
                $child->linenum(),$ccl_file);
              }
            } elsif($child->is("options")) {
              for my $opt (@{$child->{children}}) {
                $options .= "," if(defined($options));
                $options .= $opt->substring();
              }
            } elsif($child->is("tags")) {
              for my $tag (@{$child->{children}}) {
                $tags .= "," if(defined($tags));
                $tags .= $tag->substring();
              }
            } elsif($child->is("storage")) {
              for my $vname (@{$child->{children}}) {
                if($vname->is('vname')) {
                  $mem_groups .= "," if(defined($mem_groups));
                  $mem_groups .= vname($vname);
                }
              }
            } elsif($child->is("writes")) {
              for my $qrname (@{$child->{children}}) {
                if($qrname->is("qrname")) {
                  $writes_list .= "," if(defined($writes_list));
                  $writes_list .= qrname($qrname);
                }
              }
            } elsif($child->is("invalidates")) {
              for my $qrname (@{$child->{children}}) {
                if($qrname->is("qrname")) {
                  $invalidates_list .= "," if(defined($invalidates_list));
                  $invalidates_list .= qrname($qrname);
                }
              }
            } elsif($child->is("reads")) {
              for my $qrname (@{$child->{children}}) {
                if($qrname->is("qrname")) {
                  $reads_list .= "," if(defined($reads_list));
                  $reads_list .= qrname($qrname);
                }
              }
            } elsif($child->is("sync")) {
              for my $vname (@{$child->{children}}) {
                if($vname->is('uname')) {
                  $sync_groups .= "," if(defined($sync_groups));
                  $sync_groups .= vname($vname);
                }
              }
            } elsif($child->is("triggers")) {
              for my $vname (@{$child->{children}}) {
                if($vname->is('vname')) {
                  $trigger_groups .= "," if(defined($trigger_groups));
                  $trigger_groups .= vname($vname);
                }
              }
            } else {
              confess("child error: ".$child->{name});
            }
          }
          $description = $children[$#children]->substring();
          # Trim off quote characters
          $description = substr($description,1,length($description)-2);
        } elsif($nm eq "storage") {
          $type = "STOR";
          my $groups = "";
          for my $vname (@{$schedule->{children}}) {
            if($vname->is('vname')) {
              $groups .= " " if(defined($groups));
              $groups .= vname($vname);
            }
          }
          $schedule_db->{"\U$thorn\E STATEMENT_$$n_statements TYPE"}        = $type;
          $schedule_db->{"\U$thorn\E STATEMENT_$$n_statements GROUPS"}      = $groups;
          $$buffer .= "\@STATEMENT\@$$n_statements\n";
          $$n_statements++;
          next;
        } elsif($nm eq "if") {
          # Parse the ifbody group
          $$buffer .= "if (".$schedule->group(0,"boolexpr")->substring().")\n";
          &parse_schedule_statement(
            $schedule->group(1,"ifbody"),$schedule_db,$n_blocks,$n_statements,$buffer,$thorn);
          next;
        } else {
          confess("NOT FOUND: [".$schedule->{name}."]");
        }
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks NAME"}        = $name;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks AS"}          = $as;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks TYPE"}        = $type;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks DESCRIPTION"} = $description;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks WHERE"}       = $where;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks LANG"}        = $language
          if(defined($language));
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks STOR"}        = $mem_groups;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks COMM"}        = $comm_groups;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks TRIG"}        = $trigger_groups;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks SYNC"}        = $sync_groups;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks OPTIONS"}     = $options;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks TAGS"}        = $tags;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks BEFORE"}      = $before_list;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks AFTER"}       = $after_list;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks WRITES"}      = $writes_list;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks READS"}       = $reads_list;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks INVALIDATES"} = $invalidates_list;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks WHILE"}       = $while_list;
        $schedule_db->{"\U$thorn\E BLOCK_$$n_blocks IF"}          = $if_list;
        $$buffer .= "\@BLOCK\@$$n_blocks\n";
        $$n_blocks++;
      }
    } elsif($statement->is("block")) {
      $$buffer .= "{\n";
      &parse_schedule_statement($statement,$schedule_db,$n_blocks,$n_statements,$buffer,$thorn);
      $$buffer .= "}\n";
    } elsif($statement->is("if")) {
      # Parse the ifbody group
      $$buffer .= "if (".$statement->group(0,"boolexpr")->substring().")\n";
      &parse_schedule_statement(
         $statement->group(1,"ifbody"),$schedule_db,$n_blocks,$n_statements,$buffer,$thorn);
    } elsif($statement->is("else")) {
      $$buffer .= "else ";
    } else {
      confess("statement error: <".$statement->{name}.">");
    }
  }
}

#/*@@
#  @routine    parse_schedule_ccl
#  @date       Thu Sep 16 23:23:07 1999
#  @author     Tom Goodale
#  @desc
#  Parses a schedule ccl file
#  @enddesc
#  @calls
#  @calledby
#  @history
#
#  @endhistory
#
#@@*/
sub parse_schedule_ccl
{
  my($thorn, $group) = @_;
  my($line_number);
  my(%schedule_db);
  my($buffer);
  my($n_blocks);
  my($n_statements);
  my($groups);
  my ($name, $as, $type, $description, $where, $language,
       $mem_groups, $comm_groups, $trigger_groups, $sync_groups,
       $options, $tags, $before_list, $after_list,
       $writes_list, $reads_list, $invalidates_list, $while_list, $if_list);

  $buffer       = "";
  $n_blocks     = 0;
  $n_statements = 0;

  my %schedule_db1 = ();
  my %schedule_db2 = ();

  &parse_schedule_statement($group,\%schedule_db1,\$n_blocks,\$n_statements,\$buffer,$thorn);
  $schedule_db1{"\U$thorn\E N_BLOCKS"}     = $n_blocks;
  $schedule_db1{"\U$thorn\E FILE"}         = $buffer;
  $schedule_db1{"\U$thorn\E N_STATEMENTS"} = $n_statements;

  for my $k (keys %schedule_db1) {
    $schedule_db{$k} = $schedule_db1{$k};
  }

  return %schedule_db;
}

#/*@@
#  @routine    ParseScheduleBlock
#  @date       Thu Sep 16 23:34:55 1999
#  @author     Tom Goodale
#  @desc
#  Parses a schedule block and extracts all the info.
#  @enddesc
#  @calls
#  @calledby
#  @history
#
#  @endhistory
#
#@@*/
sub ParseScheduleBlock
{
  my($thorn,$line_number, @data) = @_;
  my($name, $as, $type, $description, $where, $language,
     $mem_groups, $comm_groups, $trigger_groups, $sync_groups,
     $options, $tags, $before_list, $after_list,
     $writes_list, $reads_list, $invalidates_list, $while_list, $if_list);
  my(@fields);
  my($field);
  my(@before_list)    = ();
  my(@after_list)     = ();
  my(@writes_list)    = ();
  my(@reads_list)     = ();
  my(@invalidates_list) = ();
  my(@while_list)     = ();
  my(@if_list)        = ();
  my(@mem_groups)     = ();
  my(@comm_groups)    = ();
  my(@trigger_groups) = ();
  my(@sync_groups)    = ();
  my(@options)        = ();
  my(@tags)           = ();
  my($keyword) = "";
  my(@current_sched_list) = ();

  $where = "";
  $as    = "";

  #Parse the first line of the schedule block

  $data[$line_number] =~ m:^\s*(.*)\s*$:;

  @fields = split(/([\s,\(\)]+)/, $1);

  # Find the type of the block,
  if($fields[2] =~ m:^group$:i)
  {
    $type = "GROUP";
    $field = 4;
  }
  elsif($fields[1] =~ m:^function$:i)
  {
    $type = "FUNCTION";
    $field = 4;
  }
  else
  {
    $type = "FUNCTION";
    $field = 2;
  }

  $name = $fields[$field];
  $field ++;

  while($field <= $#fields)
  {
    if($fields[$field] =~ m:^\s*$:)
    {
      $field++;
      next;
    }

    if($fields[$field] =~ m:^AT$:i)
    {
      $field+=2;
      if($where ne "")
      {
        print STDERR "Error parsing schedule block line '$data[$line_number]'\n";
        print STDERR "Attempt to schedule same block at/in two places.\n";
      }
      else
      {
        if($fields[$field] =~ m:CCTK_:i)
        {
          $where = "\U$fields[$field]\E";
        }
        else
        {
          $where = "CCTK_\U$fields[$field]\E";
        }
      }

      # check that the given schedule bin is recognized
      if ($where !~ $schedule_bin_regexp)
      {
        &CST_error(0,"Schedule bin \'$where\' not recognised in schedule.ccl " .
                   "file of thorn $thorn","",__LINE__,__FILE__);
      }
      $field+=2;
    }
    elsif($fields[$field] =~ m:^IN$:i)
    {
      $field+=2;
      if($where ne "")
      {
        print STDERR "Error parsing schedule block line '$data[$line_number]'\n";
        print STDERR "Attempt to schedule same block at/in two places.\n";
      }
      else
      {
        $where = "$fields[$field]";
      }
      $field+=2;
    }
    elsif($fields[$field] =~ m:^AS$:i)
    {
      $field+=2;
      if($as ne "")
      {
        print STDERR "Error parsing schedule block line '$data[$line_number]'\n";
        print STDERR "Attempt to schedule same block with two names.\n";
      }
      else
      {
        $as = "$fields[$field]";
      }
      $field+=2;
    }
    elsif($fields[$field] =~ m:^BEFORE$:i)
    {
      if($keyword ne "")
      {
        &CST_error(0,"Error parsing schedule block line '$data[$line_number]'",
                   "",__LINE__,__FILE__);
      }
      $keyword = "BEFORE";
      $field++;
    }
    elsif($fields[$field] =~ m:^AFTER$:i)
    {
      if($keyword ne "")
      {
        &CST_error(0,"Error parsing schedule block line '$data[$line_number]'",
                   "",__LINE__,__FILE__);
      }
      $keyword = "AFTER";
      $field++;
    }
    elsif($fields[$field] =~ m:^WHILE$:i)
    {
      if($keyword ne "")
      {
        &CST_error(0,"Error parsing schedule block line '$data[$line_number]'",
                   "",__LINE__,__FILE__);
      }
      $keyword = "WHILE";
      $field++;
    }
    elsif($fields[$field] =~ m:^IF$:i)
    {
      if($keyword ne "")
      {
        &CST_error(0,"Error parsing schedule block line '$data[$line_number]'",
                   "",__LINE__,__FILE__);
      }
      $keyword = "IF";
      $field++;
    }
    elsif($keyword ne "" && $fields[$field] =~ m:\s*\(\s*:)
    {
      # Parse a clause of the form BEFORE(a,b,c)
      @current_sched_list = ();

      $field++;

      while($fields[$field] !~ m:\s*\)\s*: && $field <= $#fields)
      {
        if($fields[$field] =~ m:\s*,\s*:)
        {
          $field++;
          next;
        }

        push(@current_sched_list, $fields[$field]);
        $field++;
      }

      $field++;

      if($keyword eq "BEFORE")
      {
        push(@before_list, @current_sched_list);
      }
      elsif($keyword eq "AFTER")
      {
        push(@after_list, @current_sched_list);
      }
      elsif($keyword eq "WHILE")
      {
        push(@while_list, @current_sched_list);
      }
      elsif($keyword eq "IF")
      {
        push(@if_list, @current_sched_list);
      }

      # Reset keyword to empty for next time.
      $keyword = "";
    }
    elsif($keyword ne "" && $fields[$field] =~ m:\w:)
    {
      if($keyword eq "BEFORE")
      {
        push(@before_list, $fields[$field]);
      }
      elsif($keyword eq "AFTER")
      {
        push(@after_list, $fields[$field]);
      }
      elsif($keyword eq "WHILE")
      {
        push(@while_list, $fields[$field]);
      }
      elsif($keyword eq "IF")
      {
        push(@if_list, $fields[$field]);
      }
      $field++;
      $keyword = "";
    }
    elsif(($keyword eq "") && ($field == $#fields) && ($fields[$field] =~ m:\s*\{\s*:))
    {
      # This bit matches a { at the end of a line
      # I don't like it, but it seems to be already in use 8-(
      $line_number--;
      $keyword = "";
      last;
    }
    else
    {
      &CST_error(0,"Error parsing schedule block line '$data[$line_number]'",
                 "",__LINE__,__FILE__);
      $keyword = "";
      $field++;
    }
  }
  $line_number++;

  # If no alias is set, just use the name.
  if($as eq "")
  {
    $as = $name;
  }

  # Parse the rest of the block

  if($data[$line_number] !~ m:\s*\{\s*:)
  {
    &CST_error(0,"Error parsing schedule block line '$data[$line_number]'\nMissing { at start of block","",__LINE__,__FILE__);
    $line_number++ while($line_number<scalar(@data) and $data[$line_number] !~ m:\s*\}\s*:);
  }
  else
  {
    while($data[$line_number] !~ m:\s*\}\s*:)
    {
      $line_number++;
      if($data[$line_number] =~ m/^\s*STOR[^:]*:\s*(.*)$/i)
      {
        if ($where eq "CCTK_STARTUP" )
        {
          &CST_error(1, "Scheduling storage \"$name\" at startup in thorn \"$thorn\"","Storage cannot be allocated at startup",__LINE__,__FILE__);
        }
        elsif ($where eq "CCTK_SHUTDOWN" )
        {
          &CST_error(1, "Scheduling storage \"$name\" at shutdown in thorn \"$thorn\"","Storage cannot be allocated at shutdown",__LINE__,__FILE__);
        }

        push(@mem_groups, split(/\s+|\s*,\s*/, $1));
      }
      elsif($data[$line_number] =~ m/^\s*COMM[^:]*:\s*(.*)$/i)
      {
        push(@comm_groups, split(/\s+|\s*,\s*/, $1));
      }
      elsif($data[$line_number] =~ m/^\s*TRIG[^:]*:\s*(.*)$/i)
      {
        push(@trigger_groups, split(/\s+|\s*,\s*/, $1));
      }
      elsif($data[$line_number] =~ m/^\s*SYNC[^:]*:\s*(.*)$/i)
      {
        push(@sync_groups, split(/\s+|\s*,\s*/, $1));
      }
      elsif($data[$line_number] =~ m/^\s*WRITES\s*:\s*(.*)$/i)
      {
        push(@writes_list, split(/\s+|\s*,\s*/, $1));
      }
      elsif($data[$line_number] =~ m/^\s*READS\s*:\s*(.*)$/i)
      {
        push(@reads_list, split(/\s+|\s*,\s*/, $1));
      }
      elsif($data[$line_number] =~ m/^\s*INVALIDATES\s*:\s*(.*)$/i)
      {
        push(@invalidates_list, split(/\s+|\s*,\s*/, $1));
      }
      elsif($data[$line_number] =~ m/^\s*OPTI[^:]*:\s*(.*)$/i)
      {
        push(@options, split(/\s+|\s*,\s*/, $1));
      }
      elsif($data[$line_number] =~ m/^\s*TAGS[^:]*:\s*(.*)$/i)
      {
        push(@tags, $1);
      }
      elsif($data[$line_number] =~ m/^\s*LANG[^:]*:\s*(.*)$/i)
      {
        if($language ne "")
        {
          my $thisline = $data[$line_number];
          $thisline =~ s/^\s*([^\s])\s$/$1/;
          my $message  = "Error parsing schedule block in $thorn\n";
          $message .= "Attempt to specify language more than once\n";
          $message .= "Line: $thisline";
          &CST_error(0,$message,"",__LINE__,__FILE__);
        }
        else
        {
          $language= $1;
          if ($type eq "GROUP")
          {
            &CST_error(1, "Scheduling group \"$name\" with LANG specifier in thorn \"$thorn\"","Groups should not have a LANG specificier",__LINE__,__FILE__);
          }
        }
      }
      elsif($data[$line_number] =~ m:\s*\}\s*:)
      {
        # do nothing.
      }
      else
      {
	$data[$line_number] =~ /^(.*)\n+/;
        &CST_error(0,"Unrecognised statement in schedule block ($name) in schedule.ccl for thorn $thorn\n\"$1\"","",__LINE__,__FILE__);
      }
    }
  }
  if($data[$line_number] =~ m:\s*\}\s*\"([^\"]*)\":)
  {
    $description = $1;
  }
  else
  {
    my $message = "Missing desciption at end of schedule block ($name) in schedule.ccl for thorn $thorn";
    &CST_error(0,$message,"",__LINE__,__FILE__);
  }

  # Turn the arrays into strings.
  $mem_groups       = join(",", @mem_groups);
  $comm_groups      = join(",", @comm_groups);
  $trigger_groups   = join(",", @trigger_groups);
  $sync_groups      = join(",", @sync_groups);
  $options          = join(",", @options);
  $tags             = join(" ", @tags);
  $before_list      = join(",", @before_list);
  $after_list       = join(",", @after_list);
  $writes_list      = join(",", @writes_list);
  $reads_list       = join(",", @reads_list);
  $invalidates_list = join(",", @invalidates_list);
  $while_list       = join(",", @while_list);
  $if_list          = join(",", @if_list);


  return ($line_number,
          $name, $as, $type, $description, $where, $language,
          $mem_groups, $comm_groups, $trigger_groups, $sync_groups,
          $options, $tags, $before_list, $after_list,
          $writes_list, $reads_list, $invalidates_list, $while_list, $if_list);

}

#/*@@
#  @routine    PrintScheduleStatistics
#  @date       Sun Sep 19 13:07:08 1999
#  @author     Tom Goodale
#  @desc
#  Prints out statistics about a thorn's schedule.ccl
#  @enddesc
#  @calls
#  @calledby
#  @history
#
#  @endhistory
#
#@@*/
sub PrintScheduleStatistics
{
  my($thorn, %schedule_database) = @_;

  print "          " . $schedule_database{"\U$thorn\E N_BLOCKS"} . " schedule blocks.\n";

  return;
}

#/*@@
#  @routine    check_schedule_database
#  @date       26th April 2002
#  @author     Gabrielle Allen
#  @desc
#  Checks on consistency of schedule database
#  @enddesc
#  @calls
#  @calledby
#  @history
#
#  @endhistory
#
#@@*/

sub check_schedule_database
{
  my($rhschedule_db,%thorns) = @_;

  # make a list of all group names
  my %allgroups = ();
  foreach my $thorn (sort keys %thorns)
  {
    # Process each schedule block
    for(my $block = 0 ; $block < $rhschedule_db->{"\U$thorn\E N_BLOCKS"}; $block++)
    {
      if ($rhschedule_db->{"\U$thorn\E BLOCK_$block TYPE"} =~ /GROUP/)
      {
        my $key = $rhschedule_db->{"\U$thorn\E BLOCK_$block NAME"};
        $allgroups{$key}++;
      }
    }
  }
  # Some schedule items aren't assigned a group.
  $allgroups{""}=1;
  # Include the schedule bins in the declared groups.
  # When a group is scheduled in a schedule bin,
  # it will be all caps with CCTK_ at the front.
  for my $bin (@schedule_bins) {
    my $cbin = "CCTK_".$bin;
    # recognize all permutations,
    # upper and lower case, with
    # cctk_ and without.
    $allgroups{uc $bin}++;
    $allgroups{uc $cbin}++;
    $allgroups{lc $bin}++;
    $allgroups{lc $cbin}++;
  }
  my @allgroups = sort keys %allgroups;

  # check that scheduling in is only for a known group
  foreach my $thorn (sort keys %thorns)
  {
    # Process each schedule block
    for(my $block = 0 ; $block < $rhschedule_db->{"\U$thorn\E N_BLOCKS"}; $block++)
    {
      my $group = $rhschedule_db->{"\U$thorn\E BLOCK_$block WHERE"};
      if($group and !defined($allgroups{$group}))
      {
        my $name  = $rhschedule_db->{"\U$thorn\E BLOCK_$block NAME"};
        my $where = $rhschedule_db->{"\U$thorn\E BLOCK_$block WHERE"};
        my $message = "Scheduling routine $name from thorn $thorn in non-existent group or timebin $where";
        print "    $message\n";
        my $hint = "If this routine should be scheduled check the spelling of the group or timebin name. Note that scheduling IN must be used to schedule a routine to run in a thorn-defined schedule group, whereas scheduling AT is used for a usual timebin. (Schedule IN may also be used with the usual timebins, but in this case the full name of the bin must be used, e.g. CCTK_EVOL and not EVOL)";
        my $info = $time_bin_info->{$thorn}->{$name}->{$where};
        &CST_error(1,$message,$hint,$info->{line},$info->{file});
      }
    }
  }
}

1;
