#include "cctk.h"
#include "cctk_Arguments.h"

#ifndef DECLARE_CCTK_ARGUMENTS_CHECKED
#define DECLARE_CCTK_ARGUMENTS_CHECKED(func) DECLARE_CCTK_ARGUMENTS
#endif


      
! Initialise Tmunu to zero

subroutine TmunuBase_ZeroTmunu (CCTK_ARGUMENTS)
  implicit none
  DECLARE_CCTK_ARGUMENTS_CHECKED(TmunuBase_ZeroTmunu)

  eTtt = 0
  
  eTtx = 0
  eTty = 0
  eTtz = 0
  
  eTxx = 0
  eTxy = 0
  eTxz = 0
  eTyy = 0
  eTyz = 0
  eTzz = 0
  
end subroutine TmunuBase_ZeroTmunu
