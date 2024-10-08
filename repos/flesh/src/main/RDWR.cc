#include "cctk_Flesh.h"
#include "cctk_Groups.h"
#include "cctk_Misc.h"
#include "cctk_WarnLevel.h"

#include "cctk_Schedule.h"
#include "cctk_Parameters.h"

#include "cctki_PreSync.h"

#include <algorithm>
#include <cassert>
#include <cstdio>
#include <cstring>
#include <set>
#include <sstream>
#include <iostream>

// this cannot go into the anonymous namespace below or STL won't find it, but
// I do not want to make the operator visible globally either
static
bool operator<(const RDWR_entry v1,const RDWR_entry v2){
    if(v1.varindex < v2.varindex) return true;
    if(v1.varindex > v2.varindex) return false;
    if(v1.timelevel < v2.timelevel) return true;
    return false;
}

namespace cctki_RDWR {

enum rdwr_t { reads_t, writes_t, invalidates_t };

void add_entry(int vi,int tl,rdwr_t rdwr,int where,cFunctionData* func,std::set<RDWR_entry>& s) {
    DECLARE_CCTK_PARAMETERS;

    RDWR_entry entry;
    entry.varindex = vi;
    entry.timelevel = tl;
    auto iter = s.find(entry);
    if(iter == s.end()) {
        entry.where_wr = CCTK_VALID_NOWHERE;
        entry.where_rd = CCTK_VALID_NOWHERE;
        entry.where_inv = CCTK_VALID_NOWHERE;
    } else {
        if(!CCTK_Equals(presync_mode, "off")) {
          if(rdwr == writes_t && iter->where_wr != CCTK_VALID_NOWHERE) {
              const int level = CCTK_Equals(presync_mode, "warn-only") ?
                                 CCTK_WARN_ALERT : CCTK_WARN_ABORT;
              CCTK_VWarn(level,__LINE__,__FILE__,"Cactus",
                          "Duplicate write specification for %s in function %s::%s",
                          CCTK_FullVarName(vi),func->thorn,func->routine);
          }
          if(rdwr == reads_t && iter->where_rd != CCTK_VALID_NOWHERE) {
              const int level = CCTK_Equals(presync_mode, "warn-only") ?
                                 CCTK_WARN_ALERT : CCTK_WARN_ABORT;
              CCTK_VWarn(level,__LINE__,__FILE__,"Cactus",
                          "Duplicate reads specification for %s in function %s::%s",
                          CCTK_FullVarName(vi),func->thorn,func->routine);
          }
          if(rdwr == invalidates_t && iter->where_inv != CCTK_VALID_NOWHERE) {
              const int level = CCTK_Equals(presync_mode, "warn-only") ?
                                 CCTK_WARN_ALERT : CCTK_WARN_ABORT;
              CCTK_VWarn(level,__LINE__,__FILE__,"Cactus",
                          "Duplicate invalidates specification for %s in function %s::%s",
                          CCTK_FullVarName(vi),func->thorn,func->routine);
          }
        }
        entry.where_wr = iter->where_wr;
        entry.where_rd = iter->where_rd;
        entry.where_inv = iter->where_inv;
        s.erase(iter);
    }
    if(rdwr == writes_t) {
        entry.where_wr |= where;
    } else if(rdwr == reads_t) {
        entry.where_rd |= where;
    } else if(rdwr == invalidates_t) {
        entry.where_inv |= where;
    } else {
      CCTK_BUILTIN_UNREACHABLE();
    }
    s.insert(entry);
}

/**
 * The following parser assumes that all values for "str" will be
 * of the form IMPL::VAR_OR_GROUP(WHERE), where WHERE must be either everywhere,
 * interior, or boundary. The name IMPL refers to a thorn or implemenation name,
 * and VAR_OR_GROUP refers to a variable or group name. In either case, a suffix
 * of _p indicates a past time level, i.e. "foo_p" refers to "foo" at time level 1.
 */
void parse(const char *str,rdwr_t rdwr,cFunctionData* func,std::set<RDWR_entry>& s) {
    DECLARE_CCTK_PARAMETERS;

    const char* rdwr_s = rdwr == reads_t ? "READS" : rdwr == writes_t ?
                                          "WRITES" : "INVALIDATES";

    char varbuf[256], where[256];
    int vecnum = -1;
    if(sscanf(str, "%256[^[][%d](%256[^)])", varbuf, &vecnum, where) != 3 and
       sscanf(str, "%256[^(](%256[^)])", varbuf, where) != 2) {
        CCTK_VError(__LINE__,__FILE__,"Cactus",
                    "Could not parse specification '%s' when parsing %s statement in schedule for %s::%s",
                    str,rdwr_s,func->thorn,func->routine);
    }

    // strip off _p's and compute timelevel
    int tl = 0;
    for(int pos = strlen(varbuf)-2 ; pos >= 0 ; pos -= 2) {
      if(varbuf[pos] == '_' && varbuf[pos+1] == 'p') {
        tl += 1;
        varbuf[pos] = '\0';
      } else {
        break;
      }
    }

    // re-add vector index
    char fullvar[300];
    if(vecnum >= 0) {
      const size_t written = snprintf(fullvar, sizeof(fullvar), "%s[%d]", varbuf, vecnum);
      assert(written < sizeof(fullvar));
    } else {
      const size_t written = snprintf(fullvar, sizeof(fullvar), "%s", varbuf);
      assert(written < sizeof(fullvar));
    }

    // decode where
    int wh = -1;
    if(CCTK_Equals(where,"everywhere") || CCTK_Equals(where,"all"))
        wh = CCTK_VALID_EVERYWHERE;
    else if(CCTK_Equals(where,"interior") || CCTK_Equals(where,"in"))
        wh = CCTK_VALID_INTERIOR;
    else if(CCTK_Equals(where,"interiorwithboundary"))
        wh = CCTK_VALID_INTERIOR | CCTK_VALID_BOUNDARY;
    else if(CCTK_Equals(where,"boundary"))
        wh = CCTK_VALID_BOUNDARY;
    else {
        CCTK_VError(__LINE__, __FILE__, "Cactus",
                    "Invalid where specification '%s' while parsing %s statement  '%s' in schedule for %s::%s",
                    where,rdwr_s,str,func->thorn,func->routine);
    }
    assert(wh != -1);

    const int vi = CCTK_VarIndex(fullvar);
    if(vi >= 0) {
        add_entry(vi,tl,rdwr,wh,func,s);
        return;
    } 

    // try a group (which could not have had a vector index)
    const int gi = CCTK_GroupIndex(fullvar);
    if(gi >= 0) {
        int i0 = CCTK_FirstVarIndexI(gi);
        int iN = i0+CCTK_NumVarsInGroupI(gi);
        for(int vi=i0;vi<iN;vi++) {
            add_entry(vi,tl,rdwr,wh,func,s);
        }
        return;
    }

    if(vecnum < 0) {
        /* try if this is a single member of a group that is a vector of
         * variables to be able to handle cases where the vector size is no
         * known at compile time */
        char fullvarvect[sizeof(fullvar) + 12]; // room for 10 digits and [];
        size_t written = snprintf(fullvarvect, sizeof(fullvarvect), "%s[%d]", fullvar, 0);
        assert(written < sizeof(fullvar));
        const int vi = CCTK_VarIndex(fullvarvect);
        // This will fail for 0-sized vectors of grid functions which do not
        // show up anywhere in Cactus' data structures
        if(vi >= 0) {
            const int gi = CCTK_GroupIndexFromVarI(vi);
            assert(gi >= 0);
            cGroup group;
            const int ierr = CCTK_GroupData(gi, &group);
            assert(!ierr);
            assert(group.vectorgroup);
            const int firstvar = CCTK_FirstVarIndexI(gi);
            assert(firstvar >= 0);
            const int varstride = group.numvars/group.vectorlength;
            assert(group.numvars % group.vectorlength == 0);
            for(int var = 0 ; var < group.vectorlength ; var++) {
                add_entry(firstvar+var*varstride,tl,rdwr,wh,func,s);
            }
            return;
        }
    }

    if(!CCTK_Equals(presync_mode, "off")) {
        if(CCTK_Equals(presync_mode, "warn-only") ||
           CCTK_Equals(presync_mode, "mixed-warn")) {
            CCTK_VWarn(CCTK_WARN_ALERT,__LINE__, __FILE__, "Cactus",
                    "Invalid variable or group name '%s' in %s for routine %s::%s",
                    fullvar,rdwr_s,func->thorn,func->routine);
        } else {
            CCTK_VError(__LINE__, __FILE__, "Cactus",
                    "Invalid variable or group name '%s' in %s for routine %s::%s",
                    fullvar,rdwr_s,func->thorn,func->routine);
        }
    }
}

