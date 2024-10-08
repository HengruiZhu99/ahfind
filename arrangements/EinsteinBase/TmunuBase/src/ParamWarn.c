#include "cctk.h"
#include "cctk_Arguments.h"
#include "cctk_Parameters.h"

void TmunuBase_ParamCheck(CCTK_ARGUMENTS)
{
  DECLARE_CCTK_PARAMETERS;

  if(support_old_CalcTmunu_mechanism) {
    CCTK_PARAMWARN("TmunuBase::support_old_CalcTmunu_mechanism = yes is no longer supported");
  }
}
