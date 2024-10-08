#include "cctk.h"

module cctk_GroupsOnGH
  implicit none

  interface

     pure subroutine CCTK_VarDataPtr (ptr, GH, timelevel, fullvarname)
       implicit none
       CCTK_POINTER         , intent(out) :: ptr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: timelevel
       character(*)         , intent(in)  :: fullvarname
     end subroutine CCTK_VarDataPtr

     pure subroutine CCTK_VarDataPtrI (ptr, GH, timelevel, varindex)
       implicit none
       CCTK_POINTER         , intent(out) :: ptr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: timelevel
       integer              , intent(in)  :: varindex
     end subroutine CCTK_VarDataPtrI

     pure subroutine CCTK_VarDataPtrB (ptr, GH, timelevel, varindex, fullvarname)
       implicit none
       CCTK_POINTER         , intent(out) :: ptr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: timelevel
       integer              , intent(in)  :: varindex
       character(*)         , intent(in)  :: fullvarname
     end subroutine CCTK_VarDataPtrB

     subroutine CCTK_DisableGroupStorageI (ierr, GH, group)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: group
     end subroutine CCTK_DisableGroupStorageI

     subroutine CCTK_DisableGroupCommI (ierr, GH, group)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: group
     end subroutine CCTK_DisableGroupCommI

     subroutine CCTK_EnableGroupStorageI (ierr, GH, group)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: group
     end subroutine CCTK_EnableGroupStorageI

     subroutine CCTK_EnableGroupCommI (ierr, GH, group)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: group
     end subroutine CCTK_EnableGroupCommI

     pure subroutine CCTK_GrouplbndGN (ierr, GH, dim, lbnd, groupname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: lbnd(dim)
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_GrouplbndGN

     pure subroutine CCTK_GrouplbndVN (ierr, GH, dim, lbnd, varname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: lbnd(dim)
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_GrouplbndVN

     pure subroutine CCTK_GrouplbndGI (ierr, GH, dim, lbnd, groupindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: lbnd(dim)
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_GrouplbndGI

     pure subroutine CCTK_GrouplbndVI (ierr, GH, dim, lbnd, varindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: lbnd(dim)
       integer              , intent(in)  :: varindex
     end subroutine CCTK_GrouplbndVI

     pure subroutine CCTK_GroupubndGN (ierr, GH, dim, ubnd, groupname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: ubnd(dim)
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_GroupubndGN

     pure subroutine CCTK_GroupubndVN (ierr, GH, dim, ubnd, varname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: ubnd(dim)
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_GroupubndVN

     pure subroutine CCTK_GroupubndGI (ierr, GH, dim, ubnd, groupindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: ubnd(dim)
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_GroupubndGI

     pure subroutine CCTK_GroupubndVI (ierr, GH, dim, ubnd, varindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: ubnd(dim)
       integer              , intent(in)  :: varindex
     end subroutine CCTK_GroupubndVI

     pure subroutine CCTK_GrouplshGN (ierr, GH, dim, lsh, groupname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: lsh(dim)
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_GrouplshGN

     pure subroutine CCTK_GrouplshVN (ierr, GH, dim, lsh, varname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: lsh(dim)
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_GrouplshVN

     pure subroutine CCTK_GrouplshGI (ierr, GH, dim, lsh, groupindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: lsh(dim)
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_GrouplshGI

     pure subroutine CCTK_GrouplshVI (ierr, GH, dim, lsh, varindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: lsh(dim)
       integer              , intent(in)  :: varindex
     end subroutine CCTK_GrouplshVI

     pure subroutine CCTK_GroupashGN (ierr, GH, dim, ash, groupname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: ash(dim)
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_GroupashGN

     pure subroutine CCTK_GroupashVN (ierr, GH, dim, ash, varname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: ash(dim)
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_GroupashVN

     pure subroutine CCTK_GroupashGI (ierr, GH, dim, ash, groupindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: ash(dim)
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_GroupashGI

     pure subroutine CCTK_GroupashVI (ierr, GH, dim, ash, varindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: ash(dim)
       integer              , intent(in)  :: varindex
     end subroutine CCTK_GroupashVI

     pure subroutine CCTK_GroupgshGN (ierr, GH, dim, gsh, groupname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: gsh(dim)
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_GroupgshGN

     pure subroutine CCTK_GroupgshVN (ierr, GH, dim, gsh, varname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: gsh(dim)
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_GroupgshVN

     pure subroutine CCTK_GroupgshGI (ierr, GH, dim, gsh, groupindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: gsh(dim)
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_GroupgshGI

     pure subroutine CCTK_GroupgshVI (ierr, GH, dim, gsh, varindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: gsh(dim)
       integer              , intent(in)  :: varindex
     end subroutine CCTK_GroupgshVI

     pure subroutine CCTK_GroupbboxGN (ierr, GH, size, bbox, groupname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: size
       integer              , intent(out) :: bbox(size)
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_GroupbboxGN

     pure subroutine CCTK_GroupbboxVN (ierr, GH, size, bbox, varname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: size
       integer              , intent(out) :: bbox(size)
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_GroupbboxVN

     pure subroutine CCTK_GroupbboxGI (ierr, GH, size, bbox, groupindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: size
       integer              , intent(out) :: bbox(size)
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_GroupbboxGI

     pure subroutine CCTK_GroupbboxVI (ierr, GH, size, bbox, varindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: size
       integer              , intent(out) :: bbox(size)
       integer              , intent(in)  :: varindex
     end subroutine CCTK_GroupbboxVI

     pure subroutine CCTK_GroupnghostzonesGN (ierr, GH, dim, nghostzones, groupname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: nghostzones(dim)
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_GroupnghostzonesGN

     pure subroutine CCTK_GroupnghostzonesVN (ierr, GH, dim, nghostzones, varname)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: nghostzones(dim)
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_GroupnghostzonesVN

     pure subroutine CCTK_GroupnghostzonesGI (ierr, GH, dim, nghostzones, groupindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: nghostzones(dim)
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_GroupnghostzonesGI

     pure subroutine CCTK_GroupnghostzonesVI (ierr, GH, dim, nghostzones, varindex)
       implicit none
       integer              , intent(out) :: ierr
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: dim
       integer              , intent(out) :: nghostzones(dim)
       integer              , intent(in)  :: varindex
     end subroutine CCTK_GroupnghostzonesVI

     pure subroutine CCTK_ActiveTimeLevels (activetimelevels, GH, groupname)
       implicit none
       integer              , intent(out) :: activetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_ActiveTimeLevels

     pure subroutine CCTK_ActiveTimeLevelsGN (activetimelevels, GH, groupname)
       implicit none
       integer              , intent(out) :: activetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_ActiveTimeLevelsGN

     pure subroutine CCTK_ActiveTimeLevelsGI (activetimelevels, GH, groupindex)
       implicit none
       integer              , intent(out) :: activetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_ActiveTimeLevelsGI

     pure subroutine CCTK_ActiveTimeLevelsVN (activetimelevels, GH, varname)
       implicit none
       integer              , intent(out) :: activetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_ActiveTimeLevelsVN

     pure subroutine CCTK_ActiveTimeLevelsVI (activetimelevels, GH, varindex)
       implicit none
       integer              , intent(out) :: activetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: varindex
     end subroutine CCTK_ActiveTimeLevelsVI

     pure subroutine CCTK_MaxActiveTimeLevels (maxactivetimelevels, GH, groupname)
       implicit none
       integer              , intent(out) :: maxactivetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_MaxActiveTimeLevels

     pure subroutine CCTK_MaxActiveTimeLevelsGN (maxactivetimelevels, GH, groupname)
       implicit none
       integer              , intent(out) :: maxactivetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       character(*)         , intent(in)  :: groupname
     end subroutine CCTK_MaxActiveTimeLevelsGN

     pure subroutine CCTK_MaxActiveTimeLevelsGI (maxactivetimelevels, GH, groupindex)
       implicit none
       integer              , intent(out) :: maxactivetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: groupindex
     end subroutine CCTK_MaxActiveTimeLevelsGI

     pure subroutine CCTK_MaxActiveTimeLevelsVN (maxactivetimelevels, GH, varname)
       implicit none
       integer              , intent(out) :: maxactivetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       character(*)         , intent(in)  :: varname
     end subroutine CCTK_MaxActiveTimeLevelsVN

     pure subroutine CCTK_MaxActiveTimeLevelsVI (maxactivetimelevels, GH, varindex)
       implicit none
       integer              , intent(out) :: maxactivetimelevels
       CCTK_POINTER_TO_CONST, intent(in)  :: GH
       integer              , intent(in)  :: varindex
     end subroutine CCTK_MaxActiveTimeLevelsVI

  end interface
  
end module cctk_GroupsOnGH
