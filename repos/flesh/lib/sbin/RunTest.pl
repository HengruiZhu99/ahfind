#!/bin/perl -s
#
# Test Suite tool

# For debugging:
my $debug = 0;
my $debug_indent_level = 0;
sub debug_print
{
  # debug statements are prefixed by a '#', to make them stand out from 
  # ordinary output
  $debug and print '#'.' 'x$debug_indent_level."@_\n";
}
sub debug
{
  $debug;
}
sub debug_indent
{
  $debug_indent_level++;
}
sub debug_dedent
{
  $debug_indent_level--;
}

use FindBin;
use lib "$FindBin::Bin";
require "RunTestUtils.pl";

use Data::Dumper;
use IO::Select;
use POSIX ":sys_wait_h";

# Read options from command line
$prompt = shift;   
$prompt =~ tr/A-Z/a-z/;
$home_dir = shift;
$config = shift;

&PrintHeader;

# Set up RunTest configuration
$config_data = &Configure($config,$home_dir,$prompt);

%runconfig = &InitialiseRunData();

# ----------------------------------------------------

# Sort out the static test data

# Initialise testdata database
$testdata = &InitialiseTestData();

# Find test parameter files
$testdata = &FindTestParameterFiles($testdata,$config_data);

# Parse test config files
$testdata = &ParseTestConfigs($testdata,$config_data,\%runconfig);

# Parse test parameter files
$testdata = &ParseAllParameterFiles($testdata,$config_data,\%runconfig);

# Print database
#&PrintDataBase($testdata);

# ----------------------------------------------------

$haverunall = 0;

