 /*@@
   @file      Startup.c
   @date      
   @author    
   @desc
              Startup routines for LocalReduce.
   @enddesc
   @version   $Id$
@@*/

#include "cctk.h"
#include "local_reductions.h"

static const char *rcsid="$Id$";

CCTK_FILEVERSION(CactusBase_LocalReduce_Startup_c);


/* prototypes of routines defined in this source file */
int LocalReduce_Startup(void);


int LocalReduce_Startup (void)
{
  /* Register the reduction operators */

  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_Mean,     "mean");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_Mean,     "average");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_Max,  "maximum");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_Min,  "minimum");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_Count,   "count");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_Sum,     "sum");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_L1,   "norm1");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_L2,   "norm2");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_L3,   "norm3");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_L4,   "norm4");
  CCTK_RegisterLocalArrayReductionOperator (LocalReduce_LInf, "norm_inf"); 


  return (0);
}
