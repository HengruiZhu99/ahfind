/*@@
  @file      GenericRK.c
  @date      Sun May 26 03:47:15 2002
  @author    Ian Hawke
  @desc
  This routine performs a generic Runge-Kutta type integration
  given the set of coefficients defined in the RKAlphaCoefficients
  and RKBetaCoefficients arrays. See the article by Shu referenced
  in the documentation for more details.
  @enddesc
  @version   $Header$
@@*/

#include "ExternalVariables.h"
#include "Operators.h"

#include <cctk.h>
#include <cctk_Arguments.h>
#include <cctk_Parameters.h>

#include <stdio.h>

static const char *rcsid = "$Header$";

CCTK_FILEVERSION(CactusBase_MoL_GenericRK_c);

/********************************************************************
 *********************     Local Data Types   ***********************
 ********************************************************************/

/********************************************************************
 ********************* Local Routine Prototypes *********************
 ********************************************************************/

static CCTK_INT AlphaIndex(CCTK_INT Step_Number, CCTK_INT Scratch_Level);

/********************************************************************
 ***************** Scheduled Routine Prototypes *********************
 ********************************************************************/

void MoL_GenericRKAdd(CCTK_ARGUMENTS);

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
  @routine    MoL_GenericRKAdd
  @date       Sun May 26 03:50:44 2002
  @author     Ian Hawke
  @desc
  Performs a single step of a generic Runge-Kutta type time
  integration.
  @enddesc
  @calls
  @calledby
  @history

  @endhistory

@@*/