while ($choice !~ /^Q/i)
{
  undef($thorn);
  undef($test);
  undef($choice);
  
  while (!($choice =~ /^Q/i) )
  {
      
    print "------------------------------------------------------------------------\n\n";
    print "  --- Menu ---\n\n";
    
    print "  Run entire set of tests [E]\n";
    print "  Run entire set of tests interactively [I]\n";
    print "  Choose test from [T]horn or [A]rrangement\n";
    print "  Rerun previous test [R]\n";
    print "  Rerun previous test and show run output on screen [S]\n";
    print "  Print tolerance table for data in previous test [P]\n";
    print "  Compare all files in the test output directories [O]\n";
    print "  Customize testsuite checking [C]\n";
    print "  Quit [Q]\n\n";

    if ($haverunall == 1)
    {
      $choice = &defprompt("  Select choice: ","Q");
    }
    else
    {
      $choice = &defprompt("  Select choice: ","E");
    }

    print "\n";
    
    if ($choice =~ /^[EIO]/i) 
    {
      print "  Processes: $config_data->{'NPROCS'}\n\n";

      # Reset/Initialise Test Statistics
      $rundata = &ResetTestStatistics($rundata,$testdata);

      # Run all parameter files
      # run up to nparallel tests in parallel
      my $nparallel = ($ENV{'CCTK_TESTSUITE_PARALLEL_TESTS'} or 1);
      if ($nparallel == 1)
      {
        foreach $thorn (sort split(" ",$testdata->{"RUNNABLETHORNS"}))
        {
          foreach $test (split(" ",$testdata->{"$thorn RUNNABLE"}))
          {
            print "------------------------------------------------------------------------\n\n";
            print "  Test $thorn: $test \n";
           print "    \"".$testdata->{"$thorn $test DESC"}."\"\n";
            my $retcode = 0;
            if ($choice !~ /^O/i)
            {
              $retcode = &RunTest("log",$test,$thorn,$config_data,$testdata,\%runconfig);
            }
            $rundata = &CompareTestFiles($test,$thorn,\%runconfig,$rundata,$config_data,$testdata,$retcode);
            $rundata = &ReportOnTest($test,$thorn,$rundata,$testdata);
            if ($choice =~ /^I/i)
            {
               &ViewResults($test,$thorn,\%runconfig,$rundata,$testdata);
            }
          }
        }
      }
      else
      {
        my %running_tests;
        my $wait_for_test = sub {
          # get data from pipes if there is any available
          my $reads = IO::Select->new();
          my %captures;
          foreach my $pid (keys %running_tests) {
            my ($thorn,$test,$STDOUT_CAPTURE,$STDERR,$RESULTS_CAPTURE) = @{$running_tests{$pid}};
            foreach my $cap ($STDOUT_CAPTURE,$STDERR,$RESULTS_CAPTURE) {
              $captures{$cap->[0]} = \$cap->[1];
              $reads->add($cap->[0]);
            }
          }
          while (my @can_read = $reads->can_read()) {
            my $total_read = 0;
            foreach my $fh (@can_read) {
              my $read = sysread($fh, my $s, 4096*4);
              die "Could not read from pipe: $!" if not defined $read;
              $total_read += $read;
              ${$captures{$fh}} .= $s;
            }
            last if $total_read == 0; # all handles are at EOF
          }
          # peel one finished test of the list of running tests
          my $finished_test = waitpid(-1, WNOHANG);
          my $retcode = $? >> 8; # exit code of child is in high byte of status
          return if $finished_test <= 0; # no child finished
          my ($thorn,$test,$STDOUT_CAPTURE,$STDERR_CAPTURE,$RESULTS_CAPTURE) = @{$running_tests{$finished_test}};
          delete $running_tests{$finished_test};

          # read in all remaining data test's stdout, stderr and results
          my $slurp = sub {
            my ($FH) = @_;
            local $/ = undef;
            my $data = <$FH>;
            close $FH;
            return $data;
          };
          my $TESTOUT = $STDOUT_CAPTURE->[1] .= &$slurp($STDOUT_CAPTURE->[0]);
          my $TESTERR = $STDERR_CAPTURE->[1] .= &$slurp($STDERR_CAPTURE->[0]);
          my $TESTRESULTS = $RESULTS_CAPTURE->[1] .= &$slurp($RESULTS_CAPTURE->[0]);
          if ($choice !~ /^O/i)
          {
            # inject testdata values into global data structure
            my %testvalues = %{eval $TESTRESULTS};
            $testdata->{"NFAILED"} += $testvalues{"NFAILED"};
            $testdata->{"$thorn failed"} .= " ".$testvalues{"$thorn FAILED"};
            if($retcode != 0) { # subprocess exited with an error
              $testdata->{"NFAILED"} += 1;
              $testdata->{"$thorn failed"} .= " ".$test;
            }
            foreach my $key (keys %testvalues) {
              if ($key =~ /^$thorn $test /) {
                $testdata->{$key} = $testvalues{$key};
              }
            }
          }

          # handle and print output
          print "------------------------------------------------------------------------\n\n";
          print "  Test $thorn: $test \n";
          print "    \"".$testdata->{"$thorn $test DESC"}."\"\n";
          print STDOUT $TESTOUT;
          print STDERR $TESTERR;

          $rundata = &CompareTestFiles($test,$thorn,\%runconfig,$rundata,$config_data,$testdata,$retcode);

          $rundata = &ReportOnTest($test,$thorn,$rundata,$testdata);
          if ($choice =~ /^I/i)
          {
            &ViewResults($test,$thorn,\%runconfig,$rundata,$testdata);
          }
        };
        foreach $thorn (sort split(" ",$testdata->{"RUNNABLETHORNS"}))
        {
          foreach $test (split(" ",$testdata->{"$thorn RUNNABLE"}))
          {
            while(scalar keys %running_tests >= $nparallel) { # wait for a task to finish
              &$wait_for_test();
            }

            pipe(my $STDOUT_RD, my $STDOUT_WR) or die "Could not open pipe: $!";
            pipe(my $STDERR_RD, my $STDERR_WR) or die "Could not open pipe: $!";
            pipe(my $RESULTS_RD, my $RESULTS_WR) or die "Could not open pipe: $!";
            my $pid = fork(); # start a sub-process
            if(not $pid) {
              # the child process
              open(STDOUT, '>&', $STDOUT_WR) or die "Could not dup STDOUT: $!";
              open(STDERR, '>&', $STDERR_WR) or die "Could not dup STDERR $!";;
              foreach my $FH ($STDOUT_RD, $STDOUT_WR, $STDERR_RD, $STDERR_WR, $RESULTS_RD) {
                close $FH or die "Failed to close file: $!";
              }

              # these are globals updated by RunTest so I initialize them to a
              # known value that I can accumulate over
              $testdata->{"NFAILED"} = 0;
              $testdata->{"$thorn failed"} = "";

              my $retcode = 0;
              if ($choice !~ /^O/i)
              {
                $retcode = &RunTest("log",$test,$thorn,$config_data,$testdata,\%runconfig);
              }

              # get all values that need to be returned to our caller
              my %retvalues;
              foreach my $key (keys %$testdata) {
                if ($key =~ /^$thorn $test /) {
                  $retvalues{$key} = $testdata->{$key};
                }
              }
              $retvalues{"$thorn FAILED"} = $testdata->{"$thorn FAILED"};
              $retvalues{"NFAILED"} = $testdata->{"NFAILED"};
              $Data::Dumper::Terse = 1;
              print $RESULTS_WR Dumper(\%retvalues) or die "Could not write results: $!";
              close($RESULTS_WR) or die "Could not write results: $!";

              exit $retcode;
            } else {
              # the parent process
              foreach my $FH ($STDOUT_WR, $STDERR_WR, $RESULTS_WR) {
                close $FH or die "Failed to close file: $!";
              }
              if ($choice !~ /^O/i)
              {
                print "  Started test $thorn: $test \n";
              }
              $running_tests{$pid} = [$thorn,$test,[$STDOUT_RD,""],[$STDERR_RD,""],[$RESULTS_RD,""]];
            }

          }
        }
        while(scalar keys %running_tests > 0) { # wait for all tasks to finish
          &$wait_for_test();
        }
      }

      # Write results of all tests
      &WriteFullResults($rundata,$testdata,$config_data);
      
      $haverunall = 1;

    } 
    elsif ($choice =~ /^[AT]/i)
    {
      ($ntests,@tests) = &ChooseTests($choice,$testdata);
      for ($i=0;$i<$ntests;$i++)
      {
	$test  = $tests[2*$i];
	$thorn = $tests[2*$i+1];
	print "------------------------------------------------------------------------\n\n";
	print "  Test $thorn: $test\n";
	print "    \"".$testdata->{"$thorn $test DESC"}."\"\n";
        my $retcode = 0;
	$retcode = &RunTest("log",$tests[2*$i],$tests[2*$i+1],$config_data,$testdata,\%runconfig);
	$rundata = &CompareTestFiles($tests[2*$i],$tests[2*$i+1],\%runconfig,$rundata,$config_data,$testdata,$retcode);
	$rundata = &ReportOnTest($tests[2*$i],$tests[2*$i+1],$rundata,$testdata);
	&ViewResults($tests[2*$i],$tests[2*$i+1],\%runconfig,$rundata,$testdata);
      }
    }
    elsif ($choice =~ /^[RS]/i)
    {
      if ($thorn && $test)
      {
	print "------------------------------------------------------------------------\n\n";
	print "  Test $thorn: $test \n";
	print "    \"".$testdata->{"$thorn $test DESC"}."\"\n";
        my $retcode = 0;
	if ($choice =~ /^S/i)
	{
	  $retcode = &RunTest("log stdout",$test,$thorn,$config_data,$testdata,\%runconfig);
	}
	else
	{
	  $retcode = &RunTest("log",$test,$thorn,$config_data,$testdata,\%runconfig);
	}
	$rundata = &CompareTestFiles($test,$thorn,\%runconfig,$rundata,$config_data,$testdata,$retcode);
	$rundata = &ReportOnTest($test,$thorn,,$rundata,$testdata);
	&ViewResults($test,$thorn,\%runconfig,$rundata,$testdata);
      }
      else
      {
        print "  No previous test has been run\n";
      }
    }
    elsif ($choice =~ /^P/i)
    {
      if ($thorn && $test)
      {
        &PrintToleranceTable($test,$thorn,$testdata,\%runconfig);
      }
      else
      {
        print "  No previous test has been run\n";
      }
    }
    elsif ($choice =~ /^C/i)
    {
      print "  Options for customization\n";
      if ($test)
      {
        while ($choice !~ /^[AR]/i)
        {
          print "    Change absolute tolerance for this run ($test) [A]\n";
          print "    Change relative tolerance for this run ($test) [R]\n";
          $choice = &defprompt("  Select choice: ","");
          if ($choice =~ /A/i)
          {
            $runconfig{"$thorn $test ABSTOL"}{".*"} = &defprompt("  New absolute tolerance: ",$runconfig{"$thorn $test ABSTOL"}{".*"});
          }
          elsif ($choice =~ /R/i)
          {
            $runconfig{"$thorn $test RELTOL"}{".*"} = &defprompt("  New relative tolerance: ",$runconfig{"$thorn $test RELTOL"}{".*"});
          }
        }
      }
      else
      {
        while ($choice !~ /^[AR]/i)
        {
          print "    Change absolute tolerance from $runconfig{'ABSTOL'} for all further runs [A]\n";
          print "    Change relative tolerance from $runconfig{'RELTOL'} for all further runs [R]\n";
          $choice = &defprompt("  Select choice: ","");
          if ($choice =~ /^A/i)
          {
            $runconfig{"ABSTOL"} = &defprompt("  New absolute tolerance: ",$runconfig{"ABSTOL"});
          }
          elsif ($choice =~ /^R/i)
          {
            $runconfig{"RELTOL"} = &defprompt("  New relative tolerance: ",$runconfig{"RELTOL"});
          }
        }
      }
    }
    elsif ($choice =~ /^Q/i)
    {
#      $loop = 0;
    }
    else
    {
      print "  Choice not recognized, try again!\n";
    }
  }
  print "\n";
}