 /*@@
   @routine    CCTKi_CreateRDWRData
   @date       Mon Sep 11 15:29:33 2017 -0500
   @author     Steven R. Brandt
   @desc
               Parse access clauses into RDWR array associated with a scheduled
               function.
   @enddesc

   @var        f
   @vdesc      A cFuntionData function description whose RDWR array is to be
               set.
   @vtype      cFunctionData
   @vio        inou
   @endvar

   @returntype void
@@*/
extern "C"
void CCTKi_CreateRDWRData(cFunctionData *f)
{
    DECLARE_CCTK_PARAMETERS;

    std::set<RDWR_entry> s;

    if(CCTK_Equals(presync_mode, "off"))
        return;

    for(int i=0;i<f->n_WritesClauses;i++) {
        parse(f->WritesClauses[i],writes_t,f,s);
    }

    for(int i=0;i<f->n_ReadsClauses;i++) {
        parse(f->ReadsClauses[i],reads_t,f,s);
    }

    for(int i=0;i<f->n_InvalidatesClauses;i++) {
        parse(f->InvalidatesClauses[i],invalidates_t,f,s);
    }

    f->n_RDWR = s.size();
    f->RDWR = new RDWR_entry[s.size()];
    int n = 0;
    /* a std::set is iterated in order of its comparison op which here means
     * first in varindex then in timelevel */
    int previous_vi = -1, previous_tl = -1;
    for(auto i=s.begin();i != s.end();++i) {
        f->RDWR[n++] = *i;
        // be paronoid and check order just in case the container is ever
        // changed to something that sorts differently
        if(previous_vi != -1 and previous_tl != -1) {
          assert(previous_vi < i->varindex or previous_tl < i->timelevel);
          previous_vi = i->varindex;
          previous_tl = i->timelevel;
        }
    }

}

