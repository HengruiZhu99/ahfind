 /*@@
   @file      Network.c
   @date      Fri 19 Jan 2001
   @author    Thomas Radke
   @desc
              Network related routines
   @enddesc
   @version $Header$
 @@*/

#include "cctk_Flesh.h"
#include "cctk_WarnLevel.h"
#include "util_Network.h"

#include <string.h>
#include <errno.h>

#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif /* HAVE_UNISTD_H */
#ifdef HAVE_NETDB_H
#  include <netdb.h>
#elif defined HAVE_WINSOCK2_H
#  include <winsock2.h>
#endif /* HAVE_WINSOCK2_H */

static const char *rcsid = "$Header$";

CCTK_FILEVERSION(util_Network_c);

/********************************************************************
 *********************     Local Data Types   ***********************
 ********************************************************************/

/********************************************************************
 ********************* Local Routine Prototypes *********************
 ********************************************************************/

/********************************************************************
 ********************* Other Routine Prototypes *********************
 ********************************************************************/

/********************************************************************
 *********************     Local Data   *****************************
 ********************************************************************/

/********************************************************************
 *********************     External Routines   **********************
 ********************************************************************/

 /*@@
   @routine    Util_GetHostName
   @date       Fri Oct 20 12:12:34 2000
   @author     Tom Goodale
   @desc
               Gets the fully qualified name of this host if possible.
   @enddesc
   @calls
   @history
               just copied from thorn HTTPD
   @endhistory
   @var     name
   @vdesc   character buffer to store name in
   @vtype   char *
   @vio     out
   @vcomment

   @endvar
   @var     length
   @vdesc   length of the character buffer
   @vtype   int
   @vio     in
   @vcomment

   @endvar

@@*/
void Util_GetHostName (char *returned_name, int length)
{
  static int have_name = 0;
  static char name[256];
  
  if (! have_name)
  {
    /* gethostname does not return an error if the name does not fit, and it is
     * undefined whether or not there is a NUL byte at the end in that case. We
     * work around this by checking that the name returned is in fact shorter
     * than what would fit in the buffer. */
    int ierr = gethostname (name, sizeof name);
    if (! ierr)
    {
      name[sizeof name - 1] = '\0';
      /* I cannot tell is a name of max length has been truncated so consider
       * any string of max. length to already be too long */
      if (strlen (name) == sizeof name - 1)
      {
        ierr = ENAMETOOLONG;
      }
    }
    
    /* Does the name include the domain name? */
    if (ierr || ! strchr (name, '.'))
    {
#ifdef HAVE_GETHOSTBYNAME
      struct hostent *thishostent = 0;
#ifndef CRAY_XT
      thishostent = gethostbyname (name);
#endif
      
      if (thishostent)
      {
        strncpy (name, thishostent->h_name, sizeof name - 1);
        name[sizeof name - 1] = '\0';
      }
      else
      {
        name[0] = '\0';
      }
#endif
    }
    
    have_name = 1;
  }
  
  if (! returned_name)
  {
    CCTK_VWarn (CCTK_WARN_ABORT, __LINE__, __FILE__, "Cactus",
                "Argument \"name\" to Util_GetHostName is NULL");
  }
  if (length < 1)
  {
    CCTK_VWarn (CCTK_WARN_ABORT, __LINE__, __FILE__, "Cactus",
                "Argument \"length\" to Util_GetHostName is too small");
  }
  
  strncpy (returned_name, name, length - 1);
  returned_name[length - 1] = '\0';
}
