#ifndef OPERATORS_H
#define OPERATORS_H

#include <cctk.h>

CCTK_INT
MoL_LinearCombination(cGH const *cctkGH,
                      CCTK_INT var,
                      CCTK_INT rl,
                      CCTK_INT tl,
                      CCTK_REAL scale,
                      CCTK_INT const srcs[],
                      CCTK_INT const tls[],
                      CCTK_REAL const facts[],
                      CCTK_INT nsrcs);

CCTK_INT
MoL_LinearCombination_REAL(cGH const *cctkGH,
                           CCTK_REAL *restrict var,
                           CCTK_INT size,
                           CCTK_REAL scale,
                           CCTK_REAL const *restrict const srcs[],
                           CCTK_REAL const facts[],
                           CCTK_INT nsrcs);

#endif  // #ifndef OPERATORS_H
