 /*@@
   @file      File.c
   @date      September 6th 1999
   @author    Gabrielle Allen
   @desc
              File Handling routines
   @enddesc
   @version   $Id$
 @@*/             

#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "cctk_Flesh.h"
#include "cctk_WarnLevel.h"
#include "cctk_FortranString.h"

#include "util_String.h"

static const char *rcsid = "$Header$";

CCTK_FILEVERSION(util_File_c);

/********************************************************************
 *********************    Macro Definitions   ***********************
 ********************************************************************/

/* some systems (eg. Windows NT) don't define this macro */
#ifndef S_ISDIR
#define S_ISDIR(mode)   (((mode) & S_IFMT) == S_IFDIR)
#endif

/* Some systems don't have mode_t and only pass one argument to mkdir. */
#ifdef HAVE_MODE_T
#define MKDIR_WRAPPER(a,b) mkdir(a,b)
#else
#define MKDIR_WRAPPER(a,b) mkdir(a)
#endif


/********************************************************************
 *********************    External Functions   **********************
 ********************************************************************/
void CCTK_FCALL CCTK_FNAME (CCTK_CreateDirectory)
                           (int *ierr, int *mode, ONE_FORTSTRING_ARG);


 /*@@
   @routine    CCTK_CreateDirectory
   @date       Tue May  2 21:38:48 2000
   @author     Tom Goodale
   @desc
               Creates all directories necessary for the path to exist.
   @enddesc
   @calls      mkdir

   @var        mode
   @vdesc      permissions of the directory to be created
   @vtype      int
   @vio        in
   @vcomment   This is the unix mode, e.g. 0755
   @endvar
   @var        pathname
   @vdesc      Name of directory path to create
   @vtype      const char *
   @vio        in
   @endvar 

   @returntype int
   @returndesc  1 - directory path already exists
                0 - directory path successfully created
               -1 - failed to allocate some temporary memory
               -2 - failed to create a directory path component
               -3 - directory path component exists but is not a directory
   @endreturndesc
@@*/
int CCTK_CreateDirectory (int mode, const char *pathname)
{
  int retval;
  const char *path;
  size_t maxlength_current;
  char *current;
  const char *token;
  struct stat statbuf;


  maxlength_current = strlen (pathname);
  current = (char *) malloc (maxlength_current + 1);
  if (current)
  {
    retval = 0;
    current[0] = '\0';

    path = pathname;
    while ((token = Util_StrSep (&path, "/")))
    {
      /* Treat first token carefully. */
      if (*current)
      {
        assert (strlen(current) + 1 + strlen(token) <= maxlength_current);
        sprintf (current + strlen(current), "/%s", token);
      }
      else
      {
        assert ((*token ? strlen(token) : 1) <= maxlength_current);
        strcpy (current, *token ? token : "/");
      }

      if (stat (current, &statbuf))
      {
        if (MKDIR_WRAPPER (current, mode) == -1)
        {
          retval = errno == EEXIST ? 1 : -2;
        }
      }
      else if (! S_ISDIR (statbuf.st_mode))
      {
        retval = -3;
      }
      else
      {
        retval = 1;
      }

      if (retval < 0)
      {
        break;
      }
    }

    if (retval >= 0)
    {
      /* Deal with last component of path */
      if ((size_t) (path - pathname) < strlen (pathname))
      {
        if (stat (pathname, &statbuf))
        {
          retval = 0;
          if (MKDIR_WRAPPER (pathname, mode) == -1)
          {
            retval = errno == EEXIST ? 1 : -2;
          }
        }
        else if (! S_ISDIR (statbuf.st_mode))
        {
          retval = -3;
        }
        else
        {
          retval = 1;
        }
      }
    }

    free (current);

  }
  else
  {
    retval = -1;
  }

  return (retval);
}


void CCTK_FCALL CCTK_FNAME (CCTK_CreateDirectory)
                           (int *ierr, int *mode, ONE_FORTSTRING_ARG)
{
  ONE_FORTSTRING_CREATE (dirname)
  *ierr = CCTK_CreateDirectory (*mode, dirname);
  free (dirname); 
}
