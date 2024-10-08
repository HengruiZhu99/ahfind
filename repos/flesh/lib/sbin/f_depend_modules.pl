#!/usr/bin/perl -w

#/*@@
#  @file    f_depend_modules.pl
#  @author  Erik Schnetter
#  @date    19 January 2004
#  @desc
#           Create dependencies for Fortran 90 "use" and "include" statements
#  @enddesc
# @@*/



use strict;

my $srcfile = $ARGV[0];
my $dest = $ARGV[1];
my $srcdir = $ARGV[2];
my @otherdirs = @ARGV[3..$#ARGV];

my @suffixes = (".f77", ".f", ".f90", ".F77", ".F", ".F90");

# the list of Fortran intrinsic modules provided by the compiler, from
# https://gcc.gnu.org/onlinedocs/gcc-10.1.0/gfortran/Intrinsic-Modules.html#Intrinsic-Modules
my @intrinsic_mods = ("ISO_FORTRAN_ENV", "ISO_C_BINDING",
                      "IEEE_EXCEPTIONS", "IEEE_ARITHMETIC",  "IEEE_FEATURES",
                      "OMP_LIB", "OMP_LIB_KINDS", "OPENACC");

# a list of "intrinsic" include files. From:
# https://gcc.gnu.org/onlinedocs/gfortran/OpenMP.html
# https://www.mpi-forum.org/docs/mpi-3.1/mpi31-report/node411.htm
my @intrinsic_includes = ("omp_lib.h", "mpif.h");

print "$dest:";

my %modules;

my $line = 0;
while (<STDIN>) {
    ++$line;
    if (/^\s*#\s*(\d+)/) {
        # Line number directive from C preprocessor
        $line = $1 - 1;
    }
    elsif (/^\s*include\s*['"]([^'"]+)['"]/i) {
        # Include statement
        my $name = $1;
        my $found = 0;
        # one of the intrinsic includes?
        foreach my $include (@intrinsic_includes) {
            if ($name =~ m:^\Q$include\E\$:i) {
                $found = 1;
                last;
            }
        }
        if (!$found) {
            # Reference to an include file in this thorn?
            my @subdirs = (".", "include");
            LOOP: foreach my $subdir (@subdirs) {
                # Note: We don't use -f directly since this will match
                # the wrong case on case-insensitive file systems
                my @filenames;
                if (opendir DIR, "$srcdir/$subdir") {
                    @filenames = sort readdir DIR;
                    closedir DIR;
                }
                if (grep { $_ eq $name } @filenames) {
                    $found = 1;
                    print " \\\n  $subdir/$name";
                    last LOOP;
                }
            }
        }
        if (!$found) {
            # Reference to an include file in another thorn?
            LOOP: foreach my $otherdir (@otherdirs) {
                # Note: We could also use SUBDIRS from make.code.defn
                # here.
                # Note: This looks into the build directories, and
                # include files won't be there.
                my @subdirs = (".");
                foreach my $subdir (@subdirs) {
                    my @filenames;
                    if (opendir DIR, "$otherdir/$subdir") {
                        @filenames = sort readdir DIR;
                        closedir DIR;
                    }
                    if (grep { $_ eq $name } @filenames) {
                        $found = 1;
                        print " \\\n  $otherdir/$subdir/$name";
                        last LOOP;
                    }
                }
            }
        }
        if (!$found) {
            print STDERR "$srcfile:$line: Warning: While tracing include dependencies: Include file \"$name\" not found\n";
            if (@otherdirs) {
                print STDERR "   Searched in thorn directory and in [" . join(', ', @otherdirs) . "]\n";
            }
            else {
                print STDERR "   Searched in thorn directory only.\n";
            }
        }
    }
    elsif (/^\s*module\s+(\w+)/i) {
        # Begin of a module
        my $name = $1;
        $modules{"\L$name"} = 1;
    }
    elsif (/^\s*use\s+(\w+)/i) {
        # Use statement
        my $name = $1;
        my $found = 0;
        # one of the intrinsic modules?
        foreach my $mod (@intrinsic_mods) {
            if ($name =~ m:^\Q$mod\E$:i) {
                $found = 1;
                last;
            }
        }
        if (!$found) {
            # Reference to a module in this file?
            if ($modules{"\L$name"}) {
                $found = 1;
            }
        }
        if (!$found) {
            # Reference to a module in this thorn?
            # Look in the source directory, matching the source file
            my @subdirs = `cd '$srcdir'; find . -type d`;
            chomp @subdirs;
            LOOP: foreach my $subdir (@subdirs) {
                my @filenames;
                if (opendir DIR, "$srcdir/$subdir") {
                    @filenames = sort readdir DIR;
                    closedir DIR;
                }
                foreach my $suffix (@suffixes) {
                    foreach my $filename (@filenames) {
                        if ("\L$filename" eq "\L$name$suffix") {
                            $found = 1;
                            print " \\\n  $subdir/$filename.o";
                            last LOOP;
                        }
                    }
                }
            }
        }
        if (!$found) {
            # Reference to a module in another thorn?
            # Look in the build directory, matching the object file
            LOOP: foreach my $otherdir (@otherdirs) {
                # note: we could also use SUBDIRS from make.code.defn
                # here
                my @subdirs = `cd '$otherdir'; find . -type d`;
                chomp @subdirs;
                foreach my $subdir (@subdirs) {
                    my @filenames;
                    if (opendir DIR, "$otherdir/$subdir") {
                        @filenames = sort readdir DIR;
                        closedir DIR;
                    }
                    foreach my $suffix (@suffixes) {
                        foreach my $filename (@filenames) {
                            if ("\L$filename" eq "\L$name$suffix.o") {
                                $found = 1;
                                print " \\\n  $otherdir/$subdir/$filename";
                                last LOOP;
                            }
                        }
                    }
                }
            }
        }
        if (!$found) {
            if ("\L$name" ne "omp_lib") {
                print STDERR "$srcfile:$line: Warning: While tracing module dependencies: Source file for module \"$name\" not found\n";
                if (@otherdirs) {
                    print STDERR "   Searched in thorn directory and in [" . join(', ', @otherdirs) . "]\n";
                }
                else {
                    print STDERR "   Searched in thorn directory only.\n";
                }
            }
        }
    }
}

print "\n";
