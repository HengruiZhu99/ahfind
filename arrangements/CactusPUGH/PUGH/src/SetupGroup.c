 /*@@
   @file      SetupGroup.c
   @date      Mon Feb  8 19:31:45 1999
   @author    Tom Goodale
   @desc
              Subroutines for setting up a group on a pGH.
   @enddesc
   @version   $Id$
 @@*/


#include <stdlib.h>
#include <string.h>

#include "pugh.h"
#include "pughi.h"

#include "cctk_Parameters.h"

static const char *rcsid = "$Header$";

CCTK_FILEVERSION (CactusPUGH_PUGH_SetupGroup_c);


/********************************************************************
 ********************    Internal Routines   ************************
 ********************************************************************/
static int PUGH_SetupGAGroup (pGH *newGH,
                              int *nsize,
                              int *ghostsize,
                              int  gtype,
                              int  vtype,
                              int  dim,
                              int  n_variables,
                              int  vectorlength,
                              int  n_timelevels);


 /*@@
   @routine    PUGH_SetupGAGroup
   @date       January 19 2000
   @author     Gabrielle Allen
   @desc
               Set up a group of grid array variables on a pGH.
   @enddesc
   @calls      CCTK_VarTypeSize
               PUGH_SetupConnectivity
               PUGH_SetupPGExtras
               PUGH_SetupGArrayGroupComm
               PUGH_SetupGArray

   @var        newGH
   @vdesc      Pointer to PUGH grid hierarchy
   @vtype      pGH *
   @vio        in
   @endvar
   @var        nsize
   @vdesc      size dimensions for variables in this group
   @vtype      int *
   @vio        in
   @endvar
   @var        ghostsize
   @vdesc      ghostsize dimensions for variables in this group
   @vtype      int *
   @vio        in
   @endvar
   @var        gtype
   @vdesc      group type
   @vtype      int
   @vio        in
   @endvar
   @var        vtype
   @vdesc      CCTK data type for variables in this group
   @vtype      int
   @vio        in
   @endvar
   @var        dim
   @vdesc      number of dimensions for variables in this group
   @vtype      int
   @vio        in
   @endvar
   @var        n_variables
   @vdesc      number of variables in this group
   @vtype      int
   @vio        in
   @endvar
   @var        n_timelevels
   @vdesc      number of timelevels in this group
   @vtype      int
   @vio        in
   @endvar

   @returntype int
   @returndesc
               PUGH_SUCCESS (0) if successful, or
               PUGH_ERRORMEMORY (negative) if memory allocation failed
   @endreturndesc
@@*/
static int PUGH_SetupGAGroup (pGH *newGH,
                              int *nsize,
                              int *ghostsize,
                              int  gtype,
                              int  vtype,
                              int  dim,
                              int  n_variables,
                              int  vectorlength,
                              int  n_timelevels)
{
  int i;
  int           variable;
  int           var_size;
  int           retval;
  int           level;
  void       ***temp1;
  int          *temp2, *temp3;
  pConnectivity *connectivity;
  pGExtras      *extras;
  pComm         *groupcomm;
  int *perme;
  int *nprocs;


  retval = PUGH_SUCCESS;
  var_size = CCTK_VarTypeSize (vtype);

  if (gtype == CCTK_ARRAY || gtype == CCTK_SCALAR)
  {
    if (n_variables > 0)
    {
      /* Arrays can't (yet) have periodicity and manual setup,
         so initialize them to zero */
      perme = calloc (dim, sizeof (int));
      nprocs = calloc (dim, sizeof (int));
      if (dim && ! (perme && nprocs))
      {
        CCTK_WARN (0, "Memory allocation error in PUGH_SetupGAGroup");
      }

      PUGH_SetupDefaultTopology (dim, nprocs);

      /* Check that there are enough grid points in this dimension
       * to make parallelising it worthwhile
       */
      for (i = 0 ; i < dim; i++)
      {
        if (abs (nsize[i]) > 0 && abs (nsize[i]) <= 2*ghostsize[i])
        {
          nprocs[i] = 1;
        }
      }

      connectivity = PUGH_SetupConnectivity (dim, newGH->nprocs, nsize,
					     ghostsize, nprocs, perme);

      extras = PUGH_SetupPGExtras (0, dim, perme, nsize, ghostsize,
                                   newGH->nprocs, connectivity->nprocs, 
                                   connectivity->neighbours, newGH->myproc);

      free (nprocs);
      free (perme);
    }
    else
    {
      connectivity = NULL;
      extras = NULL;
    }
  }
  else
  {
    /* this is for CCTK_GF variables */
    if (dim <= 0)
      CCTK_VWarn (0, __LINE__, __FILE__, "PUGH", "Dimension in function PUGH_SetupGAGroup is less than or equal to zero" );
    connectivity = newGH->Connectivity[dim-1];
    extras = newGH->GFExtras[dim-1];
  }

  /* Set up the communication buffer used for all variables within this group.
     Note: only with allocated buffers we can have group communication. */
  groupcomm = NULL;
  if(n_variables > 0 && newGH->commmodel == PUGH_ALLOCATEDBUFFERS)
  {
    groupcomm = PUGH_SetupGArrayGroupComm (newGH,
                                           dim,
                                           newGH->nvariables,
                                           n_variables,
                                           vtype,
                                           0,
                                           extras);
  }

  temp1 = realloc (newGH->variables, (newGH->nvariables+n_variables) *
                                    sizeof (void **));
  temp2 = realloc (newGH->activetimelevels, (newGH->nvariables+n_variables) *
                                            sizeof (int));
  temp3 = realloc (newGH->maxtimelevels, (newGH->nvariables+n_variables) *
                                         sizeof (int));
  if(newGH->nvariables+n_variables==0 || (temp1 && temp2 && temp3))
  {
    newGH->variables = temp1;
    newGH->activetimelevels = temp2;
    newGH->maxtimelevels = temp3;

    for (variable = 0; variable < n_variables; variable++)
    {
      newGH->variables[newGH->nvariables] = malloc (n_timelevels *
                                                    sizeof (void *));
      newGH->activetimelevels[newGH->nvariables] = 0;
      newGH->maxtimelevels[newGH->nvariables] = n_timelevels;

      if (newGH->variables[newGH->nvariables])
      {
        for (level = 0; level < n_timelevels; level++)
        {
          newGH->variables[newGH->nvariables][level] =
            PUGH_SetupGArray (newGH,
                              extras,
                              connectivity,
                              groupcomm,
                              CCTK_VarName (newGH->nvariables),
                              newGH->nvariables,
                              newGH->narrays,
                              var_size,
                              vtype,
                              vectorlength,
                              variable%vectorlength,
                              variable%vectorlength > 0 ? newGH->variables[newGH->nvariables - variable%vectorlength][level] : NULL);
          newGH->narrays++;
        }
        newGH->nvariables++;
      }
      else
      {
        retval = PUGH_ERRORMEMORY;
        break;
      }
    }
  }
  else
  {
    free (temp3);
    free (temp2);
    free (temp1);
    retval = PUGH_ERRORMEMORY;
  }

  if (retval)
  {
    CCTK_WARN (1, "Memory allocation error in PUGH_SetupGAGroup");
  }

  return (retval);
}


 /*@@
   @routine    PUGH_SetupGroup
   @date       Mon Feb  8 19:37:55 1999
   @author     Tom Goodale
   @desc
               Sets up a group on a pGH
   @enddesc
   @calls      PUGH_SetupGAGroup

   @var        newGH
   @vdesc      Pointer to PUGH grid hierarchy
   @vtype      pGH *
   @vio        in
   @endvar
   @var        nsize
   @vdesc      size dimensions for variables in this group
   @vtype      int *
   @vio        in
   @endvar
   @var        ghostsize
   @vdesc      ghostsize dimensions for variables in this group
   @vtype      int *
   @vio        in
   @endvar
   @var        gtype
   @vdesc      group type
   @vtype      int
   @vio        in
   @endvar
   @var        vtype
   @vdesc      CCTK data type for variables in this group
   @vtype      int
   @vio        in
   @endvar
   @var        dim
   @vdesc      number of dimensions for variables in this group
   @vtype      int
   @vio        in
   @endvar
   @var        n_variables
   @vdesc      number of variables in this group
   @vtype      int
   @vio        in
   @endvar
   @var        n_timelevels
   @vdesc      number of timelevels in this group
   @vtype      int
   @vio        in
   @endvar
   @var        vectorgroup
   @vdesc      is this a vector group ?
   @vtype      int
   @vio        in
   @endvar

   @returntype int
   @returndesc
               return code of @seeroutine PUGH_SetupGAGroup, or
               PUGH_ERROR if invalid group type was passed in
   @endreturndesc
@@*/
int PUGH_SetupGroup (pGH *newGH,
                     int *nsize,
                     int *nghostsize,
                     int  gtype,
                     int  vtype,
                     int  dim,
                     int  n_variables,
                     int  vectorlength,
                     int  n_timelevels,
                     int  vectorgroup)
{
  int retval;


  (void) (vectorgroup + 0);
  retval = PUGH_SetupGAGroup (newGH, nsize, nghostsize, gtype, vtype, dim,
                              n_variables, vectorlength,
                              n_timelevels);

  return (retval);
}
