#include "cctk.h"

module cctk_Groups
  implicit none

  interface

     pure subroutine CCTK_DecomposeName (ierr, fullname, implementation, implementation_nchars, name, name_nchars)
       implicit none
       integer     , intent(out) :: ierr
       character(*), intent(in)  :: fullname
       character(*), intent(out) :: implementation
       integer     , intent(in)  :: implementation_nchars
       character(*), intent(in)  :: name
       integer     , intent(out) :: name_nchars
     end subroutine CCTK_DecomposeName

     pure subroutine CCTK_FirstVarIndex (index, group)
       implicit none
       integer     , intent(out) :: index
       character(*), intent(in)  :: group
     end subroutine CCTK_FirstVarIndex

     pure subroutine CCTK_FirstVarIndexI (index, group)
       implicit none
       integer, intent(out) :: index
       integer, intent(in)  :: group
     end subroutine CCTK_FirstVarIndexI

     pure subroutine CCTK_FullName (nchars, var, fullname)
       implicit none
       integer     , intent(in)  :: nchars
       integer     , intent(in)  :: var
       character(*), intent(out) :: fullname
     end subroutine CCTK_FullName

     ! CCTK_GroupData fills a structure and has no Fortran wrapper
     
     pure subroutine CCTK_GroupDimI (dim, group)
       implicit none
       integer, intent(out) :: dim
       integer, intent(in)  :: group
     end subroutine CCTK_GroupDimI
     
     pure subroutine CCTK_GroupDimFromVarI (dim, var)
       implicit none
       integer, intent(out) :: dim
       integer, intent(in)  :: var
     end subroutine CCTK_GroupDimFromVarI

     pure subroutine CCTK_GroupDistribNumber (number, distrib)
       implicit none
       integer     , intent(out) :: number
       character(*), intent(in)  :: distrib
     end subroutine CCTK_GroupDistribNumber
     
     ! CCTK_GroupGhostsizesI is a strange function and has no Fortran wrapper

     pure subroutine CCTK_ImplementationI (nchars, group, implementation)
       implicit none
       integer     , intent(in)  :: nchars
       integer     , intent(in)  :: group
       character(*), intent(out) :: implementation
     end subroutine CCTK_ImplementationI

     pure subroutine CCTK_GroupIndex (index, group)
       implicit none
       integer     , intent(out) :: index
       character(*), intent(in)  :: group
     end subroutine CCTK_GroupIndex

     pure subroutine CCTK_GroupIndexFromVar (index, var)
       implicit none
       integer     , intent(out) :: index
       character(*), intent(in)  :: var
     end subroutine CCTK_GroupIndexFromVar

     pure subroutine CCTK_GroupIndexFromVarI (index, var)
       implicit none
       integer, intent(out) :: index
       integer, intent(in)  :: var
     end subroutine CCTK_GroupIndexFromVarI

     pure subroutine CCTK_GroupName (nchars, group, groupname)
       implicit none
       integer     , intent(in)  :: nchars
       integer     , intent(in)  :: group
       character(*), intent(out) :: groupname
     end subroutine CCTK_GroupName
     
     pure subroutine CCTK_GroupNameFromVarI (nchars, var, groupname)
       implicit none
       integer     , intent(in)  :: nchars
       integer     , intent(in)  :: var
       character(*), intent(out) :: groupname
     end subroutine CCTK_GroupNameFromVarI

     pure subroutine CCTK_GroupScopeNumber (number, scope)
       implicit none
       integer     , intent(out) :: number
       character(*), intent(in)  :: scope
     end subroutine CCTK_GroupScopeNumber
     
     ! CCTK_GroupSizesI is a strange function and has no Fortran wrapper
     
     pure subroutine CCTK_GroupTypeFromVarI (type, var)
       implicit none
       integer, intent(out) :: type
       integer, intent(in)  :: var
     end subroutine CCTK_GroupTypeFromVarI

     pure subroutine CCTK_GroupTypeNumber (number, type)
       implicit none
       integer     , intent(out) :: number
       character(*), intent(in)  :: type
     end subroutine CCTK_GroupTypeNumber
     
     pure subroutine CCTK_GroupTypeI (type, group)
       implicit none
       integer, intent(out) :: type
       integer, intent(in)  :: group
     end subroutine CCTK_GroupTypeI
     
     pure subroutine CCTK_ImpFromVarI (nchars, var, imp)
       implicit none
       integer     , intent(in)  :: nchars
       integer     , intent(in)  :: var
       character(*), intent(out) :: imp
     end subroutine CCTK_ImpFromVarI
     
     pure subroutine CCTK_MaxDim (maxdim)
       implicit none
       integer, intent(out) :: maxdim
     end subroutine CCTK_MaxDim
     
     pure subroutine CCTK_NumGroups (numgroups)
       implicit none
       integer, intent(out) :: numgroups
     end subroutine CCTK_NumGroups
     
     pure subroutine CCTK_NumTimeLevelsFromVar (numtimelevels, var)
       implicit none
       integer     , intent(out) :: numtimelevels
       character(*), intent(in)  :: var
     end subroutine CCTK_NumTimeLevelsFromVar
     
     pure subroutine CCTK_NumTimeLevelsFromVarI (numtimelevels, var)
       implicit none
       integer, intent(out) :: numtimelevels
       integer, intent(in)  :: var
     end subroutine CCTK_NumTimeLevelsFromVarI
     
     pure subroutine CCTK_NumTimeLevels (numtimelevels, var)
       implicit none
       integer     , intent(out) :: numtimelevels
       character(*), intent(in)  :: var
     end subroutine CCTK_NumTimeLevels
     
     pure subroutine CCTK_NumTimeLevelsI (numtimelevels, var)
       implicit none
       integer, intent(out) :: numtimelevels
       integer, intent(in)  :: var
     end subroutine CCTK_NumTimeLevelsI
     
     pure subroutine CCTK_MaxTimeLevels (maxtimelevels, group)
       implicit none
       integer     , intent(out) :: maxtimelevels
       character(*), intent(in)  :: group
     end subroutine CCTK_MaxTimeLevels
     
     pure subroutine CCTK_MaxTimeLevelsVN (maxtimelevels, var)
       implicit none
       integer     , intent(out) :: maxtimelevels
       character(*), intent(in)  :: var
     end subroutine CCTK_MaxTimeLevelsVN
     
     pure subroutine CCTK_MaxTimeLevelsVI (maxtimelevels, var)
       implicit none
       integer, intent(out) :: maxtimelevels
       integer, intent(in)  :: var
     end subroutine CCTK_MaxTimeLevelsVI
     
     pure subroutine CCTK_MaxTimeLevelsGN (maxtimelevels, group)
       implicit none
       integer     , intent(out) :: maxtimelevels
       character(*), intent(in)  :: group
     end subroutine CCTK_MaxTimeLevelsGN
     
     pure subroutine CCTK_MaxTimeLevelsGI (maxtimelevels, group)
       implicit none
       integer, intent(out) :: maxtimelevels
       integer, intent(in)  :: group
     end subroutine CCTK_MaxTimeLevelsGI
     
     pure subroutine CCTK_NumVars (numvars)
       implicit none
       integer, intent(out) :: numvars
     end subroutine CCTK_NumVars
     
     pure subroutine CCTK_NumVarsInGroup (numvars, group)
       implicit none
       integer     , intent(out) :: numvars
       character(*), intent(in)  :: group
     end subroutine CCTK_NumVarsInGroup
     
     pure subroutine CCTK_NumVarsInGroupI (numvars, group)
       implicit none
       integer, intent(out) :: numvars
       integer, intent(in)  :: group
     end subroutine CCTK_NumVarsInGroupI
     
     pure subroutine CCTK_VarIndex (index, var)
       implicit none
       integer     , intent(out) :: index
       character(*), intent(in)  :: var
     end subroutine CCTK_VarIndex
     
     pure subroutine CCTK_VarName (nchars, var, varname)
       implicit none
       integer     , intent(in)  :: nchars
       integer     , intent(in)  :: var
       character(*), intent(out) :: varname
     end subroutine CCTK_VarName
     
     pure subroutine CCTK_VarTypeI (type, var)
       implicit none
       integer, intent(out) :: type
       integer, intent(in)  :: var
     end subroutine CCTK_VarTypeI
     
     pure subroutine CCTK_VarTypeNumber (number, type)
       implicit none
       integer     , intent(out) :: number
       character(*), intent(in)  :: type
     end subroutine CCTK_VarTypeNumber
     
     pure subroutine CCTK_VarTypeName (nchars, type, typename)
       implicit none
       integer     , intent(in)  :: nchars
       integer     , intent(in)  :: type
       character(*), intent(out) :: typename
     end subroutine CCTK_VarTypeName
     
     pure subroutine CCTK_VarTypeSize (size, type)
       implicit none
       integer, intent(out) :: size
       integer, intent(in)  :: type
     end subroutine CCTK_VarTypeSize
     
     ! CCTKi_GroupLengthAsPointer is a strange function and has no
     ! Fortran wrapper

     ! CCTK_TraverseString has no Fortran wrapper
     
     pure subroutine CCTK_GroupTagsTable (table, group)
       implicit none
       integer     , intent(out) :: table
       character(*), intent(in)  :: group
     end subroutine CCTK_GroupTagsTable
     
     pure subroutine CCTK_GroupTagsTableI (table, group)
       implicit none
       integer, intent(out) :: table
       integer, intent(in)  :: group
     end subroutine CCTK_GroupTagsTableI
     
  end interface
  
end module cctk_Groups
