 /*@@
   @header    cctk_PreSync.h
   @date      Fri Feb 3 12:36:00 2017 -0600
   @author    Steven R. Brandt, Roland Haas
   @desc

   @enddesc
   @version $Header$
 @@*/

#ifndef __CCTKI_PRESYNC_H_
#define __CCTKI_PRESYNC_H_

#ifdef __cplusplus
extern "C" {
#endif

void CCTKi_CreateRDWRData(cFunctionData *f);
void CCTKi_FreeRDWRData(cFunctionData *f);

#ifdef __cplusplus
}
#endif

#endif /*__CCTKI_PRESYNC_H_ */