 /*@@
   @routine    CCTKi_FreeRDWRData
   @date       Mon Sep 11 15:29:33 2017 -0500
   @author     Steven R. Brandt
   @desc
               Free RDWR array associated with a scheduled function.
   @enddesc

   @var        f
   @vdesc      A cFuntionData function description whose RDWR has been
               allocated by CCTKi_CreateRDWRData.
   @vtype      cFunctionData
   @vio        inou
   @endvar

   @returntype void
@@*/
extern "C"
void CCTKi_FreeRDWRData(cFunctionData *f)
{
    if(f)
    {
        delete[] f->RDWR;
        f->RDWR = nullptr;
        f->n_RDWR = 0;
    }
}

 /*@@
   @routine    CCTK_HasAccess
   @date       Sat May  2 20:22:31 CDT 2020
   @author     Roland Haas
   @desc
               Default access check routine
   @enddesc

   @var        index
   @vdesc      The index of the variable
   @vtype      int
   @vio        in
   @endvar

   @returntype int
   @returndesc
   This function returns a non-zero value if the variable is accessible.
   @endreturndesc
@@*/
bool hasAccess(cFunctionData const * const f,
               int const RDWR_entry::* const access, const int vi,
               const int tl) {
  const RDWR_entry val{vi,-1,tl};
  const auto it = std::lower_bound(f->RDWR, f->RDWR + f->n_RDWR, val);
  return it-f->RDWR < f->n_RDWR and it->varindex == vi and it->timelevel == tl;
}
extern "C"
int CCTK_HasAccess(const cGH *cctkGH, int var_index)
{
  DECLARE_CCTK_PARAMETERS;

  static bool presync_only = CCTK_Equals(presync_mode, "presync-only");

  if(!presync_only)
    return true;

  cFunctionData const * const current_function = CCTK_ScheduleQueryCurrentFunction(cctkGH);
  if(current_function == nullptr) // called directly by the driver or flesh
    return true;

  // vectors of grid functions are all accessed via a single pointer to the
  // vector's 0th member. Thus access to the whole vector must be granted if
  // any member has a READ / WRITE clause
  const int gi = CCTK_GroupIndexFromVarI(var_index);
  assert(gi >= 0);
  cGroup group;
  const int ierr = CCTK_GroupData(gi,&group);
  assert(ierr == 0);
  int var0,varn,varstep;
  if(group.vectorgroup) {
    // for groups of vectors the variable index steps first by group member
    // then by vector index
    var0 = CCTK_FirstVarIndexI(gi);
    var0 += (var_index - var0) % group.vectorlength;
    varn = group.numvars;
    varstep = group.numvars / group.vectorlength;
  } else {
    var0 = var_index;
    varn = 1;
    varstep = 1;
  }

  for (int vi = var0; vi < var0 + varn; vi += varstep) {
    if(hasAccess(current_function,&RDWR_entry::where_rd,vi,0))
      return true;
    if(hasAccess(current_function,&RDWR_entry::where_wr,vi,0))
      return true;
  }

  return false;
}
}
