 /*@@
   @file      ExternalVariables.h
   @date      Wed May 22 02:32:10 2002
   @author    Ian Hawke
   @desc 
   The header file containing the local variables used across routines.
   These are the arrays containing GF indexes for all types of variables,
   and the number of each type of variable currently in use (the 
   parameters only give the maximum possible number).
   No function prototypes are defined in this file, so we do not protect
   it with an ifdef so that we can do inclusion within multiple routines
   in the same file.
   @enddesc 
   @version   $Header$
 @@*/


#include <cctk.h>


extern CCTK_INT *restrict EvolvedVariableIndex;
extern CCTK_INT *restrict EvolvedVariableIndexSlow;
extern CCTK_INT *restrict RHSVariableIndex;
extern CCTK_INT *restrict RHSVariableIndexSlow;
extern CCTK_INT *restrict ConstrainedVariableIndex;
extern CCTK_INT *restrict SandRVariableIndex;


extern CCTK_INT MoLNumEvolvedVariables;
extern CCTK_INT MoLNumEvolvedVariablesSlow;
extern CCTK_INT MoLNumConstrainedVariables;
extern CCTK_INT MoLNumSandRVariables;



extern CCTK_INT *restrict EvolvedArrayVariableIndex;
extern CCTK_INT *restrict RHSArrayVariableIndex;
extern CCTK_INT *restrict ConstrainedArrayVariableIndex;
extern CCTK_INT *restrict SandRArrayVariableIndex;


extern CCTK_INT MoLNumEvolvedArrayVariables;
extern CCTK_INT MoLNumConstrainedArrayVariables;
extern CCTK_INT MoLNumSandRArrayVariables;



extern CCTK_INT ScheduleStatus;


extern CCTK_REAL *restrict ArrayScratchSpace;
extern CCTK_INT *restrict ArrayScratchSizes;
extern CCTK_INT CurrentArrayScratchSize;

extern CCTK_REAL *restrict ArrayErrorSpace;
extern CCTK_INT *restrict ArrayErrorSizes;
extern CCTK_INT CurrentArrayErrorSize;

extern CCTK_INT MoLMaxNumRegisteredVariables;