void MoL_GenericRKAdd(CCTK_ARGUMENTS) {
  DECLARE_CCTK_ARGUMENTS_CHECKED(MoL_GenericRKAdd);
  DECLARE_CCTK_PARAMETERS;

  CCTK_INT rl = 0;
  if (CCTK_IsFunctionAliased("GetRefinementLevel")) {
    rl = GetRefinementLevel(cctkGH);
  }

  const int scratchspace_firstindex = CCTK_FirstVarIndex("MOL::SCRATCHSPACE");

  const CCTK_REAL dt = *Original_Delta_Time / cctkGH->cctk_timefac;

  const int mol_step = MoL_Intermediate_Steps - *MoL_Intermediate_Step;
  const CCTK_REAL beta = RKBetaCoefficients[mol_step];

  /* Real GFs */

  for (int var = 0; var < MoLNumEvolvedVariables; var++) {
    {
      if (MoL_Intermediate_Steps > 90)
        CCTK_ERROR("Internal error");
      CCTK_INT nsrcs = 0;
      CCTK_INT srcs[100];
      CCTK_INT tls[100];
      CCTK_REAL facts[100];
      srcs[nsrcs] = RHSVariableIndex[var];
      tls[nsrcs] = 0;
      facts[nsrcs] = beta * dt;
      ++nsrcs;
      for (int scratchstep = 0; scratchstep < mol_step + 1; scratchstep++) {
        CCTK_INT alphaindex = AlphaIndex(*MoL_Intermediate_Step, scratchstep);
        CCTK_REAL alpha = RKAlphaCoefficients[alphaindex];
        if (alpha != 0.0) {
          if (scratchstep == 0) {
            srcs[nsrcs] = EvolvedVariableIndex[var];
            tls[nsrcs] = 1;
          } else {
            CCTK_INT scratchindex = scratchstep - 1;
            srcs[nsrcs] = scratchspace_firstindex + scratchindex;
            tls[nsrcs] = var;
          }
          facts[nsrcs] = alpha;
          ++nsrcs;
        }
      }
      CCTK_INT dst = EvolvedVariableIndex[var];
      CCTK_INT tl = 0;
      MoL_LinearCombination(cctkGH, dst, rl, tl, 0.0, srcs, tls, facts, nsrcs);
    }

    if (*MoL_Intermediate_Step > 1) {
      const CCTK_INT nsrcs = 1;
      const CCTK_INT srcs[] = {EvolvedVariableIndex[var]};
      const CCTK_INT tls[] = {0};
      const CCTK_REAL facts[] = {1.0};
      const CCTK_INT dst = scratchspace_firstindex + mol_step;
      const CCTK_INT tl = var;
      MoL_LinearCombination(cctkGH, dst, rl, tl, 0.0, srcs, tls, facts, nsrcs);
    }
  }

  /* Real arrays */

  /* #define MOLDEBUGARRAYS 1 */

  CCTK_INT arrayscratchlocation = 0;

#ifdef MOLDEBUGARRAYS
  CCTK_VWarn(1, __LINE__, __FILE__, CCTK_THORNSTRING,
             "Array sizes are %d %d %d\n", MoL_Max_Evolved_Array_Size,
             arraytotalsize, singlearraysize);
#endif

  for (int var = 0; var < MoLNumEvolvedArrayVariables; var++) {

    CCTK_REAL *restrict UpdateVar = (CCTK_REAL *)CCTK_VarDataPtrI(
        cctkGH, 0, EvolvedArrayVariableIndex[var]);
    CCTK_REAL const *restrict RHSVar = (CCTK_REAL const *)CCTK_VarDataPtrI(
        cctkGH, 0, RHSArrayVariableIndex[var]);

    CCTK_INT arraytotalsize = ArrayScratchSizes[var];

#pragma omp /*parallel for*/ simd
    for (int index = 0; index < arraytotalsize; index++) {
      UpdateVar[index] =
          (*Original_Delta_Time) / cctkGH->cctk_timefac * beta * RHSVar[index];
    }

    for (int scratchstep = 0; scratchstep < mol_step + 1; scratchstep++) {

      const CCTK_INT alphaindex =
          AlphaIndex(*MoL_Intermediate_Step, scratchstep);
      const CCTK_INT scratchindex = scratchstep - 1;

      const CCTK_REAL alpha = RKAlphaCoefficients[alphaindex];

      CCTK_REAL *restrict ScratchVar;
      if (scratchstep) {
        ScratchVar = &ArrayScratchSpace[scratchindex * CurrentArrayScratchSize +
                                        arrayscratchlocation];
      } else {
        ScratchVar =
            CCTK_VarDataPtrI(cctkGH, 1, EvolvedArrayVariableIndex[var]);
      }

      if ((alpha > MoL_Tiny) || (alpha < -MoL_Tiny)) {
#pragma omp /*parallel for*/ simd
        for (int index = 0; index < arraytotalsize; index++) {
          UpdateVar[index] += alpha * ScratchVar[index];
#ifdef MOLDEBUGARRAYS
          if (CCTK_EQUALS(verbose, "extreme")) {
            CCTK_VWarn(1, __LINE__, __FILE__, CCTK_THORNSTRING,
                       "Variable: %d. Index: %d. step: %d. "
                       "alpha: %f. Scratch: %f. q: %f.\n",
                       var, index, *MoL_Intermediate_Step, alpha,
                       ScratchVar[index], UpdateVar[index]);
          }
#endif
        }
      }
    }

    arrayscratchlocation += arraytotalsize;
  }

  arrayscratchlocation = 0;

  if (*MoL_Intermediate_Step > 1) {
    for (int var = 0; var < MoLNumEvolvedArrayVariables; var++) {
      const CCTK_REAL *restrict const UpdateVar =
          CCTK_VarDataPtrI(cctkGH, 0, EvolvedArrayVariableIndex[var]);
      CCTK_REAL *restrict const ScratchVar =
          &ArrayScratchSpace[mol_step * CurrentArrayScratchSize +
                             // singlearraysize +
                             // (MoL_Max_Evolved_Array_Size+1) +
                             arrayscratchlocation];

      CCTK_INT arraytotalsize = ArrayScratchSizes[var];

#ifdef MOLDEBUGARRAYS
      CCTK_VWarn(1, __LINE__, __FILE__, CCTK_THORNSTRING,
                 "Writing to scratch space, initial address %ld, index %d \n",
                 ScratchVar,
                 mol_step * CurrentArrayScratchSize + arrayscratchlocation);
#endif
#pragma omp /*parallel for*/ simd
      for (int index = 0; index < arraytotalsize; index++) {
        ScratchVar[index] = UpdateVar[index];
#ifdef MOLDEBUGARRAYS
        if (CCTK_EQUALS(verbose, "extreme")) {
          CCTK_VWarn(1, __LINE__, __FILE__, CCTK_THORNSTRING,
                     "Variable: %d. Index: %d. step: %d. Scratch: %f.\n", var,
                     index, *MoL_Intermediate_Step, ScratchVar[index]);
        }
#endif
      }
      arrayscratchlocation += arraytotalsize;
    }
  }

  return;
}

/********************************************************************
 *********************     Local Routines   *************************
 ********************************************************************/

static CCTK_INT AlphaIndex(CCTK_INT Step_Number, CCTK_INT Scratch_Level) {
  DECLARE_CCTK_PARAMETERS;

  return (MoL_Intermediate_Steps - Step_Number) * MoL_Intermediate_Steps +
         Scratch_Level;
}
