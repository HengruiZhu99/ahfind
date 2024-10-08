#include "math.h"
#include "cctk.h"
#include "cctk_Arguments.h"
#include "cctk_Parameters.h"
#include "stdlib.h"

extern int HorizonWasFound(int horizon_number);

void output_processed_data_to_file(CCTK_ARGUMENTS) {

  DECLARE_CCTK_ARGUMENTS;
  DECLARE_CCTK_PARAMETERS;

  double *ah_radius = (double *)(CCTK_VarDataPtr(cctkGH, 0, "AHFinderDirect::ah_radius[0]"));
  double ah_radius_min = +1e10;
  double ah_radius_max = -1e10;
  for(int i=0; i<18 * 18 * 6; i++) {  // FIXME: these limits should not be hard coded.
    if(ah_radius[i] < ah_radius_min) ah_radius_min = ah_radius[i];
    if(ah_radius[i] > ah_radius_max) ah_radius_max = ah_radius[i];
  }
  if(ah_radius_max == -1e10) ah_radius_max = 1.0;

  if(cctk_iteration == 0) {
    FILE *outfileptr = fopen(outfilename, "w");
    fprintf(outfileptr, "# Column 1: time\n");
    fprintf(outfileptr, "# Column 2: a/M (dimensionless spin parameter, == J/M^2)\n");

    fprintf(outfileptr, "# Column 3: M_{irr} (irreducible mass)\n");

    fprintf(outfileptr, "# Column 4: J^x_{Weinberg} (x-component of Weinberg ang. momentum)\n");
    fprintf(outfileptr, "# Column 5: J^y_{Weinberg} (y-component of Weinberg ang. momentum)\n");
    fprintf(outfileptr, "# Column 6: J^z_{Weinberg} (z-component of Weinberg ang. momentum)\n");

    fprintf(outfileptr, "# Column 7: M^x_{Weinberg} (x-component of Weinberg lin. momentum)\n");
    fprintf(outfileptr, "# Column 8: M^y_{Weinberg} (y-component of Weinberg lin. momentum)\n");
    fprintf(outfileptr, "# Column 9: M^z_{Weinberg} (z-component of Weinberg lin. momentum)\n");

    fprintf(outfileptr, "# Column 10: proper polar circumference\n");
    fprintf(outfileptr, "# Column 11: proper polar circumference, at phi=pi/2\n");
    fprintf(outfileptr, "# Column 12: proper equatorial circumference\n");

    fprintf(outfileptr, "# Column 13: isolated horizon mass\n");
    fprintf(outfileptr, "# Column 14: isolated horizon J\n");

    fprintf(outfileptr, "# Column 15: r_{AH, min} minimum apparent horizon radius\n");
    fprintf(outfileptr, "# Column 16: r_{AH, max} maximum apparent horizon radius\n");

    fprintf(outfileptr, "# Column 17: Killing vector eigenvalue: real part\n");
    fprintf(outfileptr, "# Column 18: Killing vector eigenvalue: imag part\n");
    fclose(outfileptr);
  }

  if(HorizonWasFound(1)) { // inputs into HorizonWasFound must be >= 1.
    {
      FILE *outfileptr = fopen(recent_ah_radius_max_filename, "w");
      fprintf(outfileptr, "%d\n", cctk_iteration);
      fprintf(outfileptr, "%e\n", ah_radius_max);
      fclose(outfileptr);
    }

    double *J = (double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_spin[0]"));
    double *M = (double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_mass[0]"));
    double a_over_M = (*J)/((*M) * (*M));

    FILE *outfileptr = fopen(outfilename, "a");
    fprintf(outfileptr, "%.15e %e", cctk_time, a_over_M);
    fprintf(outfileptr, " %e", *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_irreducible_mass[0]")));
    fprintf(outfileptr, " %e %e %e",
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_w_angular_momentum_x[0]")),
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_w_angular_momentum_y[0]")),
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_w_angular_momentum_z[0]")));
    fprintf(outfileptr, " %e %e %e",
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_w_momentum_x[0]")),
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_w_momentum_y[0]")),
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_w_momentum_z[0]")));
    fprintf(outfileptr, " %e %e %e",
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_polar_circumference_0[0]")),
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_polar_circumference_pi_2[0]")),
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_equatorial_circumference[0]")));
    fprintf(outfileptr, " %e %e",
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_mass[0]")),
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_spin[0]")));
    fprintf(outfileptr, " %e %e", ah_radius_min, ah_radius_max),
    fprintf(outfileptr, " %e %e\n",
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_killing_eigenvalue_re[0]")),
            *(double *)(CCTK_VarDataPtr(cctkGH, 0, "QuasiLocalMeasures::qlm_killing_eigenvalue_im[0]")));
    fclose(outfileptr);
  }
}
