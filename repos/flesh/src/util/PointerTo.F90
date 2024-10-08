 /*@@
   @file      PointerTo.F90
   @date      Wed Jun 10 07:28:09 CDT 2020
   @author    Roland Hass
   @desc
              Fortran PointerTo function
   @enddesc
   @version   $Id$
 @@*/

#include "cctk_Types.h"

#ifdef HAVE_CCTK_F_TYPE_STAR

CCTK_POINTER function CCTK_PointerTo(var)
  use iso_c_binding, only: c_loc

  implicit none

  type(*), dimension(..), TARGET :: var
  CCTK_POINTER :: address

  address = transfer(c_loc(var), address)

  CCTK_PointerTo = address
end function

#endif /* HAVE_CCTK_F_TYPE_STAR */
