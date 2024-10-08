#include "cctk.h"
#include "cctk_Arguments.h"
#include "cctk_Parameters.h"

#ifndef DECLARE_CCTK_ARGUMENTS_CHECKED
#define DECLARE_CCTK_ARGUMENTS_CHECKED(func) DECLARE_CCTK_ARGUMENTS
#endif



! Set the stress energy (storage) state grid scalar from the parameter.

subroutine TmunuBase_SetStressEnergyState (CCTK_ARGUMENTS)
  implicit none
  DECLARE_CCTK_ARGUMENTS_CHECKED(TmunuBase_SetStressEnergyState)
  DECLARE_CCTK_PARAMETERS
  
  stress_energy_state = stress_energy_storage
end subroutine TmunuBase_SetStressEnergyState
