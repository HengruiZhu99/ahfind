#include <cctk.h>

#include "ExternalVariables.h"

void MoL_UpdateValidForInitialCopy(CCTK_ARGUMENTS)
{
  DECLARE_CCTK_ARGUMENTS;
  if (!CCTK_IsFunctionAliased("Driver_GetValidRegion"))
    return;
  for (int var = 0; var < MoLNumEvolvedVariables; var++)
  {
    int varindex = EvolvedVariableIndex[var];
    int mask1 = Driver_GetValidRegion(cctkGH,varindex,1);
    Driver_SetValidRegion(cctkGH,varindex,0,mask1);
  }
}

void MoL_UpdateValidForAdd(CCTK_ARGUMENTS)
{
  if (!CCTK_IsFunctionAliased("Driver_GetValidRegion"))
    return;
  DECLARE_CCTK_ARGUMENTS;
  for (int var = 0; var < MoLNumEvolvedVariables; var++)
  {
    int varindex = EvolvedVariableIndex[var];
    int rhsindex = RHSVariableIndex[var];
    int mask1 = Driver_GetValidRegion(cctkGH,varindex,0);
    int mask2 = Driver_GetValidRegion(cctkGH,varindex,1);
    int mask3 = Driver_GetValidRegion(cctkGH,rhsindex,0);
    int mask = mask1 & mask2 & mask3;
    Driver_SetValidRegion(cctkGH,varindex,0,mask);
  }
}
