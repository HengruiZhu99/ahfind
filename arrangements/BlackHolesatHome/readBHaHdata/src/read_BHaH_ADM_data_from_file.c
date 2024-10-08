#include "math.h"
#include "cctk.h"
#include "cctk_Arguments.h"
#include "cctk_Parameters.h"
#include "stdlib.h"

extern int HorizonWasFound(int horizon_number);

/*
 * Set up low-level Einstein Toolkit (ETK) functions to perform diagnostics
 */
void read_BHaH_ADM_data_from_file(CCTK_ARGUMENTS) {

  DECLARE_CCTK_ARGUMENTS;
  DECLARE_CCTK_PARAMETERS;

#define FREAD(ptr, size, nmemb, stream)                         \
  {                                                             \
    const int numitems=fread((ptr), (size), (nmemb), (stream)); \
    /* fprintf(stderr, "numitems = %d\n", numitems); */         \
  }

#define ADM_ALPHA 0
#define ADM_BETAX 1
#define ADM_BETAY 2
#define ADM_BETAZ 3
#define ADM_GAMMAXX 4
#define ADM_GAMMAXY 5
#define ADM_GAMMAXZ 6
#define ADM_GAMMAYY 7
#define ADM_GAMMAYZ 8
#define ADM_GAMMAZZ 9
#define ADM_KXX 10
#define ADM_KXY 11
#define ADM_KXZ 12
#define ADM_KYY 13
#define ADM_KYZ 14
#define ADM_KZZ 15

  FILE *etk_output_file = fopen("etk_output_file.dat", "r");
  //cctkGH->cctk_iteration = 102;
  FREAD(&cctkGH->cctk_iteration, sizeof(int), 1, etk_output_file);
  //cctkGH->cctk_time      = 10.2;
  FREAD(&cctkGH->cctk_time, sizeof(double), 1, etk_output_file);

  FREAD(alp, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(betax, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(betay, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(betaz, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(gxx, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(gxy, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(gxz, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(gyy, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(gyz, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(gzz, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(kxx, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(kxy, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(kxz, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(kyy, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(kyz, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  FREAD(kzz, sizeof(double), cctk_lsh[0]*cctk_lsh[1]*cctk_lsh[2], etk_output_file);
  fclose(etk_output_file);
}
