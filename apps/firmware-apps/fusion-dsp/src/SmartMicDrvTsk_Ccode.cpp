//
// File: SmartMicDrvTsk_Ccode.cpp
//
// Code generated for Simulink model 'SmartMicDrvTsk_Ccode'.
//
// Model version                  : 1.78
// Simulink Coder version         : 9.9 (R2023a) 19-Nov-2022
// C/C++ source code generated on : Tue Jun 27 14:18:13 2023
//
// Target selection: ert.tlc
// Embedded hardware selection: ARM Compatible->ARM 10
// Code generation objectives:
//    1. Execution efficiency
//    2. Traceability
// Validation result: Not run
//
#include "SmartMicDrvTsk_Ccode.h"
#include <stdint.h>
#include "complex_types.h"
#include <cstring>
#include <cmath>
#include <stdbool.h>
#include <cstdlib>
#include <stddef.h>
#include "rtw_linux_mac.h"

extern void AdvanceTaskCounters(SmartMicDrvTsk_Ccode::RT_MODEL & rtM);

// This function updates active task counters and model execution time.
void AdvanceTaskCounters(SmartMicDrvTsk_Ccode::RT_MODEL & rtM)
{
  // Compute which subrates run during the next base time step.  Subrates
  //  are an integer multiple of the base rate counter.  Therefore, the subtask
  //  counter is reset when it reaches its limit (zero means run).

  ((&rtM)->Timing.TaskCounters.TID[1])++;
  if (((&rtM)->Timing.TaskCounters.TID[1]) > 49) {// Sample time: [0.5s, 0.0s]
    (&rtM)->Timing.TaskCounters.TID[1] = 0;
  }

  // Update absolute time for base rate
  // The "clockTick0" counts the number of times the code of this task has
  //  been executed. The resolution of this integer timer is 0.01, which is the step size
  //  of the task. Size of "clockTick0" ensures timer will not overflow during the
  //  application lifespan selected.

}

// System initialize for atomic system:
void SmartMicDrvTsk_Ccode::MATLABSystem_Init(DW_MATLABSystem *localDW)
{
  // Start for MATLABSystem: '<S1>/MATLAB System'
  localDW->objisempty = true;

  //  Perform one-time calculations, such as computing constants
  std::memset(&localDW->obj.B[0], 0, 6000U * sizeof(float));
  localDW->obj.ix = 1;

  //  Index of the first buffer
  //  Initialize / reset discrete-state properties
}

// Output and update for atomic system:
void SmartMicDrvTsk_Ccode::MATLABSystem(const float rtu_0[60], DW_MATLABSystem
  *localDW)
{
  // MATLABSystem: '<S1>/MATLAB System'
  //  Implement algorithm. Calculate y as a function of input u and
  //  discrete states.
  for (int32_t i{0}; i < 60; i++) {
    localDW->obj.B[i + 60 * (localDW->obj.ix - 1)] = rtu_0[i];
  }

  if (localDW->obj.ix > 2147483646) {
    localDW->obj.ix = INT32_MAX;
  } else {
    localDW->obj.ix++;
  }

  if (localDW->obj.ix > 100) {
    localDW->obj.ix = 1;
  }

  // MATLABSystem: '<S1>/MATLAB System'
  std::memcpy(&localDW->MATLABSystem_o1[0], &localDW->obj.B[0], 6000U * sizeof
              (float));

  // MATLABSystem: '<S1>/MATLAB System'
  localDW->MATLABSystem_o2 = localDW->obj.ix;
}

// System initialize for atomic system:
void SmartMicDrvTsk_Ccode::SampleRateConverter_Init(DW_SampleRateConverter
  *localDW)
{
  static const float tmp_0[16]{ 0.0581078306F, 0.219008401F, -0.0205490105F,
    0.0F, 0.0F, 0.25F, 0.0F, 0.0F, -0.0205490105F, 0.219008401F, 0.0581078306F,
    0.0F, -0.0176831651F, 0.142456397F, 0.142456397F, -0.0176831651F };

  static const float tmp[8]{ 0.0F, 0.5F, 0.0F, 0.0F, -0.0420742147F,
    0.290070832F, 0.290070832F, -0.0420742147F };

  b_dspcodegen_FIRDecimator *iobj_1;
  b_dspcodegen_FIRDecimator_1 *iobj_0;

  // Start for MATLABSystem: '<S1>/Sample-Rate Converter'
  localDW->obj._pobj1.matlabCodegenIsDeleted = true;
  localDW->obj._pobj0.matlabCodegenIsDeleted = true;
  localDW->obj.matlabCodegenIsDeleted = false;
  localDW->objisempty = true;
  localDW->obj.isInitialized = 1;
  localDW->obj._pobj1.isInitialized = 0;
  localDW->obj._pobj1.isInitialized = 0;

  // System object Constructor function: dsp.FIRDecimator
  localDW->obj._pobj1.cSFunObject.P0_IC = 0.0F;
  for (int32_t i{0}; i < 8; i++) {
    localDW->obj._pobj1.cSFunObject.P1_FILT[i] = tmp[i];
  }

  localDW->obj._pobj1.matlabCodegenIsDeleted = false;
  localDW->obj.filt1 = &localDW->obj._pobj1;
  localDW->obj._pobj0.isInitialized = 0;
  localDW->obj._pobj0.isInitialized = 0;

  // System object Constructor function: dsp.FIRDecimator
  localDW->obj._pobj0.cSFunObject.P0_IC = 0.0F;
  for (int32_t i{0}; i < 16; i++) {
    localDW->obj._pobj0.cSFunObject.P1_FILT[i] = tmp_0[i];
  }

  localDW->obj._pobj0.matlabCodegenIsDeleted = false;
  localDW->obj.filt2 = &localDW->obj._pobj0;
  localDW->obj.NumChannels = 1;
  localDW->obj.isSetupComplete = true;

  // End of Start for MATLABSystem: '<S1>/Sample-Rate Converter'

  // InitializeConditions for MATLABSystem: '<S1>/Sample-Rate Converter'
  iobj_1 = localDW->obj.filt1;
  if (iobj_1->isInitialized == 1) {
    // System object Initialization function: dsp.FIRDecimator
    iobj_1->cSFunObject.W2_CoeffIdx = 4;
    iobj_1->cSFunObject.W0_PhaseIdx = 1;
    iobj_1->cSFunObject.W4_TapDelayIndex = 3;
    iobj_1->cSFunObject.W1_Sums = 0.0F;
    for (int32_t i{0}; i < 6; i++) {
      iobj_1->cSFunObject.W3_StatesBuff[i] = 0.0F;
    }
  }

  iobj_0 = localDW->obj.filt2;
  if (iobj_0->isInitialized == 1) {
    // System object Initialization function: dsp.FIRDecimator
    iobj_0->cSFunObject.W2_CoeffIdx = 12;
    iobj_0->cSFunObject.W0_PhaseIdx = 3;
    iobj_0->cSFunObject.W4_TapDelayIndex = 9;
    iobj_0->cSFunObject.W1_Sums = 0.0F;
    for (int32_t i{0}; i < 12; i++) {
      iobj_0->cSFunObject.W3_StatesBuff[i] = 0.0F;
    }
  }

  // End of InitializeConditions for MATLABSystem: '<S1>/Sample-Rate Converter'
}

// Output and update for atomic system:
void SmartMicDrvTsk_Ccode::SampleRateConverter(const float rtu_0[480],
  DW_SampleRateConverter *localDW)
{
  b_dsp_FIRDecimator_0 *obj_1;
  b_dsp_FIRDecimator_1 *obj_2;
  b_dspcodegen_FIRDecimator *obj;
  b_dspcodegen_FIRDecimator_1 *obj_0;
  float b_y1[240];
  float acc;
  float acc_tmp;
  int32_t cffIdx;
  int32_t curTapIdx;
  int32_t inputIdx;
  int32_t inputSegment;
  int32_t maxWindow;
  int32_t outBufIdx;
  int32_t outputSegment;
  int32_t phaseIdx;
  int32_t tapIdx;

  // MATLABSystem: '<S1>/Sample-Rate Converter'
  obj = localDW->obj.filt1;
  if (obj->isInitialized != 1) {
    obj->isSetupComplete = false;
    obj->isInitialized = 1;
    obj->isSetupComplete = true;

    // System object Initialization function: dsp.FIRDecimator
    obj->cSFunObject.W2_CoeffIdx = 4;
    obj->cSFunObject.W0_PhaseIdx = 1;
    obj->cSFunObject.W4_TapDelayIndex = 3;
    obj->cSFunObject.W1_Sums = 0.0F;
    for (int32_t i{0}; i < 6; i++) {
      obj->cSFunObject.W3_StatesBuff[i] = 0.0F;
    }
  }

  obj_1 = &obj->cSFunObject;

  // System object Outputs function: dsp.FIRDecimator
  cffIdx = obj->cSFunObject.W2_CoeffIdx;
  phaseIdx = obj->cSFunObject.W0_PhaseIdx;
  inputIdx = 0;
  outputSegment = 0;
  inputSegment = 0;
  curTapIdx = obj->cSFunObject.W4_TapDelayIndex;
  for (int32_t i{0}; i < 1; i++) {
    curTapIdx = obj_1->W4_TapDelayIndex;
    phaseIdx = obj_1->W0_PhaseIdx;
    cffIdx = obj_1->W2_CoeffIdx;
    outBufIdx = 0;
    maxWindow = ((phaseIdx + 1) * 3 + inputSegment) - 3;
    for (int32_t iIdx{0}; iIdx < 480; iIdx++) {
      tapIdx = (inputSegment + curTapIdx) + 1;
      acc_tmp = rtu_0[inputIdx + iIdx];
      acc = acc_tmp * obj_1->P1_FILT[cffIdx] + obj_1->W1_Sums;
      cffIdx++;
      for (int32_t jIdx{tapIdx}; jIdx <= maxWindow + 2; jIdx++) {
        acc += obj_1->P1_FILT[(cffIdx + jIdx) - tapIdx] * obj_1->
          W3_StatesBuff[jIdx];
      }

      cffIdx = ((cffIdx + maxWindow) - tapIdx) + 3;
      for (int32_t jIdx{maxWindow}; jIdx < tapIdx; jIdx++) {
        acc += obj_1->P1_FILT[(cffIdx + jIdx) - maxWindow] *
          obj_1->W3_StatesBuff[jIdx];
      }

      cffIdx = (cffIdx + tapIdx) - maxWindow;
      obj_1->W1_Sums = acc;
      obj_1->W3_StatesBuff[tapIdx - 1] = acc_tmp;
      curTapIdx += 3;
      if (curTapIdx >= 6) {
        curTapIdx -= 6;
      }

      phaseIdx++;
      if (phaseIdx < 2) {
        maxWindow += 3;
      } else {
        obj_1->O0_Y0[outputSegment + outBufIdx] = obj_1->W1_Sums;
        outBufIdx++;
        obj_1->W1_Sums = 0.0F;
        phaseIdx = 0;
        cffIdx = 0;
        curTapIdx--;
        if (curTapIdx < 0) {
          curTapIdx += 3;
        }

        maxWindow = inputSegment;
      }
    }

    inputIdx += 480;
    outputSegment += 240;
    inputSegment += 6;
  }

  obj->cSFunObject.W4_TapDelayIndex = curTapIdx;
  obj->cSFunObject.W2_CoeffIdx = cffIdx;
  obj->cSFunObject.W0_PhaseIdx = phaseIdx;
  for (int32_t i{0}; i < 240; i++) {
    b_y1[i] = obj->cSFunObject.O0_Y0[i];
  }

  obj_0 = localDW->obj.filt2;
  if (obj_0->isInitialized != 1) {
    obj_0->isSetupComplete = false;
    obj_0->isInitialized = 1;
    obj_0->isSetupComplete = true;

    // System object Initialization function: dsp.FIRDecimator
    obj_0->cSFunObject.W2_CoeffIdx = 12;
    obj_0->cSFunObject.W0_PhaseIdx = 3;
    obj_0->cSFunObject.W4_TapDelayIndex = 9;
    obj_0->cSFunObject.W1_Sums = 0.0F;
    for (int32_t i{0}; i < 12; i++) {
      obj_0->cSFunObject.W3_StatesBuff[i] = 0.0F;
    }
  }

  obj_2 = &obj_0->cSFunObject;

  // System object Outputs function: dsp.FIRDecimator
  cffIdx = obj_0->cSFunObject.W2_CoeffIdx;
  phaseIdx = obj_0->cSFunObject.W0_PhaseIdx;
  inputIdx = 0;
  outputSegment = 0;
  inputSegment = 0;
  curTapIdx = obj_0->cSFunObject.W4_TapDelayIndex;
  for (int32_t i{0}; i < 1; i++) {
    curTapIdx = obj_2->W4_TapDelayIndex;
    phaseIdx = obj_2->W0_PhaseIdx;
    cffIdx = obj_2->W2_CoeffIdx;
    outBufIdx = 0;
    maxWindow = ((phaseIdx + 1) * 3 + inputSegment) - 3;
    for (int32_t iIdx{0}; iIdx < 240; iIdx++) {
      tapIdx = (inputSegment + curTapIdx) + 1;
      acc_tmp = b_y1[inputIdx + iIdx];
      acc = acc_tmp * obj_2->P1_FILT[cffIdx] + obj_2->W1_Sums;
      cffIdx++;
      for (int32_t jIdx{tapIdx}; jIdx <= maxWindow + 2; jIdx++) {
        acc += obj_2->P1_FILT[(cffIdx + jIdx) - tapIdx] * obj_2->
          W3_StatesBuff[jIdx];
      }

      cffIdx = ((cffIdx + maxWindow) - tapIdx) + 3;
      for (int32_t jIdx{maxWindow}; jIdx < tapIdx; jIdx++) {
        acc += obj_2->P1_FILT[(cffIdx + jIdx) - maxWindow] *
          obj_2->W3_StatesBuff[jIdx];
      }

      cffIdx = (cffIdx + tapIdx) - maxWindow;
      obj_2->W1_Sums = acc;
      obj_2->W3_StatesBuff[tapIdx - 1] = acc_tmp;
      curTapIdx += 3;
      if (curTapIdx >= 12) {
        curTapIdx -= 12;
      }

      phaseIdx++;
      if (phaseIdx < 4) {
        maxWindow += 3;
      } else {
        obj_2->O0_Y0[outputSegment + outBufIdx] = obj_2->W1_Sums;
        outBufIdx++;
        obj_2->W1_Sums = 0.0F;
        phaseIdx = 0;
        cffIdx = 0;
        curTapIdx--;
        if (curTapIdx < 0) {
          curTapIdx += 3;
        }

        maxWindow = inputSegment;
      }
    }

    inputIdx += 240;
    outputSegment += 60;
    inputSegment += 12;
  }

  obj_0->cSFunObject.W4_TapDelayIndex = curTapIdx;
  obj_0->cSFunObject.W2_CoeffIdx = cffIdx;
  obj_0->cSFunObject.W0_PhaseIdx = phaseIdx;
  for (int32_t i{0}; i < 60; i++) {
    // MATLABSystem: '<S1>/Sample-Rate Converter'
    localDW->SampleRateConverter_b[i] = obj_0->cSFunObject.O0_Y0[i];
  }
}

void SmartMicDrvTsk_Ccode::emxInit_int32_t(emxArray_int32_t **pEmxArray, int32_t
  numDimensions)
{
  emxArray_int32_t *emxArray;
  *pEmxArray = static_cast<emxArray_int32_t *>(std::malloc(sizeof
    (emxArray_int32_t)));
  emxArray = *pEmxArray;
  emxArray->data = static_cast<int32_t *>(nullptr);
  emxArray->numDimensions = numDimensions;
  emxArray->size = static_cast<int32_t *>(std::malloc(sizeof(int32_t) *
    static_cast<uint32_t>(numDimensions)));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (int32_t i{0}; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

void SmartMicDrvTsk_Ccode::emxEnsureCapacity_int32_t(emxArray_int32_t *emxArray,
  int32_t oldNumel)
{
  int32_t i;
  int32_t newNumel;
  void *newData;
  if (oldNumel < 0) {
    oldNumel = 0;
  }

  newNumel = 1;
  for (i = 0; i < emxArray->numDimensions; i++) {
    newNumel *= emxArray->size[i];
  }

  if (newNumel > emxArray->allocatedSize) {
    i = emxArray->allocatedSize;
    if (i < 16) {
      i = 16;
    }

    while (i < newNumel) {
      if (i > 1073741823) {
        i = INT32_MAX;
      } else {
        i <<= 1;
      }
    }

    newData = std::calloc(static_cast<uint32_t>(i), sizeof(int32_t));
    if (emxArray->data != nullptr) {
      std::memcpy(newData, emxArray->data, sizeof(int32_t) *
                  static_cast<uint32_t>(oldNumel));
      if (emxArray->canFreeData) {
        std::free(emxArray->data);
      }
    }

    emxArray->data = static_cast<int32_t *>(newData);
    emxArray->allocatedSize = i;
    emxArray->canFreeData = true;
  }
}

void SmartMicDrvTsk_Ccode::emxFree_int32_t(emxArray_int32_t **pEmxArray)
{
  if (*pEmxArray != static_cast<emxArray_int32_t *>(nullptr)) {
    if (((*pEmxArray)->data != static_cast<int32_t *>(nullptr)) && (*pEmxArray
        )->canFreeData) {
      std::free((*pEmxArray)->data);
    }

    std::free((*pEmxArray)->size);
    std::free(*pEmxArray);
    *pEmxArray = static_cast<emxArray_int32_t *>(nullptr);
  }
}

int32_t SmartMicDrvTsk_Ccode::AsyncBuffercgHelper_write
  (h_dsp_internal_AsyncBuffercgHel *obj, const float in[480])
{
  emxArray_int32_t *b;
  emxArray_int32_t *bc;
  emxArray_int32_t *y;
  emxArray_int32_t *y_0;
  int32_t c;
  int32_t k;
  int32_t n;
  int32_t n_tmp_tmp;
  int32_t overrun;
  int32_t qY;
  int32_t rPtr;
  int32_t yk;
  rPtr = obj->ReadPointer;
  overrun = 0;
  if (obj->WritePointer > 2147483167) {
    qY = INT32_MAX;
  } else {
    qY = obj->WritePointer + 480;
  }

  c = qY - 1;
  emxInit_int32_t(&bc, 2);
  emxInit_int32_t(&y, 2);
  if (qY - 1 > 192001) {
    n = qY - 192002;
    c = qY - 192002;
    n_tmp_tmp = 192002 - obj->WritePointer;
    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = 192002 - obj->WritePointer;
    emxEnsureCapacity_int32_t(y, k);
    y->data[0] = obj->WritePointer;
    yk = obj->WritePointer;
    for (k = 2; k <= n_tmp_tmp; k++) {
      yk++;
      y->data[k - 1] = yk;
    }

    emxInit_int32_t(&y_0, 2);
    k = y_0->size[0] * y_0->size[1];
    y_0->size[0] = 1;
    y_0->size[1] = qY - 192002;
    emxEnsureCapacity_int32_t(y_0, k);
    y_0->data[0] = 1;
    yk = 1;
    for (k = 2; k <= n; k++) {
      yk++;
      y_0->data[k - 1] = yk;
    }

    k = bc->size[0] * bc->size[1];
    bc->size[0] = 1;
    bc->size[1] = y->size[1] + y_0->size[1];
    emxEnsureCapacity_int32_t(bc, k);
    yk = y->size[1];
    if (yk - 1 >= 0) {
      std::memcpy(&bc->data[0], &y->data[0], static_cast<uint32_t>(yk) * sizeof
                  (int32_t));
    }

    yk = y_0->size[1];
    for (k = 0; k < yk; k++) {
      bc->data[k + y->size[1]] = y_0->data[k];
    }

    emxFree_int32_t(&y_0);
    if (obj->WritePointer <= obj->ReadPointer) {
      if (obj->ReadPointer < -2147291646) {
        k = INT32_MAX;
      } else {
        k = 192001 - obj->ReadPointer;
      }

      if (k > 2147483646) {
        k = INT32_MAX;
      } else {
        k++;
      }

      if ((k < 0) && (qY - 192002 < INT32_MIN - k)) {
        overrun = INT32_MIN;
      } else if ((k > 0) && (qY - 192002 > INT32_MAX - k)) {
        overrun = INT32_MAX;
      } else {
        overrun = (qY + k) - 192002;
      }
    } else if (obj->ReadPointer <= qY - 192002) {
      if (obj->ReadPointer < qY + 2147291647) {
        qY = INT32_MAX;
      } else {
        qY = (qY - obj->ReadPointer) - 192002;
      }

      if (qY > 2147483646) {
        overrun = INT32_MAX;
      } else {
        overrun = qY + 1;
      }
    }
  } else {
    if (qY - 1 < obj->WritePointer) {
      n = 0;
    } else {
      n = qY - obj->WritePointer;
    }

    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = n;
    emxEnsureCapacity_int32_t(y, k);
    if (n > 0) {
      y->data[0] = obj->WritePointer;
      yk = obj->WritePointer;
      for (k = 2; k <= n; k++) {
        yk++;
        y->data[k - 1] = yk;
      }
    }

    k = bc->size[0] * bc->size[1];
    bc->size[0] = 1;
    bc->size[1] = y->size[1];
    emxEnsureCapacity_int32_t(bc, k);
    yk = y->size[1];
    if (yk - 1 >= 0) {
      std::memcpy(&bc->data[0], &y->data[0], static_cast<uint32_t>(yk) * sizeof
                  (int32_t));
    }

    if ((obj->WritePointer <= obj->ReadPointer) && (obj->ReadPointer <= qY - 1))
    {
      if ((qY - 1 >= 0) && (obj->ReadPointer < qY + INT32_MIN)) {
        qY = INT32_MAX;
      } else if ((qY - 1 < 0) && (obj->ReadPointer > qY + INT32_MAX)) {
        qY = INT32_MIN;
      } else {
        qY = (qY - obj->ReadPointer) - 1;
      }

      if (qY > 2147483646) {
        overrun = INT32_MAX;
      } else {
        overrun = qY + 1;
      }
    }
  }

  emxFree_int32_t(&y);
  emxInit_int32_t(&b, 1);
  k = b->size[0];
  b->size[0] = bc->size[1];
  emxEnsureCapacity_int32_t(b, k);
  yk = bc->size[1];
  for (k = 0; k < yk; k++) {
    b->data[k] = bc->data[k] - 1;
  }

  emxFree_int32_t(&bc);
  qY = b->size[0];
  for (k = 0; k < qY; k++) {
    obj->Cache[b->data[k]] = in[k];
  }

  emxFree_int32_t(&b);
  if (c + 1 > 192001) {
    c = 1;
  } else {
    c++;
  }

  if (overrun != 0) {
    rPtr = c;
  }

  if ((obj->CumulativeOverrun < 0) && (overrun < INT32_MIN -
       obj->CumulativeOverrun)) {
    obj->CumulativeOverrun = INT32_MIN;
  } else if ((obj->CumulativeOverrun > 0) && (overrun > INT32_MAX -
              obj->CumulativeOverrun)) {
    obj->CumulativeOverrun = INT32_MAX;
  } else {
    obj->CumulativeOverrun += overrun;
  }

  obj->WritePointer = c;
  obj->ReadPointer = rPtr;
  return overrun;
}

void SmartMicDrvTsk_Ccode::FFTSystem_setupImpl(FFTSystem_p *obj, DW_FFTSystem
  *localDW)
{
  cell_wrap varSizes;
  h_dsp_internal_AsyncBuffercgHel *obj_0;
  double b_tmp;
  float tmp[480];
  int32_t i;
  int16_t inSize[8];
  bool exitg1;

  //  Perform one-time calculations, such as computing constants
  //  Prepare the overlap buffer
  obj->buff.pBuffer.NumChannels = -1;
  obj->buff.pBuffer.isInitialized = 0;
  obj->buff.pBuffer.matlabCodegenIsDeleted = false;
  obj->buff.matlabCodegenIsDeleted = false;
  obj_0 = &obj->buff.pBuffer;
  if (obj->buff.pBuffer.isInitialized != 1) {
    obj->buff.pBuffer.isSetupComplete = false;
    obj->buff.pBuffer.isInitialized = 1;
    varSizes.f1[0] = 480U;
    varSizes.f1[1] = 1U;
    for (i = 0; i < 6; i++) {
      varSizes.f1[i + 2] = 1U;
    }

    obj->buff.pBuffer.inputVarSize = varSizes;
    obj->buff.pBuffer.NumChannels = 1;
    obj->buff.pBuffer.AsyncBuffercgHelper_isInitialized = true;
    for (i = 0; i < 192001; i++) {
      obj->buff.pBuffer.Cache[i] = 0.0F;
    }

    obj->buff.pBuffer.isSetupComplete = true;
    obj->buff.pBuffer.ReadPointer = 1;
    obj->buff.pBuffer.WritePointer = 2;
    obj->buff.pBuffer.CumulativeOverrun = 0;
    obj->buff.pBuffer.CumulativeUnderrun = 0;
    for (i = 0; i < 192001; i++) {
      obj->buff.pBuffer.Cache[i] = 0.0F;
    }
  }

  inSize[0] = 480;
  inSize[1] = 1;
  for (i = 0; i < 6; i++) {
    inSize[i + 2] = 1;
  }

  i = 0;
  exitg1 = false;
  while ((!exitg1) && (i < 8)) {
    if (obj_0->inputVarSize.f1[i] != static_cast<uint32_t>(inSize[i])) {
      for (i = 0; i < 8; i++) {
        obj_0->inputVarSize.f1[i] = static_cast<uint32_t>(inSize[i]);
      }

      exitg1 = true;
    } else {
      i++;
    }
  }

  std::memset(&tmp[0], 0, 480U * sizeof(float));
  AsyncBuffercgHelper_write(&obj->buff.pBuffer, tmp);
  for (i = 0; i < 960; i++) {
    b_tmp = std::sin((static_cast<double>(i) + 0.5) * 1.5707963267948966 / 480.0);
    localDW->b[i] = std::sin(1.5707963267948966 * b_tmp * b_tmp);
  }

  for (i = 0; i < 960; i++) {
    obj->ha[i] = localDW->b[i];
  }

  //  hann(2*obj.frame_len);
}

void SmartMicDrvTsk_Ccode::emxInit_float(emxArray_float **pEmxArray, int32_t
  numDimensions)
{
  emxArray_float *emxArray;
  *pEmxArray = static_cast<emxArray_float *>(std::malloc(sizeof(emxArray_float)));
  emxArray = *pEmxArray;
  emxArray->data = static_cast<float *>(nullptr);
  emxArray->numDimensions = numDimensions;
  emxArray->size = static_cast<int32_t *>(std::malloc(sizeof(int32_t) *
    static_cast<uint32_t>(numDimensions)));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (int32_t i{0}; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

void SmartMicDrvTsk_Ccode::emxEnsureCapacity_float(emxArray_float *emxArray,
  int32_t oldNumel)
{
  int32_t i;
  int32_t newNumel;
  void *newData;
  if (oldNumel < 0) {
    oldNumel = 0;
  }

  newNumel = 1;
  for (i = 0; i < emxArray->numDimensions; i++) {
    newNumel *= emxArray->size[i];
  }

  if (newNumel > emxArray->allocatedSize) {
    i = emxArray->allocatedSize;
    if (i < 16) {
      i = 16;
    }

    while (i < newNumel) {
      if (i > 1073741823) {
        i = INT32_MAX;
      } else {
        i <<= 1;
      }
    }

    newData = std::calloc(static_cast<uint32_t>(i), sizeof(float));
    if (emxArray->data != nullptr) {
      std::memcpy(newData, emxArray->data, sizeof(float) * static_cast<uint32_t>
                  (oldNumel));
      if (emxArray->canFreeData) {
        std::free(emxArray->data);
      }
    }

    emxArray->data = static_cast<float *>(newData);
    emxArray->allocatedSize = i;
    emxArray->canFreeData = true;
  }
}

void SmartMicDrvTsk_Ccode::AsyncBuffercgHelper_ReadSamples(const
  h_dsp_internal_AsyncBuffercgHel *obj, emxArray_float *out, int32_t *underrun,
  int32_t *overlapUnderrun, int32_t *c)
{
  emxArray_int32_t *readIdx;
  emxArray_int32_t *y;
  emxArray_int32_t *y_0;
  int32_t k;
  int32_t n;
  int32_t qY;
  int32_t qY_0;
  int32_t qY_tmp_tmp;
  int32_t rPtr;
  int32_t yk;
  *underrun = 0;
  *overlapUnderrun = 0;
  if (obj->ReadPointer > 2147483646) {
    rPtr = INT32_MAX;
  } else {
    rPtr = obj->ReadPointer + 1;
  }

  if (rPtr > 192001) {
    rPtr = 1;
  }

  if (rPtr < -2147483168) {
    qY_0 = INT32_MIN;
    qY = INT32_MIN;
  } else {
    qY_0 = rPtr - 480;
    qY = rPtr - 480;
  }

  qY_tmp_tmp = qY + 959;
  *c = qY + 959;
  emxInit_int32_t(&readIdx, 2);
  emxInit_int32_t(&y, 2);
  emxInit_int32_t(&y_0, 2);
  if (qY_0 < 1) {
    n = 1 - qY_0;
    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = 1 - qY_0;
    emxEnsureCapacity_int32_t(y, k);
    y->data[0] = qY_0 + 192001;
    yk = qY_0 + 192001;
    for (k = 2; k <= n; k++) {
      yk++;
      y->data[k - 1] = yk;
    }

    k = y_0->size[0] * y_0->size[1];
    y_0->size[0] = 1;
    y_0->size[1] = qY + 959;
    emxEnsureCapacity_int32_t(y_0, k);
    y_0->data[0] = 1;
    yk = 1;
    for (k = 2; k <= qY_tmp_tmp; k++) {
      yk++;
      y_0->data[k - 1] = yk;
    }

    k = readIdx->size[0] * readIdx->size[1];
    readIdx->size[0] = 1;
    readIdx->size[1] = y->size[1] + y_0->size[1];
    emxEnsureCapacity_int32_t(readIdx, k);
    qY_tmp_tmp = y->size[1];
    if (qY_tmp_tmp - 1 >= 0) {
      std::memcpy(&readIdx->data[0], &y->data[0], static_cast<uint32_t>
                  (qY_tmp_tmp) * sizeof(int32_t));
    }

    qY_tmp_tmp = y_0->size[1];
    for (k = 0; k < qY_tmp_tmp; k++) {
      readIdx->data[k + y->size[1]] = y_0->data[k];
    }

    if ((rPtr <= obj->WritePointer) && (obj->WritePointer <= qY + 959)) {
      if ((qY + 959 >= 0) && (obj->WritePointer < qY - 2147482688)) {
        qY_0 = INT32_MAX;
      } else if ((qY + 959 < 0) && (obj->WritePointer > qY - 2147482689)) {
        qY_0 = INT32_MIN;
      } else {
        qY_0 = (qY - obj->WritePointer) + 959;
      }

      if (qY_0 > 2147483646) {
        *underrun = INT32_MAX;
      } else {
        *underrun = qY_0 + 1;
      }
    } else if (obj->WritePointer < rPtr) {
      if (qY_0 + 192001 < -2147291646) {
        qY_0 = INT32_MAX;
      } else {
        qY_0 = -qY_0;
      }

      if (qY_0 > 2147483646) {
        qY_0 = INT32_MAX;
      } else {
        qY_0++;
      }

      if (obj->WritePointer > INT32_MAX - qY_0) {
        *overlapUnderrun = INT32_MAX;
      } else {
        *overlapUnderrun = qY_0 + obj->WritePointer;
      }
    } else if (obj->WritePointer > qY_0 + 192001) {
      if ((obj->WritePointer >= 0) && (qY_0 + 192001 < obj->WritePointer -
           INT32_MAX)) {
        qY_0 = INT32_MAX;
      } else if ((obj->WritePointer < 0) && (qY_0 + 192001 > obj->WritePointer -
                  INT32_MIN)) {
        qY_0 = INT32_MIN;
      } else {
        qY_0 = (obj->WritePointer - qY_0) - 192001;
      }

      if (qY_0 > 2147483646) {
        *overlapUnderrun = INT32_MAX;
      } else {
        *overlapUnderrun = qY_0 + 1;
      }
    }
  } else if (qY + 959 > 192001) {
    qY_tmp_tmp = qY - 191042;
    *c = qY - 191042;
    n = 192002 - qY_0;
    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = 192002 - qY_0;
    emxEnsureCapacity_int32_t(y, k);
    y->data[0] = qY_0;
    yk = qY_0;
    for (k = 2; k <= n; k++) {
      yk++;
      y->data[k - 1] = yk;
    }

    k = y_0->size[0] * y_0->size[1];
    y_0->size[0] = 1;
    y_0->size[1] = qY - 191042;
    emxEnsureCapacity_int32_t(y_0, k);
    y_0->data[0] = 1;
    yk = 1;
    for (k = 2; k <= qY_tmp_tmp; k++) {
      yk++;
      y_0->data[k - 1] = yk;
    }

    k = readIdx->size[0] * readIdx->size[1];
    readIdx->size[0] = 1;
    readIdx->size[1] = y->size[1] + y_0->size[1];
    emxEnsureCapacity_int32_t(readIdx, k);
    qY_tmp_tmp = y->size[1];
    std::memcpy(&readIdx->data[0], &y->data[0], static_cast<uint32_t>(qY_tmp_tmp)
                * sizeof(int32_t));
    qY_tmp_tmp = y_0->size[1];
    for (k = 0; k < qY_tmp_tmp; k++) {
      readIdx->data[k + y->size[1]] = y_0->data[k];
    }

    if (rPtr <= obj->WritePointer) {
      if (obj->WritePointer < -2147291646) {
        qY_0 = INT32_MAX;
      } else {
        qY_0 = 192001 - obj->WritePointer;
      }

      if (qY_0 > 2147483646) {
        qY_0 = INT32_MAX;
      } else {
        qY_0++;
      }

      if ((qY_0 < 0) && (qY - 191042 < INT32_MIN - qY_0)) {
        *underrun = INT32_MIN;
      } else if ((qY_0 > 0) && (qY - 191042 > INT32_MAX - qY_0)) {
        *underrun = INT32_MAX;
      } else {
        *underrun = (qY + qY_0) - 191042;
      }
    } else if (obj->WritePointer <= qY - 191042) {
      if (obj->WritePointer < qY + 2147292607) {
        qY_0 = INT32_MAX;
      } else {
        qY_0 = (qY - obj->WritePointer) - 191042;
      }

      if (qY_0 > 2147483646) {
        *underrun = INT32_MAX;
      } else {
        *underrun = qY_0 + 1;
      }
    } else if ((qY_0 < obj->WritePointer) && (obj->WritePointer < rPtr)) {
      if ((obj->WritePointer >= 0) && (qY_0 < obj->WritePointer - INT32_MAX)) {
        qY_0 = INT32_MAX;
      } else if ((obj->WritePointer < 0) && (qY_0 > obj->WritePointer -
                  INT32_MIN)) {
        qY_0 = INT32_MIN;
      } else {
        qY_0 = obj->WritePointer - qY_0;
      }

      if (qY_0 > 2147483646) {
        *overlapUnderrun = INT32_MAX;
      } else {
        *overlapUnderrun = qY_0 + 1;
      }
    }
  } else {
    if (qY + 959 < qY_0) {
      n = 0;
    } else {
      n = (qY - qY_0) + 960;
    }

    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = n;
    emxEnsureCapacity_int32_t(y, k);
    if (n > 0) {
      y->data[0] = qY_0;
      yk = qY_0;
      for (k = 2; k <= n; k++) {
        yk++;
        y->data[k - 1] = yk;
      }
    }

    k = readIdx->size[0] * readIdx->size[1];
    readIdx->size[0] = 1;
    readIdx->size[1] = y->size[1];
    emxEnsureCapacity_int32_t(readIdx, k);
    qY_tmp_tmp = y->size[1];
    if (qY_tmp_tmp - 1 >= 0) {
      std::memcpy(&readIdx->data[0], &y->data[0], static_cast<uint32_t>
                  (qY_tmp_tmp) * sizeof(int32_t));
    }

    if ((rPtr <= obj->WritePointer) && (obj->WritePointer <= qY + 959)) {
      if ((qY + 959 >= 0) && (obj->WritePointer < qY - 2147482688)) {
        qY_0 = INT32_MAX;
      } else if ((qY + 959 < 0) && (obj->WritePointer > qY - 2147482689)) {
        qY_0 = INT32_MIN;
      } else {
        qY_0 = (qY - obj->WritePointer) + 959;
      }

      if (qY_0 > 2147483646) {
        *underrun = INT32_MAX;
      } else {
        *underrun = qY_0 + 1;
      }
    } else if ((qY_0 <= obj->WritePointer) && (obj->WritePointer < rPtr)) {
      if ((obj->WritePointer >= 0) && (qY_0 < obj->WritePointer - INT32_MAX)) {
        qY_0 = INT32_MAX;
      } else if ((obj->WritePointer < 0) && (qY_0 > obj->WritePointer -
                  INT32_MIN)) {
        qY_0 = INT32_MIN;
      } else {
        qY_0 = obj->WritePointer - qY_0;
      }

      if (qY_0 > 2147483646) {
        *overlapUnderrun = INT32_MAX;
      } else {
        *overlapUnderrun = qY_0 + 1;
      }
    }
  }

  emxFree_int32_t(&y_0);
  emxFree_int32_t(&y);
  k = out->size[0];
  out->size[0] = readIdx->size[1];
  emxEnsureCapacity_float(out, k);
  qY_tmp_tmp = readIdx->size[1];
  for (k = 0; k < qY_tmp_tmp; k++) {
    out->data[k] = obj->Cache[readIdx->data[k] - 1];
  }

  emxFree_int32_t(&readIdx);
  if (*underrun != 0) {
    if (*underrun < -2147482687) {
      qY_0 = INT32_MAX;
    } else {
      qY_0 = 960 - *underrun;
    }

    if (qY_0 > 2147483646) {
      qY_0 = INT32_MAX;
    } else {
      qY_0++;
    }

    if (qY_0 > 960) {
      rPtr = 0;
    } else {
      rPtr = qY_0 - 1;
    }

    if (*underrun - 1 >= 0) {
      std::memset(&out->data[rPtr], 0, static_cast<uint32_t>((*underrun + rPtr)
        - rPtr) * sizeof(float));
    }
  } else if (*overlapUnderrun != 0) {
    if (*overlapUnderrun == 960) {
      k = out->size[0];
      out->size[0] = 960;
      emxEnsureCapacity_float(out, k);
      std::memset(&out->data[0], 0, 960U * sizeof(float));
    } else if (*overlapUnderrun - 1 >= 0) {
      std::memset(&out->data[0], 0, static_cast<uint32_t>(*overlapUnderrun) *
                  sizeof(float));
    }
  }
}

void SmartMicDrvTsk_Ccode::emxFree_float(emxArray_float **pEmxArray)
{
  if (*pEmxArray != static_cast<emxArray_float *>(nullptr)) {
    if (((*pEmxArray)->data != static_cast<float *>(nullptr)) && (*pEmxArray)
        ->canFreeData) {
      std::free((*pEmxArray)->data);
    }

    std::free((*pEmxArray)->size);
    std::free(*pEmxArray);
    *pEmxArray = static_cast<emxArray_float *>(nullptr);
  }
}

void SmartMicDrvTsk_Ccode::FFTImplementationCallback_doH_j(const float x[960],
  creal32_T y[960], const creal32_T wwc[959], const float costabinv[1025], const
  float sintabinv[1025], DW_FFTSystem *localDW)
{
  static const creal32_T tmp_3[480]{ { 1.0F,// re
      -1.0F                            // im
    }, { 0.993455052F,                 // re
      -0.999978602F                    // im
    }, { 0.986910403F,                 // re
      -0.999914348F                    // im
    }, { 0.98036629F,                  // re
      -0.999807239F                    // im
    }, { 0.973823071F,                 // re
      -0.999657333F                    // im
    }, { 0.967280924F,                 // re
      -0.999464571F                    // im
    }, { 0.960740209F,                 // re
      -0.999229F                       // im
    }, { 0.954201102F,                 // re
      -0.99895066F                     // im
    }, { 0.947664F,                    // re
      -0.99862951F                     // im
    }, { 0.941129208F,                 // re
      -0.998265624F                    // im
    }, { 0.934596896F,                 // re
      -0.997858942F                    // im
    }, { 0.928067327F,                 // re
      -0.997409463F                    // im
    }, { 0.921540916F,                 // re
      -0.996917307F                    // im
    }, { 0.915017843F,                 // re
      -0.996382475F                    // im
    }, { 0.908498406F,                 // re
      -0.995804906F                    // im
    }, { 0.901982844F,                 // re
      -0.99518472F                     // im
    }, { 0.895471513F,                 // re
      -0.994521916F                    // im
    }, { 0.888964713F,                 // re
      -0.993816435F                    // im
    }, { 0.882462621F,                 // re
      -0.993068457F                    // im
    }, { 0.875965536F,                 // re
      -0.99227792F                     // im
    }, { 0.869473815F,                 // re
      -0.991444886F                    // im
    }, { 0.862987638F,                 // re
      -0.990569353F                    // im
    }, { 0.856507361F,                 // re
      -0.989651382F                    // im
    }, { 0.850033224F,                 // re
      -0.988691032F                    // im
    }, { 0.843565524F,                 // re
      -0.987688363F                    // im
    }, { 0.837104559F,                 // re
      -0.986643314F                    // im
    }, { 0.830650508F,                 // re
      -0.985556066F                    // im
    }, { 0.82420373F,                  // re
      -0.984426558F                    // im
    }, { 0.817764461F,                 // re
      -0.98325491F                     // im
    }, { 0.81133306F,                  // re
      -0.982041121F                    // im
    }, { 0.804909706F,                 // re
      -0.980785251F                    // im
    }, { 0.798494697F,                 // re
      -0.979487419F                    // im
    }, { 0.79208827F,                  // re
      -0.978147626F                    // im
    }, { 0.785690844F,                 // re
      -0.976765871F                    // im
    }, { 0.779302537F,                 // re
      -0.975342333F                    // im
    }, { 0.772923708F,                 // re
      -0.973876953F                    // im
    }, { 0.766554594F,                 // re
      -0.972369909F                    // im
    }, { 0.760195553F,                 // re
      -0.970821202F                    // im
    }, { 0.753846705F,                 // re
      -0.96923089F                     // im
    }, { 0.747508407F,                 // re
      -0.967599094F                    // im
    }, { 0.741180956F,                 // re
      -0.965925813F                    // im
    }, { 0.734864593F,                 // re
      -0.964211166F                    // im
    }, { 0.728559554F,                 // re
      -0.962455213F                    // im
    }, { 0.722266138F,                 // re
      -0.960658073F                    // im
    }, { 0.715984643F,                 // re
      -0.958819747F                    // im
    }, { 0.709715366F,                 // re
      -0.956940353F                    // im
    }, { 0.703458428F,                 // re
      -0.955019951F                    // im
    }, { 0.697214246F,                 // re
      -0.95305866F                     // im
    }, { 0.690983F,                    // re
      -0.95105654F                     // im
    }, { 0.684765F,                    // re
      -0.94901365F                     // im
    }, { 0.678560555F,                 // re
      -0.94693011F                     // im
    }, { 0.672369838F,                 // re
      -0.944806039F                    // im
    }, { 0.666193128F,                 // re
      -0.942641497F                    // im
    }, { 0.660030723F,                 // re
      -0.940436542F                    // im
    }, { 0.653882921F,                 // re
      -0.938191354F                    // im
    }, { 0.647749901F,                 // re
      -0.935905933F                    // im
    }, { 0.64163208F,                  // re
      -0.933580399F                    // im
    }, { 0.635529518F,                 // re
      -0.931214929F                    // im
    }, { 0.629442573F,                 // re
      -0.928809524F                    // im
    }, { 0.623371482F,                 // re
      -0.926364362F                    // im
    }, { 0.617316544F,                 // re
      -0.923879504F                    // im
    }, { 0.611278057F,                 // re
      -0.921355128F                    // im
    }, { 0.605256081F,                 // re
      -0.918791175F                    // im
    }, { 0.599251151F,                 // re
      -0.916187942F                    // im
    }, { 0.593263388F,                 // re
      -0.91354543F                     // im
    }, { 0.587292969F,                 // re
      -0.910863817F                    // im
    }, { 0.581340253F,                 // re
      -0.908143163F                    // im
    }, { 0.575405478F,                 // re
      -0.905383587F                    // im
    }, { 0.569488883F,                 // re
      -0.902585268F                    // im
    }, { 0.563590765F,                 // re
      -0.899748266F                    // im
    }, { 0.557711244F,                 // re
      -0.896872699F                    // im
    }, { 0.551850796F,                 // re
      -0.893958747F                    // im
    }, { 0.546009481F,                 // re
      -0.891006529F                    // im
    }, { 0.540187597F,                 // re
      -0.888016105F                    // im
    }, { 0.534385443F,                 // re
      -0.884987652F                    // im
    }, { 0.528603256F,                 // re
      -0.881921232F                    // im
    }, { 0.522841215F,                 // re
      -0.878817081F                    // im
    }, { 0.517099619F,                 // re
      -0.875675321F                    // im
    }, { 0.511378765F,                 // re
      -0.872496F                       // im
    }, { 0.505678773F,                 // re
      -0.869279325F                    // im
    }, { 0.5F,                         // re
      -0.866025388F                    // im
    }, { 0.494342566F,                 // re
      -0.862734377F                    // im
    }, { 0.488706887F,                 // re
      -0.859406412F                    // im
    }, { 0.483093083F,                 // re
      -0.85604161F                     // im
    }, { 0.477501452F,                 // re
      -0.852640152F                    // im
    }, { 0.471932173F,                 // re
      -0.849202156F                    // im
    }, { 0.466385484F,                 // re
      -0.845727801F                    // im
    }, { 0.460861683F,                 // re
      -0.842217207F                    // im
    }, { 0.455360949F,                 // re
      -0.838670552F                    // im
    }, { 0.44988358F,                  // re
      -0.835087955F                    // im
    }, { 0.444429755F,                 // re
      -0.831469595F                    // im
    }, { 0.438999712F,                 // re
      -0.827815592F                    // im
    }, { 0.43359375F,                  // re
      -0.824126184F                    // im
    }, { 0.428212047F,                 // re
      -0.82040143F                     // im
    }, { 0.422854781F,                 // re
      -0.816641569F                    // im
    }, { 0.417522311F,                 // re
      -0.812846661F                    // im
    }, { 0.412214756F,                 // re
      -0.809017F                       // im
    }, { 0.406932354F,                 // re
      -0.805152655F                    // im
    }, { 0.401675403F,                 // re
      -0.801253796F                    // im
    }, { 0.396444023F,                 // re
      -0.797320604F                    // im
    }, { 0.39123857F,                  // re
      -0.793353319F                    // im
    }, { 0.386059165F,                 // re
      -0.789352059F                    // im
    }, { 0.380906045F,                 // re
      -0.785316944F                    // im
    }, { 0.37577945F,                  // re
      -0.781248152F                    // im
    }, { 0.370679617F,                 // re
      -0.777146F                       // im
    }, { 0.365606666F,                 // re
      -0.773010433F                    // im
    }, { 0.360561F,                    // re
      -0.768841803F                    // im
    }, { 0.35554266F,                  // re
      -0.764640272F                    // im
    }, { 0.350551903F,                 // re
      -0.760405958F                    // im
    }, { 0.345589042F,                 // re
      -0.7561391F                      // im
    }, { 0.340654135F,                 // re
      -0.751839757F                    // im
    }, { 0.33574754F,                  // re
      -0.747508347F                    // im
    }, { 0.330869377F,                 // re
      -0.74314481F                     // im
    }, { 0.326019883F,                 // re
      -0.738749444F                    // im
    }, { 0.321199238F,                 // re
      -0.734322488F                    // im
    }, { 0.316407681F,                 // re
      -0.729864061F                    // im
    }, { 0.311645448F,                 // re
      -0.725374341F                    // im
    }, { 0.306912661F,                 // re
      -0.720853567F                    // im
    }, { 0.302209496F,                 // re
      -0.716301918F                    // im
    }, { 0.297536314F,                 // re
      -0.711719632F                    // im
    }, { 0.292893231F,                 // re
      -0.707106769F                    // im
    }, { 0.288280368F,                 // re
      -0.702463686F                    // im
    }, { 0.283698082F,                 // re
      -0.697790504F                    // im
    }, { 0.279146433F,                 // re
      -0.693087339F                    // im
    }, { 0.274625659F,                 // re
      -0.688354552F                    // im
    }, { 0.270135939F,                 // re
      -0.683592319F                    // im
    }, { 0.265677512F,                 // re
      -0.678800762F                    // im
    }, { 0.261250556F,                 // re
      -0.673980117F                    // im
    }, { 0.25685519F,                  // re
      -0.669130623F                    // im
    }, { 0.252491653F,                 // re
      -0.66425246F                     // im
    }, { 0.248160243F,                 // re
      -0.659345865F                    // im
    }, { 0.2438609F,                   // re
      -0.654410958F                    // im
    }, { 0.239594042F,                 // re
      -0.649448097F                    // im
    }, { 0.235359728F,                 // re
      -0.64445734F                     // im
    }, { 0.231158197F,                 // re
      -0.639439F                       // im
    }, { 0.226989567F,                 // re
      -0.634393334F                    // im
    }, { 0.222854018F,                 // re
      -0.629320383F                    // im
    }, { 0.218751848F,                 // re
      -0.62422055F                     // im
    }, { 0.214683056F,                 // re
      -0.619093955F                    // im
    }, { 0.210647941F,                 // re
      -0.613940835F                    // im
    }, { 0.206646681F,                 // re
      -0.60876143F                     // im
    }, { 0.202679396F,                 // re
      -0.603556F                       // im
    }, { 0.198746204F,                 // re
      -0.598324597F                    // im
    }, { 0.194847345F,                 // re
      -0.593067646F                    // im
    }, { 0.190983F,                    // re
      -0.587785244F                    // im
    }, { 0.187153339F,                 // re
      -0.582477689F                    // im
    }, { 0.183358431F,                 // re
      -0.577145219F                    // im
    }, { 0.17959857F,                  // re
      -0.571787953F                    // im
    }, { 0.175873816F,                 // re
      -0.56640625F                     // im
    }, { 0.172184408F,                 // re
      -0.561000288F                    // im
    }, { 0.168530405F,                 // re
      -0.555570245F                    // im
    }, { 0.164912045F,                 // re
      -0.55011642F                     // im
    }, { 0.161329448F,                 // re
      -0.544639051F                    // im
    }, { 0.157782793F,                 // re
      -0.539138317F                    // im
    }, { 0.154272199F,                 // re
      -0.533614516F                    // im
    }, { 0.150797844F,                 // re
      -0.528067827F                    // im
    }, { 0.147359848F,                 // re
      -0.522498548F                    // im
    }, { 0.14395839F,                  // re
      -0.516906917F                    // im
    }, { 0.140593588F,                 // re
      -0.511293113F                    // im
    }, { 0.137265623F,                 // re
      -0.505657434F                    // im
    }, { 0.133974612F,                 // re
      -0.5F                            // im
    }, { 0.130720675F,                 // re
      -0.494321197F                    // im
    }, { 0.127503991F,                 // re
      -0.488621265F                    // im
    }, { 0.124324679F,                 // re
      -0.482900351F                    // im
    }, { 0.121182919F,                 // re
      -0.477158785F                    // im
    }, { 0.118078768F,                 // re
      -0.471396744F                    // im
    }, { 0.115012348F,                 // re
      -0.465614527F                    // im
    }, { 0.111983895F,                 // re
      -0.459812373F                    // im
    }, { 0.108993471F,                 // re
      -0.453990519F                    // im
    }, { 0.106041253F,                 // re
      -0.448149204F                    // im
    }, { 0.103127301F,                 // re
      -0.442288727F                    // im
    }, { 0.100251734F,                 // re
      -0.436409235F                    // im
    }, { 0.097414732F,                 // re
      -0.430511117F                    // im
    }, { 0.0946164131F,                // re
      -0.424594522F                    // im
    }, { 0.0918568373F,                // re
      -0.418659747F                    // im
    }, { 0.0891361833F,                // re
      -0.412707031F                    // im
    }, { 0.0864545703F,                // re
      -0.406736642F                    // im
    }, { 0.083812058F,                 // re
      -0.400748849F                    // im
    }, { 0.0812088251F,                // re
      -0.39474389F                     // im
    }, { 0.0786448717F,                // re
      -0.388721973F                    // im
    }, { 0.0761204958F,                // re
      -0.382683456F                    // im
    }, { 0.0736356378F,                // re
      -0.376628518F                    // im
    }, { 0.0711904764F,                // re
      -0.370557427F                    // im
    }, { 0.0687850714F,                // re
      -0.364470512F                    // im
    }, { 0.0664196F,                   // re
      -0.35836795F                     // im
    }, { 0.0640940666F,                // re
      -0.352250069F                    // im
    }, { 0.0618086457F,                // re
      -0.346117079F                    // im
    }, { 0.059563458F,                 // re
      -0.339969248F                    // im
    }, { 0.0573585033F,                // re
      -0.333806872F                    // im
    }, { 0.0551939607F,                // re
      -0.327630192F                    // im
    }, { 0.0530698895F,                // re
      -0.321439445F                    // im
    }, { 0.0509863496F,                // re
      -0.315235F                       // im
    }, { 0.04894346F,                  // re
      -0.309017F                       // im
    }, { 0.04694134F,                  // re
      -0.302785784F                    // im
    }, { 0.0449800491F,                // re
      -0.296541601F                    // im
    }, { 0.0430596471F,                // re
      -0.290284663F                    // im
    }, { 0.041180253F,                 // re
      -0.284015357F                    // im
    }, { 0.0393419266F,                // re
      -0.277733862F                    // im
    }, { 0.0375447869F,                // re
      -0.271440446F                    // im
    }, { 0.0357888341F,                // re
      -0.265135437F                    // im
    }, { 0.0340741873F,                // re
      -0.258819044F                    // im
    }, { 0.0324009061F,                // re
      -0.252491593F                    // im
    }, { 0.0307691097F,                // re
      -0.246153295F                    // im
    }, { 0.0291787982F,                // re
      -0.239804462F                    // im
    }, { 0.0276300907F,                // re
      -0.233445376F                    // im
    }, { 0.0261230469F,                // re
      -0.227076277F                    // im
    }, { 0.0246576667F,                // re
      -0.220697448F                    // im
    }, { 0.023234129F,                 // re
      -0.214309156F                    // im
    }, { 0.0218523741F,                // re
      -0.2079117F                      // im
    }, { 0.0205125809F,                // re
      -0.201505333F                    // im
    }, { 0.0192147493F,                // re
      -0.195090324F                    // im
    }, { 0.0179588795F,                // re
      -0.18866697F                     // im
    }, { 0.0167450905F,                // re
      -0.182235524F                    // im
    }, { 0.015573442F,                 // re
      -0.175796285F                    // im
    }, { 0.014443934F,                 // re
      -0.169349506F                    // im
    }, { 0.0133566856F,                // re
      -0.162895471F                    // im
    }, { 0.0123116374F,                // re
      -0.156434476F                    // im
    }, { 0.0113089681F,                // re
      -0.149966761F                    // im
    }, { 0.010348618F,                 // re
      -0.143492624F                    // im
    }, { 0.0094306469F,                // re
      -0.137012333F                    // im
    }, { 0.00855511427F,               // re
      -0.1305262F                      // im
    }, { 0.00772207975F,               // re
      -0.124034457F                    // im
    }, { 0.00693154335F,               // re
      -0.117537402F                    // im
    }, { 0.00618356466F,               // re
      -0.11103531F                     // im
    }, { 0.00547808409F,               // re
      -0.104528464F                    // im
    }, { 0.00481528044F,               // re
      -0.0980171412F                   // im
    }, { 0.00419509411F,               // re
      -0.0915016234F                   // im
    }, { 0.0036175251F,                // re
      -0.0849821791F                   // im
    }, { 0.00308269262F,               // re
      -0.0784591F                      // im
    }, { 0.00259053707F,               // re
      -0.0719326586F                   // im
    }, { 0.00214105844F,               // re
      -0.0654031336F                   // im
    }, { 0.00173437595F,               // re
      -0.0588708036F                   // im
    }, { 0.0013704896F,                // re
      -0.0523359589F                   // im
    }, { 0.00104933977F,               // re
      -0.0457988679F                   // im
    }, { 0.00077098608F,               // re
      -0.0392598175F                   // im
    }, { 0.000535428524F,              // re
      -0.0327190831F                   // im
    }, { 0.000342667103F,              // re
      -0.02617695F                     // im
    }, { 0.000192761421F,              // re
      -0.0196336936F                   // im
    }, { 8.56518745E-5F,               // re
      -0.0130895963F                   // im
    }, { 2.13980675E-5F,               // re
      -0.00654493831F                  // im
    }, { 0.0F,                         // re
      -0.0F                            // im
    }, { 2.13980675E-5F,               // re
      0.00654493831F                   // im
    }, { 8.56518745E-5F,               // re
      0.0130895963F                    // im
    }, { 0.000192761421F,              // re
      0.0196336936F                    // im
    }, { 0.000342667103F,              // re
      0.02617695F                      // im
    }, { 0.000535428524F,              // re
      0.0327190831F                    // im
    }, { 0.00077098608F,               // re
      0.0392598175F                    // im
    }, { 0.00104933977F,               // re
      0.0457988679F                    // im
    }, { 0.0013704896F,                // re
      0.0523359589F                    // im
    }, { 0.00173437595F,               // re
      0.0588708036F                    // im
    }, { 0.00214105844F,               // re
      0.0654031336F                    // im
    }, { 0.00259053707F,               // re
      0.0719326586F                    // im
    }, { 0.00308269262F,               // re
      0.0784591F                       // im
    }, { 0.0036175251F,                // re
      0.0849821791F                    // im
    }, { 0.00419509411F,               // re
      0.0915016234F                    // im
    }, { 0.00481528044F,               // re
      0.0980171412F                    // im
    }, { 0.00547808409F,               // re
      0.104528464F                     // im
    }, { 0.00618356466F,               // re
      0.11103531F                      // im
    }, { 0.00693154335F,               // re
      0.117537402F                     // im
    }, { 0.00772207975F,               // re
      0.124034457F                     // im
    }, { 0.00855511427F,               // re
      0.1305262F                       // im
    }, { 0.0094306469F,                // re
      0.137012333F                     // im
    }, { 0.010348618F,                 // re
      0.143492624F                     // im
    }, { 0.0113089681F,                // re
      0.149966761F                     // im
    }, { 0.0123116374F,                // re
      0.156434476F                     // im
    }, { 0.0133566856F,                // re
      0.162895471F                     // im
    }, { 0.014443934F,                 // re
      0.169349506F                     // im
    }, { 0.015573442F,                 // re
      0.175796285F                     // im
    }, { 0.0167450905F,                // re
      0.182235524F                     // im
    }, { 0.0179588795F,                // re
      0.18866697F                      // im
    }, { 0.0192147493F,                // re
      0.195090324F                     // im
    }, { 0.0205125809F,                // re
      0.201505333F                     // im
    }, { 0.0218523741F,                // re
      0.2079117F                       // im
    }, { 0.023234129F,                 // re
      0.214309156F                     // im
    }, { 0.0246576667F,                // re
      0.220697448F                     // im
    }, { 0.0261230469F,                // re
      0.227076277F                     // im
    }, { 0.0276300907F,                // re
      0.233445376F                     // im
    }, { 0.0291787982F,                // re
      0.239804462F                     // im
    }, { 0.0307691097F,                // re
      0.246153295F                     // im
    }, { 0.0324009061F,                // re
      0.252491593F                     // im
    }, { 0.0340741873F,                // re
      0.258819044F                     // im
    }, { 0.0357888341F,                // re
      0.265135437F                     // im
    }, { 0.0375447869F,                // re
      0.271440446F                     // im
    }, { 0.0393419266F,                // re
      0.277733862F                     // im
    }, { 0.041180253F,                 // re
      0.284015357F                     // im
    }, { 0.0430596471F,                // re
      0.290284663F                     // im
    }, { 0.0449800491F,                // re
      0.296541601F                     // im
    }, { 0.04694134F,                  // re
      0.302785784F                     // im
    }, { 0.04894346F,                  // re
      0.309017F                        // im
    }, { 0.0509863496F,                // re
      0.315235F                        // im
    }, { 0.0530698895F,                // re
      0.321439445F                     // im
    }, { 0.0551939607F,                // re
      0.327630192F                     // im
    }, { 0.0573585033F,                // re
      0.333806872F                     // im
    }, { 0.059563458F,                 // re
      0.339969248F                     // im
    }, { 0.0618086457F,                // re
      0.346117079F                     // im
    }, { 0.0640940666F,                // re
      0.352250069F                     // im
    }, { 0.0664196F,                   // re
      0.35836795F                      // im
    }, { 0.0687850714F,                // re
      0.364470512F                     // im
    }, { 0.0711904764F,                // re
      0.370557427F                     // im
    }, { 0.0736356378F,                // re
      0.376628518F                     // im
    }, { 0.0761204958F,                // re
      0.382683456F                     // im
    }, { 0.0786448717F,                // re
      0.388721973F                     // im
    }, { 0.0812088251F,                // re
      0.39474389F                      // im
    }, { 0.083812058F,                 // re
      0.400748849F                     // im
    }, { 0.0864545703F,                // re
      0.406736642F                     // im
    }, { 0.0891361833F,                // re
      0.412707031F                     // im
    }, { 0.0918568373F,                // re
      0.418659747F                     // im
    }, { 0.0946164131F,                // re
      0.424594522F                     // im
    }, { 0.097414732F,                 // re
      0.430511117F                     // im
    }, { 0.100251734F,                 // re
      0.436409235F                     // im
    }, { 0.103127301F,                 // re
      0.442288727F                     // im
    }, { 0.106041253F,                 // re
      0.448149204F                     // im
    }, { 0.108993471F,                 // re
      0.453990519F                     // im
    }, { 0.111983895F,                 // re
      0.459812373F                     // im
    }, { 0.115012348F,                 // re
      0.465614527F                     // im
    }, { 0.118078768F,                 // re
      0.471396744F                     // im
    }, { 0.121182919F,                 // re
      0.477158785F                     // im
    }, { 0.124324679F,                 // re
      0.482900351F                     // im
    }, { 0.127503991F,                 // re
      0.488621265F                     // im
    }, { 0.130720675F,                 // re
      0.494321197F                     // im
    }, { 0.133974612F,                 // re
      0.5F                             // im
    }, { 0.137265623F,                 // re
      0.505657434F                     // im
    }, { 0.140593588F,                 // re
      0.511293113F                     // im
    }, { 0.14395839F,                  // re
      0.516906917F                     // im
    }, { 0.147359848F,                 // re
      0.522498548F                     // im
    }, { 0.150797844F,                 // re
      0.528067827F                     // im
    }, { 0.154272199F,                 // re
      0.533614516F                     // im
    }, { 0.157782793F,                 // re
      0.539138317F                     // im
    }, { 0.161329448F,                 // re
      0.544639051F                     // im
    }, { 0.164912045F,                 // re
      0.55011642F                      // im
    }, { 0.168530405F,                 // re
      0.555570245F                     // im
    }, { 0.172184408F,                 // re
      0.561000288F                     // im
    }, { 0.175873816F,                 // re
      0.56640625F                      // im
    }, { 0.17959857F,                  // re
      0.571787953F                     // im
    }, { 0.183358431F,                 // re
      0.577145219F                     // im
    }, { 0.187153339F,                 // re
      0.582477689F                     // im
    }, { 0.190983F,                    // re
      0.587785244F                     // im
    }, { 0.194847345F,                 // re
      0.593067646F                     // im
    }, { 0.198746204F,                 // re
      0.598324597F                     // im
    }, { 0.202679396F,                 // re
      0.603556F                        // im
    }, { 0.206646681F,                 // re
      0.60876143F                      // im
    }, { 0.210647941F,                 // re
      0.613940835F                     // im
    }, { 0.214683056F,                 // re
      0.619093955F                     // im
    }, { 0.218751848F,                 // re
      0.62422055F                      // im
    }, { 0.222854018F,                 // re
      0.629320383F                     // im
    }, { 0.226989567F,                 // re
      0.634393334F                     // im
    }, { 0.231158197F,                 // re
      0.639439F                        // im
    }, { 0.235359728F,                 // re
      0.64445734F                      // im
    }, { 0.239594042F,                 // re
      0.649448097F                     // im
    }, { 0.2438609F,                   // re
      0.654410958F                     // im
    }, { 0.248160243F,                 // re
      0.659345865F                     // im
    }, { 0.252491653F,                 // re
      0.66425246F                      // im
    }, { 0.25685519F,                  // re
      0.669130623F                     // im
    }, { 0.261250556F,                 // re
      0.673980117F                     // im
    }, { 0.265677512F,                 // re
      0.678800762F                     // im
    }, { 0.270135939F,                 // re
      0.683592319F                     // im
    }, { 0.274625659F,                 // re
      0.688354552F                     // im
    }, { 0.279146433F,                 // re
      0.693087339F                     // im
    }, { 0.283698082F,                 // re
      0.697790504F                     // im
    }, { 0.288280368F,                 // re
      0.702463686F                     // im
    }, { 0.292893231F,                 // re
      0.707106769F                     // im
    }, { 0.297536314F,                 // re
      0.711719632F                     // im
    }, { 0.302209496F,                 // re
      0.716301918F                     // im
    }, { 0.306912661F,                 // re
      0.720853567F                     // im
    }, { 0.311645448F,                 // re
      0.725374341F                     // im
    }, { 0.316407681F,                 // re
      0.729864061F                     // im
    }, { 0.321199238F,                 // re
      0.734322488F                     // im
    }, { 0.326019883F,                 // re
      0.738749444F                     // im
    }, { 0.330869377F,                 // re
      0.74314481F                      // im
    }, { 0.33574754F,                  // re
      0.747508347F                     // im
    }, { 0.340654135F,                 // re
      0.751839757F                     // im
    }, { 0.345589042F,                 // re
      0.7561391F                       // im
    }, { 0.350551903F,                 // re
      0.760405958F                     // im
    }, { 0.35554266F,                  // re
      0.764640272F                     // im
    }, { 0.360561F,                    // re
      0.768841803F                     // im
    }, { 0.365606666F,                 // re
      0.773010433F                     // im
    }, { 0.370679617F,                 // re
      0.777146F                        // im
    }, { 0.37577945F,                  // re
      0.781248152F                     // im
    }, { 0.380906045F,                 // re
      0.785316944F                     // im
    }, { 0.386059165F,                 // re
      0.789352059F                     // im
    }, { 0.39123857F,                  // re
      0.793353319F                     // im
    }, { 0.396444023F,                 // re
      0.797320604F                     // im
    }, { 0.401675403F,                 // re
      0.801253796F                     // im
    }, { 0.406932354F,                 // re
      0.805152655F                     // im
    }, { 0.412214756F,                 // re
      0.809017F                        // im
    }, { 0.417522311F,                 // re
      0.812846661F                     // im
    }, { 0.422854781F,                 // re
      0.816641569F                     // im
    }, { 0.428212047F,                 // re
      0.82040143F                      // im
    }, { 0.43359375F,                  // re
      0.824126184F                     // im
    }, { 0.438999712F,                 // re
      0.827815592F                     // im
    }, { 0.444429755F,                 // re
      0.831469595F                     // im
    }, { 0.44988358F,                  // re
      0.835087955F                     // im
    }, { 0.455360949F,                 // re
      0.838670552F                     // im
    }, { 0.460861683F,                 // re
      0.842217207F                     // im
    }, { 0.466385484F,                 // re
      0.845727801F                     // im
    }, { 0.471932173F,                 // re
      0.849202156F                     // im
    }, { 0.477501452F,                 // re
      0.852640152F                     // im
    }, { 0.483093083F,                 // re
      0.85604161F                      // im
    }, { 0.488706887F,                 // re
      0.859406412F                     // im
    }, { 0.494342566F,                 // re
      0.862734377F                     // im
    }, { 0.5F,                         // re
      0.866025388F                     // im
    }, { 0.505678773F,                 // re
      0.869279325F                     // im
    }, { 0.511378765F,                 // re
      0.872496F                        // im
    }, { 0.517099619F,                 // re
      0.875675321F                     // im
    }, { 0.522841215F,                 // re
      0.878817081F                     // im
    }, { 0.528603256F,                 // re
      0.881921232F                     // im
    }, { 0.534385443F,                 // re
      0.884987652F                     // im
    }, { 0.540187597F,                 // re
      0.888016105F                     // im
    }, { 0.546009481F,                 // re
      0.891006529F                     // im
    }, { 0.551850796F,                 // re
      0.893958747F                     // im
    }, { 0.557711244F,                 // re
      0.896872699F                     // im
    }, { 0.563590765F,                 // re
      0.899748266F                     // im
    }, { 0.569488883F,                 // re
      0.902585268F                     // im
    }, { 0.575405478F,                 // re
      0.905383587F                     // im
    }, { 0.581340253F,                 // re
      0.908143163F                     // im
    }, { 0.587292969F,                 // re
      0.910863817F                     // im
    }, { 0.593263388F,                 // re
      0.91354543F                      // im
    }, { 0.599251151F,                 // re
      0.916187942F                     // im
    }, { 0.605256081F,                 // re
      0.918791175F                     // im
    }, { 0.611278057F,                 // re
      0.921355128F                     // im
    }, { 0.617316544F,                 // re
      0.923879504F                     // im
    }, { 0.623371482F,                 // re
      0.926364362F                     // im
    }, { 0.629442573F,                 // re
      0.928809524F                     // im
    }, { 0.635529518F,                 // re
      0.931214929F                     // im
    }, { 0.64163208F,                  // re
      0.933580399F                     // im
    }, { 0.647749901F,                 // re
      0.935905933F                     // im
    }, { 0.653882921F,                 // re
      0.938191354F                     // im
    }, { 0.660030723F,                 // re
      0.940436542F                     // im
    }, { 0.666193128F,                 // re
      0.942641497F                     // im
    }, { 0.672369838F,                 // re
      0.944806039F                     // im
    }, { 0.678560555F,                 // re
      0.94693011F                      // im
    }, { 0.684765F,                    // re
      0.94901365F                      // im
    }, { 0.690983F,                    // re
      0.95105654F                      // im
    }, { 0.697214246F,                 // re
      0.95305866F                      // im
    }, { 0.703458428F,                 // re
      0.955019951F                     // im
    }, { 0.709715366F,                 // re
      0.956940353F                     // im
    }, { 0.715984643F,                 // re
      0.958819747F                     // im
    }, { 0.722266138F,                 // re
      0.960658073F                     // im
    }, { 0.728559554F,                 // re
      0.962455213F                     // im
    }, { 0.734864593F,                 // re
      0.964211166F                     // im
    }, { 0.741180956F,                 // re
      0.965925813F                     // im
    }, { 0.747508407F,                 // re
      0.967599094F                     // im
    }, { 0.753846705F,                 // re
      0.96923089F                      // im
    }, { 0.760195553F,                 // re
      0.970821202F                     // im
    }, { 0.766554594F,                 // re
      0.972369909F                     // im
    }, { 0.772923708F,                 // re
      0.973876953F                     // im
    }, { 0.779302537F,                 // re
      0.975342333F                     // im
    }, { 0.785690844F,                 // re
      0.976765871F                     // im
    }, { 0.79208827F,                  // re
      0.978147626F                     // im
    }, { 0.798494697F,                 // re
      0.979487419F                     // im
    }, { 0.804909706F,                 // re
      0.980785251F                     // im
    }, { 0.81133306F,                  // re
      0.982041121F                     // im
    }, { 0.817764461F,                 // re
      0.98325491F                      // im
    }, { 0.82420373F,                  // re
      0.984426558F                     // im
    }, { 0.830650508F,                 // re
      0.985556066F                     // im
    }, { 0.837104559F,                 // re
      0.986643314F                     // im
    }, { 0.843565524F,                 // re
      0.987688363F                     // im
    }, { 0.850033224F,                 // re
      0.988691032F                     // im
    }, { 0.856507361F,                 // re
      0.989651382F                     // im
    }, { 0.862987638F,                 // re
      0.990569353F                     // im
    }, { 0.869473815F,                 // re
      0.991444886F                     // im
    }, { 0.875965536F,                 // re
      0.99227792F                      // im
    }, { 0.882462621F,                 // re
      0.993068457F                     // im
    }, { 0.888964713F,                 // re
      0.993816435F                     // im
    }, { 0.895471513F,                 // re
      0.994521916F                     // im
    }, { 0.901982844F,                 // re
      0.99518472F                      // im
    }, { 0.908498406F,                 // re
      0.995804906F                     // im
    }, { 0.915017843F,                 // re
      0.996382475F                     // im
    }, { 0.921540916F,                 // re
      0.996917307F                     // im
    }, { 0.928067327F,                 // re
      0.997409463F                     // im
    }, { 0.934596896F,                 // re
      0.997858942F                     // im
    }, { 0.941129208F,                 // re
      0.998265624F                     // im
    }, { 0.947664F,                    // re
      0.99862951F                      // im
    }, { 0.954201102F,                 // re
      0.99895066F                      // im
    }, { 0.960740209F,                 // re
      0.999229F                        // im
    }, { 0.967280924F,                 // re
      0.999464571F                     // im
    }, { 0.973823071F,                 // re
      0.999657333F                     // im
    }, { 0.98036629F,                  // re
      0.999807239F                     // im
    }, { 0.986910403F,                 // re
      0.999914348F                     // im
    }, { 0.993455052F,                 // re
      0.999978602F                     // im
    } };

  static const creal32_T tmp_4[480]{ { 1.0F,// re
      1.0F                             // im
    }, { 1.00654495F,                  // re
      0.999978602F                     // im
    }, { 1.01308954F,                  // re
      0.999914348F                     // im
    }, { 1.01963365F,                  // re
      0.999807239F                     // im
    }, { 1.02617693F,                  // re
      0.999657333F                     // im
    }, { 1.03271914F,                  // re
      0.999464571F                     // im
    }, { 1.03925979F,                  // re
      0.999229F                        // im
    }, { 1.0457989F,                   // re
      0.99895066F                      // im
    }, { 1.05233598F,                  // re
      0.99862951F                      // im
    }, { 1.05887079F,                  // re
      0.998265624F                     // im
    }, { 1.0654031F,                   // re
      0.997858942F                     // im
    }, { 1.07193267F,                  // re
      0.997409463F                     // im
    }, { 1.07845914F,                  // re
      0.996917307F                     // im
    }, { 1.08498216F,                  // re
      0.996382475F                     // im
    }, { 1.09150159F,                  // re
      0.995804906F                     // im
    }, { 1.0980171F,                   // re
      0.99518472F                      // im
    }, { 1.10452843F,                  // re
      0.994521916F                     // im
    }, { 1.11103535F,                  // re
      0.993816435F                     // im
    }, { 1.11753738F,                  // re
      0.993068457F                     // im
    }, { 1.1240344F,                   // re
      0.99227792F                      // im
    }, { 1.13052619F,                  // re
      0.991444886F                     // im
    }, { 1.13701236F,                  // re
      0.990569353F                     // im
    }, { 1.14349258F,                  // re
      0.989651382F                     // im
    }, { 1.14996672F,                  // re
      0.988691032F                     // im
    }, { 1.15643454F,                  // re
      0.987688363F                     // im
    }, { 1.16289544F,                  // re
      0.986643314F                     // im
    }, { 1.16934955F,                  // re
      0.985556066F                     // im
    }, { 1.17579627F,                  // re
      0.984426558F                     // im
    }, { 1.18223548F,                  // re
      0.98325491F                      // im
    }, { 1.18866694F,                  // re
      0.982041121F                     // im
    }, { 1.19509029F,                  // re
      0.980785251F                     // im
    }, { 1.2015053F,                   // re
      0.979487419F                     // im
    }, { 1.20791173F,                  // re
      0.978147626F                     // im
    }, { 1.21430922F,                  // re
      0.976765871F                     // im
    }, { 1.2206974F,                   // re
      0.975342333F                     // im
    }, { 1.22707629F,                  // re
      0.973876953F                     // im
    }, { 1.23344541F,                  // re
      0.972369909F                     // im
    }, { 1.23980451F,                  // re
      0.970821202F                     // im
    }, { 1.24615335F,                  // re
      0.96923089F                      // im
    }, { 1.25249159F,                  // re
      0.967599094F                     // im
    }, { 1.2588191F,                   // re
      0.965925813F                     // im
    }, { 1.26513541F,                  // re
      0.964211166F                     // im
    }, { 1.27144051F,                  // re
      0.962455213F                     // im
    }, { 1.2777338F,                   // re
      0.960658073F                     // im
    }, { 1.28401542F,                  // re
      0.958819747F                     // im
    }, { 1.29028463F,                  // re
      0.956940353F                     // im
    }, { 1.29654157F,                  // re
      0.955019951F                     // im
    }, { 1.30278575F,                  // re
      0.95305866F                      // im
    }, { 1.30901694F,                  // re
      0.95105654F                      // im
    }, { 1.31523502F,                  // re
      0.94901365F                      // im
    }, { 1.3214395F,                   // re
      0.94693011F                      // im
    }, { 1.32763016F,                  // re
      0.944806039F                     // im
    }, { 1.33380687F,                  // re
      0.942641497F                     // im
    }, { 1.33996928F,                  // re
      0.940436542F                     // im
    }, { 1.34611702F,                  // re
      0.938191354F                     // im
    }, { 1.3522501F,                   // re
      0.935905933F                     // im
    }, { 1.35836792F,                  // re
      0.933580399F                     // im
    }, { 1.36447048F,                  // re
      0.931214929F                     // im
    }, { 1.37055743F,                  // re
      0.928809524F                     // im
    }, { 1.37662852F,                  // re
      0.926364362F                     // im
    }, { 1.38268352F,                  // re
      0.923879504F                     // im
    }, { 1.38872194F,                  // re
      0.921355128F                     // im
    }, { 1.39474392F,                  // re
      0.918791175F                     // im
    }, { 1.40074885F,                  // re
      0.916187942F                     // im
    }, { 1.40673661F,                  // re
      0.91354543F                      // im
    }, { 1.41270709F,                  // re
      0.910863817F                     // im
    }, { 1.41865969F,                  // re
      0.908143163F                     // im
    }, { 1.42459452F,                  // re
      0.905383587F                     // im
    }, { 1.43051112F,                  // re
      0.902585268F                     // im
    }, { 1.43640924F,                  // re
      0.899748266F                     // im
    }, { 1.44228876F,                  // re
      0.896872699F                     // im
    }, { 1.4481492F,                   // re
      0.893958747F                     // im
    }, { 1.45399046F,                  // re
      0.891006529F                     // im
    }, { 1.4598124F,                   // re
      0.888016105F                     // im
    }, { 1.46561456F,                  // re
      0.884987652F                     // im
    }, { 1.47139668F,                  // re
      0.881921232F                     // im
    }, { 1.47715878F,                  // re
      0.878817081F                     // im
    }, { 1.48290038F,                  // re
      0.875675321F                     // im
    }, { 1.48862123F,                  // re
      0.872496F                        // im
    }, { 1.49432123F,                  // re
      0.869279325F                     // im
    }, { 1.5F,                         // re
      0.866025388F                     // im
    }, { 1.50565743F,                  // re
      0.862734377F                     // im
    }, { 1.51129317F,                  // re
      0.859406412F                     // im
    }, { 1.51690698F,                  // re
      0.85604161F                      // im
    }, { 1.52249861F,                  // re
      0.852640152F                     // im
    }, { 1.52806783F,                  // re
      0.849202156F                     // im
    }, { 1.53361452F,                  // re
      0.845727801F                     // im
    }, { 1.53913832F,                  // re
      0.842217207F                     // im
    }, { 1.54463911F,                  // re
      0.838670552F                     // im
    }, { 1.55011642F,                  // re
      0.835087955F                     // im
    }, { 1.55557024F,                  // re
      0.831469595F                     // im
    }, { 1.56100035F,                  // re
      0.827815592F                     // im
    }, { 1.56640625F,                  // re
      0.824126184F                     // im
    }, { 1.57178795F,                  // re
      0.82040143F                      // im
    }, { 1.57714522F,                  // re
      0.816641569F                     // im
    }, { 1.58247769F,                  // re
      0.812846661F                     // im
    }, { 1.58778524F,                  // re
      0.809017F                        // im
    }, { 1.59306765F,                  // re
      0.805152655F                     // im
    }, { 1.59832454F,                  // re
      0.801253796F                     // im
    }, { 1.60355592F,                  // re
      0.797320604F                     // im
    }, { 1.60876143F,                  // re
      0.793353319F                     // im
    }, { 1.61394083F,                  // re
      0.789352059F                     // im
    }, { 1.61909389F,                  // re
      0.785316944F                     // im
    }, { 1.62422061F,                  // re
      0.781248152F                     // im
    }, { 1.62932038F,                  // re
      0.777146F                        // im
    }, { 1.63439333F,                  // re
      0.773010433F                     // im
    }, { 1.63943899F,                  // re
      0.768841803F                     // im
    }, { 1.64445734F,                  // re
      0.764640272F                     // im
    }, { 1.64944816F,                  // re
      0.760405958F                     // im
    }, { 1.65441096F,                  // re
      0.7561391F                       // im
    }, { 1.65934587F,                  // re
      0.751839757F                     // im
    }, { 1.66425252F,                  // re
      0.747508347F                     // im
    }, { 1.66913056F,                  // re
      0.74314481F                      // im
    }, { 1.67398012F,                  // re
      0.738749444F                     // im
    }, { 1.67880082F,                  // re
      0.734322488F                     // im
    }, { 1.68359232F,                  // re
      0.729864061F                     // im
    }, { 1.68835449F,                  // re
      0.725374341F                     // im
    }, { 1.69308734F,                  // re
      0.720853567F                     // im
    }, { 1.6977905F,                   // re
      0.716301918F                     // im
    }, { 1.70246363F,                  // re
      0.711719632F                     // im
    }, { 1.70710683F,                  // re
      0.707106769F                     // im
    }, { 1.71171963F,                  // re
      0.702463686F                     // im
    }, { 1.71630192F,                  // re
      0.697790504F                     // im
    }, { 1.72085357F,                  // re
      0.693087339F                     // im
    }, { 1.72537434F,                  // re
      0.688354552F                     // im
    }, { 1.72986412F,                  // re
      0.683592319F                     // im
    }, { 1.73432255F,                  // re
      0.678800762F                     // im
    }, { 1.7387495F,                   // re
      0.673980117F                     // im
    }, { 1.74314475F,                  // re
      0.669130623F                     // im
    }, { 1.74750829F,                  // re
      0.66425246F                      // im
    }, { 1.75183976F,                  // re
      0.659345865F                     // im
    }, { 1.75613904F,                  // re
      0.654410958F                     // im
    }, { 1.76040602F,                  // re
      0.649448097F                     // im
    }, { 1.76464033F,                  // re
      0.64445734F                      // im
    }, { 1.76884174F,                  // re
      0.639439F                        // im
    }, { 1.77301049F,                  // re
      0.634393334F                     // im
    }, { 1.77714598F,                  // re
      0.629320383F                     // im
    }, { 1.78124809F,                  // re
      0.62422055F                      // im
    }, { 1.78531694F,                  // re
      0.619093955F                     // im
    }, { 1.78935206F,                  // re
      0.613940835F                     // im
    }, { 1.79335332F,                  // re
      0.60876143F                      // im
    }, { 1.7973206F,                   // re
      0.603556F                        // im
    }, { 1.8012538F,                   // re
      0.598324597F                     // im
    }, { 1.80515265F,                  // re
      0.593067646F                     // im
    }, { 1.80901694F,                  // re
      0.587785244F                     // im
    }, { 1.81284666F,                  // re
      0.582477689F                     // im
    }, { 1.81664157F,                  // re
      0.577145219F                     // im
    }, { 1.82040143F,                  // re
      0.571787953F                     // im
    }, { 1.82412624F,                  // re
      0.56640625F                      // im
    }, { 1.82781553F,                  // re
      0.561000288F                     // im
    }, { 1.83146954F,                  // re
      0.555570245F                     // im
    }, { 1.83508801F,                  // re
      0.55011642F                      // im
    }, { 1.83867049F,                  // re
      0.544639051F                     // im
    }, { 1.84221721F,                  // re
      0.539138317F                     // im
    }, { 1.8457278F,                   // re
      0.533614516F                     // im
    }, { 1.84920216F,                  // re
      0.528067827F                     // im
    }, { 1.85264015F,                  // re
      0.522498548F                     // im
    }, { 1.85604167F,                  // re
      0.516906917F                     // im
    }, { 1.85940647F,                  // re
      0.511293113F                     // im
    }, { 1.86273432F,                  // re
      0.505657434F                     // im
    }, { 1.86602545F,                  // re
      0.5F                             // im
    }, { 1.86927938F,                  // re
      0.494321197F                     // im
    }, { 1.87249601F,                  // re
      0.488621265F                     // im
    }, { 1.87567532F,                  // re
      0.482900351F                     // im
    }, { 1.87881708F,                  // re
      0.477158785F                     // im
    }, { 1.88192129F,                  // re
      0.471396744F                     // im
    }, { 1.88498759F,                  // re
      0.465614527F                     // im
    }, { 1.8880161F,                   // re
      0.459812373F                     // im
    }, { 1.89100647F,                  // re
      0.453990519F                     // im
    }, { 1.89395881F,                  // re
      0.448149204F                     // im
    }, { 1.89687276F,                  // re
      0.442288727F                     // im
    }, { 1.89974833F,                  // re
      0.436409235F                     // im
    }, { 1.90258527F,                  // re
      0.430511117F                     // im
    }, { 1.90538359F,                  // re
      0.424594522F                     // im
    }, { 1.90814316F,                  // re
      0.418659747F                     // im
    }, { 1.91086388F,                  // re
      0.412707031F                     // im
    }, { 1.91354537F,                  // re
      0.406736642F                     // im
    }, { 1.916188F,                    // re
      0.400748849F                     // im
    }, { 1.91879117F,                  // re
      0.39474389F                      // im
    }, { 1.92135513F,                  // re
      0.388721973F                     // im
    }, { 1.9238795F,                   // re
      0.382683456F                     // im
    }, { 1.92636442F,                  // re
      0.376628518F                     // im
    }, { 1.92880952F,                  // re
      0.370557427F                     // im
    }, { 1.93121493F,                  // re
      0.364470512F                     // im
    }, { 1.9335804F,                   // re
      0.35836795F                      // im
    }, { 1.93590593F,                  // re
      0.352250069F                     // im
    }, { 1.93819141F,                  // re
      0.346117079F                     // im
    }, { 1.9404366F,                   // re
      0.339969248F                     // im
    }, { 1.9426415F,                   // re
      0.333806872F                     // im
    }, { 1.9448061F,                   // re
      0.327630192F                     // im
    }, { 1.94693017F,                  // re
      0.321439445F                     // im
    }, { 1.94901371F,                  // re
      0.315235F                        // im
    }, { 1.95105648F,                  // re
      0.309017F                        // im
    }, { 1.95305872F,                  // re
      0.302785784F                     // im
    }, { 1.95502F,                     // re
      0.296541601F                     // im
    }, { 1.95694041F,                  // re
      0.290284663F                     // im
    }, { 1.95881975F,                  // re
      0.284015357F                     // im
    }, { 1.96065807F,                  // re
      0.277733862F                     // im
    }, { 1.96245527F,                  // re
      0.271440446F                     // im
    }, { 1.96421123F,                  // re
      0.265135437F                     // im
    }, { 1.96592581F,                  // re
      0.258819044F                     // im
    }, { 1.96759915F,                  // re
      0.252491593F                     // im
    }, { 1.96923089F,                  // re
      0.246153295F                     // im
    }, { 1.97082114F,                  // re
      0.239804462F                     // im
    }, { 1.97236991F,                  // re
      0.233445376F                     // im
    }, { 1.97387695F,                  // re
      0.227076277F                     // im
    }, { 1.97534227F,                  // re
      0.220697448F                     // im
    }, { 1.97676587F,                  // re
      0.214309156F                     // im
    }, { 1.97814763F,                  // re
      0.2079117F                       // im
    }, { 1.97948742F,                  // re
      0.201505333F                     // im
    }, { 1.98078525F,                  // re
      0.195090324F                     // im
    }, { 1.98204112F,                  // re
      0.18866697F                      // im
    }, { 1.98325491F,                  // re
      0.182235524F                     // im
    }, { 1.9844265F,                   // re
      0.175796285F                     // im
    }, { 1.98555613F,                  // re
      0.169349506F                     // im
    }, { 1.98664331F,                  // re
      0.162895471F                     // im
    }, { 1.9876883F,                   // re
      0.156434476F                     // im
    }, { 1.98869109F,                  // re
      0.149966761F                     // im
    }, { 1.98965144F,                  // re
      0.143492624F                     // im
    }, { 1.99056935F,                  // re
      0.137012333F                     // im
    }, { 1.99144483F,                  // re
      0.1305262F                       // im
    }, { 1.99227786F,                  // re
      0.124034457F                     // im
    }, { 1.99306846F,                  // re
      0.117537402F                     // im
    }, { 1.99381638F,                  // re
      0.11103531F                      // im
    }, { 1.99452186F,                  // re
      0.104528464F                     // im
    }, { 1.99518466F,                  // re
      0.0980171412F                    // im
    }, { 1.99580491F,                  // re
      0.0915016234F                    // im
    }, { 1.99638247F,                  // re
      0.0849821791F                    // im
    }, { 1.99691725F,                  // re
      0.0784591F                       // im
    }, { 1.99740946F,                  // re
      0.0719326586F                    // im
    }, { 1.997859F,                    // re
      0.0654031336F                    // im
    }, { 1.99826562F,                  // re
      0.0588708036F                    // im
    }, { 1.99862957F,                  // re
      0.0523359589F                    // im
    }, { 1.99895072F,                  // re
      0.0457988679F                    // im
    }, { 1.99922895F,                  // re
      0.0392598175F                    // im
    }, { 1.99946451F,                  // re
      0.0327190831F                    // im
    }, { 1.99965739F,                  // re
      0.02617695F                      // im
    }, { 1.99980724F,                  // re
      0.0196336936F                    // im
    }, { 1.99991441F,                  // re
      0.0130895963F                    // im
    }, { 1.99997854F,                  // re
      0.00654493831F                   // im
    }, { 2.0F,                         // re
      0.0F                             // im
    }, { 1.99997854F,                  // re
      -0.00654493831F                  // im
    }, { 1.99991441F,                  // re
      -0.0130895963F                   // im
    }, { 1.99980724F,                  // re
      -0.0196336936F                   // im
    }, { 1.99965739F,                  // re
      -0.02617695F                     // im
    }, { 1.99946451F,                  // re
      -0.0327190831F                   // im
    }, { 1.99922895F,                  // re
      -0.0392598175F                   // im
    }, { 1.99895072F,                  // re
      -0.0457988679F                   // im
    }, { 1.99862957F,                  // re
      -0.0523359589F                   // im
    }, { 1.99826562F,                  // re
      -0.0588708036F                   // im
    }, { 1.997859F,                    // re
      -0.0654031336F                   // im
    }, { 1.99740946F,                  // re
      -0.0719326586F                   // im
    }, { 1.99691725F,                  // re
      -0.0784591F                      // im
    }, { 1.99638247F,                  // re
      -0.0849821791F                   // im
    }, { 1.99580491F,                  // re
      -0.0915016234F                   // im
    }, { 1.99518466F,                  // re
      -0.0980171412F                   // im
    }, { 1.99452186F,                  // re
      -0.104528464F                    // im
    }, { 1.99381638F,                  // re
      -0.11103531F                     // im
    }, { 1.99306846F,                  // re
      -0.117537402F                    // im
    }, { 1.99227786F,                  // re
      -0.124034457F                    // im
    }, { 1.99144483F,                  // re
      -0.1305262F                      // im
    }, { 1.99056935F,                  // re
      -0.137012333F                    // im
    }, { 1.98965144F,                  // re
      -0.143492624F                    // im
    }, { 1.98869109F,                  // re
      -0.149966761F                    // im
    }, { 1.9876883F,                   // re
      -0.156434476F                    // im
    }, { 1.98664331F,                  // re
      -0.162895471F                    // im
    }, { 1.98555613F,                  // re
      -0.169349506F                    // im
    }, { 1.9844265F,                   // re
      -0.175796285F                    // im
    }, { 1.98325491F,                  // re
      -0.182235524F                    // im
    }, { 1.98204112F,                  // re
      -0.18866697F                     // im
    }, { 1.98078525F,                  // re
      -0.195090324F                    // im
    }, { 1.97948742F,                  // re
      -0.201505333F                    // im
    }, { 1.97814763F,                  // re
      -0.2079117F                      // im
    }, { 1.97676587F,                  // re
      -0.214309156F                    // im
    }, { 1.97534227F,                  // re
      -0.220697448F                    // im
    }, { 1.97387695F,                  // re
      -0.227076277F                    // im
    }, { 1.97236991F,                  // re
      -0.233445376F                    // im
    }, { 1.97082114F,                  // re
      -0.239804462F                    // im
    }, { 1.96923089F,                  // re
      -0.246153295F                    // im
    }, { 1.96759915F,                  // re
      -0.252491593F                    // im
    }, { 1.96592581F,                  // re
      -0.258819044F                    // im
    }, { 1.96421123F,                  // re
      -0.265135437F                    // im
    }, { 1.96245527F,                  // re
      -0.271440446F                    // im
    }, { 1.96065807F,                  // re
      -0.277733862F                    // im
    }, { 1.95881975F,                  // re
      -0.284015357F                    // im
    }, { 1.95694041F,                  // re
      -0.290284663F                    // im
    }, { 1.95502F,                     // re
      -0.296541601F                    // im
    }, { 1.95305872F,                  // re
      -0.302785784F                    // im
    }, { 1.95105648F,                  // re
      -0.309017F                       // im
    }, { 1.94901371F,                  // re
      -0.315235F                       // im
    }, { 1.94693017F,                  // re
      -0.321439445F                    // im
    }, { 1.9448061F,                   // re
      -0.327630192F                    // im
    }, { 1.9426415F,                   // re
      -0.333806872F                    // im
    }, { 1.9404366F,                   // re
      -0.339969248F                    // im
    }, { 1.93819141F,                  // re
      -0.346117079F                    // im
    }, { 1.93590593F,                  // re
      -0.352250069F                    // im
    }, { 1.9335804F,                   // re
      -0.35836795F                     // im
    }, { 1.93121493F,                  // re
      -0.364470512F                    // im
    }, { 1.92880952F,                  // re
      -0.370557427F                    // im
    }, { 1.92636442F,                  // re
      -0.376628518F                    // im
    }, { 1.9238795F,                   // re
      -0.382683456F                    // im
    }, { 1.92135513F,                  // re
      -0.388721973F                    // im
    }, { 1.91879117F,                  // re
      -0.39474389F                     // im
    }, { 1.916188F,                    // re
      -0.400748849F                    // im
    }, { 1.91354537F,                  // re
      -0.406736642F                    // im
    }, { 1.91086388F,                  // re
      -0.412707031F                    // im
    }, { 1.90814316F,                  // re
      -0.418659747F                    // im
    }, { 1.90538359F,                  // re
      -0.424594522F                    // im
    }, { 1.90258527F,                  // re
      -0.430511117F                    // im
    }, { 1.89974833F,                  // re
      -0.436409235F                    // im
    }, { 1.89687276F,                  // re
      -0.442288727F                    // im
    }, { 1.89395881F,                  // re
      -0.448149204F                    // im
    }, { 1.89100647F,                  // re
      -0.453990519F                    // im
    }, { 1.8880161F,                   // re
      -0.459812373F                    // im
    }, { 1.88498759F,                  // re
      -0.465614527F                    // im
    }, { 1.88192129F,                  // re
      -0.471396744F                    // im
    }, { 1.87881708F,                  // re
      -0.477158785F                    // im
    }, { 1.87567532F,                  // re
      -0.482900351F                    // im
    }, { 1.87249601F,                  // re
      -0.488621265F                    // im
    }, { 1.86927938F,                  // re
      -0.494321197F                    // im
    }, { 1.86602545F,                  // re
      -0.5F                            // im
    }, { 1.86273432F,                  // re
      -0.505657434F                    // im
    }, { 1.85940647F,                  // re
      -0.511293113F                    // im
    }, { 1.85604167F,                  // re
      -0.516906917F                    // im
    }, { 1.85264015F,                  // re
      -0.522498548F                    // im
    }, { 1.84920216F,                  // re
      -0.528067827F                    // im
    }, { 1.8457278F,                   // re
      -0.533614516F                    // im
    }, { 1.84221721F,                  // re
      -0.539138317F                    // im
    }, { 1.83867049F,                  // re
      -0.544639051F                    // im
    }, { 1.83508801F,                  // re
      -0.55011642F                     // im
    }, { 1.83146954F,                  // re
      -0.555570245F                    // im
    }, { 1.82781553F,                  // re
      -0.561000288F                    // im
    }, { 1.82412624F,                  // re
      -0.56640625F                     // im
    }, { 1.82040143F,                  // re
      -0.571787953F                    // im
    }, { 1.81664157F,                  // re
      -0.577145219F                    // im
    }, { 1.81284666F,                  // re
      -0.582477689F                    // im
    }, { 1.80901694F,                  // re
      -0.587785244F                    // im
    }, { 1.80515265F,                  // re
      -0.593067646F                    // im
    }, { 1.8012538F,                   // re
      -0.598324597F                    // im
    }, { 1.7973206F,                   // re
      -0.603556F                       // im
    }, { 1.79335332F,                  // re
      -0.60876143F                     // im
    }, { 1.78935206F,                  // re
      -0.613940835F                    // im
    }, { 1.78531694F,                  // re
      -0.619093955F                    // im
    }, { 1.78124809F,                  // re
      -0.62422055F                     // im
    }, { 1.77714598F,                  // re
      -0.629320383F                    // im
    }, { 1.77301049F,                  // re
      -0.634393334F                    // im
    }, { 1.76884174F,                  // re
      -0.639439F                       // im
    }, { 1.76464033F,                  // re
      -0.64445734F                     // im
    }, { 1.76040602F,                  // re
      -0.649448097F                    // im
    }, { 1.75613904F,                  // re
      -0.654410958F                    // im
    }, { 1.75183976F,                  // re
      -0.659345865F                    // im
    }, { 1.74750829F,                  // re
      -0.66425246F                     // im
    }, { 1.74314475F,                  // re
      -0.669130623F                    // im
    }, { 1.7387495F,                   // re
      -0.673980117F                    // im
    }, { 1.73432255F,                  // re
      -0.678800762F                    // im
    }, { 1.72986412F,                  // re
      -0.683592319F                    // im
    }, { 1.72537434F,                  // re
      -0.688354552F                    // im
    }, { 1.72085357F,                  // re
      -0.693087339F                    // im
    }, { 1.71630192F,                  // re
      -0.697790504F                    // im
    }, { 1.71171963F,                  // re
      -0.702463686F                    // im
    }, { 1.70710683F,                  // re
      -0.707106769F                    // im
    }, { 1.70246363F,                  // re
      -0.711719632F                    // im
    }, { 1.6977905F,                   // re
      -0.716301918F                    // im
    }, { 1.69308734F,                  // re
      -0.720853567F                    // im
    }, { 1.68835449F,                  // re
      -0.725374341F                    // im
    }, { 1.68359232F,                  // re
      -0.729864061F                    // im
    }, { 1.67880082F,                  // re
      -0.734322488F                    // im
    }, { 1.67398012F,                  // re
      -0.738749444F                    // im
    }, { 1.66913056F,                  // re
      -0.74314481F                     // im
    }, { 1.66425252F,                  // re
      -0.747508347F                    // im
    }, { 1.65934587F,                  // re
      -0.751839757F                    // im
    }, { 1.65441096F,                  // re
      -0.7561391F                      // im
    }, { 1.64944816F,                  // re
      -0.760405958F                    // im
    }, { 1.64445734F,                  // re
      -0.764640272F                    // im
    }, { 1.63943899F,                  // re
      -0.768841803F                    // im
    }, { 1.63439333F,                  // re
      -0.773010433F                    // im
    }, { 1.62932038F,                  // re
      -0.777146F                       // im
    }, { 1.62422061F,                  // re
      -0.781248152F                    // im
    }, { 1.61909389F,                  // re
      -0.785316944F                    // im
    }, { 1.61394083F,                  // re
      -0.789352059F                    // im
    }, { 1.60876143F,                  // re
      -0.793353319F                    // im
    }, { 1.60355592F,                  // re
      -0.797320604F                    // im
    }, { 1.59832454F,                  // re
      -0.801253796F                    // im
    }, { 1.59306765F,                  // re
      -0.805152655F                    // im
    }, { 1.58778524F,                  // re
      -0.809017F                       // im
    }, { 1.58247769F,                  // re
      -0.812846661F                    // im
    }, { 1.57714522F,                  // re
      -0.816641569F                    // im
    }, { 1.57178795F,                  // re
      -0.82040143F                     // im
    }, { 1.56640625F,                  // re
      -0.824126184F                    // im
    }, { 1.56100035F,                  // re
      -0.827815592F                    // im
    }, { 1.55557024F,                  // re
      -0.831469595F                    // im
    }, { 1.55011642F,                  // re
      -0.835087955F                    // im
    }, { 1.54463911F,                  // re
      -0.838670552F                    // im
    }, { 1.53913832F,                  // re
      -0.842217207F                    // im
    }, { 1.53361452F,                  // re
      -0.845727801F                    // im
    }, { 1.52806783F,                  // re
      -0.849202156F                    // im
    }, { 1.52249861F,                  // re
      -0.852640152F                    // im
    }, { 1.51690698F,                  // re
      -0.85604161F                     // im
    }, { 1.51129317F,                  // re
      -0.859406412F                    // im
    }, { 1.50565743F,                  // re
      -0.862734377F                    // im
    }, { 1.5F,                         // re
      -0.866025388F                    // im
    }, { 1.49432123F,                  // re
      -0.869279325F                    // im
    }, { 1.48862123F,                  // re
      -0.872496F                       // im
    }, { 1.48290038F,                  // re
      -0.875675321F                    // im
    }, { 1.47715878F,                  // re
      -0.878817081F                    // im
    }, { 1.47139668F,                  // re
      -0.881921232F                    // im
    }, { 1.46561456F,                  // re
      -0.884987652F                    // im
    }, { 1.4598124F,                   // re
      -0.888016105F                    // im
    }, { 1.45399046F,                  // re
      -0.891006529F                    // im
    }, { 1.4481492F,                   // re
      -0.893958747F                    // im
    }, { 1.44228876F,                  // re
      -0.896872699F                    // im
    }, { 1.43640924F,                  // re
      -0.899748266F                    // im
    }, { 1.43051112F,                  // re
      -0.902585268F                    // im
    }, { 1.42459452F,                  // re
      -0.905383587F                    // im
    }, { 1.41865969F,                  // re
      -0.908143163F                    // im
    }, { 1.41270709F,                  // re
      -0.910863817F                    // im
    }, { 1.40673661F,                  // re
      -0.91354543F                     // im
    }, { 1.40074885F,                  // re
      -0.916187942F                    // im
    }, { 1.39474392F,                  // re
      -0.918791175F                    // im
    }, { 1.38872194F,                  // re
      -0.921355128F                    // im
    }, { 1.38268352F,                  // re
      -0.923879504F                    // im
    }, { 1.37662852F,                  // re
      -0.926364362F                    // im
    }, { 1.37055743F,                  // re
      -0.928809524F                    // im
    }, { 1.36447048F,                  // re
      -0.931214929F                    // im
    }, { 1.35836792F,                  // re
      -0.933580399F                    // im
    }, { 1.3522501F,                   // re
      -0.935905933F                    // im
    }, { 1.34611702F,                  // re
      -0.938191354F                    // im
    }, { 1.33996928F,                  // re
      -0.940436542F                    // im
    }, { 1.33380687F,                  // re
      -0.942641497F                    // im
    }, { 1.32763016F,                  // re
      -0.944806039F                    // im
    }, { 1.3214395F,                   // re
      -0.94693011F                     // im
    }, { 1.31523502F,                  // re
      -0.94901365F                     // im
    }, { 1.30901694F,                  // re
      -0.95105654F                     // im
    }, { 1.30278575F,                  // re
      -0.95305866F                     // im
    }, { 1.29654157F,                  // re
      -0.955019951F                    // im
    }, { 1.29028463F,                  // re
      -0.956940353F                    // im
    }, { 1.28401542F,                  // re
      -0.958819747F                    // im
    }, { 1.2777338F,                   // re
      -0.960658073F                    // im
    }, { 1.27144051F,                  // re
      -0.962455213F                    // im
    }, { 1.26513541F,                  // re
      -0.964211166F                    // im
    }, { 1.2588191F,                   // re
      -0.965925813F                    // im
    }, { 1.25249159F,                  // re
      -0.967599094F                    // im
    }, { 1.24615335F,                  // re
      -0.96923089F                     // im
    }, { 1.23980451F,                  // re
      -0.970821202F                    // im
    }, { 1.23344541F,                  // re
      -0.972369909F                    // im
    }, { 1.22707629F,                  // re
      -0.973876953F                    // im
    }, { 1.2206974F,                   // re
      -0.975342333F                    // im
    }, { 1.21430922F,                  // re
      -0.976765871F                    // im
    }, { 1.20791173F,                  // re
      -0.978147626F                    // im
    }, { 1.2015053F,                   // re
      -0.979487419F                    // im
    }, { 1.19509029F,                  // re
      -0.980785251F                    // im
    }, { 1.18866694F,                  // re
      -0.982041121F                    // im
    }, { 1.18223548F,                  // re
      -0.98325491F                     // im
    }, { 1.17579627F,                  // re
      -0.984426558F                    // im
    }, { 1.16934955F,                  // re
      -0.985556066F                    // im
    }, { 1.16289544F,                  // re
      -0.986643314F                    // im
    }, { 1.15643454F,                  // re
      -0.987688363F                    // im
    }, { 1.14996672F,                  // re
      -0.988691032F                    // im
    }, { 1.14349258F,                  // re
      -0.989651382F                    // im
    }, { 1.13701236F,                  // re
      -0.990569353F                    // im
    }, { 1.13052619F,                  // re
      -0.991444886F                    // im
    }, { 1.1240344F,                   // re
      -0.99227792F                     // im
    }, { 1.11753738F,                  // re
      -0.993068457F                    // im
    }, { 1.11103535F,                  // re
      -0.993816435F                    // im
    }, { 1.10452843F,                  // re
      -0.994521916F                    // im
    }, { 1.0980171F,                   // re
      -0.99518472F                     // im
    }, { 1.09150159F,                  // re
      -0.995804906F                    // im
    }, { 1.08498216F,                  // re
      -0.996382475F                    // im
    }, { 1.07845914F,                  // re
      -0.996917307F                    // im
    }, { 1.07193267F,                  // re
      -0.997409463F                    // im
    }, { 1.0654031F,                   // re
      -0.997858942F                    // im
    }, { 1.05887079F,                  // re
      -0.998265624F                    // im
    }, { 1.05233598F,                  // re
      -0.99862951F                     // im
    }, { 1.0457989F,                   // re
      -0.99895066F                     // im
    }, { 1.03925979F,                  // re
      -0.999229F                       // im
    }, { 1.03271914F,                  // re
      -0.999464571F                    // im
    }, { 1.02617693F,                  // re
      -0.999657333F                    // im
    }, { 1.01963365F,                  // re
      -0.999807239F                    // im
    }, { 1.01308954F,                  // re
      -0.999914348F                    // im
    }, { 1.00654495F,                  // re
      -0.999978602F                    // im
    } };

  static const float tmp_1[1025]{ 0.0F, -0.00306795677F, -0.00613588467F,
    -0.00920375437F, -0.0122715384F, -0.0153392069F, -0.0184067301F,
    -0.021474082F, -0.024541229F, -0.027608145F, -0.030674804F, -0.0337411761F,
    -0.0368072242F, -0.0398729295F, -0.0429382585F, -0.0460031815F,
    -0.0490676761F, -0.0521317087F, -0.0551952459F, -0.0582582653F,
    -0.0613207407F, -0.0643826351F, -0.0674439222F, -0.070504576F,
    -0.0735645667F, -0.0766238645F, -0.0796824396F, -0.0827402696F,
    -0.0857973173F, -0.0888535529F, -0.0919089541F, -0.0949635F, -0.0980171412F,
    -0.101069868F, -0.10412164F, -0.10717243F, -0.110222206F, -0.113270953F,
    -0.116318636F, -0.119365215F, -0.122410677F, -0.125454977F, -0.128498122F,
    -0.13154003F, -0.134580716F, -0.137620121F, -0.140658244F, -0.143695042F,
    -0.146730468F, -0.149764538F, -0.152797192F, -0.155828416F, -0.15885815F,
    -0.161886394F, -0.164913133F, -0.167938292F, -0.170961902F, -0.173983872F,
    -0.177004218F, -0.18002291F, -0.183039889F, -0.186055154F, -0.18906866F,
    -0.192080408F, -0.195090324F, -0.198098406F, -0.201104641F, -0.204108968F,
    -0.207111388F, -0.210111842F, -0.213110328F, -0.216106802F, -0.219101235F,
    -0.222093627F, -0.225083917F, -0.228072092F, -0.231058121F, -0.234041959F,
    -0.237023607F, -0.24000302F, -0.242980197F, -0.24595505F, -0.248927608F,
    -0.251897812F, -0.254865676F, -0.257831097F, -0.260794133F, -0.263754696F,
    -0.266712785F, -0.269668311F, -0.272621363F, -0.275571823F, -0.27851969F,
    -0.281464934F, -0.284407556F, -0.287347466F, -0.290284663F, -0.293219179F,
    -0.296150893F, -0.299079835F, -0.302005947F, -0.304929256F, -0.307849675F,
    -0.310767144F, -0.313681751F, -0.316593409F, -0.319502026F, -0.322407693F,
    -0.32531032F, -0.328209847F, -0.331106305F, -0.333999664F, -0.336889863F,
    -0.339776874F, -0.342660725F, -0.345541328F, -0.348418683F, -0.351292759F,
    -0.354163527F, -0.357031F, -0.359895051F, -0.362755746F, -0.365613F,
    -0.368466824F, -0.371317208F, -0.374164075F, -0.377007425F, -0.379847199F,
    -0.382683456F, -0.385516077F, -0.388345033F, -0.391170382F, -0.393992066F,
    -0.39681F, -0.399624199F, -0.402434677F, -0.40524134F, -0.408044159F,
    -0.410843194F, -0.413638324F, -0.416429579F, -0.419216901F, -0.422000289F,
    -0.424779713F, -0.427555084F, -0.430326492F, -0.433093846F, -0.435857117F,
    -0.438616246F, -0.441371292F, -0.444122165F, -0.446868837F, -0.449611336F,
    -0.452349603F, -0.455083579F, -0.457813323F, -0.460538715F, -0.463259816F,
    -0.465976506F, -0.468688846F, -0.471396744F, -0.474100202F, -0.47679925F,
    -0.479493737F, -0.482183754F, -0.484869242F, -0.487550169F, -0.490226507F,
    -0.492898226F, -0.495565295F, -0.498227656F, -0.500885367F, -0.50353837F,
    -0.506186664F, -0.50883019F, -0.511468887F, -0.514102757F, -0.516731799F,
    -0.519356F, -0.521975279F, -0.524589717F, -0.527199149F, -0.529803634F,
    -0.532403171F, -0.534997642F, -0.537587047F, -0.540171504F, -0.542750776F,
    -0.545325041F, -0.547894061F, -0.550458F, -0.553016722F, -0.555570245F,
    -0.558118522F, -0.560661614F, -0.563199341F, -0.565731823F, -0.568259F,
    -0.570780754F, -0.573297143F, -0.575808227F, -0.578313828F, -0.580814F,
    -0.583308697F, -0.585797906F, -0.588281572F, -0.590759695F, -0.593232274F,
    -0.59569931F, -0.598160744F, -0.600616515F, -0.603066623F, -0.605511F,
    -0.607949793F, -0.610382795F, -0.612810075F, -0.615231633F, -0.61764735F,
    -0.620057225F, -0.622461259F, -0.624859512F, -0.627251804F, -0.629638255F,
    -0.632018745F, -0.634393334F, -0.636761844F, -0.639124453F, -0.641481042F,
    -0.643831551F, -0.64617604F, -0.64851445F, -0.65084672F, -0.653172851F,
    -0.655492842F, -0.657806695F, -0.660114348F, -0.662415802F, -0.664711F,
    -0.666999936F, -0.669282556F, -0.671559F, -0.673829F, -0.676092744F,
    -0.678350091F, -0.680601F, -0.682845592F, -0.685083628F, -0.687315345F,
    -0.689540565F, -0.691759288F, -0.693971455F, -0.696177125F, -0.698376298F,
    -0.700568795F, -0.702754736F, -0.704934061F, -0.707106769F, -0.709272802F,
    -0.711432219F, -0.7135849F, -0.715730786F, -0.71787F, -0.720002472F,
    -0.722128153F, -0.724247098F, -0.726359129F, -0.728464365F, -0.730562747F,
    -0.732654274F, -0.734738886F, -0.736816525F, -0.73888731F, -0.740951121F,
    -0.743007958F, -0.745057762F, -0.747100592F, -0.749136388F, -0.751165092F,
    -0.753186822F, -0.755201399F, -0.757208824F, -0.759209156F, -0.761202335F,
    -0.763188422F, -0.765167236F, -0.767138898F, -0.769103348F, -0.771060526F,
    -0.773010433F, -0.774953067F, -0.77688843F, -0.778816521F, -0.780737221F,
    -0.78265059F, -0.784556627F, -0.786455214F, -0.78834641F, -0.790230215F,
    -0.792106569F, -0.793975472F, -0.795836926F, -0.797690809F, -0.799537241F,
    -0.801376164F, -0.803207517F, -0.8050313F, -0.806847572F, -0.808656156F,
    -0.81045717F, -0.812250555F, -0.81403631F, -0.815814376F, -0.817584813F,
    -0.819347501F, -0.8211025F, -0.822849751F, -0.824589252F, -0.826321065F,
    -0.828045F, -0.829761207F, -0.831469595F, -0.833170176F, -0.834862828F,
    -0.836547732F, -0.838224709F, -0.839893758F, -0.841555F, -0.843208253F,
    -0.84485358F, -0.84649092F, -0.848120332F, -0.849741757F, -0.851355195F,
    -0.852960587F, -0.854558F, -0.856147349F, -0.857728601F, -0.859301805F,
    -0.860866904F, -0.862423956F, -0.863972843F, -0.865513623F, -0.867046237F,
    -0.868570685F, -0.870086968F, -0.871595085F, -0.873095F, -0.874586642F,
    -0.876070082F, -0.877545297F, -0.879012227F, -0.880470872F, -0.881921232F,
    -0.883363307F, -0.884797096F, -0.886222541F, -0.887639642F, -0.889048338F,
    -0.890448749F, -0.891840696F, -0.893224299F, -0.894599497F, -0.895966232F,
    -0.897324562F, -0.898674488F, -0.900015891F, -0.901348829F, -0.902673304F,
    -0.903989315F, -0.905296743F, -0.906595707F, -0.907886088F, -0.909167945F,
    -0.910441279F, -0.91170603F, -0.912962198F, -0.914209723F, -0.915448725F,
    -0.916679084F, -0.917900741F, -0.919113874F, -0.920318246F, -0.921514034F,
    -0.92270112F, -0.923879504F, -0.925049245F, -0.926210225F, -0.927362502F,
    -0.928506076F, -0.929640889F, -0.93076694F, -0.931884289F, -0.932992816F,
    -0.934092522F, -0.935183525F, -0.936265647F, -0.937339F, -0.938403547F,
    -0.939459205F, -0.940506101F, -0.941544056F, -0.94257319F, -0.943593442F,
    -0.944604814F, -0.945607305F, -0.946600914F, -0.947585583F, -0.94856137F,
    -0.949528158F, -0.950486064F, -0.951435F, -0.952375F, -0.953306F,
    -0.954228103F, -0.955141187F, -0.95604527F, -0.956940353F, -0.957826376F,
    -0.958703458F, -0.959571481F, -0.960430503F, -0.961280465F, -0.962121427F,
    -0.962953269F, -0.963776052F, -0.964589775F, -0.965394437F, -0.96619F,
    -0.966976464F, -0.967753828F, -0.968522072F, -0.969281256F, -0.970031261F,
    -0.970772147F, -0.971503913F, -0.972226501F, -0.972939968F, -0.973644257F,
    -0.974339366F, -0.975025356F, -0.975702107F, -0.976369739F, -0.977028131F,
    -0.977677345F, -0.97831738F, -0.978948176F, -0.979569793F, -0.980182111F,
    -0.980785251F, -0.981379211F, -0.981963873F, -0.982539296F, -0.983105481F,
    -0.983662426F, -0.984210074F, -0.984748483F, -0.985277653F, -0.985797524F,
    -0.986308098F, -0.986809373F, -0.987301409F, -0.987784147F, -0.988257587F,
    -0.988721669F, -0.989176512F, -0.989622F, -0.990058184F, -0.990485072F,
    -0.990902662F, -0.991310835F, -0.991709769F, -0.992099285F, -0.992479563F,
    -0.992850423F, -0.993211925F, -0.993564129F, -0.993907F, -0.994240463F,
    -0.994564593F, -0.994879305F, -0.99518472F, -0.995480776F, -0.995767415F,
    -0.996044695F, -0.996312618F, -0.996571124F, -0.996820271F, -0.997060061F,
    -0.997290432F, -0.997511446F, -0.997723043F, -0.997925282F, -0.998118103F,
    -0.998301566F, -0.998475552F, -0.998640239F, -0.99879545F, -0.998941302F,
    -0.999077737F, -0.999204755F, -0.999322414F, -0.999430597F, -0.999529421F,
    -0.999618828F, -0.999698818F, -0.99976939F, -0.999830604F, -0.99988234F,
    -0.999924719F, -0.999957621F, -0.999981165F, -0.999995291F, -1.0F,
    -0.999995291F, -0.999981165F, -0.999957621F, -0.999924719F, -0.99988234F,
    -0.999830604F, -0.99976939F, -0.999698818F, -0.999618828F, -0.999529421F,
    -0.999430597F, -0.999322414F, -0.999204755F, -0.999077737F, -0.998941302F,
    -0.99879545F, -0.998640239F, -0.998475552F, -0.998301566F, -0.998118103F,
    -0.997925282F, -0.997723043F, -0.997511446F, -0.997290432F, -0.997060061F,
    -0.996820271F, -0.996571124F, -0.996312618F, -0.996044695F, -0.995767415F,
    -0.995480776F, -0.99518472F, -0.994879305F, -0.994564593F, -0.994240463F,
    -0.993907F, -0.993564129F, -0.993211925F, -0.992850423F, -0.992479563F,
    -0.992099285F, -0.991709769F, -0.991310835F, -0.990902662F, -0.990485072F,
    -0.990058184F, -0.989622F, -0.989176512F, -0.988721669F, -0.988257587F,
    -0.987784147F, -0.987301409F, -0.986809373F, -0.986308098F, -0.985797524F,
    -0.985277653F, -0.984748483F, -0.984210074F, -0.983662426F, -0.983105481F,
    -0.982539296F, -0.981963873F, -0.981379211F, -0.980785251F, -0.980182111F,
    -0.979569793F, -0.978948176F, -0.97831738F, -0.977677345F, -0.977028131F,
    -0.976369739F, -0.975702107F, -0.975025356F, -0.974339366F, -0.973644257F,
    -0.972939968F, -0.972226501F, -0.971503913F, -0.970772147F, -0.970031261F,
    -0.969281256F, -0.968522072F, -0.967753828F, -0.966976464F, -0.96619F,
    -0.965394437F, -0.964589775F, -0.963776052F, -0.962953269F, -0.962121427F,
    -0.961280465F, -0.960430503F, -0.959571481F, -0.958703458F, -0.957826376F,
    -0.956940353F, -0.95604527F, -0.955141187F, -0.954228103F, -0.953306F,
    -0.952375F, -0.951435F, -0.950486064F, -0.949528158F, -0.94856137F,
    -0.947585583F, -0.946600914F, -0.945607305F, -0.944604814F, -0.943593442F,
    -0.94257319F, -0.941544056F, -0.940506101F, -0.939459205F, -0.938403547F,
    -0.937339F, -0.936265647F, -0.935183525F, -0.934092522F, -0.932992816F,
    -0.931884289F, -0.93076694F, -0.929640889F, -0.928506076F, -0.927362502F,
    -0.926210225F, -0.925049245F, -0.923879504F, -0.92270112F, -0.921514034F,
    -0.920318246F, -0.919113874F, -0.917900741F, -0.916679084F, -0.915448725F,
    -0.914209723F, -0.912962198F, -0.91170603F, -0.910441279F, -0.909167945F,
    -0.907886088F, -0.906595707F, -0.905296743F, -0.903989315F, -0.902673304F,
    -0.901348829F, -0.900015891F, -0.898674488F, -0.897324562F, -0.895966232F,
    -0.894599497F, -0.893224299F, -0.891840696F, -0.890448749F, -0.889048338F,
    -0.887639642F, -0.886222541F, -0.884797096F, -0.883363307F, -0.881921232F,
    -0.880470872F, -0.879012227F, -0.877545297F, -0.876070082F, -0.874586642F,
    -0.873095F, -0.871595085F, -0.870086968F, -0.868570685F, -0.867046237F,
    -0.865513623F, -0.863972843F, -0.862423956F, -0.860866904F, -0.859301805F,
    -0.857728601F, -0.856147349F, -0.854558F, -0.852960587F, -0.851355195F,
    -0.849741757F, -0.848120332F, -0.84649092F, -0.84485358F, -0.843208253F,
    -0.841555F, -0.839893758F, -0.838224709F, -0.836547732F, -0.834862828F,
    -0.833170176F, -0.831469595F, -0.829761207F, -0.828045F, -0.826321065F,
    -0.824589252F, -0.822849751F, -0.8211025F, -0.819347501F, -0.817584813F,
    -0.815814376F, -0.81403631F, -0.812250555F, -0.81045717F, -0.808656156F,
    -0.806847572F, -0.8050313F, -0.803207517F, -0.801376164F, -0.799537241F,
    -0.797690809F, -0.795836926F, -0.793975472F, -0.792106569F, -0.790230215F,
    -0.78834641F, -0.786455214F, -0.784556627F, -0.78265059F, -0.780737221F,
    -0.778816521F, -0.77688843F, -0.774953067F, -0.773010433F, -0.771060526F,
    -0.769103348F, -0.767138898F, -0.765167236F, -0.763188422F, -0.761202335F,
    -0.759209156F, -0.757208824F, -0.755201399F, -0.753186822F, -0.751165092F,
    -0.749136388F, -0.747100592F, -0.745057762F, -0.743007958F, -0.740951121F,
    -0.73888731F, -0.736816525F, -0.734738886F, -0.732654274F, -0.730562747F,
    -0.728464365F, -0.726359129F, -0.724247098F, -0.722128153F, -0.720002472F,
    -0.71787F, -0.715730786F, -0.7135849F, -0.711432219F, -0.709272802F,
    -0.707106769F, -0.704934061F, -0.702754736F, -0.700568795F, -0.698376298F,
    -0.696177125F, -0.693971455F, -0.691759288F, -0.689540565F, -0.687315345F,
    -0.685083628F, -0.682845592F, -0.680601F, -0.678350091F, -0.676092744F,
    -0.673829F, -0.671559F, -0.669282556F, -0.666999936F, -0.664711F,
    -0.662415802F, -0.660114348F, -0.657806695F, -0.655492842F, -0.653172851F,
    -0.65084672F, -0.64851445F, -0.64617604F, -0.643831551F, -0.641481042F,
    -0.639124453F, -0.636761844F, -0.634393334F, -0.632018745F, -0.629638255F,
    -0.627251804F, -0.624859512F, -0.622461259F, -0.620057225F, -0.61764735F,
    -0.615231633F, -0.612810075F, -0.610382795F, -0.607949793F, -0.605511F,
    -0.603066623F, -0.600616515F, -0.598160744F, -0.59569931F, -0.593232274F,
    -0.590759695F, -0.588281572F, -0.585797906F, -0.583308697F, -0.580814F,
    -0.578313828F, -0.575808227F, -0.573297143F, -0.570780754F, -0.568259F,
    -0.565731823F, -0.563199341F, -0.560661614F, -0.558118522F, -0.555570245F,
    -0.553016722F, -0.550458F, -0.547894061F, -0.545325041F, -0.542750776F,
    -0.540171504F, -0.537587047F, -0.534997642F, -0.532403171F, -0.529803634F,
    -0.527199149F, -0.524589717F, -0.521975279F, -0.519356F, -0.516731799F,
    -0.514102757F, -0.511468887F, -0.50883019F, -0.506186664F, -0.50353837F,
    -0.500885367F, -0.498227656F, -0.495565295F, -0.492898226F, -0.490226507F,
    -0.487550169F, -0.484869242F, -0.482183754F, -0.479493737F, -0.47679925F,
    -0.474100202F, -0.471396744F, -0.468688846F, -0.465976506F, -0.463259816F,
    -0.460538715F, -0.457813323F, -0.455083579F, -0.452349603F, -0.449611336F,
    -0.446868837F, -0.444122165F, -0.441371292F, -0.438616246F, -0.435857117F,
    -0.433093846F, -0.430326492F, -0.427555084F, -0.424779713F, -0.422000289F,
    -0.419216901F, -0.416429579F, -0.413638324F, -0.410843194F, -0.408044159F,
    -0.40524134F, -0.402434677F, -0.399624199F, -0.39681F, -0.393992066F,
    -0.391170382F, -0.388345033F, -0.385516077F, -0.382683456F, -0.379847199F,
    -0.377007425F, -0.374164075F, -0.371317208F, -0.368466824F, -0.365613F,
    -0.362755746F, -0.359895051F, -0.357031F, -0.354163527F, -0.351292759F,
    -0.348418683F, -0.345541328F, -0.342660725F, -0.339776874F, -0.336889863F,
    -0.333999664F, -0.331106305F, -0.328209847F, -0.32531032F, -0.322407693F,
    -0.319502026F, -0.316593409F, -0.313681751F, -0.310767144F, -0.307849675F,
    -0.304929256F, -0.302005947F, -0.299079835F, -0.296150893F, -0.293219179F,
    -0.290284663F, -0.287347466F, -0.284407556F, -0.281464934F, -0.27851969F,
    -0.275571823F, -0.272621363F, -0.269668311F, -0.266712785F, -0.263754696F,
    -0.260794133F, -0.257831097F, -0.254865676F, -0.251897812F, -0.248927608F,
    -0.24595505F, -0.242980197F, -0.24000302F, -0.237023607F, -0.234041959F,
    -0.231058121F, -0.228072092F, -0.225083917F, -0.222093627F, -0.219101235F,
    -0.216106802F, -0.213110328F, -0.210111842F, -0.207111388F, -0.204108968F,
    -0.201104641F, -0.198098406F, -0.195090324F, -0.192080408F, -0.18906866F,
    -0.186055154F, -0.183039889F, -0.18002291F, -0.177004218F, -0.173983872F,
    -0.170961902F, -0.167938292F, -0.164913133F, -0.161886394F, -0.15885815F,
    -0.155828416F, -0.152797192F, -0.149764538F, -0.146730468F, -0.143695042F,
    -0.140658244F, -0.137620121F, -0.134580716F, -0.13154003F, -0.128498122F,
    -0.125454977F, -0.122410677F, -0.119365215F, -0.116318636F, -0.113270953F,
    -0.110222206F, -0.10717243F, -0.10412164F, -0.101069868F, -0.0980171412F,
    -0.0949635F, -0.0919089541F, -0.0888535529F, -0.0857973173F, -0.0827402696F,
    -0.0796824396F, -0.0766238645F, -0.0735645667F, -0.070504576F,
    -0.0674439222F, -0.0643826351F, -0.0613207407F, -0.0582582653F,
    -0.0551952459F, -0.0521317087F, -0.0490676761F, -0.0460031815F,
    -0.0429382585F, -0.0398729295F, -0.0368072242F, -0.0337411761F,
    -0.030674804F, -0.027608145F, -0.024541229F, -0.021474082F, -0.0184067301F,
    -0.0153392069F, -0.0122715384F, -0.00920375437F, -0.00613588467F,
    -0.00306795677F, -0.0F };

  static const float tmp_2[1025]{ 1.0F, 0.999995291F, 0.999981165F, 0.999957621F,
    0.999924719F, 0.99988234F, 0.999830604F, 0.99976939F, 0.999698818F,
    0.999618828F, 0.999529421F, 0.999430597F, 0.999322414F, 0.999204755F,
    0.999077737F, 0.998941302F, 0.99879545F, 0.998640239F, 0.998475552F,
    0.998301566F, 0.998118103F, 0.997925282F, 0.997723043F, 0.997511446F,
    0.997290432F, 0.997060061F, 0.996820271F, 0.996571124F, 0.996312618F,
    0.996044695F, 0.995767415F, 0.995480776F, 0.99518472F, 0.994879305F,
    0.994564593F, 0.994240463F, 0.993907F, 0.993564129F, 0.993211925F,
    0.992850423F, 0.992479563F, 0.992099285F, 0.991709769F, 0.991310835F,
    0.990902662F, 0.990485072F, 0.990058184F, 0.989622F, 0.989176512F,
    0.988721669F, 0.988257587F, 0.987784147F, 0.987301409F, 0.986809373F,
    0.986308098F, 0.985797524F, 0.985277653F, 0.984748483F, 0.984210074F,
    0.983662426F, 0.983105481F, 0.982539296F, 0.981963873F, 0.981379211F,
    0.980785251F, 0.980182111F, 0.979569793F, 0.978948176F, 0.97831738F,
    0.977677345F, 0.977028131F, 0.976369739F, 0.975702107F, 0.975025356F,
    0.974339366F, 0.973644257F, 0.972939968F, 0.972226501F, 0.971503913F,
    0.970772147F, 0.970031261F, 0.969281256F, 0.968522072F, 0.967753828F,
    0.966976464F, 0.96619F, 0.965394437F, 0.964589775F, 0.963776052F,
    0.962953269F, 0.962121427F, 0.961280465F, 0.960430503F, 0.959571481F,
    0.958703458F, 0.957826376F, 0.956940353F, 0.95604527F, 0.955141187F,
    0.954228103F, 0.953306F, 0.952375F, 0.951435F, 0.950486064F, 0.949528158F,
    0.94856137F, 0.947585583F, 0.946600914F, 0.945607305F, 0.944604814F,
    0.943593442F, 0.94257319F, 0.941544056F, 0.940506101F, 0.939459205F,
    0.938403547F, 0.937339F, 0.936265647F, 0.935183525F, 0.934092522F,
    0.932992816F, 0.931884289F, 0.93076694F, 0.929640889F, 0.928506076F,
    0.927362502F, 0.926210225F, 0.925049245F, 0.923879504F, 0.92270112F,
    0.921514034F, 0.920318246F, 0.919113874F, 0.917900741F, 0.916679084F,
    0.915448725F, 0.914209723F, 0.912962198F, 0.91170603F, 0.910441279F,
    0.909167945F, 0.907886088F, 0.906595707F, 0.905296743F, 0.903989315F,
    0.902673304F, 0.901348829F, 0.900015891F, 0.898674488F, 0.897324562F,
    0.895966232F, 0.894599497F, 0.893224299F, 0.891840696F, 0.890448749F,
    0.889048338F, 0.887639642F, 0.886222541F, 0.884797096F, 0.883363307F,
    0.881921232F, 0.880470872F, 0.879012227F, 0.877545297F, 0.876070082F,
    0.874586642F, 0.873095F, 0.871595085F, 0.870086968F, 0.868570685F,
    0.867046237F, 0.865513623F, 0.863972843F, 0.862423956F, 0.860866904F,
    0.859301805F, 0.857728601F, 0.856147349F, 0.854558F, 0.852960587F,
    0.851355195F, 0.849741757F, 0.848120332F, 0.84649092F, 0.84485358F,
    0.843208253F, 0.841555F, 0.839893758F, 0.838224709F, 0.836547732F,
    0.834862828F, 0.833170176F, 0.831469595F, 0.829761207F, 0.828045F,
    0.826321065F, 0.824589252F, 0.822849751F, 0.8211025F, 0.819347501F,
    0.817584813F, 0.815814376F, 0.81403631F, 0.812250555F, 0.81045717F,
    0.808656156F, 0.806847572F, 0.8050313F, 0.803207517F, 0.801376164F,
    0.799537241F, 0.797690809F, 0.795836926F, 0.793975472F, 0.792106569F,
    0.790230215F, 0.78834641F, 0.786455214F, 0.784556627F, 0.78265059F,
    0.780737221F, 0.778816521F, 0.77688843F, 0.774953067F, 0.773010433F,
    0.771060526F, 0.769103348F, 0.767138898F, 0.765167236F, 0.763188422F,
    0.761202335F, 0.759209156F, 0.757208824F, 0.755201399F, 0.753186822F,
    0.751165092F, 0.749136388F, 0.747100592F, 0.745057762F, 0.743007958F,
    0.740951121F, 0.73888731F, 0.736816525F, 0.734738886F, 0.732654274F,
    0.730562747F, 0.728464365F, 0.726359129F, 0.724247098F, 0.722128153F,
    0.720002472F, 0.71787F, 0.715730786F, 0.7135849F, 0.711432219F, 0.709272802F,
    0.707106769F, 0.704934061F, 0.702754736F, 0.700568795F, 0.698376298F,
    0.696177125F, 0.693971455F, 0.691759288F, 0.689540565F, 0.687315345F,
    0.685083628F, 0.682845592F, 0.680601F, 0.678350091F, 0.676092744F, 0.673829F,
    0.671559F, 0.669282556F, 0.666999936F, 0.664711F, 0.662415802F, 0.660114348F,
    0.657806695F, 0.655492842F, 0.653172851F, 0.65084672F, 0.64851445F,
    0.64617604F, 0.643831551F, 0.641481042F, 0.639124453F, 0.636761844F,
    0.634393334F, 0.632018745F, 0.629638255F, 0.627251804F, 0.624859512F,
    0.622461259F, 0.620057225F, 0.61764735F, 0.615231633F, 0.612810075F,
    0.610382795F, 0.607949793F, 0.605511F, 0.603066623F, 0.600616515F,
    0.598160744F, 0.59569931F, 0.593232274F, 0.590759695F, 0.588281572F,
    0.585797906F, 0.583308697F, 0.580814F, 0.578313828F, 0.575808227F,
    0.573297143F, 0.570780754F, 0.568259F, 0.565731823F, 0.563199341F,
    0.560661614F, 0.558118522F, 0.555570245F, 0.553016722F, 0.550458F,
    0.547894061F, 0.545325041F, 0.542750776F, 0.540171504F, 0.537587047F,
    0.534997642F, 0.532403171F, 0.529803634F, 0.527199149F, 0.524589717F,
    0.521975279F, 0.519356F, 0.516731799F, 0.514102757F, 0.511468887F,
    0.50883019F, 0.506186664F, 0.50353837F, 0.500885367F, 0.498227656F,
    0.495565295F, 0.492898226F, 0.490226507F, 0.487550169F, 0.484869242F,
    0.482183754F, 0.479493737F, 0.47679925F, 0.474100202F, 0.471396744F,
    0.468688846F, 0.465976506F, 0.463259816F, 0.460538715F, 0.457813323F,
    0.455083579F, 0.452349603F, 0.449611336F, 0.446868837F, 0.444122165F,
    0.441371292F, 0.438616246F, 0.435857117F, 0.433093846F, 0.430326492F,
    0.427555084F, 0.424779713F, 0.422000289F, 0.419216901F, 0.416429579F,
    0.413638324F, 0.410843194F, 0.408044159F, 0.40524134F, 0.402434677F,
    0.399624199F, 0.39681F, 0.393992066F, 0.391170382F, 0.388345033F,
    0.385516077F, 0.382683456F, 0.379847199F, 0.377007425F, 0.374164075F,
    0.371317208F, 0.368466824F, 0.365613F, 0.362755746F, 0.359895051F, 0.357031F,
    0.354163527F, 0.351292759F, 0.348418683F, 0.345541328F, 0.342660725F,
    0.339776874F, 0.336889863F, 0.333999664F, 0.331106305F, 0.328209847F,
    0.32531032F, 0.322407693F, 0.319502026F, 0.316593409F, 0.313681751F,
    0.310767144F, 0.307849675F, 0.304929256F, 0.302005947F, 0.299079835F,
    0.296150893F, 0.293219179F, 0.290284663F, 0.287347466F, 0.284407556F,
    0.281464934F, 0.27851969F, 0.275571823F, 0.272621363F, 0.269668311F,
    0.266712785F, 0.263754696F, 0.260794133F, 0.257831097F, 0.254865676F,
    0.251897812F, 0.248927608F, 0.24595505F, 0.242980197F, 0.24000302F,
    0.237023607F, 0.234041959F, 0.231058121F, 0.228072092F, 0.225083917F,
    0.222093627F, 0.219101235F, 0.216106802F, 0.213110328F, 0.210111842F,
    0.207111388F, 0.204108968F, 0.201104641F, 0.198098406F, 0.195090324F,
    0.192080408F, 0.18906866F, 0.186055154F, 0.183039889F, 0.18002291F,
    0.177004218F, 0.173983872F, 0.170961902F, 0.167938292F, 0.164913133F,
    0.161886394F, 0.15885815F, 0.155828416F, 0.152797192F, 0.149764538F,
    0.146730468F, 0.143695042F, 0.140658244F, 0.137620121F, 0.134580716F,
    0.13154003F, 0.128498122F, 0.125454977F, 0.122410677F, 0.119365215F,
    0.116318636F, 0.113270953F, 0.110222206F, 0.10717243F, 0.10412164F,
    0.101069868F, 0.0980171412F, 0.0949635F, 0.0919089541F, 0.0888535529F,
    0.0857973173F, 0.0827402696F, 0.0796824396F, 0.0766238645F, 0.0735645667F,
    0.070504576F, 0.0674439222F, 0.0643826351F, 0.0613207407F, 0.0582582653F,
    0.0551952459F, 0.0521317087F, 0.0490676761F, 0.0460031815F, 0.0429382585F,
    0.0398729295F, 0.0368072242F, 0.0337411761F, 0.030674804F, 0.027608145F,
    0.024541229F, 0.021474082F, 0.0184067301F, 0.0153392069F, 0.0122715384F,
    0.00920375437F, 0.00613588467F, 0.00306795677F, 0.0F, -0.00306795677F,
    -0.00613588467F, -0.00920375437F, -0.0122715384F, -0.0153392069F,
    -0.0184067301F, -0.021474082F, -0.024541229F, -0.027608145F, -0.030674804F,
    -0.0337411761F, -0.0368072242F, -0.0398729295F, -0.0429382585F,
    -0.0460031815F, -0.0490676761F, -0.0521317087F, -0.0551952459F,
    -0.0582582653F, -0.0613207407F, -0.0643826351F, -0.0674439222F,
    -0.070504576F, -0.0735645667F, -0.0766238645F, -0.0796824396F,
    -0.0827402696F, -0.0857973173F, -0.0888535529F, -0.0919089541F, -0.0949635F,
    -0.0980171412F, -0.101069868F, -0.10412164F, -0.10717243F, -0.110222206F,
    -0.113270953F, -0.116318636F, -0.119365215F, -0.122410677F, -0.125454977F,
    -0.128498122F, -0.13154003F, -0.134580716F, -0.137620121F, -0.140658244F,
    -0.143695042F, -0.146730468F, -0.149764538F, -0.152797192F, -0.155828416F,
    -0.15885815F, -0.161886394F, -0.164913133F, -0.167938292F, -0.170961902F,
    -0.173983872F, -0.177004218F, -0.18002291F, -0.183039889F, -0.186055154F,
    -0.18906866F, -0.192080408F, -0.195090324F, -0.198098406F, -0.201104641F,
    -0.204108968F, -0.207111388F, -0.210111842F, -0.213110328F, -0.216106802F,
    -0.219101235F, -0.222093627F, -0.225083917F, -0.228072092F, -0.231058121F,
    -0.234041959F, -0.237023607F, -0.24000302F, -0.242980197F, -0.24595505F,
    -0.248927608F, -0.251897812F, -0.254865676F, -0.257831097F, -0.260794133F,
    -0.263754696F, -0.266712785F, -0.269668311F, -0.272621363F, -0.275571823F,
    -0.27851969F, -0.281464934F, -0.284407556F, -0.287347466F, -0.290284663F,
    -0.293219179F, -0.296150893F, -0.299079835F, -0.302005947F, -0.304929256F,
    -0.307849675F, -0.310767144F, -0.313681751F, -0.316593409F, -0.319502026F,
    -0.322407693F, -0.32531032F, -0.328209847F, -0.331106305F, -0.333999664F,
    -0.336889863F, -0.339776874F, -0.342660725F, -0.345541328F, -0.348418683F,
    -0.351292759F, -0.354163527F, -0.357031F, -0.359895051F, -0.362755746F,
    -0.365613F, -0.368466824F, -0.371317208F, -0.374164075F, -0.377007425F,
    -0.379847199F, -0.382683456F, -0.385516077F, -0.388345033F, -0.391170382F,
    -0.393992066F, -0.39681F, -0.399624199F, -0.402434677F, -0.40524134F,
    -0.408044159F, -0.410843194F, -0.413638324F, -0.416429579F, -0.419216901F,
    -0.422000289F, -0.424779713F, -0.427555084F, -0.430326492F, -0.433093846F,
    -0.435857117F, -0.438616246F, -0.441371292F, -0.444122165F, -0.446868837F,
    -0.449611336F, -0.452349603F, -0.455083579F, -0.457813323F, -0.460538715F,
    -0.463259816F, -0.465976506F, -0.468688846F, -0.471396744F, -0.474100202F,
    -0.47679925F, -0.479493737F, -0.482183754F, -0.484869242F, -0.487550169F,
    -0.490226507F, -0.492898226F, -0.495565295F, -0.498227656F, -0.500885367F,
    -0.50353837F, -0.506186664F, -0.50883019F, -0.511468887F, -0.514102757F,
    -0.516731799F, -0.519356F, -0.521975279F, -0.524589717F, -0.527199149F,
    -0.529803634F, -0.532403171F, -0.534997642F, -0.537587047F, -0.540171504F,
    -0.542750776F, -0.545325041F, -0.547894061F, -0.550458F, -0.553016722F,
    -0.555570245F, -0.558118522F, -0.560661614F, -0.563199341F, -0.565731823F,
    -0.568259F, -0.570780754F, -0.573297143F, -0.575808227F, -0.578313828F,
    -0.580814F, -0.583308697F, -0.585797906F, -0.588281572F, -0.590759695F,
    -0.593232274F, -0.59569931F, -0.598160744F, -0.600616515F, -0.603066623F,
    -0.605511F, -0.607949793F, -0.610382795F, -0.612810075F, -0.615231633F,
    -0.61764735F, -0.620057225F, -0.622461259F, -0.624859512F, -0.627251804F,
    -0.629638255F, -0.632018745F, -0.634393334F, -0.636761844F, -0.639124453F,
    -0.641481042F, -0.643831551F, -0.64617604F, -0.64851445F, -0.65084672F,
    -0.653172851F, -0.655492842F, -0.657806695F, -0.660114348F, -0.662415802F,
    -0.664711F, -0.666999936F, -0.669282556F, -0.671559F, -0.673829F,
    -0.676092744F, -0.678350091F, -0.680601F, -0.682845592F, -0.685083628F,
    -0.687315345F, -0.689540565F, -0.691759288F, -0.693971455F, -0.696177125F,
    -0.698376298F, -0.700568795F, -0.702754736F, -0.704934061F, -0.707106769F,
    -0.709272802F, -0.711432219F, -0.7135849F, -0.715730786F, -0.71787F,
    -0.720002472F, -0.722128153F, -0.724247098F, -0.726359129F, -0.728464365F,
    -0.730562747F, -0.732654274F, -0.734738886F, -0.736816525F, -0.73888731F,
    -0.740951121F, -0.743007958F, -0.745057762F, -0.747100592F, -0.749136388F,
    -0.751165092F, -0.753186822F, -0.755201399F, -0.757208824F, -0.759209156F,
    -0.761202335F, -0.763188422F, -0.765167236F, -0.767138898F, -0.769103348F,
    -0.771060526F, -0.773010433F, -0.774953067F, -0.77688843F, -0.778816521F,
    -0.780737221F, -0.78265059F, -0.784556627F, -0.786455214F, -0.78834641F,
    -0.790230215F, -0.792106569F, -0.793975472F, -0.795836926F, -0.797690809F,
    -0.799537241F, -0.801376164F, -0.803207517F, -0.8050313F, -0.806847572F,
    -0.808656156F, -0.81045717F, -0.812250555F, -0.81403631F, -0.815814376F,
    -0.817584813F, -0.819347501F, -0.8211025F, -0.822849751F, -0.824589252F,
    -0.826321065F, -0.828045F, -0.829761207F, -0.831469595F, -0.833170176F,
    -0.834862828F, -0.836547732F, -0.838224709F, -0.839893758F, -0.841555F,
    -0.843208253F, -0.84485358F, -0.84649092F, -0.848120332F, -0.849741757F,
    -0.851355195F, -0.852960587F, -0.854558F, -0.856147349F, -0.857728601F,
    -0.859301805F, -0.860866904F, -0.862423956F, -0.863972843F, -0.865513623F,
    -0.867046237F, -0.868570685F, -0.870086968F, -0.871595085F, -0.873095F,
    -0.874586642F, -0.876070082F, -0.877545297F, -0.879012227F, -0.880470872F,
    -0.881921232F, -0.883363307F, -0.884797096F, -0.886222541F, -0.887639642F,
    -0.889048338F, -0.890448749F, -0.891840696F, -0.893224299F, -0.894599497F,
    -0.895966232F, -0.897324562F, -0.898674488F, -0.900015891F, -0.901348829F,
    -0.902673304F, -0.903989315F, -0.905296743F, -0.906595707F, -0.907886088F,
    -0.909167945F, -0.910441279F, -0.91170603F, -0.912962198F, -0.914209723F,
    -0.915448725F, -0.916679084F, -0.917900741F, -0.919113874F, -0.920318246F,
    -0.921514034F, -0.92270112F, -0.923879504F, -0.925049245F, -0.926210225F,
    -0.927362502F, -0.928506076F, -0.929640889F, -0.93076694F, -0.931884289F,
    -0.932992816F, -0.934092522F, -0.935183525F, -0.936265647F, -0.937339F,
    -0.938403547F, -0.939459205F, -0.940506101F, -0.941544056F, -0.94257319F,
    -0.943593442F, -0.944604814F, -0.945607305F, -0.946600914F, -0.947585583F,
    -0.94856137F, -0.949528158F, -0.950486064F, -0.951435F, -0.952375F,
    -0.953306F, -0.954228103F, -0.955141187F, -0.95604527F, -0.956940353F,
    -0.957826376F, -0.958703458F, -0.959571481F, -0.960430503F, -0.961280465F,
    -0.962121427F, -0.962953269F, -0.963776052F, -0.964589775F, -0.965394437F,
    -0.96619F, -0.966976464F, -0.967753828F, -0.968522072F, -0.969281256F,
    -0.970031261F, -0.970772147F, -0.971503913F, -0.972226501F, -0.972939968F,
    -0.973644257F, -0.974339366F, -0.975025356F, -0.975702107F, -0.976369739F,
    -0.977028131F, -0.977677345F, -0.97831738F, -0.978948176F, -0.979569793F,
    -0.980182111F, -0.980785251F, -0.981379211F, -0.981963873F, -0.982539296F,
    -0.983105481F, -0.983662426F, -0.984210074F, -0.984748483F, -0.985277653F,
    -0.985797524F, -0.986308098F, -0.986809373F, -0.987301409F, -0.987784147F,
    -0.988257587F, -0.988721669F, -0.989176512F, -0.989622F, -0.990058184F,
    -0.990485072F, -0.990902662F, -0.991310835F, -0.991709769F, -0.992099285F,
    -0.992479563F, -0.992850423F, -0.993211925F, -0.993564129F, -0.993907F,
    -0.994240463F, -0.994564593F, -0.994879305F, -0.99518472F, -0.995480776F,
    -0.995767415F, -0.996044695F, -0.996312618F, -0.996571124F, -0.996820271F,
    -0.997060061F, -0.997290432F, -0.997511446F, -0.997723043F, -0.997925282F,
    -0.998118103F, -0.998301566F, -0.998475552F, -0.998640239F, -0.99879545F,
    -0.998941302F, -0.999077737F, -0.999204755F, -0.999322414F, -0.999430597F,
    -0.999529421F, -0.999618828F, -0.999698818F, -0.99976939F, -0.999830604F,
    -0.99988234F, -0.999924719F, -0.999957621F, -0.999981165F, -0.999995291F,
    -1.0F };

  static const int16_t tmp_5[480]{ 1, 480, 479, 478, 477, 476, 475, 474, 473,
    472, 471, 470, 469, 468, 467, 466, 465, 464, 463, 462, 461, 460, 459, 458,
    457, 456, 455, 454, 453, 452, 451, 450, 449, 448, 447, 446, 445, 444, 443,
    442, 441, 440, 439, 438, 437, 436, 435, 434, 433, 432, 431, 430, 429, 428,
    427, 426, 425, 424, 423, 422, 421, 420, 419, 418, 417, 416, 415, 414, 413,
    412, 411, 410, 409, 408, 407, 406, 405, 404, 403, 402, 401, 400, 399, 398,
    397, 396, 395, 394, 393, 392, 391, 390, 389, 388, 387, 386, 385, 384, 383,
    382, 381, 380, 379, 378, 377, 376, 375, 374, 373, 372, 371, 370, 369, 368,
    367, 366, 365, 364, 363, 362, 361, 360, 359, 358, 357, 356, 355, 354, 353,
    352, 351, 350, 349, 348, 347, 346, 345, 344, 343, 342, 341, 340, 339, 338,
    337, 336, 335, 334, 333, 332, 331, 330, 329, 328, 327, 326, 325, 324, 323,
    322, 321, 320, 319, 318, 317, 316, 315, 314, 313, 312, 311, 310, 309, 308,
    307, 306, 305, 304, 303, 302, 301, 300, 299, 298, 297, 296, 295, 294, 293,
    292, 291, 290, 289, 288, 287, 286, 285, 284, 283, 282, 281, 280, 279, 278,
    277, 276, 275, 274, 273, 272, 271, 270, 269, 268, 267, 266, 265, 264, 263,
    262, 261, 260, 259, 258, 257, 256, 255, 254, 253, 252, 251, 250, 249, 248,
    247, 246, 245, 244, 243, 242, 241, 240, 239, 238, 237, 236, 235, 234, 233,
    232, 231, 230, 229, 228, 227, 226, 225, 224, 223, 222, 221, 220, 219, 218,
    217, 216, 215, 214, 213, 212, 211, 210, 209, 208, 207, 206, 205, 204, 203,
    202, 201, 200, 199, 198, 197, 196, 195, 194, 193, 192, 191, 190, 189, 188,
    187, 186, 185, 184, 183, 182, 181, 180, 179, 178, 177, 176, 175, 174, 173,
    172, 171, 170, 169, 168, 167, 166, 165, 164, 163, 162, 161, 160, 159, 158,
    157, 156, 155, 154, 153, 152, 151, 150, 149, 148, 147, 146, 145, 144, 143,
    142, 141, 140, 139, 138, 137, 136, 135, 134, 133, 132, 131, 130, 129, 128,
    127, 126, 125, 124, 123, 122, 121, 120, 119, 118, 117, 116, 115, 114, 113,
    112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, 100, 99, 98, 97,
    96, 95, 94, 93, 92, 91, 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78,
    77, 76, 75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60, 59,
    58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40,
    39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21,
    20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 };

  creal32_T reconVar1[480];
  creal32_T reconVar2[480];
  creal32_T ytmp[480];
  float hcostab[512];
  float hcostabinv[512];
  float hsintab[512];
  float hsintabinv[512];
  const float *costab;
  const float *sintab;
  float reconVar2_0;
  float temp_im;
  float temp_re;
  float twid_im;
  float twid_re;
  int32_t i;
  int32_t iDelta2;
  int32_t iheight;
  int32_t ihi;
  int32_t istart;
  int32_t iy;
  int32_t ju;
  int32_t temp_re_tmp_tmp;
  int16_t wrapIndex[480];
  bool tst;
  sintab = &tmp_1[0];
  costab = &tmp_2[0];
  for (i = 0; i < 512; i++) {
    ju = ((i + 1) << 1) - 2;
    hcostab[i] = costab[ju];
    hsintab[i] = sintab[ju];
    hcostabinv[i] = costabinv[ju];
    hsintabinv[i] = sintabinv[ju];
  }

  for (i = 0; i < 480; i++) {
    istart = i << 1;
    temp_re = x[istart];
    temp_im = x[istart + 1];
    twid_re = wwc[i + 479].re;
    twid_im = wwc[i + 479].im;
    ytmp[i].re = twid_re * temp_re + twid_im * temp_im;
    ytmp[i].im = twid_re * temp_im - twid_im * temp_re;
  }

  std::memset(&localDW->fy[0], 0, sizeof(creal32_T) << 10U);
  iy = 0;
  ju = 0;
  for (i = 0; i < 479; i++) {
    localDW->fy[iy] = ytmp[i];
    iy = 1024;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  localDW->fy[iy] = ytmp[479];
  for (i = 0; i <= 1022; i += 2) {
    temp_re = localDW->fy[i + 1].re;
    temp_im = localDW->fy[i + 1].im;
    twid_re = localDW->fy[i].re;
    twid_im = localDW->fy[i].im;
    localDW->fy[i + 1].re = twid_re - temp_re;
    localDW->fy[i + 1].im = twid_im - temp_im;
    localDW->fy[i].re = twid_re + temp_re;
    localDW->fy[i].im = twid_im + temp_im;
  }

  iy = 2;
  iDelta2 = 4;
  ju = 256;
  iheight = 1021;
  while (ju > 0) {
    for (i = 0; i < iheight; i += iDelta2) {
      istart = i + iy;
      temp_re = localDW->fy[istart].re;
      temp_im = localDW->fy[istart].im;
      localDW->fy[istart].re = localDW->fy[i].re - temp_re;
      localDW->fy[istart].im = localDW->fy[i].im - temp_im;
      localDW->fy[i].re += temp_re;
      localDW->fy[i].im += temp_im;
    }

    istart = 1;
    for (int32_t j{ju}; j < 512; j += ju) {
      twid_re = hcostab[j];
      twid_im = hsintab[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        temp_re_tmp_tmp = i + iy;
        temp_im = localDW->fy[temp_re_tmp_tmp].im;
        reconVar2_0 = localDW->fy[temp_re_tmp_tmp].re;
        temp_re = reconVar2_0 * twid_re - temp_im * twid_im;
        temp_im = temp_im * twid_re + reconVar2_0 * twid_im;
        localDW->fy[temp_re_tmp_tmp].re = localDW->fy[i].re - temp_re;
        localDW->fy[temp_re_tmp_tmp].im = localDW->fy[i].im - temp_im;
        localDW->fy[i].re += temp_re;
        localDW->fy[i].im += temp_im;
        i += iDelta2;
      }

      istart++;
    }

    ju = static_cast<int32_t>(static_cast<uint32_t>(ju) >> 1);
    iy = iDelta2;
    iDelta2 += iDelta2;
    iheight -= iy;
  }

  std::memset(&localDW->fv[0], 0, sizeof(creal32_T) << 10U);
  iy = 0;
  ju = 0;
  for (i = 0; i < 958; i++) {
    localDW->fv[iy] = wwc[i];
    iy = 1024;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  localDW->fv[iy] = wwc[958];
  for (i = 0; i <= 1022; i += 2) {
    temp_re = localDW->fv[i + 1].re;
    temp_im = localDW->fv[i + 1].im;
    twid_re = localDW->fv[i].re;
    twid_im = localDW->fv[i].im;
    localDW->fv[i + 1].re = twid_re - temp_re;
    localDW->fv[i + 1].im = twid_im - temp_im;
    localDW->fv[i].re = twid_re + temp_re;
    localDW->fv[i].im = twid_im + temp_im;
  }

  iy = 2;
  iDelta2 = 4;
  ju = 256;
  iheight = 1021;
  while (ju > 0) {
    for (i = 0; i < iheight; i += iDelta2) {
      istart = i + iy;
      temp_re = localDW->fv[istart].re;
      temp_im = localDW->fv[istart].im;
      localDW->fv[istart].re = localDW->fv[i].re - temp_re;
      localDW->fv[istart].im = localDW->fv[i].im - temp_im;
      localDW->fv[i].re += temp_re;
      localDW->fv[i].im += temp_im;
    }

    istart = 1;
    for (int32_t j{ju}; j < 512; j += ju) {
      twid_re = hcostab[j];
      twid_im = hsintab[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        temp_re_tmp_tmp = i + iy;
        temp_im = localDW->fv[temp_re_tmp_tmp].im;
        reconVar2_0 = localDW->fv[temp_re_tmp_tmp].re;
        temp_re = reconVar2_0 * twid_re - temp_im * twid_im;
        temp_im = temp_im * twid_re + reconVar2_0 * twid_im;
        localDW->fv[temp_re_tmp_tmp].re = localDW->fv[i].re - temp_re;
        localDW->fv[temp_re_tmp_tmp].im = localDW->fv[i].im - temp_im;
        localDW->fv[i].re += temp_re;
        localDW->fv[i].im += temp_im;
        i += iDelta2;
      }

      istart++;
    }

    ju = static_cast<int32_t>(static_cast<uint32_t>(ju) >> 1);
    iy = iDelta2;
    iDelta2 += iDelta2;
    iheight -= iy;
  }

  for (i = 0; i < 1024; i++) {
    temp_re = localDW->fy[i].re;
    temp_im = localDW->fy[i].im;
    twid_re = localDW->fv[i].im;
    twid_im = localDW->fv[i].re;
    localDW->fy[i].re = temp_re * twid_im - temp_im * twid_re;
    localDW->fy[i].im = temp_re * twid_re + temp_im * twid_im;
  }

  iy = 0;
  ju = 0;
  for (i = 0; i < 1023; i++) {
    localDW->fv[iy] = localDW->fy[i];
    iy = 1024;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  localDW->fv[iy] = localDW->fy[1023];
  for (i = 0; i <= 1022; i += 2) {
    temp_re = localDW->fv[i + 1].re;
    temp_im = localDW->fv[i + 1].im;
    twid_re = localDW->fv[i].re;
    twid_im = localDW->fv[i].im;
    localDW->fv[i + 1].re = twid_re - temp_re;
    localDW->fv[i + 1].im = twid_im - temp_im;
    localDW->fv[i].re = twid_re + temp_re;
    localDW->fv[i].im = twid_im + temp_im;
  }

  iy = 2;
  iDelta2 = 4;
  ju = 256;
  iheight = 1021;
  while (ju > 0) {
    for (i = 0; i < iheight; i += iDelta2) {
      istart = i + iy;
      temp_re = localDW->fv[istart].re;
      temp_im = localDW->fv[istart].im;
      localDW->fv[istart].re = localDW->fv[i].re - temp_re;
      localDW->fv[istart].im = localDW->fv[i].im - temp_im;
      localDW->fv[i].re += temp_re;
      localDW->fv[i].im += temp_im;
    }

    istart = 1;
    for (int32_t j{ju}; j < 512; j += ju) {
      twid_re = hcostabinv[j];
      twid_im = hsintabinv[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        temp_re_tmp_tmp = i + iy;
        temp_im = localDW->fv[temp_re_tmp_tmp].im;
        reconVar2_0 = localDW->fv[temp_re_tmp_tmp].re;
        temp_re = reconVar2_0 * twid_re - temp_im * twid_im;
        temp_im = temp_im * twid_re + reconVar2_0 * twid_im;
        localDW->fv[temp_re_tmp_tmp].re = localDW->fv[i].re - temp_re;
        localDW->fv[temp_re_tmp_tmp].im = localDW->fv[i].im - temp_im;
        localDW->fv[i].re += temp_re;
        localDW->fv[i].im += temp_im;
        i += iDelta2;
      }

      istart++;
    }

    ju = static_cast<int32_t>(static_cast<uint32_t>(ju) >> 1);
    iy = iDelta2;
    iDelta2 += iDelta2;
    iheight -= iy;
  }

  for (i = 0; i < 1024; i++) {
    localDW->fv[i].re *= 0.0009765625F;
    localDW->fv[i].im *= 0.0009765625F;
  }

  for (ju = 0; ju < 480; ju++) {
    twid_re = wwc[ju + 479].re;
    twid_im = wwc[ju + 479].im;
    temp_re = localDW->fv[ju + 479].re;
    temp_im = localDW->fv[ju + 479].im;
    ytmp[ju].re = twid_re * temp_re + twid_im * temp_im;
    ytmp[ju].im = twid_re * temp_im - twid_im * temp_re;
    reconVar1[ju] = tmp_3[ju];
    reconVar2[ju] = tmp_4[ju];
    wrapIndex[ju] = tmp_5[ju];
  }

  for (i = 0; i < 480; i++) {
    float reconVar2_1;
    float tmp;
    float tmp_0;
    int16_t wrapIndex_0;
    wrapIndex_0 = wrapIndex[i];
    temp_re = ytmp[wrapIndex_0 - 1].re;
    temp_im = -ytmp[wrapIndex_0 - 1].im;
    twid_re = reconVar1[i].re;
    twid_im = reconVar1[i].im;
    reconVar2_0 = reconVar2[i].re;
    reconVar2_1 = reconVar2[i].im;
    tmp = ytmp[i].re;
    tmp_0 = ytmp[i].im;
    y[i].re = ((tmp * twid_re - tmp_0 * twid_im) + (temp_re * reconVar2_0 -
                temp_im * reconVar2_1)) * 0.5F;
    y[i].im = ((tmp * twid_im + tmp_0 * twid_re) + (temp_re * reconVar2_1 +
                temp_im * reconVar2_0)) * 0.5F;
    y[i + 480].re = ((tmp * reconVar2_0 - tmp_0 * reconVar2_1) + (temp_re *
      twid_re - temp_im * twid_im)) * 0.5F;
    y[i + 480].im = ((tmp * reconVar2_1 + tmp_0 * reconVar2_0) + (temp_re *
      twid_im + temp_im * twid_re)) * 0.5F;
  }
}

// System initialize for atomic system:
void SmartMicDrvTsk_Ccode::FFTSystem_Init(DW_FFTSystem *localDW)
{
  // Start for MATLABSystem: '<S7>/FFTSystem'
  localDW->obj.buff.pBuffer.matlabCodegenIsDeleted = true;
  localDW->obj.buff.matlabCodegenIsDeleted = true;
  localDW->obj.matlabCodegenIsDeleted = false;
  localDW->objisempty = true;
  localDW->obj.isInitialized = 1;
  FFTSystem_setupImpl(&localDW->obj, localDW);

  //  Initialize / reset discrete-state properties
}

// Output and update for atomic system:
void SmartMicDrvTsk_Ccode::FFTSystem(const float rtu_0[480], DW_FFTSystem
  *localDW)
{
  static const float tmp[1025]{ 1.0F, 0.999995291F, 0.999981165F, 0.999957621F,
    0.999924719F, 0.99988234F, 0.999830604F, 0.99976939F, 0.999698818F,
    0.999618828F, 0.999529421F, 0.999430597F, 0.999322414F, 0.999204755F,
    0.999077737F, 0.998941302F, 0.99879545F, 0.998640239F, 0.998475552F,
    0.998301566F, 0.998118103F, 0.997925282F, 0.997723043F, 0.997511446F,
    0.997290432F, 0.997060061F, 0.996820271F, 0.996571124F, 0.996312618F,
    0.996044695F, 0.995767415F, 0.995480776F, 0.99518472F, 0.994879305F,
    0.994564593F, 0.994240463F, 0.993907F, 0.993564129F, 0.993211925F,
    0.992850423F, 0.992479563F, 0.992099285F, 0.991709769F, 0.991310835F,
    0.990902662F, 0.990485072F, 0.990058184F, 0.989622F, 0.989176512F,
    0.988721669F, 0.988257587F, 0.987784147F, 0.987301409F, 0.986809373F,
    0.986308098F, 0.985797524F, 0.985277653F, 0.984748483F, 0.984210074F,
    0.983662426F, 0.983105481F, 0.982539296F, 0.981963873F, 0.981379211F,
    0.980785251F, 0.980182111F, 0.979569793F, 0.978948176F, 0.97831738F,
    0.977677345F, 0.977028131F, 0.976369739F, 0.975702107F, 0.975025356F,
    0.974339366F, 0.973644257F, 0.972939968F, 0.972226501F, 0.971503913F,
    0.970772147F, 0.970031261F, 0.969281256F, 0.968522072F, 0.967753828F,
    0.966976464F, 0.96619F, 0.965394437F, 0.964589775F, 0.963776052F,
    0.962953269F, 0.962121427F, 0.961280465F, 0.960430503F, 0.959571481F,
    0.958703458F, 0.957826376F, 0.956940353F, 0.95604527F, 0.955141187F,
    0.954228103F, 0.953306F, 0.952375F, 0.951435F, 0.950486064F, 0.949528158F,
    0.94856137F, 0.947585583F, 0.946600914F, 0.945607305F, 0.944604814F,
    0.943593442F, 0.94257319F, 0.941544056F, 0.940506101F, 0.939459205F,
    0.938403547F, 0.937339F, 0.936265647F, 0.935183525F, 0.934092522F,
    0.932992816F, 0.931884289F, 0.93076694F, 0.929640889F, 0.928506076F,
    0.927362502F, 0.926210225F, 0.925049245F, 0.923879504F, 0.92270112F,
    0.921514034F, 0.920318246F, 0.919113874F, 0.917900741F, 0.916679084F,
    0.915448725F, 0.914209723F, 0.912962198F, 0.91170603F, 0.910441279F,
    0.909167945F, 0.907886088F, 0.906595707F, 0.905296743F, 0.903989315F,
    0.902673304F, 0.901348829F, 0.900015891F, 0.898674488F, 0.897324562F,
    0.895966232F, 0.894599497F, 0.893224299F, 0.891840696F, 0.890448749F,
    0.889048338F, 0.887639642F, 0.886222541F, 0.884797096F, 0.883363307F,
    0.881921232F, 0.880470872F, 0.879012227F, 0.877545297F, 0.876070082F,
    0.874586642F, 0.873095F, 0.871595085F, 0.870086968F, 0.868570685F,
    0.867046237F, 0.865513623F, 0.863972843F, 0.862423956F, 0.860866904F,
    0.859301805F, 0.857728601F, 0.856147349F, 0.854558F, 0.852960587F,
    0.851355195F, 0.849741757F, 0.848120332F, 0.84649092F, 0.84485358F,
    0.843208253F, 0.841555F, 0.839893758F, 0.838224709F, 0.836547732F,
    0.834862828F, 0.833170176F, 0.831469595F, 0.829761207F, 0.828045F,
    0.826321065F, 0.824589252F, 0.822849751F, 0.8211025F, 0.819347501F,
    0.817584813F, 0.815814376F, 0.81403631F, 0.812250555F, 0.81045717F,
    0.808656156F, 0.806847572F, 0.8050313F, 0.803207517F, 0.801376164F,
    0.799537241F, 0.797690809F, 0.795836926F, 0.793975472F, 0.792106569F,
    0.790230215F, 0.78834641F, 0.786455214F, 0.784556627F, 0.78265059F,
    0.780737221F, 0.778816521F, 0.77688843F, 0.774953067F, 0.773010433F,
    0.771060526F, 0.769103348F, 0.767138898F, 0.765167236F, 0.763188422F,
    0.761202335F, 0.759209156F, 0.757208824F, 0.755201399F, 0.753186822F,
    0.751165092F, 0.749136388F, 0.747100592F, 0.745057762F, 0.743007958F,
    0.740951121F, 0.73888731F, 0.736816525F, 0.734738886F, 0.732654274F,
    0.730562747F, 0.728464365F, 0.726359129F, 0.724247098F, 0.722128153F,
    0.720002472F, 0.71787F, 0.715730786F, 0.7135849F, 0.711432219F, 0.709272802F,
    0.707106769F, 0.704934061F, 0.702754736F, 0.700568795F, 0.698376298F,
    0.696177125F, 0.693971455F, 0.691759288F, 0.689540565F, 0.687315345F,
    0.685083628F, 0.682845592F, 0.680601F, 0.678350091F, 0.676092744F, 0.673829F,
    0.671559F, 0.669282556F, 0.666999936F, 0.664711F, 0.662415802F, 0.660114348F,
    0.657806695F, 0.655492842F, 0.653172851F, 0.65084672F, 0.64851445F,
    0.64617604F, 0.643831551F, 0.641481042F, 0.639124453F, 0.636761844F,
    0.634393334F, 0.632018745F, 0.629638255F, 0.627251804F, 0.624859512F,
    0.622461259F, 0.620057225F, 0.61764735F, 0.615231633F, 0.612810075F,
    0.610382795F, 0.607949793F, 0.605511F, 0.603066623F, 0.600616515F,
    0.598160744F, 0.59569931F, 0.593232274F, 0.590759695F, 0.588281572F,
    0.585797906F, 0.583308697F, 0.580814F, 0.578313828F, 0.575808227F,
    0.573297143F, 0.570780754F, 0.568259F, 0.565731823F, 0.563199341F,
    0.560661614F, 0.558118522F, 0.555570245F, 0.553016722F, 0.550458F,
    0.547894061F, 0.545325041F, 0.542750776F, 0.540171504F, 0.537587047F,
    0.534997642F, 0.532403171F, 0.529803634F, 0.527199149F, 0.524589717F,
    0.521975279F, 0.519356F, 0.516731799F, 0.514102757F, 0.511468887F,
    0.50883019F, 0.506186664F, 0.50353837F, 0.500885367F, 0.498227656F,
    0.495565295F, 0.492898226F, 0.490226507F, 0.487550169F, 0.484869242F,
    0.482183754F, 0.479493737F, 0.47679925F, 0.474100202F, 0.471396744F,
    0.468688846F, 0.465976506F, 0.463259816F, 0.460538715F, 0.457813323F,
    0.455083579F, 0.452349603F, 0.449611336F, 0.446868837F, 0.444122165F,
    0.441371292F, 0.438616246F, 0.435857117F, 0.433093846F, 0.430326492F,
    0.427555084F, 0.424779713F, 0.422000289F, 0.419216901F, 0.416429579F,
    0.413638324F, 0.410843194F, 0.408044159F, 0.40524134F, 0.402434677F,
    0.399624199F, 0.39681F, 0.393992066F, 0.391170382F, 0.388345033F,
    0.385516077F, 0.382683456F, 0.379847199F, 0.377007425F, 0.374164075F,
    0.371317208F, 0.368466824F, 0.365613F, 0.362755746F, 0.359895051F, 0.357031F,
    0.354163527F, 0.351292759F, 0.348418683F, 0.345541328F, 0.342660725F,
    0.339776874F, 0.336889863F, 0.333999664F, 0.331106305F, 0.328209847F,
    0.32531032F, 0.322407693F, 0.319502026F, 0.316593409F, 0.313681751F,
    0.310767144F, 0.307849675F, 0.304929256F, 0.302005947F, 0.299079835F,
    0.296150893F, 0.293219179F, 0.290284663F, 0.287347466F, 0.284407556F,
    0.281464934F, 0.27851969F, 0.275571823F, 0.272621363F, 0.269668311F,
    0.266712785F, 0.263754696F, 0.260794133F, 0.257831097F, 0.254865676F,
    0.251897812F, 0.248927608F, 0.24595505F, 0.242980197F, 0.24000302F,
    0.237023607F, 0.234041959F, 0.231058121F, 0.228072092F, 0.225083917F,
    0.222093627F, 0.219101235F, 0.216106802F, 0.213110328F, 0.210111842F,
    0.207111388F, 0.204108968F, 0.201104641F, 0.198098406F, 0.195090324F,
    0.192080408F, 0.18906866F, 0.186055154F, 0.183039889F, 0.18002291F,
    0.177004218F, 0.173983872F, 0.170961902F, 0.167938292F, 0.164913133F,
    0.161886394F, 0.15885815F, 0.155828416F, 0.152797192F, 0.149764538F,
    0.146730468F, 0.143695042F, 0.140658244F, 0.137620121F, 0.134580716F,
    0.13154003F, 0.128498122F, 0.125454977F, 0.122410677F, 0.119365215F,
    0.116318636F, 0.113270953F, 0.110222206F, 0.10717243F, 0.10412164F,
    0.101069868F, 0.0980171412F, 0.0949635F, 0.0919089541F, 0.0888535529F,
    0.0857973173F, 0.0827402696F, 0.0796824396F, 0.0766238645F, 0.0735645667F,
    0.070504576F, 0.0674439222F, 0.0643826351F, 0.0613207407F, 0.0582582653F,
    0.0551952459F, 0.0521317087F, 0.0490676761F, 0.0460031815F, 0.0429382585F,
    0.0398729295F, 0.0368072242F, 0.0337411761F, 0.030674804F, 0.027608145F,
    0.024541229F, 0.021474082F, 0.0184067301F, 0.0153392069F, 0.0122715384F,
    0.00920375437F, 0.00613588467F, 0.00306795677F, 0.0F, -0.00306795677F,
    -0.00613588467F, -0.00920375437F, -0.0122715384F, -0.0153392069F,
    -0.0184067301F, -0.021474082F, -0.024541229F, -0.027608145F, -0.030674804F,
    -0.0337411761F, -0.0368072242F, -0.0398729295F, -0.0429382585F,
    -0.0460031815F, -0.0490676761F, -0.0521317087F, -0.0551952459F,
    -0.0582582653F, -0.0613207407F, -0.0643826351F, -0.0674439222F,
    -0.070504576F, -0.0735645667F, -0.0766238645F, -0.0796824396F,
    -0.0827402696F, -0.0857973173F, -0.0888535529F, -0.0919089541F, -0.0949635F,
    -0.0980171412F, -0.101069868F, -0.10412164F, -0.10717243F, -0.110222206F,
    -0.113270953F, -0.116318636F, -0.119365215F, -0.122410677F, -0.125454977F,
    -0.128498122F, -0.13154003F, -0.134580716F, -0.137620121F, -0.140658244F,
    -0.143695042F, -0.146730468F, -0.149764538F, -0.152797192F, -0.155828416F,
    -0.15885815F, -0.161886394F, -0.164913133F, -0.167938292F, -0.170961902F,
    -0.173983872F, -0.177004218F, -0.18002291F, -0.183039889F, -0.186055154F,
    -0.18906866F, -0.192080408F, -0.195090324F, -0.198098406F, -0.201104641F,
    -0.204108968F, -0.207111388F, -0.210111842F, -0.213110328F, -0.216106802F,
    -0.219101235F, -0.222093627F, -0.225083917F, -0.228072092F, -0.231058121F,
    -0.234041959F, -0.237023607F, -0.24000302F, -0.242980197F, -0.24595505F,
    -0.248927608F, -0.251897812F, -0.254865676F, -0.257831097F, -0.260794133F,
    -0.263754696F, -0.266712785F, -0.269668311F, -0.272621363F, -0.275571823F,
    -0.27851969F, -0.281464934F, -0.284407556F, -0.287347466F, -0.290284663F,
    -0.293219179F, -0.296150893F, -0.299079835F, -0.302005947F, -0.304929256F,
    -0.307849675F, -0.310767144F, -0.313681751F, -0.316593409F, -0.319502026F,
    -0.322407693F, -0.32531032F, -0.328209847F, -0.331106305F, -0.333999664F,
    -0.336889863F, -0.339776874F, -0.342660725F, -0.345541328F, -0.348418683F,
    -0.351292759F, -0.354163527F, -0.357031F, -0.359895051F, -0.362755746F,
    -0.365613F, -0.368466824F, -0.371317208F, -0.374164075F, -0.377007425F,
    -0.379847199F, -0.382683456F, -0.385516077F, -0.388345033F, -0.391170382F,
    -0.393992066F, -0.39681F, -0.399624199F, -0.402434677F, -0.40524134F,
    -0.408044159F, -0.410843194F, -0.413638324F, -0.416429579F, -0.419216901F,
    -0.422000289F, -0.424779713F, -0.427555084F, -0.430326492F, -0.433093846F,
    -0.435857117F, -0.438616246F, -0.441371292F, -0.444122165F, -0.446868837F,
    -0.449611336F, -0.452349603F, -0.455083579F, -0.457813323F, -0.460538715F,
    -0.463259816F, -0.465976506F, -0.468688846F, -0.471396744F, -0.474100202F,
    -0.47679925F, -0.479493737F, -0.482183754F, -0.484869242F, -0.487550169F,
    -0.490226507F, -0.492898226F, -0.495565295F, -0.498227656F, -0.500885367F,
    -0.50353837F, -0.506186664F, -0.50883019F, -0.511468887F, -0.514102757F,
    -0.516731799F, -0.519356F, -0.521975279F, -0.524589717F, -0.527199149F,
    -0.529803634F, -0.532403171F, -0.534997642F, -0.537587047F, -0.540171504F,
    -0.542750776F, -0.545325041F, -0.547894061F, -0.550458F, -0.553016722F,
    -0.555570245F, -0.558118522F, -0.560661614F, -0.563199341F, -0.565731823F,
    -0.568259F, -0.570780754F, -0.573297143F, -0.575808227F, -0.578313828F,
    -0.580814F, -0.583308697F, -0.585797906F, -0.588281572F, -0.590759695F,
    -0.593232274F, -0.59569931F, -0.598160744F, -0.600616515F, -0.603066623F,
    -0.605511F, -0.607949793F, -0.610382795F, -0.612810075F, -0.615231633F,
    -0.61764735F, -0.620057225F, -0.622461259F, -0.624859512F, -0.627251804F,
    -0.629638255F, -0.632018745F, -0.634393334F, -0.636761844F, -0.639124453F,
    -0.641481042F, -0.643831551F, -0.64617604F, -0.64851445F, -0.65084672F,
    -0.653172851F, -0.655492842F, -0.657806695F, -0.660114348F, -0.662415802F,
    -0.664711F, -0.666999936F, -0.669282556F, -0.671559F, -0.673829F,
    -0.676092744F, -0.678350091F, -0.680601F, -0.682845592F, -0.685083628F,
    -0.687315345F, -0.689540565F, -0.691759288F, -0.693971455F, -0.696177125F,
    -0.698376298F, -0.700568795F, -0.702754736F, -0.704934061F, -0.707106769F,
    -0.709272802F, -0.711432219F, -0.7135849F, -0.715730786F, -0.71787F,
    -0.720002472F, -0.722128153F, -0.724247098F, -0.726359129F, -0.728464365F,
    -0.730562747F, -0.732654274F, -0.734738886F, -0.736816525F, -0.73888731F,
    -0.740951121F, -0.743007958F, -0.745057762F, -0.747100592F, -0.749136388F,
    -0.751165092F, -0.753186822F, -0.755201399F, -0.757208824F, -0.759209156F,
    -0.761202335F, -0.763188422F, -0.765167236F, -0.767138898F, -0.769103348F,
    -0.771060526F, -0.773010433F, -0.774953067F, -0.77688843F, -0.778816521F,
    -0.780737221F, -0.78265059F, -0.784556627F, -0.786455214F, -0.78834641F,
    -0.790230215F, -0.792106569F, -0.793975472F, -0.795836926F, -0.797690809F,
    -0.799537241F, -0.801376164F, -0.803207517F, -0.8050313F, -0.806847572F,
    -0.808656156F, -0.81045717F, -0.812250555F, -0.81403631F, -0.815814376F,
    -0.817584813F, -0.819347501F, -0.8211025F, -0.822849751F, -0.824589252F,
    -0.826321065F, -0.828045F, -0.829761207F, -0.831469595F, -0.833170176F,
    -0.834862828F, -0.836547732F, -0.838224709F, -0.839893758F, -0.841555F,
    -0.843208253F, -0.84485358F, -0.84649092F, -0.848120332F, -0.849741757F,
    -0.851355195F, -0.852960587F, -0.854558F, -0.856147349F, -0.857728601F,
    -0.859301805F, -0.860866904F, -0.862423956F, -0.863972843F, -0.865513623F,
    -0.867046237F, -0.868570685F, -0.870086968F, -0.871595085F, -0.873095F,
    -0.874586642F, -0.876070082F, -0.877545297F, -0.879012227F, -0.880470872F,
    -0.881921232F, -0.883363307F, -0.884797096F, -0.886222541F, -0.887639642F,
    -0.889048338F, -0.890448749F, -0.891840696F, -0.893224299F, -0.894599497F,
    -0.895966232F, -0.897324562F, -0.898674488F, -0.900015891F, -0.901348829F,
    -0.902673304F, -0.903989315F, -0.905296743F, -0.906595707F, -0.907886088F,
    -0.909167945F, -0.910441279F, -0.91170603F, -0.912962198F, -0.914209723F,
    -0.915448725F, -0.916679084F, -0.917900741F, -0.919113874F, -0.920318246F,
    -0.921514034F, -0.92270112F, -0.923879504F, -0.925049245F, -0.926210225F,
    -0.927362502F, -0.928506076F, -0.929640889F, -0.93076694F, -0.931884289F,
    -0.932992816F, -0.934092522F, -0.935183525F, -0.936265647F, -0.937339F,
    -0.938403547F, -0.939459205F, -0.940506101F, -0.941544056F, -0.94257319F,
    -0.943593442F, -0.944604814F, -0.945607305F, -0.946600914F, -0.947585583F,
    -0.94856137F, -0.949528158F, -0.950486064F, -0.951435F, -0.952375F,
    -0.953306F, -0.954228103F, -0.955141187F, -0.95604527F, -0.956940353F,
    -0.957826376F, -0.958703458F, -0.959571481F, -0.960430503F, -0.961280465F,
    -0.962121427F, -0.962953269F, -0.963776052F, -0.964589775F, -0.965394437F,
    -0.96619F, -0.966976464F, -0.967753828F, -0.968522072F, -0.969281256F,
    -0.970031261F, -0.970772147F, -0.971503913F, -0.972226501F, -0.972939968F,
    -0.973644257F, -0.974339366F, -0.975025356F, -0.975702107F, -0.976369739F,
    -0.977028131F, -0.977677345F, -0.97831738F, -0.978948176F, -0.979569793F,
    -0.980182111F, -0.980785251F, -0.981379211F, -0.981963873F, -0.982539296F,
    -0.983105481F, -0.983662426F, -0.984210074F, -0.984748483F, -0.985277653F,
    -0.985797524F, -0.986308098F, -0.986809373F, -0.987301409F, -0.987784147F,
    -0.988257587F, -0.988721669F, -0.989176512F, -0.989622F, -0.990058184F,
    -0.990485072F, -0.990902662F, -0.991310835F, -0.991709769F, -0.992099285F,
    -0.992479563F, -0.992850423F, -0.993211925F, -0.993564129F, -0.993907F,
    -0.994240463F, -0.994564593F, -0.994879305F, -0.99518472F, -0.995480776F,
    -0.995767415F, -0.996044695F, -0.996312618F, -0.996571124F, -0.996820271F,
    -0.997060061F, -0.997290432F, -0.997511446F, -0.997723043F, -0.997925282F,
    -0.998118103F, -0.998301566F, -0.998475552F, -0.998640239F, -0.99879545F,
    -0.998941302F, -0.999077737F, -0.999204755F, -0.999322414F, -0.999430597F,
    -0.999529421F, -0.999618828F, -0.999698818F, -0.99976939F, -0.999830604F,
    -0.99988234F, -0.999924719F, -0.999957621F, -0.999981165F, -0.999995291F,
    -1.0F };

  static const float tmp_0[1025]{ 0.0F, 0.00306795677F, 0.00613588467F,
    0.00920375437F, 0.0122715384F, 0.0153392069F, 0.0184067301F, 0.021474082F,
    0.024541229F, 0.027608145F, 0.030674804F, 0.0337411761F, 0.0368072242F,
    0.0398729295F, 0.0429382585F, 0.0460031815F, 0.0490676761F, 0.0521317087F,
    0.0551952459F, 0.0582582653F, 0.0613207407F, 0.0643826351F, 0.0674439222F,
    0.070504576F, 0.0735645667F, 0.0766238645F, 0.0796824396F, 0.0827402696F,
    0.0857973173F, 0.0888535529F, 0.0919089541F, 0.0949635F, 0.0980171412F,
    0.101069868F, 0.10412164F, 0.10717243F, 0.110222206F, 0.113270953F,
    0.116318636F, 0.119365215F, 0.122410677F, 0.125454977F, 0.128498122F,
    0.13154003F, 0.134580716F, 0.137620121F, 0.140658244F, 0.143695042F,
    0.146730468F, 0.149764538F, 0.152797192F, 0.155828416F, 0.15885815F,
    0.161886394F, 0.164913133F, 0.167938292F, 0.170961902F, 0.173983872F,
    0.177004218F, 0.18002291F, 0.183039889F, 0.186055154F, 0.18906866F,
    0.192080408F, 0.195090324F, 0.198098406F, 0.201104641F, 0.204108968F,
    0.207111388F, 0.210111842F, 0.213110328F, 0.216106802F, 0.219101235F,
    0.222093627F, 0.225083917F, 0.228072092F, 0.231058121F, 0.234041959F,
    0.237023607F, 0.24000302F, 0.242980197F, 0.24595505F, 0.248927608F,
    0.251897812F, 0.254865676F, 0.257831097F, 0.260794133F, 0.263754696F,
    0.266712785F, 0.269668311F, 0.272621363F, 0.275571823F, 0.27851969F,
    0.281464934F, 0.284407556F, 0.287347466F, 0.290284663F, 0.293219179F,
    0.296150893F, 0.299079835F, 0.302005947F, 0.304929256F, 0.307849675F,
    0.310767144F, 0.313681751F, 0.316593409F, 0.319502026F, 0.322407693F,
    0.32531032F, 0.328209847F, 0.331106305F, 0.333999664F, 0.336889863F,
    0.339776874F, 0.342660725F, 0.345541328F, 0.348418683F, 0.351292759F,
    0.354163527F, 0.357031F, 0.359895051F, 0.362755746F, 0.365613F, 0.368466824F,
    0.371317208F, 0.374164075F, 0.377007425F, 0.379847199F, 0.382683456F,
    0.385516077F, 0.388345033F, 0.391170382F, 0.393992066F, 0.39681F,
    0.399624199F, 0.402434677F, 0.40524134F, 0.408044159F, 0.410843194F,
    0.413638324F, 0.416429579F, 0.419216901F, 0.422000289F, 0.424779713F,
    0.427555084F, 0.430326492F, 0.433093846F, 0.435857117F, 0.438616246F,
    0.441371292F, 0.444122165F, 0.446868837F, 0.449611336F, 0.452349603F,
    0.455083579F, 0.457813323F, 0.460538715F, 0.463259816F, 0.465976506F,
    0.468688846F, 0.471396744F, 0.474100202F, 0.47679925F, 0.479493737F,
    0.482183754F, 0.484869242F, 0.487550169F, 0.490226507F, 0.492898226F,
    0.495565295F, 0.498227656F, 0.500885367F, 0.50353837F, 0.506186664F,
    0.50883019F, 0.511468887F, 0.514102757F, 0.516731799F, 0.519356F,
    0.521975279F, 0.524589717F, 0.527199149F, 0.529803634F, 0.532403171F,
    0.534997642F, 0.537587047F, 0.540171504F, 0.542750776F, 0.545325041F,
    0.547894061F, 0.550458F, 0.553016722F, 0.555570245F, 0.558118522F,
    0.560661614F, 0.563199341F, 0.565731823F, 0.568259F, 0.570780754F,
    0.573297143F, 0.575808227F, 0.578313828F, 0.580814F, 0.583308697F,
    0.585797906F, 0.588281572F, 0.590759695F, 0.593232274F, 0.59569931F,
    0.598160744F, 0.600616515F, 0.603066623F, 0.605511F, 0.607949793F,
    0.610382795F, 0.612810075F, 0.615231633F, 0.61764735F, 0.620057225F,
    0.622461259F, 0.624859512F, 0.627251804F, 0.629638255F, 0.632018745F,
    0.634393334F, 0.636761844F, 0.639124453F, 0.641481042F, 0.643831551F,
    0.64617604F, 0.64851445F, 0.65084672F, 0.653172851F, 0.655492842F,
    0.657806695F, 0.660114348F, 0.662415802F, 0.664711F, 0.666999936F,
    0.669282556F, 0.671559F, 0.673829F, 0.676092744F, 0.678350091F, 0.680601F,
    0.682845592F, 0.685083628F, 0.687315345F, 0.689540565F, 0.691759288F,
    0.693971455F, 0.696177125F, 0.698376298F, 0.700568795F, 0.702754736F,
    0.704934061F, 0.707106769F, 0.709272802F, 0.711432219F, 0.7135849F,
    0.715730786F, 0.71787F, 0.720002472F, 0.722128153F, 0.724247098F,
    0.726359129F, 0.728464365F, 0.730562747F, 0.732654274F, 0.734738886F,
    0.736816525F, 0.73888731F, 0.740951121F, 0.743007958F, 0.745057762F,
    0.747100592F, 0.749136388F, 0.751165092F, 0.753186822F, 0.755201399F,
    0.757208824F, 0.759209156F, 0.761202335F, 0.763188422F, 0.765167236F,
    0.767138898F, 0.769103348F, 0.771060526F, 0.773010433F, 0.774953067F,
    0.77688843F, 0.778816521F, 0.780737221F, 0.78265059F, 0.784556627F,
    0.786455214F, 0.78834641F, 0.790230215F, 0.792106569F, 0.793975472F,
    0.795836926F, 0.797690809F, 0.799537241F, 0.801376164F, 0.803207517F,
    0.8050313F, 0.806847572F, 0.808656156F, 0.81045717F, 0.812250555F,
    0.81403631F, 0.815814376F, 0.817584813F, 0.819347501F, 0.8211025F,
    0.822849751F, 0.824589252F, 0.826321065F, 0.828045F, 0.829761207F,
    0.831469595F, 0.833170176F, 0.834862828F, 0.836547732F, 0.838224709F,
    0.839893758F, 0.841555F, 0.843208253F, 0.84485358F, 0.84649092F,
    0.848120332F, 0.849741757F, 0.851355195F, 0.852960587F, 0.854558F,
    0.856147349F, 0.857728601F, 0.859301805F, 0.860866904F, 0.862423956F,
    0.863972843F, 0.865513623F, 0.867046237F, 0.868570685F, 0.870086968F,
    0.871595085F, 0.873095F, 0.874586642F, 0.876070082F, 0.877545297F,
    0.879012227F, 0.880470872F, 0.881921232F, 0.883363307F, 0.884797096F,
    0.886222541F, 0.887639642F, 0.889048338F, 0.890448749F, 0.891840696F,
    0.893224299F, 0.894599497F, 0.895966232F, 0.897324562F, 0.898674488F,
    0.900015891F, 0.901348829F, 0.902673304F, 0.903989315F, 0.905296743F,
    0.906595707F, 0.907886088F, 0.909167945F, 0.910441279F, 0.91170603F,
    0.912962198F, 0.914209723F, 0.915448725F, 0.916679084F, 0.917900741F,
    0.919113874F, 0.920318246F, 0.921514034F, 0.92270112F, 0.923879504F,
    0.925049245F, 0.926210225F, 0.927362502F, 0.928506076F, 0.929640889F,
    0.93076694F, 0.931884289F, 0.932992816F, 0.934092522F, 0.935183525F,
    0.936265647F, 0.937339F, 0.938403547F, 0.939459205F, 0.940506101F,
    0.941544056F, 0.94257319F, 0.943593442F, 0.944604814F, 0.945607305F,
    0.946600914F, 0.947585583F, 0.94856137F, 0.949528158F, 0.950486064F,
    0.951435F, 0.952375F, 0.953306F, 0.954228103F, 0.955141187F, 0.95604527F,
    0.956940353F, 0.957826376F, 0.958703458F, 0.959571481F, 0.960430503F,
    0.961280465F, 0.962121427F, 0.962953269F, 0.963776052F, 0.964589775F,
    0.965394437F, 0.96619F, 0.966976464F, 0.967753828F, 0.968522072F,
    0.969281256F, 0.970031261F, 0.970772147F, 0.971503913F, 0.972226501F,
    0.972939968F, 0.973644257F, 0.974339366F, 0.975025356F, 0.975702107F,
    0.976369739F, 0.977028131F, 0.977677345F, 0.97831738F, 0.978948176F,
    0.979569793F, 0.980182111F, 0.980785251F, 0.981379211F, 0.981963873F,
    0.982539296F, 0.983105481F, 0.983662426F, 0.984210074F, 0.984748483F,
    0.985277653F, 0.985797524F, 0.986308098F, 0.986809373F, 0.987301409F,
    0.987784147F, 0.988257587F, 0.988721669F, 0.989176512F, 0.989622F,
    0.990058184F, 0.990485072F, 0.990902662F, 0.991310835F, 0.991709769F,
    0.992099285F, 0.992479563F, 0.992850423F, 0.993211925F, 0.993564129F,
    0.993907F, 0.994240463F, 0.994564593F, 0.994879305F, 0.99518472F,
    0.995480776F, 0.995767415F, 0.996044695F, 0.996312618F, 0.996571124F,
    0.996820271F, 0.997060061F, 0.997290432F, 0.997511446F, 0.997723043F,
    0.997925282F, 0.998118103F, 0.998301566F, 0.998475552F, 0.998640239F,
    0.99879545F, 0.998941302F, 0.999077737F, 0.999204755F, 0.999322414F,
    0.999430597F, 0.999529421F, 0.999618828F, 0.999698818F, 0.99976939F,
    0.999830604F, 0.99988234F, 0.999924719F, 0.999957621F, 0.999981165F,
    0.999995291F, 1.0F, 0.999995291F, 0.999981165F, 0.999957621F, 0.999924719F,
    0.99988234F, 0.999830604F, 0.99976939F, 0.999698818F, 0.999618828F,
    0.999529421F, 0.999430597F, 0.999322414F, 0.999204755F, 0.999077737F,
    0.998941302F, 0.99879545F, 0.998640239F, 0.998475552F, 0.998301566F,
    0.998118103F, 0.997925282F, 0.997723043F, 0.997511446F, 0.997290432F,
    0.997060061F, 0.996820271F, 0.996571124F, 0.996312618F, 0.996044695F,
    0.995767415F, 0.995480776F, 0.99518472F, 0.994879305F, 0.994564593F,
    0.994240463F, 0.993907F, 0.993564129F, 0.993211925F, 0.992850423F,
    0.992479563F, 0.992099285F, 0.991709769F, 0.991310835F, 0.990902662F,
    0.990485072F, 0.990058184F, 0.989622F, 0.989176512F, 0.988721669F,
    0.988257587F, 0.987784147F, 0.987301409F, 0.986809373F, 0.986308098F,
    0.985797524F, 0.985277653F, 0.984748483F, 0.984210074F, 0.983662426F,
    0.983105481F, 0.982539296F, 0.981963873F, 0.981379211F, 0.980785251F,
    0.980182111F, 0.979569793F, 0.978948176F, 0.97831738F, 0.977677345F,
    0.977028131F, 0.976369739F, 0.975702107F, 0.975025356F, 0.974339366F,
    0.973644257F, 0.972939968F, 0.972226501F, 0.971503913F, 0.970772147F,
    0.970031261F, 0.969281256F, 0.968522072F, 0.967753828F, 0.966976464F,
    0.96619F, 0.965394437F, 0.964589775F, 0.963776052F, 0.962953269F,
    0.962121427F, 0.961280465F, 0.960430503F, 0.959571481F, 0.958703458F,
    0.957826376F, 0.956940353F, 0.95604527F, 0.955141187F, 0.954228103F,
    0.953306F, 0.952375F, 0.951435F, 0.950486064F, 0.949528158F, 0.94856137F,
    0.947585583F, 0.946600914F, 0.945607305F, 0.944604814F, 0.943593442F,
    0.94257319F, 0.941544056F, 0.940506101F, 0.939459205F, 0.938403547F,
    0.937339F, 0.936265647F, 0.935183525F, 0.934092522F, 0.932992816F,
    0.931884289F, 0.93076694F, 0.929640889F, 0.928506076F, 0.927362502F,
    0.926210225F, 0.925049245F, 0.923879504F, 0.92270112F, 0.921514034F,
    0.920318246F, 0.919113874F, 0.917900741F, 0.916679084F, 0.915448725F,
    0.914209723F, 0.912962198F, 0.91170603F, 0.910441279F, 0.909167945F,
    0.907886088F, 0.906595707F, 0.905296743F, 0.903989315F, 0.902673304F,
    0.901348829F, 0.900015891F, 0.898674488F, 0.897324562F, 0.895966232F,
    0.894599497F, 0.893224299F, 0.891840696F, 0.890448749F, 0.889048338F,
    0.887639642F, 0.886222541F, 0.884797096F, 0.883363307F, 0.881921232F,
    0.880470872F, 0.879012227F, 0.877545297F, 0.876070082F, 0.874586642F,
    0.873095F, 0.871595085F, 0.870086968F, 0.868570685F, 0.867046237F,
    0.865513623F, 0.863972843F, 0.862423956F, 0.860866904F, 0.859301805F,
    0.857728601F, 0.856147349F, 0.854558F, 0.852960587F, 0.851355195F,
    0.849741757F, 0.848120332F, 0.84649092F, 0.84485358F, 0.843208253F,
    0.841555F, 0.839893758F, 0.838224709F, 0.836547732F, 0.834862828F,
    0.833170176F, 0.831469595F, 0.829761207F, 0.828045F, 0.826321065F,
    0.824589252F, 0.822849751F, 0.8211025F, 0.819347501F, 0.817584813F,
    0.815814376F, 0.81403631F, 0.812250555F, 0.81045717F, 0.808656156F,
    0.806847572F, 0.8050313F, 0.803207517F, 0.801376164F, 0.799537241F,
    0.797690809F, 0.795836926F, 0.793975472F, 0.792106569F, 0.790230215F,
    0.78834641F, 0.786455214F, 0.784556627F, 0.78265059F, 0.780737221F,
    0.778816521F, 0.77688843F, 0.774953067F, 0.773010433F, 0.771060526F,
    0.769103348F, 0.767138898F, 0.765167236F, 0.763188422F, 0.761202335F,
    0.759209156F, 0.757208824F, 0.755201399F, 0.753186822F, 0.751165092F,
    0.749136388F, 0.747100592F, 0.745057762F, 0.743007958F, 0.740951121F,
    0.73888731F, 0.736816525F, 0.734738886F, 0.732654274F, 0.730562747F,
    0.728464365F, 0.726359129F, 0.724247098F, 0.722128153F, 0.720002472F,
    0.71787F, 0.715730786F, 0.7135849F, 0.711432219F, 0.709272802F, 0.707106769F,
    0.704934061F, 0.702754736F, 0.700568795F, 0.698376298F, 0.696177125F,
    0.693971455F, 0.691759288F, 0.689540565F, 0.687315345F, 0.685083628F,
    0.682845592F, 0.680601F, 0.678350091F, 0.676092744F, 0.673829F, 0.671559F,
    0.669282556F, 0.666999936F, 0.664711F, 0.662415802F, 0.660114348F,
    0.657806695F, 0.655492842F, 0.653172851F, 0.65084672F, 0.64851445F,
    0.64617604F, 0.643831551F, 0.641481042F, 0.639124453F, 0.636761844F,
    0.634393334F, 0.632018745F, 0.629638255F, 0.627251804F, 0.624859512F,
    0.622461259F, 0.620057225F, 0.61764735F, 0.615231633F, 0.612810075F,
    0.610382795F, 0.607949793F, 0.605511F, 0.603066623F, 0.600616515F,
    0.598160744F, 0.59569931F, 0.593232274F, 0.590759695F, 0.588281572F,
    0.585797906F, 0.583308697F, 0.580814F, 0.578313828F, 0.575808227F,
    0.573297143F, 0.570780754F, 0.568259F, 0.565731823F, 0.563199341F,
    0.560661614F, 0.558118522F, 0.555570245F, 0.553016722F, 0.550458F,
    0.547894061F, 0.545325041F, 0.542750776F, 0.540171504F, 0.537587047F,
    0.534997642F, 0.532403171F, 0.529803634F, 0.527199149F, 0.524589717F,
    0.521975279F, 0.519356F, 0.516731799F, 0.514102757F, 0.511468887F,
    0.50883019F, 0.506186664F, 0.50353837F, 0.500885367F, 0.498227656F,
    0.495565295F, 0.492898226F, 0.490226507F, 0.487550169F, 0.484869242F,
    0.482183754F, 0.479493737F, 0.47679925F, 0.474100202F, 0.471396744F,
    0.468688846F, 0.465976506F, 0.463259816F, 0.460538715F, 0.457813323F,
    0.455083579F, 0.452349603F, 0.449611336F, 0.446868837F, 0.444122165F,
    0.441371292F, 0.438616246F, 0.435857117F, 0.433093846F, 0.430326492F,
    0.427555084F, 0.424779713F, 0.422000289F, 0.419216901F, 0.416429579F,
    0.413638324F, 0.410843194F, 0.408044159F, 0.40524134F, 0.402434677F,
    0.399624199F, 0.39681F, 0.393992066F, 0.391170382F, 0.388345033F,
    0.385516077F, 0.382683456F, 0.379847199F, 0.377007425F, 0.374164075F,
    0.371317208F, 0.368466824F, 0.365613F, 0.362755746F, 0.359895051F, 0.357031F,
    0.354163527F, 0.351292759F, 0.348418683F, 0.345541328F, 0.342660725F,
    0.339776874F, 0.336889863F, 0.333999664F, 0.331106305F, 0.328209847F,
    0.32531032F, 0.322407693F, 0.319502026F, 0.316593409F, 0.313681751F,
    0.310767144F, 0.307849675F, 0.304929256F, 0.302005947F, 0.299079835F,
    0.296150893F, 0.293219179F, 0.290284663F, 0.287347466F, 0.284407556F,
    0.281464934F, 0.27851969F, 0.275571823F, 0.272621363F, 0.269668311F,
    0.266712785F, 0.263754696F, 0.260794133F, 0.257831097F, 0.254865676F,
    0.251897812F, 0.248927608F, 0.24595505F, 0.242980197F, 0.24000302F,
    0.237023607F, 0.234041959F, 0.231058121F, 0.228072092F, 0.225083917F,
    0.222093627F, 0.219101235F, 0.216106802F, 0.213110328F, 0.210111842F,
    0.207111388F, 0.204108968F, 0.201104641F, 0.198098406F, 0.195090324F,
    0.192080408F, 0.18906866F, 0.186055154F, 0.183039889F, 0.18002291F,
    0.177004218F, 0.173983872F, 0.170961902F, 0.167938292F, 0.164913133F,
    0.161886394F, 0.15885815F, 0.155828416F, 0.152797192F, 0.149764538F,
    0.146730468F, 0.143695042F, 0.140658244F, 0.137620121F, 0.134580716F,
    0.13154003F, 0.128498122F, 0.125454977F, 0.122410677F, 0.119365215F,
    0.116318636F, 0.113270953F, 0.110222206F, 0.10717243F, 0.10412164F,
    0.101069868F, 0.0980171412F, 0.0949635F, 0.0919089541F, 0.0888535529F,
    0.0857973173F, 0.0827402696F, 0.0796824396F, 0.0766238645F, 0.0735645667F,
    0.070504576F, 0.0674439222F, 0.0643826351F, 0.0613207407F, 0.0582582653F,
    0.0551952459F, 0.0521317087F, 0.0490676761F, 0.0460031815F, 0.0429382585F,
    0.0398729295F, 0.0368072242F, 0.0337411761F, 0.030674804F, 0.027608145F,
    0.024541229F, 0.021474082F, 0.0184067301F, 0.0153392069F, 0.0122715384F,
    0.00920375437F, 0.00613588467F, 0.00306795677F, 0.0F };

  b_dsp_AsyncBuffer *obj_tmp;
  cell_wrap varSizes;
  emxArray_float *c_out;
  h_dsp_internal_AsyncBuffercgHel *obj;
  float w[960];
  float nt_im;
  int32_t c;
  int32_t i;
  int32_t overlapUnderrun;
  int32_t rt;
  int16_t inSize[8];
  bool exitg1;

  // MATLABSystem: '<S7>/FFTSystem'
  obj_tmp = &localDW->obj.buff;
  obj = &localDW->obj.buff.pBuffer;
  if (localDW->obj.buff.pBuffer.isInitialized != 1) {
    localDW->obj.buff.pBuffer.isSetupComplete = false;
    localDW->obj.buff.pBuffer.isInitialized = 1;
    varSizes.f1[0] = 480U;
    varSizes.f1[1] = 1U;
    for (i = 0; i < 6; i++) {
      varSizes.f1[i + 2] = 1U;
    }

    localDW->obj.buff.pBuffer.inputVarSize = varSizes;
    localDW->obj.buff.pBuffer.NumChannels = 1;
    localDW->obj.buff.pBuffer.AsyncBuffercgHelper_isInitialized = true;
    for (i = 0; i < 192001; i++) {
      obj_tmp->pBuffer.Cache[i] = 0.0F;
    }

    localDW->obj.buff.pBuffer.isSetupComplete = true;
    localDW->obj.buff.pBuffer.ReadPointer = 1;
    localDW->obj.buff.pBuffer.WritePointer = 2;
    localDW->obj.buff.pBuffer.CumulativeOverrun = 0;
    localDW->obj.buff.pBuffer.CumulativeUnderrun = 0;
    for (i = 0; i < 192001; i++) {
      obj_tmp->pBuffer.Cache[i] = 0.0F;
    }
  }

  inSize[0] = 480;
  inSize[1] = 1;
  for (i = 0; i < 6; i++) {
    inSize[i + 2] = 1;
  }

  i = 0;
  exitg1 = false;
  while ((!exitg1) && (i < 8)) {
    if (obj->inputVarSize.f1[i] != static_cast<uint32_t>(inSize[i])) {
      for (i = 0; i < 8; i++) {
        obj->inputVarSize.f1[i] = static_cast<uint32_t>(inSize[i]);
      }

      exitg1 = true;
    } else {
      i++;
    }
  }

  AsyncBuffercgHelper_write(&localDW->obj.buff.pBuffer, rtu_0);
  i = localDW->obj.buff.pBuffer.WritePointer;
  emxInit_float(&c_out, 1);

  // MATLABSystem: '<S7>/FFTSystem'
  AsyncBuffercgHelper_ReadSamples(&localDW->obj.buff.pBuffer, c_out, &rt,
    &overlapUnderrun, &c);
  overlapUnderrun = localDW->obj.buff.pBuffer.CumulativeUnderrun;
  if ((overlapUnderrun < 0) && (rt < INT32_MIN - overlapUnderrun)) {
    localDW->obj.buff.pBuffer.CumulativeUnderrun = INT32_MIN;
  } else if ((overlapUnderrun > 0) && (rt > INT32_MAX - overlapUnderrun)) {
    localDW->obj.buff.pBuffer.CumulativeUnderrun = INT32_MAX;
  } else {
    localDW->obj.buff.pBuffer.CumulativeUnderrun = overlapUnderrun + rt;
  }

  if (rt != 0) {
    if (i < -2147483647) {
      localDW->obj.buff.pBuffer.ReadPointer = INT32_MIN;
    } else {
      localDW->obj.buff.pBuffer.ReadPointer = i - 1;
    }
  } else {
    localDW->obj.buff.pBuffer.ReadPointer = c;
  }

  for (i = 0; i < 960; i++) {
    w[i] = static_cast<float>(localDW->obj.ha[i]) * c_out->data[i];
  }

  emxFree_float(&c_out);

  // MATLABSystem: '<S7>/FFTSystem'
  rt = 0;
  localDW->wwc[479].re = 1.0F;
  localDW->wwc[479].im = 0.0F;
  for (i = 0; i < 479; i++) {
    c = ((i + 1) << 1) - 1;
    if (960 - rt <= c) {
      rt = (c + rt) - 960;
    } else {
      rt += c;
    }

    nt_im = -3.14159274F * static_cast<float>(rt) / 480.0F;
    localDW->wwc[478 - i].re = std::cos(nt_im);
    localDW->wwc[478 - i].im = -std::sin(nt_im);
  }

  for (i = 478; i >= 0; i--) {
    localDW->wwc[i + 480] = localDW->wwc[478 - i];
  }

  FFTImplementationCallback_doH_j(w, localDW->b_X, localDW->wwc, tmp, tmp_0,
    localDW);
  localDW->b_X[0].im = localDW->b_X[480].re;

  // MATLABSystem: '<S7>/FFTSystem'
  std::memcpy(&localDW->FFTSystem_k[0], &localDW->b_X[0], 480U * sizeof
              (creal32_T));
}

void SmartMicDrvTsk_Ccode::emxInit_creal32_T(emxArray_creal32_T **pEmxArray,
  int32_t numDimensions)
{
  emxArray_creal32_T *emxArray;
  *pEmxArray = static_cast<emxArray_creal32_T *>(std::malloc(sizeof
    (emxArray_creal32_T)));
  emxArray = *pEmxArray;
  emxArray->data = static_cast<creal32_T *>(nullptr);
  emxArray->numDimensions = numDimensions;
  emxArray->size = static_cast<int32_t *>(std::malloc(sizeof(int32_t) *
    static_cast<uint32_t>(numDimensions)));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (int32_t i{0}; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

void SmartMicDrvTsk_Ccode::emxEnsureCapacity_creal32_T(emxArray_creal32_T
  *emxArray, int32_t oldNumel)
{
  int32_t i;
  int32_t newNumel;
  void *newData;
  if (oldNumel < 0) {
    oldNumel = 0;
  }

  newNumel = 1;
  for (i = 0; i < emxArray->numDimensions; i++) {
    newNumel *= emxArray->size[i];
  }

  if (newNumel > emxArray->allocatedSize) {
    i = emxArray->allocatedSize;
    if (i < 16) {
      i = 16;
    }

    while (i < newNumel) {
      if (i > 1073741823) {
        i = INT32_MAX;
      } else {
        i <<= 1;
      }
    }

    newData = std::calloc(static_cast<uint32_t>(i), sizeof(creal32_T));
    if (emxArray->data != nullptr) {
      std::memcpy(newData, emxArray->data, sizeof(creal32_T)
                  * static_cast<uint32_t>(oldNumel));
      if (emxArray->canFreeData) {
        std::free(emxArray->data);
      }
    }

    emxArray->data = static_cast<creal32_T *>(newData);
    emxArray->allocatedSize = i;
    emxArray->canFreeData = true;
  }
}

void SmartMicDrvTsk_Ccode::emxInit_float_j(emxArray_float **pEmxArray, int32_t
  numDimensions)
{
  emxArray_float *emxArray;
  *pEmxArray = static_cast<emxArray_float *>(std::malloc(sizeof(emxArray_float)));
  emxArray = *pEmxArray;
  emxArray->data = static_cast<float *>(nullptr);
  emxArray->numDimensions = numDimensions;
  emxArray->size = static_cast<int32_t *>(std::malloc(sizeof(int32_t) *
    static_cast<uint32_t>(numDimensions)));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (int32_t i{0}; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

void SmartMicDrvTsk_Ccode::emxEnsureCapacity_float_j(emxArray_float *emxArray,
  int32_t oldNumel)
{
  int32_t i;
  int32_t newNumel;
  void *newData;
  if (oldNumel < 0) {
    oldNumel = 0;
  }

  newNumel = 1;
  for (i = 0; i < emxArray->numDimensions; i++) {
    newNumel *= emxArray->size[i];
  }

  if (newNumel > emxArray->allocatedSize) {
    i = emxArray->allocatedSize;
    if (i < 16) {
      i = 16;
    }

    while (i < newNumel) {
      if (i > 1073741823) {
        i = INT32_MAX;
      } else {
        i <<= 1;
      }
    }

    newData = std::calloc(static_cast<uint32_t>(i), sizeof(float));
    if (emxArray->data != nullptr) {
      std::memcpy(newData, emxArray->data, sizeof(float) * static_cast<uint32_t>
                  (oldNumel));
      if (emxArray->canFreeData) {
        std::free(emxArray->data);
      }
    }

    emxArray->data = static_cast<float *>(newData);
    emxArray->allocatedSize = i;
    emxArray->canFreeData = true;
  }
}

void SmartMicDrvTsk_Ccode::emxFree_creal32_T(emxArray_creal32_T **pEmxArray)
{
  if (*pEmxArray != static_cast<emxArray_creal32_T *>(nullptr)) {
    if (((*pEmxArray)->data != static_cast<creal32_T *>(nullptr)) && (*pEmxArray)
        ->canFreeData) {
      std::free((*pEmxArray)->data);
    }

    std::free((*pEmxArray)->size);
    std::free(*pEmxArray);
    *pEmxArray = static_cast<emxArray_creal32_T *>(nullptr);
  }
}

void SmartMicDrvTsk_Ccode::binary_expand_op_j(LinearAECSystem *in1, int32_t in2)
{
  emxArray_creal32_T *in1_0;
  float tmp;
  float tmp_0;
  float tmp_1;
  float tmp_2;
  int32_t i;
  int32_t loop_ub;
  int32_t stride_0_0;
  int32_t stride_1_0;
  int32_t stride_2_0;
  int32_t tmp_3;
  int32_t tmp_4;
  emxInit_creal32_T(&in1_0, 1);

  // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
  // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
  // MATLABSystem: '<S4>/LinearAECL' incorporates:
  //   MATLABSystem: '<S3>/MATLAB System5'
  //   MATLABSystem: '<S3>/MATLAB System6'

  i = in1_0->size[0];
  in1_0->size[0] = (in1->H.b->size[0] == 1 ? in1->H.K->size[0] : in1->H.b->size
                    [0]) == 1 ? in1->H.f->size[0] : in1->H.b->size[0] == 1 ?
    in1->H.K->size[0] : in1->H.b->size[0];
  emxEnsureCapacity_creal32_T(in1_0, i);
  stride_0_0 = (in1->H.f->size[0] != 1);
  stride_1_0 = (in1->H.K->size[0] != 1);
  stride_2_0 = (in1->H.b->size[0] != 1);
  loop_ub = (in1->H.b->size[0] == 1 ? in1->H.K->size[0] : in1->H.b->size[0]) ==
    1 ? in1->H.f->size[0] : in1->H.b->size[0] == 1 ? in1->H.K->size[0] :
    in1->H.b->size[0];
  for (i = 0; i < loop_ub; i++) {
    tmp_3 = i * stride_1_0;
    tmp = in1->H.K->data[(static_cast<int32_t>((static_cast<double>(in2) + 2.0)
      - 1.0) - 1) * in1->H.K->size[0] + tmp_3].re;
    tmp_4 = i * stride_2_0;
    tmp_0 = in1->H.b->data[(static_cast<int32_t>((static_cast<double>(in2) + 2.0)
      - 1.0) - 1) * in1->H.b->size[0] + tmp_4].im;
    tmp_1 = in1->H.K->data[(static_cast<int32_t>((static_cast<double>(in2) + 2.0)
      - 1.0) - 1) * in1->H.K->size[0] + tmp_3].im;
    tmp_2 = in1->H.b->data[(static_cast<int32_t>((static_cast<double>(in2) + 2.0)
      - 1.0) - 1) * in1->H.b->size[0] + tmp_4].re;
    in1_0->data[i].re = in1->H.f->data[(static_cast<int32_t>((static_cast<double>
      (in2) + 2.0) - 1.0) - 1) * in1->H.f->size[0] + i * stride_0_0].re - (tmp *
      tmp_2 - tmp_1 * tmp_0);
    in1_0->data[i].im = in1->H.f->data[(static_cast<int32_t>((static_cast<double>
      (in2) + 2.0) - 1.0) - 1) * in1->H.f->size[0] + i * stride_0_0].im - (tmp *
      tmp_0 + tmp_1 * tmp_2);
  }

  loop_ub = in1_0->size[0];
  for (i = 0; i < loop_ub; i++) {
    in1->H.f->data[i + in1->H.f->size[0] * (in2 + 1)] = in1_0->data[i];
  }

  // End of MATLABSystem: '<S4>/LinearAECL'
  // End of Outputs for SubSystem: '<Root>/LinearBandL'
  // End of Outputs for SubSystem: '<Root>/LinearBandH'
  emxFree_creal32_T(&in1_0);
}

void SmartMicDrvTsk_Ccode::binary_expand_op(emxArray_creal32_T *in1, int32_t in2,
  const LinearAECSystem *in3)
{
  int32_t loop_ub;
  int32_t stride_0_0;
  int32_t stride_1_0;
  int32_t stride_2_0;

  // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
  // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
  // MATLABSystem: '<S4>/LinearAECL' incorporates:
  //   MATLABSystem: '<S3>/MATLAB System5'
  //   MATLABSystem: '<S3>/MATLAB System6'

  stride_0_0 = (in3->H.b->size[0] != 1);
  stride_1_0 = (in3->H.K->size[0] != 1);
  stride_2_0 = (in3->H.f->size[0] != 1);
  loop_ub = (in3->H.f->size[0] == 1 ? in3->H.K->size[0] : in3->H.f->size[0]) ==
    1 ? in3->H.b->size[0] : in3->H.f->size[0] == 1 ? in3->H.K->size[0] :
    in3->H.f->size[0];
  for (int32_t i{0}; i < loop_ub; i++) {
    float in3_im;
    float in3_re;
    float tmp;
    float tmp_0;
    int32_t in3_re_tmp;
    in3_re_tmp = i * stride_1_0;
    in3_re = in3->H.K->data[(static_cast<int32_t>((static_cast<double>(in2) +
      2.0) - 1.0) - 1) * in3->H.K->size[0] + in3_re_tmp].re;
    in3_im = -in3->H.K->data[(static_cast<int32_t>((static_cast<double>(in2) +
      2.0) - 1.0) - 1) * in3->H.K->size[0] + in3_re_tmp].im;
    in3_re_tmp = i * stride_2_0;
    tmp = in3->H.f->data[(static_cast<int32_t>((static_cast<double>(in2) + 2.0)
      - 1.0) - 1) * in3->H.f->size[0] + in3_re_tmp].im;
    tmp_0 = in3->H.f->data[(static_cast<int32_t>((static_cast<double>(in2) + 2.0)
      - 1.0) - 1) * in3->H.f->size[0] + in3_re_tmp].re;
    in1->data[i + in1->size[0] * (in2 + 1)].re = in3->H.b->data
      [(static_cast<int32_t>((static_cast<double>(in2) + 2.0) - 1.0) - 1) *
      in3->H.b->size[0] + i * stride_0_0].re - (tmp_0 * in3_re - tmp * in3_im);
    in1->data[i + in1->size[0] * (in2 + 1)].im = in3->H.b->data
      [(static_cast<int32_t>((static_cast<double>(in2) + 2.0) - 1.0) - 1) *
      in3->H.b->size[0] + i * stride_0_0].im - (tmp * in3_re + tmp_0 * in3_im);
  }

  // End of MATLABSystem: '<S4>/LinearAECL'
  // End of Outputs for SubSystem: '<Root>/LinearBandL'
  // End of Outputs for SubSystem: '<Root>/LinearBandH'
}

void SmartMicDrvTsk_Ccode::binary_expand_op_j3x(emxArray_float *in1, float in2,
  const LinearAECSystem *in3, int32_t in4, const emxArray_float *in5)
{
  float tmp;
  float tmp_0;
  int32_t i;
  int32_t loop_ub;
  int32_t stride_0_0;
  int32_t stride_1_0;
  int32_t stride_2_0;
  int32_t tmp_1;

  // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
  // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
  // MATLABSystem: '<S4>/LinearAECL' incorporates:
  //   MATLABSystem: '<S3>/MATLAB System5'
  //   MATLABSystem: '<S3>/MATLAB System6'

  i = in1->size[0];
  in1->size[0] = (in5->size[0] == 1 ? in3->H.f->size[0] : in5->size[0]) == 1 ?
    in3->H.mu->size[0] : in5->size[0] == 1 ? in3->H.f->size[0] : in5->size[0];
  emxEnsureCapacity_float_j(in1, i);
  stride_0_0 = (in3->H.mu->size[0] != 1);
  stride_1_0 = (in3->H.f->size[0] != 1);
  stride_2_0 = (in5->size[0] != 1);
  loop_ub = (in5->size[0] == 1 ? in3->H.f->size[0] : in5->size[0]) == 1 ?
    in3->H.mu->size[0] : in5->size[0] == 1 ? in3->H.f->size[0] : in5->size[0];
  for (i = 0; i < loop_ub; i++) {
    tmp_1 = i * stride_1_0;
    tmp = in3->H.f->data[in3->H.f->size[0] * in4 + tmp_1].re;
    tmp_0 = in3->H.f->data[in3->H.f->size[0] * in4 + tmp_1].im;
    in1->data[i] = 1.0F / in3->H.mu->data[i * stride_0_0 + in3->H.mu->size[0] *
      in4] * (1.0F - in2) + ((tmp * tmp - tmp_0 * -tmp_0) + in5->data[i *
      stride_2_0 + in5->size[0] * in4]);
  }

  // End of MATLABSystem: '<S4>/LinearAECL'
  // End of Outputs for SubSystem: '<Root>/LinearBandL'
  // End of Outputs for SubSystem: '<Root>/LinearBandH'
}

void SmartMicDrvTsk_Ccode::binary_expand_op_j3(LinearAECSystem *in1, int32_t in2,
  const emxArray_creal32_T *in3, const emxArray_creal32_T *in4)
{
  emxArray_creal32_T *in1_0;
  float in3_im;
  float in3_re;
  float in4_im;
  float in4_re;
  float tmp;
  float tmp_0;
  float tmp_1;
  float tmp_2;
  float tmp_3;
  int32_t i;
  int32_t in3_re_tmp;
  int32_t loop_ub;
  int32_t stride_0_0;
  int32_t stride_1_0;
  int32_t stride_2_0;
  int32_t stride_3_0;
  int32_t stride_4_0;
  int32_t stride_5_0;
  emxInit_creal32_T(&in1_0, 1);

  // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
  // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
  // MATLABSystem: '<S4>/LinearAECL' incorporates:
  //   MATLABSystem: '<S3>/MATLAB System5'
  //   MATLABSystem: '<S3>/MATLAB System6'

  i = in1_0->size[0];
  in1_0->size[0] = (((in1->H.f->size[0] == 1 ? in4->size[0] : in1->H.f->size[0])
                     == 1 ? in3->size[0] == 1 ? in1->H.f->size[0] : in3->size[0]
                     : in1->H.f->size[0] == 1 ? in4->size[0] : in1->H.f->size[0])
                    == 1 ? in1->H.mu->size[0] : (in1->H.f->size[0] == 1 ?
    in4->size[0] : in1->H.f->size[0]) == 1 ? in3->size[0] == 1 ? in1->H.f->size
                    [0] : in3->size[0] : in1->H.f->size[0] == 1 ? in4->size[0] :
                    in1->H.f->size[0]) == 1 ? in1->H.K->size[0] : ((in1->
    H.f->size[0] == 1 ? in4->size[0] : in1->H.f->size[0]) == 1 ? in3->size[0] ==
    1 ? in1->H.f->size[0] : in3->size[0] : in1->H.f->size[0] == 1 ? in4->size[0]
    : in1->H.f->size[0]) == 1 ? in1->H.mu->size[0] : (in1->H.f->size[0] == 1 ?
    in4->size[0] : in1->H.f->size[0]) == 1 ? in3->size[0] == 1 ? in1->H.f->size
    [0] : in3->size[0] : in1->H.f->size[0] == 1 ? in4->size[0] : in1->H.f->size
    [0];
  emxEnsureCapacity_creal32_T(in1_0, i);
  stride_0_0 = (in1->H.K->size[0] != 1);
  stride_1_0 = (in1->H.mu->size[0] != 1);
  stride_2_0 = (in1->H.f->size[0] != 1);
  stride_3_0 = (in3->size[0] != 1);
  stride_4_0 = (in4->size[0] != 1);
  stride_5_0 = (in1->H.f->size[0] != 1);
  loop_ub = (((in1->H.f->size[0] == 1 ? in4->size[0] : in1->H.f->size[0]) == 1 ?
              in3->size[0] == 1 ? in1->H.f->size[0] : in3->size[0] : in1->
              H.f->size[0] == 1 ? in4->size[0] : in1->H.f->size[0]) == 1 ?
             in1->H.mu->size[0] : (in1->H.f->size[0] == 1 ? in4->size[0] :
              in1->H.f->size[0]) == 1 ? in3->size[0] == 1 ? in1->H.f->size[0] :
             in3->size[0] : in1->H.f->size[0] == 1 ? in4->size[0] : in1->
             H.f->size[0]) == 1 ? in1->H.K->size[0] : ((in1->H.f->size[0] == 1 ?
    in4->size[0] : in1->H.f->size[0]) == 1 ? in3->size[0] == 1 ? in1->H.f->size
    [0] : in3->size[0] : in1->H.f->size[0] == 1 ? in4->size[0] : in1->H.f->size
    [0]) == 1 ? in1->H.mu->size[0] : (in1->H.f->size[0] == 1 ? in4->size[0] :
    in1->H.f->size[0]) == 1 ? in3->size[0] == 1 ? in1->H.f->size[0] : in3->size
    [0] : in1->H.f->size[0] == 1 ? in4->size[0] : in1->H.f->size[0];
  for (i = 0; i < loop_ub; i++) {
    in3_re_tmp = i * stride_3_0;
    in3_re = in3->data[in3->size[0] * in2 + in3_re_tmp].re;
    in3_im = -in3->data[in3->size[0] * in2 + in3_re_tmp].im;
    in3_re_tmp = i * stride_4_0;
    in4_re = in4->data[(static_cast<int32_t>((static_cast<double>(in2) + 1.0) +
      1.0) - 1) * in4->size[0] + in3_re_tmp].re;
    in4_im = -in4->data[(static_cast<int32_t>((static_cast<double>(in2) + 1.0) +
      1.0) - 1) * in4->size[0] + in3_re_tmp].im;
    in3_re_tmp = i * stride_2_0;
    tmp = in1->H.f->data[(static_cast<int32_t>((static_cast<double>(in2) + 1.0)
      + 1.0) - 1) * in1->H.f->size[0] + in3_re_tmp].re;
    tmp_0 = in1->H.f->data[(static_cast<int32_t>((static_cast<double>(in2) + 1.0)
      + 1.0) - 1) * in1->H.f->size[0] + in3_re_tmp].im;
    in3_re_tmp = i * stride_5_0;
    tmp_1 = in1->H.f->data[in1->H.f->size[0] * in2 + in3_re_tmp].im;
    tmp_2 = in1->H.f->data[in1->H.f->size[0] * in2 + in3_re_tmp].re;
    tmp_3 = in1->H.mu->data[i * stride_1_0 + in1->H.mu->size[0] * in2];
    in1_0->data[i].re = ((tmp * in3_re - tmp_0 * in3_im) + (tmp_2 * in4_re -
      tmp_1 * in4_im)) * tmp_3 + in1->H.K->data[i * stride_0_0 + in1->H.K->size
      [0] * in2].re;
    in1_0->data[i].im = ((tmp * in3_im + tmp_0 * in3_re) + (tmp_1 * in4_re +
      tmp_2 * in4_im)) * tmp_3 + in1->H.K->data[i * stride_0_0 + in1->H.K->size
      [0] * in2].im;
  }

  loop_ub = in1_0->size[0];
  for (i = 0; i < loop_ub; i++) {
    in1->H.K->data[i + in1->H.K->size[0] * in2] = in1_0->data[i];
  }

  // End of MATLABSystem: '<S4>/LinearAECL'
  // End of Outputs for SubSystem: '<Root>/LinearBandL'
  // End of Outputs for SubSystem: '<Root>/LinearBandH'
  emxFree_creal32_T(&in1_0);
}

void SmartMicDrvTsk_Ccode::emxFree_float_j(emxArray_float **pEmxArray)
{
  if (*pEmxArray != static_cast<emxArray_float *>(nullptr)) {
    if (((*pEmxArray)->data != static_cast<float *>(nullptr)) && (*pEmxArray)
        ->canFreeData) {
      std::free((*pEmxArray)->data);
    }

    std::free((*pEmxArray)->size);
    std::free(*pEmxArray);
    *pEmxArray = static_cast<emxArray_float *>(nullptr);
  }
}

void SmartMicDrvTsk_Ccode::binary_expand_op_j3xz2(creal32_T in1[161], const
  LinearAECSystem *in2, int32_t in3)
{
  int32_t stride_0_0;
  int32_t stride_1_0;

  // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
  // MATLABSystem: '<S4>/LinearAECL'
  stride_0_0 = (in2->H.G->size[0] != 1);
  stride_1_0 = (in2->H.b->size[0] != 1);
  for (int32_t i{0}; i < 161; i++) {
    float tmp;
    float tmp_0;
    float tmp_1;
    float tmp_2;
    int32_t tmp_3;
    tmp = in2->H.G->data[i * stride_0_0 + in2->H.G->size[0] * in3].re;
    tmp_3 = i * stride_1_0;
    tmp_0 = in2->H.b->data[in2->H.b->size[0] * in3 + tmp_3].im;
    tmp_1 = in2->H.G->data[i * stride_0_0 + in2->H.G->size[0] * in3].im;
    tmp_2 = in2->H.b->data[in2->H.b->size[0] * in3 + tmp_3].re;
    in1[i].re -= tmp * tmp_2 - tmp_1 * tmp_0;
    in1[i].im -= tmp * tmp_0 + tmp_1 * tmp_2;
  }

  // End of MATLABSystem: '<S4>/LinearAECL'
  // End of Outputs for SubSystem: '<Root>/LinearBandL'
}

void SmartMicDrvTsk_Ccode::binary_expand_op_j3xz(LinearAECSystem *in1, int32_t
  in2, const creal32_T in3[161])
{
  emxArray_creal32_T *in1_1;
  float in3_0;
  float in3_1;
  float re;
  float re_tmp;
  int32_t i;
  int32_t in1_0;
  int32_t re_tmp_0;
  int32_t stride_0_0;
  int32_t stride_1_0;
  int32_t stride_2_0;

  // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
  // MATLABSystem: '<S4>/LinearAECL'
  in1_0 = in1->H.G->size[0];

  // End of Outputs for SubSystem: '<Root>/LinearBandL'
  emxInit_creal32_T(&in1_1, 1);

  // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
  // MATLABSystem: '<S4>/LinearAECL'
  i = in1_1->size[0];
  in1_1->size[0] = in1->H.G->size[0];
  emxEnsureCapacity_creal32_T(in1_1, i);
  stride_0_0 = (in1->H.G->size[0] != 1);
  stride_1_0 = (in1->H.mu->size[0] != 1);
  stride_2_0 = (in1->H.b->size[0] != 1);
  for (i = 0; i < in1_0; i++) {
    re_tmp = in1->H.mu->data[i * stride_1_0 + in1->H.mu->size[0] * in2] * 2.0F;
    re_tmp_0 = i * stride_2_0;
    re = in1->H.b->data[in1->H.b->size[0] * in2 + re_tmp_0].re * re_tmp;
    re_tmp *= -in1->H.b->data[in1->H.b->size[0] * in2 + re_tmp_0].im;
    in3_0 = in3[i].re;
    in3_1 = in3[i].im;
    re_tmp_0 = i * stride_0_0;
    in1_1->data[i].re = (re * in3_0 - re_tmp * in3_1) + in1->H.G->data[in1->
      H.G->size[0] * in2 + re_tmp_0].re;
    in1_1->data[i].im = (re * in3_1 + re_tmp * in3_0) + in1->H.G->data[in1->
      H.G->size[0] * in2 + re_tmp_0].im;
  }

  in1_0 = in1_1->size[0];
  for (i = 0; i < in1_0; i++) {
    in1->H.G->data[i + in1->H.G->size[0] * in2] = in1_1->data[i];
  }

  // End of Outputs for SubSystem: '<Root>/LinearBandL'
  emxFree_creal32_T(&in1_1);
}

void SmartMicDrvTsk_Ccode::emxInit_int32_t_j(emxArray_int32_t **pEmxArray,
  int32_t numDimensions)
{
  emxArray_int32_t *emxArray;
  *pEmxArray = static_cast<emxArray_int32_t *>(std::malloc(sizeof
    (emxArray_int32_t)));
  emxArray = *pEmxArray;
  emxArray->data = static_cast<int32_t *>(nullptr);
  emxArray->numDimensions = numDimensions;
  emxArray->size = static_cast<int32_t *>(std::malloc(sizeof(int32_t) *
    static_cast<uint32_t>(numDimensions)));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (int32_t i{0}; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

void SmartMicDrvTsk_Ccode::emxEnsureCapacity_int32_t_j(emxArray_int32_t
  *emxArray, int32_t oldNumel)
{
  int32_t i;
  int32_t newNumel;
  void *newData;
  if (oldNumel < 0) {
    oldNumel = 0;
  }

  newNumel = 1;
  for (i = 0; i < emxArray->numDimensions; i++) {
    newNumel *= emxArray->size[i];
  }

  if (newNumel > emxArray->allocatedSize) {
    i = emxArray->allocatedSize;
    if (i < 16) {
      i = 16;
    }

    while (i < newNumel) {
      if (i > 1073741823) {
        i = INT32_MAX;
      } else {
        i <<= 1;
      }
    }

    newData = std::calloc(static_cast<uint32_t>(i), sizeof(int32_t));
    if (emxArray->data != nullptr) {
      std::memcpy(newData, emxArray->data, sizeof(int32_t) *
                  static_cast<uint32_t>(oldNumel));
      if (emxArray->canFreeData) {
        std::free(emxArray->data);
      }
    }

    emxArray->data = static_cast<int32_t *>(newData);
    emxArray->allocatedSize = i;
    emxArray->canFreeData = true;
  }
}

void SmartMicDrvTsk_Ccode::emxFree_int32_t_j(emxArray_int32_t **pEmxArray)
{
  if (*pEmxArray != static_cast<emxArray_int32_t *>(nullptr)) {
    if (((*pEmxArray)->data != static_cast<int32_t *>(nullptr)) && (*pEmxArray
        )->canFreeData) {
      std::free((*pEmxArray)->data);
    }

    std::free((*pEmxArray)->size);
    std::free(*pEmxArray);
    *pEmxArray = static_cast<emxArray_int32_t *>(nullptr);
  }
}

void SmartMicDrvTsk_Ccode::AsyncBuffercgHelper_ReadSampl_j(const
  h_dsp_internal_AsyncBuffercgHel *obj, emxArray_float *out, int32_t *underrun,
  int32_t *c)
{
  emxArray_int32_t *readIdx;
  emxArray_int32_t *y;
  int32_t k;
  int32_t n;
  int32_t qY_tmp_tmp;
  int32_t rPtr;
  int32_t yk;
  int16_t y_data[479];
  *underrun = 0;
  if (obj->ReadPointer > 2147483646) {
    rPtr = INT32_MAX;
  } else {
    rPtr = obj->ReadPointer + 1;
  }

  if (rPtr > 192001) {
    rPtr = 1;
  }

  *c = rPtr + 479;
  emxInit_int32_t_j(&readIdx, 2);
  emxInit_int32_t_j(&y, 2);
  if (rPtr + 479 > 192001) {
    qY_tmp_tmp = rPtr - 191522;
    *c = rPtr - 191522;
    n = 192002 - rPtr;
    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = 192002 - rPtr;
    emxEnsureCapacity_int32_t_j(y, k);
    y->data[0] = rPtr;
    yk = rPtr;
    for (k = 2; k <= n; k++) {
      yk++;
      y->data[k - 1] = yk;
    }

    y_data[0] = 1;
    yk = 1;
    for (k = 2; k <= qY_tmp_tmp; k++) {
      yk++;
      y_data[k - 1] = static_cast<int16_t>(yk);
    }

    k = readIdx->size[0] * readIdx->size[1];
    readIdx->size[0] = 1;
    readIdx->size[1] = (y->size[1] + rPtr) - 191522;
    emxEnsureCapacity_int32_t_j(readIdx, k);
    n = y->size[1];
    if (n - 1 >= 0) {
      std::memcpy(&readIdx->data[0], &y->data[0], static_cast<uint32_t>(n) *
                  sizeof(int32_t));
    }

    for (k = 0; k < qY_tmp_tmp; k++) {
      readIdx->data[k + y->size[1]] = y_data[k];
    }

    if (rPtr <= obj->WritePointer) {
      if (obj->WritePointer < -2147291646) {
        k = INT32_MAX;
      } else {
        k = 192001 - obj->WritePointer;
      }

      if (k > 2147483646) {
        k = INT32_MAX;
      } else {
        k++;
      }

      if ((k < 0) && (rPtr - 191522 < INT32_MIN - k)) {
        *underrun = INT32_MIN;
      } else if ((k > 0) && (rPtr - 191522 > INT32_MAX - k)) {
        *underrun = INT32_MAX;
      } else {
        *underrun = (rPtr + k) - 191522;
      }
    } else if (obj->WritePointer <= rPtr - 191522) {
      if (obj->WritePointer < rPtr + 2147292127) {
        k = INT32_MAX;
      } else {
        k = (rPtr - obj->WritePointer) - 191522;
      }

      if (k > 2147483646) {
        *underrun = INT32_MAX;
      } else {
        *underrun = k + 1;
      }
    }
  } else {
    if (rPtr + 479 < rPtr) {
      n = 0;
    } else {
      n = 480;
    }

    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = n;
    emxEnsureCapacity_int32_t_j(y, k);
    if (n > 0) {
      y->data[0] = rPtr;
      yk = rPtr;
      for (k = 2; k <= n; k++) {
        yk++;
        y->data[k - 1] = yk;
      }
    }

    k = readIdx->size[0] * readIdx->size[1];
    readIdx->size[0] = 1;
    readIdx->size[1] = y->size[1];
    emxEnsureCapacity_int32_t_j(readIdx, k);
    n = y->size[1];
    if (n - 1 >= 0) {
      std::memcpy(&readIdx->data[0], &y->data[0], static_cast<uint32_t>(n) *
                  sizeof(int32_t));
    }

    if ((rPtr <= obj->WritePointer) && (obj->WritePointer <= rPtr + 479)) {
      if ((rPtr + 479 >= 0) && (obj->WritePointer < rPtr - 2147483168)) {
        k = INT32_MAX;
      } else if ((rPtr + 479 < 0) && (obj->WritePointer > rPtr - 2147483169)) {
        k = INT32_MIN;
      } else {
        k = (rPtr - obj->WritePointer) + 479;
      }

      if (k > 2147483646) {
        *underrun = INT32_MAX;
      } else {
        *underrun = k + 1;
      }
    }
  }

  emxFree_int32_t_j(&y);
  k = out->size[0];
  out->size[0] = readIdx->size[1];
  emxEnsureCapacity_float_j(out, k);
  n = readIdx->size[1];
  for (k = 0; k < n; k++) {
    out->data[k] = obj->Cache[readIdx->data[k] - 1];
  }

  emxFree_int32_t_j(&readIdx);
  if (*underrun != 0) {
    if (*underrun < -2147483167) {
      k = INT32_MAX;
    } else {
      k = 480 - *underrun;
    }

    if (k > 2147483646) {
      k = INT32_MAX;
    } else {
      k++;
    }

    if (k > 480) {
      rPtr = 0;
    } else {
      rPtr = k - 1;
    }

    if (*underrun - 1 >= 0) {
      std::memset(&out->data[rPtr], 0, static_cast<uint32_t>((*underrun + rPtr)
        - rPtr) * sizeof(float));
    }
  }
}

int32_t SmartMicDrvTsk_Ccode::AsyncBuffercgHelper_write_j
  (h_dsp_internal_AsyncBuffercgHel *obj, const float in[480])
{
  emxArray_int32_t *b;
  emxArray_int32_t *bc;
  emxArray_int32_t *y;
  int32_t y_data[479];
  int32_t c;
  int32_t k;
  int32_t n;
  int32_t n_tmp_tmp;
  int32_t overrun;
  int32_t qY;
  int32_t rPtr;
  int32_t yk;
  rPtr = obj->ReadPointer;
  overrun = 0;
  if (obj->WritePointer > 2147483167) {
    qY = INT32_MAX;
  } else {
    qY = obj->WritePointer + 480;
  }

  c = qY - 1;
  emxInit_int32_t_j(&bc, 2);
  emxInit_int32_t_j(&y, 2);
  if (qY - 1 > 192001) {
    n = qY - 192002;
    c = qY - 192002;
    n_tmp_tmp = 192002 - obj->WritePointer;
    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = 192002 - obj->WritePointer;
    emxEnsureCapacity_int32_t_j(y, k);
    y->data[0] = obj->WritePointer;
    yk = obj->WritePointer;
    for (k = 2; k <= n_tmp_tmp; k++) {
      yk++;
      y->data[k - 1] = yk;
    }

    y_data[0] = 1;
    yk = 1;
    for (k = 2; k <= n; k++) {
      yk++;
      y_data[k - 1] = yk;
    }

    k = bc->size[0] * bc->size[1];
    bc->size[0] = 1;
    bc->size[1] = (y->size[1] + qY) - 192002;
    emxEnsureCapacity_int32_t_j(bc, k);
    yk = y->size[1];
    if (yk - 1 >= 0) {
      std::memcpy(&bc->data[0], &y->data[0], static_cast<uint32_t>(yk) * sizeof
                  (int32_t));
    }

    for (k = 0; k < n; k++) {
      bc->data[k + y->size[1]] = y_data[k];
    }

    if (obj->WritePointer <= obj->ReadPointer) {
      if (obj->ReadPointer < -2147291646) {
        k = INT32_MAX;
      } else {
        k = 192001 - obj->ReadPointer;
      }

      if (k > 2147483646) {
        k = INT32_MAX;
      } else {
        k++;
      }

      if ((k < 0) && (qY - 192002 < INT32_MIN - k)) {
        overrun = INT32_MIN;
      } else if ((k > 0) && (qY - 192002 > INT32_MAX - k)) {
        overrun = INT32_MAX;
      } else {
        overrun = (qY + k) - 192002;
      }
    } else if (obj->ReadPointer <= qY - 192002) {
      if (obj->ReadPointer < qY + 2147291647) {
        qY = INT32_MAX;
      } else {
        qY = (qY - obj->ReadPointer) - 192002;
      }

      if (qY > 2147483646) {
        overrun = INT32_MAX;
      } else {
        overrun = qY + 1;
      }
    }
  } else {
    if (qY - 1 < obj->WritePointer) {
      n = 0;
    } else {
      n = qY - obj->WritePointer;
    }

    k = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = n;
    emxEnsureCapacity_int32_t_j(y, k);
    if (n > 0) {
      y->data[0] = obj->WritePointer;
      yk = obj->WritePointer;
      for (k = 2; k <= n; k++) {
        yk++;
        y->data[k - 1] = yk;
      }
    }

    k = bc->size[0] * bc->size[1];
    bc->size[0] = 1;
    bc->size[1] = y->size[1];
    emxEnsureCapacity_int32_t_j(bc, k);
    yk = y->size[1];
    if (yk - 1 >= 0) {
      std::memcpy(&bc->data[0], &y->data[0], static_cast<uint32_t>(yk) * sizeof
                  (int32_t));
    }

    if ((obj->WritePointer <= obj->ReadPointer) && (obj->ReadPointer <= qY - 1))
    {
      if ((qY - 1 >= 0) && (obj->ReadPointer < qY + INT32_MIN)) {
        qY = INT32_MAX;
      } else if ((qY - 1 < 0) && (obj->ReadPointer > qY + INT32_MAX)) {
        qY = INT32_MIN;
      } else {
        qY = (qY - obj->ReadPointer) - 1;
      }

      if (qY > 2147483646) {
        overrun = INT32_MAX;
      } else {
        overrun = qY + 1;
      }
    }
  }

  emxFree_int32_t_j(&y);
  emxInit_int32_t_j(&b, 1);
  k = b->size[0];
  b->size[0] = bc->size[1];
  emxEnsureCapacity_int32_t_j(b, k);
  yk = bc->size[1];
  for (k = 0; k < yk; k++) {
    b->data[k] = bc->data[k] - 1;
  }

  emxFree_int32_t_j(&bc);
  qY = b->size[0];
  for (k = 0; k < qY; k++) {
    obj->Cache[b->data[k]] = in[k];
  }

  emxFree_int32_t_j(&b);
  if (c + 1 > 192001) {
    c = 1;
  } else {
    c++;
  }

  if (overrun != 0) {
    rPtr = c;
  }

  if ((obj->CumulativeOverrun < 0) && (overrun < INT32_MIN -
       obj->CumulativeOverrun)) {
    obj->CumulativeOverrun = INT32_MIN;
  } else if ((obj->CumulativeOverrun > 0) && (overrun > INT32_MAX -
              obj->CumulativeOverrun)) {
    obj->CumulativeOverrun = INT32_MAX;
  } else {
    obj->CumulativeOverrun += overrun;
  }

  obj->WritePointer = c;
  obj->ReadPointer = rPtr;
  return overrun;
}

void SmartMicDrvTsk_Ccode::iFFTSystem_stepImpl(iFFTSystem *obj, const creal32_T
  X_0[480], float u[480])
{
  static const float tmp[1025]{ 1.0F, 0.999995291F, 0.999981165F, 0.999957621F,
    0.999924719F, 0.99988234F, 0.999830604F, 0.99976939F, 0.999698818F,
    0.999618828F, 0.999529421F, 0.999430597F, 0.999322414F, 0.999204755F,
    0.999077737F, 0.998941302F, 0.99879545F, 0.998640239F, 0.998475552F,
    0.998301566F, 0.998118103F, 0.997925282F, 0.997723043F, 0.997511446F,
    0.997290432F, 0.997060061F, 0.996820271F, 0.996571124F, 0.996312618F,
    0.996044695F, 0.995767415F, 0.995480776F, 0.99518472F, 0.994879305F,
    0.994564593F, 0.994240463F, 0.993907F, 0.993564129F, 0.993211925F,
    0.992850423F, 0.992479563F, 0.992099285F, 0.991709769F, 0.991310835F,
    0.990902662F, 0.990485072F, 0.990058184F, 0.989622F, 0.989176512F,
    0.988721669F, 0.988257587F, 0.987784147F, 0.987301409F, 0.986809373F,
    0.986308098F, 0.985797524F, 0.985277653F, 0.984748483F, 0.984210074F,
    0.983662426F, 0.983105481F, 0.982539296F, 0.981963873F, 0.981379211F,
    0.980785251F, 0.980182111F, 0.979569793F, 0.978948176F, 0.97831738F,
    0.977677345F, 0.977028131F, 0.976369739F, 0.975702107F, 0.975025356F,
    0.974339366F, 0.973644257F, 0.972939968F, 0.972226501F, 0.971503913F,
    0.970772147F, 0.970031261F, 0.969281256F, 0.968522072F, 0.967753828F,
    0.966976464F, 0.96619F, 0.965394437F, 0.964589775F, 0.963776052F,
    0.962953269F, 0.962121427F, 0.961280465F, 0.960430503F, 0.959571481F,
    0.958703458F, 0.957826376F, 0.956940353F, 0.95604527F, 0.955141187F,
    0.954228103F, 0.953306F, 0.952375F, 0.951435F, 0.950486064F, 0.949528158F,
    0.94856137F, 0.947585583F, 0.946600914F, 0.945607305F, 0.944604814F,
    0.943593442F, 0.94257319F, 0.941544056F, 0.940506101F, 0.939459205F,
    0.938403547F, 0.937339F, 0.936265647F, 0.935183525F, 0.934092522F,
    0.932992816F, 0.931884289F, 0.93076694F, 0.929640889F, 0.928506076F,
    0.927362502F, 0.926210225F, 0.925049245F, 0.923879504F, 0.92270112F,
    0.921514034F, 0.920318246F, 0.919113874F, 0.917900741F, 0.916679084F,
    0.915448725F, 0.914209723F, 0.912962198F, 0.91170603F, 0.910441279F,
    0.909167945F, 0.907886088F, 0.906595707F, 0.905296743F, 0.903989315F,
    0.902673304F, 0.901348829F, 0.900015891F, 0.898674488F, 0.897324562F,
    0.895966232F, 0.894599497F, 0.893224299F, 0.891840696F, 0.890448749F,
    0.889048338F, 0.887639642F, 0.886222541F, 0.884797096F, 0.883363307F,
    0.881921232F, 0.880470872F, 0.879012227F, 0.877545297F, 0.876070082F,
    0.874586642F, 0.873095F, 0.871595085F, 0.870086968F, 0.868570685F,
    0.867046237F, 0.865513623F, 0.863972843F, 0.862423956F, 0.860866904F,
    0.859301805F, 0.857728601F, 0.856147349F, 0.854558F, 0.852960587F,
    0.851355195F, 0.849741757F, 0.848120332F, 0.84649092F, 0.84485358F,
    0.843208253F, 0.841555F, 0.839893758F, 0.838224709F, 0.836547732F,
    0.834862828F, 0.833170176F, 0.831469595F, 0.829761207F, 0.828045F,
    0.826321065F, 0.824589252F, 0.822849751F, 0.8211025F, 0.819347501F,
    0.817584813F, 0.815814376F, 0.81403631F, 0.812250555F, 0.81045717F,
    0.808656156F, 0.806847572F, 0.8050313F, 0.803207517F, 0.801376164F,
    0.799537241F, 0.797690809F, 0.795836926F, 0.793975472F, 0.792106569F,
    0.790230215F, 0.78834641F, 0.786455214F, 0.784556627F, 0.78265059F,
    0.780737221F, 0.778816521F, 0.77688843F, 0.774953067F, 0.773010433F,
    0.771060526F, 0.769103348F, 0.767138898F, 0.765167236F, 0.763188422F,
    0.761202335F, 0.759209156F, 0.757208824F, 0.755201399F, 0.753186822F,
    0.751165092F, 0.749136388F, 0.747100592F, 0.745057762F, 0.743007958F,
    0.740951121F, 0.73888731F, 0.736816525F, 0.734738886F, 0.732654274F,
    0.730562747F, 0.728464365F, 0.726359129F, 0.724247098F, 0.722128153F,
    0.720002472F, 0.71787F, 0.715730786F, 0.7135849F, 0.711432219F, 0.709272802F,
    0.707106769F, 0.704934061F, 0.702754736F, 0.700568795F, 0.698376298F,
    0.696177125F, 0.693971455F, 0.691759288F, 0.689540565F, 0.687315345F,
    0.685083628F, 0.682845592F, 0.680601F, 0.678350091F, 0.676092744F, 0.673829F,
    0.671559F, 0.669282556F, 0.666999936F, 0.664711F, 0.662415802F, 0.660114348F,
    0.657806695F, 0.655492842F, 0.653172851F, 0.65084672F, 0.64851445F,
    0.64617604F, 0.643831551F, 0.641481042F, 0.639124453F, 0.636761844F,
    0.634393334F, 0.632018745F, 0.629638255F, 0.627251804F, 0.624859512F,
    0.622461259F, 0.620057225F, 0.61764735F, 0.615231633F, 0.612810075F,
    0.610382795F, 0.607949793F, 0.605511F, 0.603066623F, 0.600616515F,
    0.598160744F, 0.59569931F, 0.593232274F, 0.590759695F, 0.588281572F,
    0.585797906F, 0.583308697F, 0.580814F, 0.578313828F, 0.575808227F,
    0.573297143F, 0.570780754F, 0.568259F, 0.565731823F, 0.563199341F,
    0.560661614F, 0.558118522F, 0.555570245F, 0.553016722F, 0.550458F,
    0.547894061F, 0.545325041F, 0.542750776F, 0.540171504F, 0.537587047F,
    0.534997642F, 0.532403171F, 0.529803634F, 0.527199149F, 0.524589717F,
    0.521975279F, 0.519356F, 0.516731799F, 0.514102757F, 0.511468887F,
    0.50883019F, 0.506186664F, 0.50353837F, 0.500885367F, 0.498227656F,
    0.495565295F, 0.492898226F, 0.490226507F, 0.487550169F, 0.484869242F,
    0.482183754F, 0.479493737F, 0.47679925F, 0.474100202F, 0.471396744F,
    0.468688846F, 0.465976506F, 0.463259816F, 0.460538715F, 0.457813323F,
    0.455083579F, 0.452349603F, 0.449611336F, 0.446868837F, 0.444122165F,
    0.441371292F, 0.438616246F, 0.435857117F, 0.433093846F, 0.430326492F,
    0.427555084F, 0.424779713F, 0.422000289F, 0.419216901F, 0.416429579F,
    0.413638324F, 0.410843194F, 0.408044159F, 0.40524134F, 0.402434677F,
    0.399624199F, 0.39681F, 0.393992066F, 0.391170382F, 0.388345033F,
    0.385516077F, 0.382683456F, 0.379847199F, 0.377007425F, 0.374164075F,
    0.371317208F, 0.368466824F, 0.365613F, 0.362755746F, 0.359895051F, 0.357031F,
    0.354163527F, 0.351292759F, 0.348418683F, 0.345541328F, 0.342660725F,
    0.339776874F, 0.336889863F, 0.333999664F, 0.331106305F, 0.328209847F,
    0.32531032F, 0.322407693F, 0.319502026F, 0.316593409F, 0.313681751F,
    0.310767144F, 0.307849675F, 0.304929256F, 0.302005947F, 0.299079835F,
    0.296150893F, 0.293219179F, 0.290284663F, 0.287347466F, 0.284407556F,
    0.281464934F, 0.27851969F, 0.275571823F, 0.272621363F, 0.269668311F,
    0.266712785F, 0.263754696F, 0.260794133F, 0.257831097F, 0.254865676F,
    0.251897812F, 0.248927608F, 0.24595505F, 0.242980197F, 0.24000302F,
    0.237023607F, 0.234041959F, 0.231058121F, 0.228072092F, 0.225083917F,
    0.222093627F, 0.219101235F, 0.216106802F, 0.213110328F, 0.210111842F,
    0.207111388F, 0.204108968F, 0.201104641F, 0.198098406F, 0.195090324F,
    0.192080408F, 0.18906866F, 0.186055154F, 0.183039889F, 0.18002291F,
    0.177004218F, 0.173983872F, 0.170961902F, 0.167938292F, 0.164913133F,
    0.161886394F, 0.15885815F, 0.155828416F, 0.152797192F, 0.149764538F,
    0.146730468F, 0.143695042F, 0.140658244F, 0.137620121F, 0.134580716F,
    0.13154003F, 0.128498122F, 0.125454977F, 0.122410677F, 0.119365215F,
    0.116318636F, 0.113270953F, 0.110222206F, 0.10717243F, 0.10412164F,
    0.101069868F, 0.0980171412F, 0.0949635F, 0.0919089541F, 0.0888535529F,
    0.0857973173F, 0.0827402696F, 0.0796824396F, 0.0766238645F, 0.0735645667F,
    0.070504576F, 0.0674439222F, 0.0643826351F, 0.0613207407F, 0.0582582653F,
    0.0551952459F, 0.0521317087F, 0.0490676761F, 0.0460031815F, 0.0429382585F,
    0.0398729295F, 0.0368072242F, 0.0337411761F, 0.030674804F, 0.027608145F,
    0.024541229F, 0.021474082F, 0.0184067301F, 0.0153392069F, 0.0122715384F,
    0.00920375437F, 0.00613588467F, 0.00306795677F, 0.0F, -0.00306795677F,
    -0.00613588467F, -0.00920375437F, -0.0122715384F, -0.0153392069F,
    -0.0184067301F, -0.021474082F, -0.024541229F, -0.027608145F, -0.030674804F,
    -0.0337411761F, -0.0368072242F, -0.0398729295F, -0.0429382585F,
    -0.0460031815F, -0.0490676761F, -0.0521317087F, -0.0551952459F,
    -0.0582582653F, -0.0613207407F, -0.0643826351F, -0.0674439222F,
    -0.070504576F, -0.0735645667F, -0.0766238645F, -0.0796824396F,
    -0.0827402696F, -0.0857973173F, -0.0888535529F, -0.0919089541F, -0.0949635F,
    -0.0980171412F, -0.101069868F, -0.10412164F, -0.10717243F, -0.110222206F,
    -0.113270953F, -0.116318636F, -0.119365215F, -0.122410677F, -0.125454977F,
    -0.128498122F, -0.13154003F, -0.134580716F, -0.137620121F, -0.140658244F,
    -0.143695042F, -0.146730468F, -0.149764538F, -0.152797192F, -0.155828416F,
    -0.15885815F, -0.161886394F, -0.164913133F, -0.167938292F, -0.170961902F,
    -0.173983872F, -0.177004218F, -0.18002291F, -0.183039889F, -0.186055154F,
    -0.18906866F, -0.192080408F, -0.195090324F, -0.198098406F, -0.201104641F,
    -0.204108968F, -0.207111388F, -0.210111842F, -0.213110328F, -0.216106802F,
    -0.219101235F, -0.222093627F, -0.225083917F, -0.228072092F, -0.231058121F,
    -0.234041959F, -0.237023607F, -0.24000302F, -0.242980197F, -0.24595505F,
    -0.248927608F, -0.251897812F, -0.254865676F, -0.257831097F, -0.260794133F,
    -0.263754696F, -0.266712785F, -0.269668311F, -0.272621363F, -0.275571823F,
    -0.27851969F, -0.281464934F, -0.284407556F, -0.287347466F, -0.290284663F,
    -0.293219179F, -0.296150893F, -0.299079835F, -0.302005947F, -0.304929256F,
    -0.307849675F, -0.310767144F, -0.313681751F, -0.316593409F, -0.319502026F,
    -0.322407693F, -0.32531032F, -0.328209847F, -0.331106305F, -0.333999664F,
    -0.336889863F, -0.339776874F, -0.342660725F, -0.345541328F, -0.348418683F,
    -0.351292759F, -0.354163527F, -0.357031F, -0.359895051F, -0.362755746F,
    -0.365613F, -0.368466824F, -0.371317208F, -0.374164075F, -0.377007425F,
    -0.379847199F, -0.382683456F, -0.385516077F, -0.388345033F, -0.391170382F,
    -0.393992066F, -0.39681F, -0.399624199F, -0.402434677F, -0.40524134F,
    -0.408044159F, -0.410843194F, -0.413638324F, -0.416429579F, -0.419216901F,
    -0.422000289F, -0.424779713F, -0.427555084F, -0.430326492F, -0.433093846F,
    -0.435857117F, -0.438616246F, -0.441371292F, -0.444122165F, -0.446868837F,
    -0.449611336F, -0.452349603F, -0.455083579F, -0.457813323F, -0.460538715F,
    -0.463259816F, -0.465976506F, -0.468688846F, -0.471396744F, -0.474100202F,
    -0.47679925F, -0.479493737F, -0.482183754F, -0.484869242F, -0.487550169F,
    -0.490226507F, -0.492898226F, -0.495565295F, -0.498227656F, -0.500885367F,
    -0.50353837F, -0.506186664F, -0.50883019F, -0.511468887F, -0.514102757F,
    -0.516731799F, -0.519356F, -0.521975279F, -0.524589717F, -0.527199149F,
    -0.529803634F, -0.532403171F, -0.534997642F, -0.537587047F, -0.540171504F,
    -0.542750776F, -0.545325041F, -0.547894061F, -0.550458F, -0.553016722F,
    -0.555570245F, -0.558118522F, -0.560661614F, -0.563199341F, -0.565731823F,
    -0.568259F, -0.570780754F, -0.573297143F, -0.575808227F, -0.578313828F,
    -0.580814F, -0.583308697F, -0.585797906F, -0.588281572F, -0.590759695F,
    -0.593232274F, -0.59569931F, -0.598160744F, -0.600616515F, -0.603066623F,
    -0.605511F, -0.607949793F, -0.610382795F, -0.612810075F, -0.615231633F,
    -0.61764735F, -0.620057225F, -0.622461259F, -0.624859512F, -0.627251804F,
    -0.629638255F, -0.632018745F, -0.634393334F, -0.636761844F, -0.639124453F,
    -0.641481042F, -0.643831551F, -0.64617604F, -0.64851445F, -0.65084672F,
    -0.653172851F, -0.655492842F, -0.657806695F, -0.660114348F, -0.662415802F,
    -0.664711F, -0.666999936F, -0.669282556F, -0.671559F, -0.673829F,
    -0.676092744F, -0.678350091F, -0.680601F, -0.682845592F, -0.685083628F,
    -0.687315345F, -0.689540565F, -0.691759288F, -0.693971455F, -0.696177125F,
    -0.698376298F, -0.700568795F, -0.702754736F, -0.704934061F, -0.707106769F,
    -0.709272802F, -0.711432219F, -0.7135849F, -0.715730786F, -0.71787F,
    -0.720002472F, -0.722128153F, -0.724247098F, -0.726359129F, -0.728464365F,
    -0.730562747F, -0.732654274F, -0.734738886F, -0.736816525F, -0.73888731F,
    -0.740951121F, -0.743007958F, -0.745057762F, -0.747100592F, -0.749136388F,
    -0.751165092F, -0.753186822F, -0.755201399F, -0.757208824F, -0.759209156F,
    -0.761202335F, -0.763188422F, -0.765167236F, -0.767138898F, -0.769103348F,
    -0.771060526F, -0.773010433F, -0.774953067F, -0.77688843F, -0.778816521F,
    -0.780737221F, -0.78265059F, -0.784556627F, -0.786455214F, -0.78834641F,
    -0.790230215F, -0.792106569F, -0.793975472F, -0.795836926F, -0.797690809F,
    -0.799537241F, -0.801376164F, -0.803207517F, -0.8050313F, -0.806847572F,
    -0.808656156F, -0.81045717F, -0.812250555F, -0.81403631F, -0.815814376F,
    -0.817584813F, -0.819347501F, -0.8211025F, -0.822849751F, -0.824589252F,
    -0.826321065F, -0.828045F, -0.829761207F, -0.831469595F, -0.833170176F,
    -0.834862828F, -0.836547732F, -0.838224709F, -0.839893758F, -0.841555F,
    -0.843208253F, -0.84485358F, -0.84649092F, -0.848120332F, -0.849741757F,
    -0.851355195F, -0.852960587F, -0.854558F, -0.856147349F, -0.857728601F,
    -0.859301805F, -0.860866904F, -0.862423956F, -0.863972843F, -0.865513623F,
    -0.867046237F, -0.868570685F, -0.870086968F, -0.871595085F, -0.873095F,
    -0.874586642F, -0.876070082F, -0.877545297F, -0.879012227F, -0.880470872F,
    -0.881921232F, -0.883363307F, -0.884797096F, -0.886222541F, -0.887639642F,
    -0.889048338F, -0.890448749F, -0.891840696F, -0.893224299F, -0.894599497F,
    -0.895966232F, -0.897324562F, -0.898674488F, -0.900015891F, -0.901348829F,
    -0.902673304F, -0.903989315F, -0.905296743F, -0.906595707F, -0.907886088F,
    -0.909167945F, -0.910441279F, -0.91170603F, -0.912962198F, -0.914209723F,
    -0.915448725F, -0.916679084F, -0.917900741F, -0.919113874F, -0.920318246F,
    -0.921514034F, -0.92270112F, -0.923879504F, -0.925049245F, -0.926210225F,
    -0.927362502F, -0.928506076F, -0.929640889F, -0.93076694F, -0.931884289F,
    -0.932992816F, -0.934092522F, -0.935183525F, -0.936265647F, -0.937339F,
    -0.938403547F, -0.939459205F, -0.940506101F, -0.941544056F, -0.94257319F,
    -0.943593442F, -0.944604814F, -0.945607305F, -0.946600914F, -0.947585583F,
    -0.94856137F, -0.949528158F, -0.950486064F, -0.951435F, -0.952375F,
    -0.953306F, -0.954228103F, -0.955141187F, -0.95604527F, -0.956940353F,
    -0.957826376F, -0.958703458F, -0.959571481F, -0.960430503F, -0.961280465F,
    -0.962121427F, -0.962953269F, -0.963776052F, -0.964589775F, -0.965394437F,
    -0.96619F, -0.966976464F, -0.967753828F, -0.968522072F, -0.969281256F,
    -0.970031261F, -0.970772147F, -0.971503913F, -0.972226501F, -0.972939968F,
    -0.973644257F, -0.974339366F, -0.975025356F, -0.975702107F, -0.976369739F,
    -0.977028131F, -0.977677345F, -0.97831738F, -0.978948176F, -0.979569793F,
    -0.980182111F, -0.980785251F, -0.981379211F, -0.981963873F, -0.982539296F,
    -0.983105481F, -0.983662426F, -0.984210074F, -0.984748483F, -0.985277653F,
    -0.985797524F, -0.986308098F, -0.986809373F, -0.987301409F, -0.987784147F,
    -0.988257587F, -0.988721669F, -0.989176512F, -0.989622F, -0.990058184F,
    -0.990485072F, -0.990902662F, -0.991310835F, -0.991709769F, -0.992099285F,
    -0.992479563F, -0.992850423F, -0.993211925F, -0.993564129F, -0.993907F,
    -0.994240463F, -0.994564593F, -0.994879305F, -0.99518472F, -0.995480776F,
    -0.995767415F, -0.996044695F, -0.996312618F, -0.996571124F, -0.996820271F,
    -0.997060061F, -0.997290432F, -0.997511446F, -0.997723043F, -0.997925282F,
    -0.998118103F, -0.998301566F, -0.998475552F, -0.998640239F, -0.99879545F,
    -0.998941302F, -0.999077737F, -0.999204755F, -0.999322414F, -0.999430597F,
    -0.999529421F, -0.999618828F, -0.999698818F, -0.99976939F, -0.999830604F,
    -0.99988234F, -0.999924719F, -0.999957621F, -0.999981165F, -0.999995291F,
    -1.0F };

  static const float tmp_0[1025]{ 0.0F, -0.00306795677F, -0.00613588467F,
    -0.00920375437F, -0.0122715384F, -0.0153392069F, -0.0184067301F,
    -0.021474082F, -0.024541229F, -0.027608145F, -0.030674804F, -0.0337411761F,
    -0.0368072242F, -0.0398729295F, -0.0429382585F, -0.0460031815F,
    -0.0490676761F, -0.0521317087F, -0.0551952459F, -0.0582582653F,
    -0.0613207407F, -0.0643826351F, -0.0674439222F, -0.070504576F,
    -0.0735645667F, -0.0766238645F, -0.0796824396F, -0.0827402696F,
    -0.0857973173F, -0.0888535529F, -0.0919089541F, -0.0949635F, -0.0980171412F,
    -0.101069868F, -0.10412164F, -0.10717243F, -0.110222206F, -0.113270953F,
    -0.116318636F, -0.119365215F, -0.122410677F, -0.125454977F, -0.128498122F,
    -0.13154003F, -0.134580716F, -0.137620121F, -0.140658244F, -0.143695042F,
    -0.146730468F, -0.149764538F, -0.152797192F, -0.155828416F, -0.15885815F,
    -0.161886394F, -0.164913133F, -0.167938292F, -0.170961902F, -0.173983872F,
    -0.177004218F, -0.18002291F, -0.183039889F, -0.186055154F, -0.18906866F,
    -0.192080408F, -0.195090324F, -0.198098406F, -0.201104641F, -0.204108968F,
    -0.207111388F, -0.210111842F, -0.213110328F, -0.216106802F, -0.219101235F,
    -0.222093627F, -0.225083917F, -0.228072092F, -0.231058121F, -0.234041959F,
    -0.237023607F, -0.24000302F, -0.242980197F, -0.24595505F, -0.248927608F,
    -0.251897812F, -0.254865676F, -0.257831097F, -0.260794133F, -0.263754696F,
    -0.266712785F, -0.269668311F, -0.272621363F, -0.275571823F, -0.27851969F,
    -0.281464934F, -0.284407556F, -0.287347466F, -0.290284663F, -0.293219179F,
    -0.296150893F, -0.299079835F, -0.302005947F, -0.304929256F, -0.307849675F,
    -0.310767144F, -0.313681751F, -0.316593409F, -0.319502026F, -0.322407693F,
    -0.32531032F, -0.328209847F, -0.331106305F, -0.333999664F, -0.336889863F,
    -0.339776874F, -0.342660725F, -0.345541328F, -0.348418683F, -0.351292759F,
    -0.354163527F, -0.357031F, -0.359895051F, -0.362755746F, -0.365613F,
    -0.368466824F, -0.371317208F, -0.374164075F, -0.377007425F, -0.379847199F,
    -0.382683456F, -0.385516077F, -0.388345033F, -0.391170382F, -0.393992066F,
    -0.39681F, -0.399624199F, -0.402434677F, -0.40524134F, -0.408044159F,
    -0.410843194F, -0.413638324F, -0.416429579F, -0.419216901F, -0.422000289F,
    -0.424779713F, -0.427555084F, -0.430326492F, -0.433093846F, -0.435857117F,
    -0.438616246F, -0.441371292F, -0.444122165F, -0.446868837F, -0.449611336F,
    -0.452349603F, -0.455083579F, -0.457813323F, -0.460538715F, -0.463259816F,
    -0.465976506F, -0.468688846F, -0.471396744F, -0.474100202F, -0.47679925F,
    -0.479493737F, -0.482183754F, -0.484869242F, -0.487550169F, -0.490226507F,
    -0.492898226F, -0.495565295F, -0.498227656F, -0.500885367F, -0.50353837F,
    -0.506186664F, -0.50883019F, -0.511468887F, -0.514102757F, -0.516731799F,
    -0.519356F, -0.521975279F, -0.524589717F, -0.527199149F, -0.529803634F,
    -0.532403171F, -0.534997642F, -0.537587047F, -0.540171504F, -0.542750776F,
    -0.545325041F, -0.547894061F, -0.550458F, -0.553016722F, -0.555570245F,
    -0.558118522F, -0.560661614F, -0.563199341F, -0.565731823F, -0.568259F,
    -0.570780754F, -0.573297143F, -0.575808227F, -0.578313828F, -0.580814F,
    -0.583308697F, -0.585797906F, -0.588281572F, -0.590759695F, -0.593232274F,
    -0.59569931F, -0.598160744F, -0.600616515F, -0.603066623F, -0.605511F,
    -0.607949793F, -0.610382795F, -0.612810075F, -0.615231633F, -0.61764735F,
    -0.620057225F, -0.622461259F, -0.624859512F, -0.627251804F, -0.629638255F,
    -0.632018745F, -0.634393334F, -0.636761844F, -0.639124453F, -0.641481042F,
    -0.643831551F, -0.64617604F, -0.64851445F, -0.65084672F, -0.653172851F,
    -0.655492842F, -0.657806695F, -0.660114348F, -0.662415802F, -0.664711F,
    -0.666999936F, -0.669282556F, -0.671559F, -0.673829F, -0.676092744F,
    -0.678350091F, -0.680601F, -0.682845592F, -0.685083628F, -0.687315345F,
    -0.689540565F, -0.691759288F, -0.693971455F, -0.696177125F, -0.698376298F,
    -0.700568795F, -0.702754736F, -0.704934061F, -0.707106769F, -0.709272802F,
    -0.711432219F, -0.7135849F, -0.715730786F, -0.71787F, -0.720002472F,
    -0.722128153F, -0.724247098F, -0.726359129F, -0.728464365F, -0.730562747F,
    -0.732654274F, -0.734738886F, -0.736816525F, -0.73888731F, -0.740951121F,
    -0.743007958F, -0.745057762F, -0.747100592F, -0.749136388F, -0.751165092F,
    -0.753186822F, -0.755201399F, -0.757208824F, -0.759209156F, -0.761202335F,
    -0.763188422F, -0.765167236F, -0.767138898F, -0.769103348F, -0.771060526F,
    -0.773010433F, -0.774953067F, -0.77688843F, -0.778816521F, -0.780737221F,
    -0.78265059F, -0.784556627F, -0.786455214F, -0.78834641F, -0.790230215F,
    -0.792106569F, -0.793975472F, -0.795836926F, -0.797690809F, -0.799537241F,
    -0.801376164F, -0.803207517F, -0.8050313F, -0.806847572F, -0.808656156F,
    -0.81045717F, -0.812250555F, -0.81403631F, -0.815814376F, -0.817584813F,
    -0.819347501F, -0.8211025F, -0.822849751F, -0.824589252F, -0.826321065F,
    -0.828045F, -0.829761207F, -0.831469595F, -0.833170176F, -0.834862828F,
    -0.836547732F, -0.838224709F, -0.839893758F, -0.841555F, -0.843208253F,
    -0.84485358F, -0.84649092F, -0.848120332F, -0.849741757F, -0.851355195F,
    -0.852960587F, -0.854558F, -0.856147349F, -0.857728601F, -0.859301805F,
    -0.860866904F, -0.862423956F, -0.863972843F, -0.865513623F, -0.867046237F,
    -0.868570685F, -0.870086968F, -0.871595085F, -0.873095F, -0.874586642F,
    -0.876070082F, -0.877545297F, -0.879012227F, -0.880470872F, -0.881921232F,
    -0.883363307F, -0.884797096F, -0.886222541F, -0.887639642F, -0.889048338F,
    -0.890448749F, -0.891840696F, -0.893224299F, -0.894599497F, -0.895966232F,
    -0.897324562F, -0.898674488F, -0.900015891F, -0.901348829F, -0.902673304F,
    -0.903989315F, -0.905296743F, -0.906595707F, -0.907886088F, -0.909167945F,
    -0.910441279F, -0.91170603F, -0.912962198F, -0.914209723F, -0.915448725F,
    -0.916679084F, -0.917900741F, -0.919113874F, -0.920318246F, -0.921514034F,
    -0.92270112F, -0.923879504F, -0.925049245F, -0.926210225F, -0.927362502F,
    -0.928506076F, -0.929640889F, -0.93076694F, -0.931884289F, -0.932992816F,
    -0.934092522F, -0.935183525F, -0.936265647F, -0.937339F, -0.938403547F,
    -0.939459205F, -0.940506101F, -0.941544056F, -0.94257319F, -0.943593442F,
    -0.944604814F, -0.945607305F, -0.946600914F, -0.947585583F, -0.94856137F,
    -0.949528158F, -0.950486064F, -0.951435F, -0.952375F, -0.953306F,
    -0.954228103F, -0.955141187F, -0.95604527F, -0.956940353F, -0.957826376F,
    -0.958703458F, -0.959571481F, -0.960430503F, -0.961280465F, -0.962121427F,
    -0.962953269F, -0.963776052F, -0.964589775F, -0.965394437F, -0.96619F,
    -0.966976464F, -0.967753828F, -0.968522072F, -0.969281256F, -0.970031261F,
    -0.970772147F, -0.971503913F, -0.972226501F, -0.972939968F, -0.973644257F,
    -0.974339366F, -0.975025356F, -0.975702107F, -0.976369739F, -0.977028131F,
    -0.977677345F, -0.97831738F, -0.978948176F, -0.979569793F, -0.980182111F,
    -0.980785251F, -0.981379211F, -0.981963873F, -0.982539296F, -0.983105481F,
    -0.983662426F, -0.984210074F, -0.984748483F, -0.985277653F, -0.985797524F,
    -0.986308098F, -0.986809373F, -0.987301409F, -0.987784147F, -0.988257587F,
    -0.988721669F, -0.989176512F, -0.989622F, -0.990058184F, -0.990485072F,
    -0.990902662F, -0.991310835F, -0.991709769F, -0.992099285F, -0.992479563F,
    -0.992850423F, -0.993211925F, -0.993564129F, -0.993907F, -0.994240463F,
    -0.994564593F, -0.994879305F, -0.99518472F, -0.995480776F, -0.995767415F,
    -0.996044695F, -0.996312618F, -0.996571124F, -0.996820271F, -0.997060061F,
    -0.997290432F, -0.997511446F, -0.997723043F, -0.997925282F, -0.998118103F,
    -0.998301566F, -0.998475552F, -0.998640239F, -0.99879545F, -0.998941302F,
    -0.999077737F, -0.999204755F, -0.999322414F, -0.999430597F, -0.999529421F,
    -0.999618828F, -0.999698818F, -0.99976939F, -0.999830604F, -0.99988234F,
    -0.999924719F, -0.999957621F, -0.999981165F, -0.999995291F, -1.0F,
    -0.999995291F, -0.999981165F, -0.999957621F, -0.999924719F, -0.99988234F,
    -0.999830604F, -0.99976939F, -0.999698818F, -0.999618828F, -0.999529421F,
    -0.999430597F, -0.999322414F, -0.999204755F, -0.999077737F, -0.998941302F,
    -0.99879545F, -0.998640239F, -0.998475552F, -0.998301566F, -0.998118103F,
    -0.997925282F, -0.997723043F, -0.997511446F, -0.997290432F, -0.997060061F,
    -0.996820271F, -0.996571124F, -0.996312618F, -0.996044695F, -0.995767415F,
    -0.995480776F, -0.99518472F, -0.994879305F, -0.994564593F, -0.994240463F,
    -0.993907F, -0.993564129F, -0.993211925F, -0.992850423F, -0.992479563F,
    -0.992099285F, -0.991709769F, -0.991310835F, -0.990902662F, -0.990485072F,
    -0.990058184F, -0.989622F, -0.989176512F, -0.988721669F, -0.988257587F,
    -0.987784147F, -0.987301409F, -0.986809373F, -0.986308098F, -0.985797524F,
    -0.985277653F, -0.984748483F, -0.984210074F, -0.983662426F, -0.983105481F,
    -0.982539296F, -0.981963873F, -0.981379211F, -0.980785251F, -0.980182111F,
    -0.979569793F, -0.978948176F, -0.97831738F, -0.977677345F, -0.977028131F,
    -0.976369739F, -0.975702107F, -0.975025356F, -0.974339366F, -0.973644257F,
    -0.972939968F, -0.972226501F, -0.971503913F, -0.970772147F, -0.970031261F,
    -0.969281256F, -0.968522072F, -0.967753828F, -0.966976464F, -0.96619F,
    -0.965394437F, -0.964589775F, -0.963776052F, -0.962953269F, -0.962121427F,
    -0.961280465F, -0.960430503F, -0.959571481F, -0.958703458F, -0.957826376F,
    -0.956940353F, -0.95604527F, -0.955141187F, -0.954228103F, -0.953306F,
    -0.952375F, -0.951435F, -0.950486064F, -0.949528158F, -0.94856137F,
    -0.947585583F, -0.946600914F, -0.945607305F, -0.944604814F, -0.943593442F,
    -0.94257319F, -0.941544056F, -0.940506101F, -0.939459205F, -0.938403547F,
    -0.937339F, -0.936265647F, -0.935183525F, -0.934092522F, -0.932992816F,
    -0.931884289F, -0.93076694F, -0.929640889F, -0.928506076F, -0.927362502F,
    -0.926210225F, -0.925049245F, -0.923879504F, -0.92270112F, -0.921514034F,
    -0.920318246F, -0.919113874F, -0.917900741F, -0.916679084F, -0.915448725F,
    -0.914209723F, -0.912962198F, -0.91170603F, -0.910441279F, -0.909167945F,
    -0.907886088F, -0.906595707F, -0.905296743F, -0.903989315F, -0.902673304F,
    -0.901348829F, -0.900015891F, -0.898674488F, -0.897324562F, -0.895966232F,
    -0.894599497F, -0.893224299F, -0.891840696F, -0.890448749F, -0.889048338F,
    -0.887639642F, -0.886222541F, -0.884797096F, -0.883363307F, -0.881921232F,
    -0.880470872F, -0.879012227F, -0.877545297F, -0.876070082F, -0.874586642F,
    -0.873095F, -0.871595085F, -0.870086968F, -0.868570685F, -0.867046237F,
    -0.865513623F, -0.863972843F, -0.862423956F, -0.860866904F, -0.859301805F,
    -0.857728601F, -0.856147349F, -0.854558F, -0.852960587F, -0.851355195F,
    -0.849741757F, -0.848120332F, -0.84649092F, -0.84485358F, -0.843208253F,
    -0.841555F, -0.839893758F, -0.838224709F, -0.836547732F, -0.834862828F,
    -0.833170176F, -0.831469595F, -0.829761207F, -0.828045F, -0.826321065F,
    -0.824589252F, -0.822849751F, -0.8211025F, -0.819347501F, -0.817584813F,
    -0.815814376F, -0.81403631F, -0.812250555F, -0.81045717F, -0.808656156F,
    -0.806847572F, -0.8050313F, -0.803207517F, -0.801376164F, -0.799537241F,
    -0.797690809F, -0.795836926F, -0.793975472F, -0.792106569F, -0.790230215F,
    -0.78834641F, -0.786455214F, -0.784556627F, -0.78265059F, -0.780737221F,
    -0.778816521F, -0.77688843F, -0.774953067F, -0.773010433F, -0.771060526F,
    -0.769103348F, -0.767138898F, -0.765167236F, -0.763188422F, -0.761202335F,
    -0.759209156F, -0.757208824F, -0.755201399F, -0.753186822F, -0.751165092F,
    -0.749136388F, -0.747100592F, -0.745057762F, -0.743007958F, -0.740951121F,
    -0.73888731F, -0.736816525F, -0.734738886F, -0.732654274F, -0.730562747F,
    -0.728464365F, -0.726359129F, -0.724247098F, -0.722128153F, -0.720002472F,
    -0.71787F, -0.715730786F, -0.7135849F, -0.711432219F, -0.709272802F,
    -0.707106769F, -0.704934061F, -0.702754736F, -0.700568795F, -0.698376298F,
    -0.696177125F, -0.693971455F, -0.691759288F, -0.689540565F, -0.687315345F,
    -0.685083628F, -0.682845592F, -0.680601F, -0.678350091F, -0.676092744F,
    -0.673829F, -0.671559F, -0.669282556F, -0.666999936F, -0.664711F,
    -0.662415802F, -0.660114348F, -0.657806695F, -0.655492842F, -0.653172851F,
    -0.65084672F, -0.64851445F, -0.64617604F, -0.643831551F, -0.641481042F,
    -0.639124453F, -0.636761844F, -0.634393334F, -0.632018745F, -0.629638255F,
    -0.627251804F, -0.624859512F, -0.622461259F, -0.620057225F, -0.61764735F,
    -0.615231633F, -0.612810075F, -0.610382795F, -0.607949793F, -0.605511F,
    -0.603066623F, -0.600616515F, -0.598160744F, -0.59569931F, -0.593232274F,
    -0.590759695F, -0.588281572F, -0.585797906F, -0.583308697F, -0.580814F,
    -0.578313828F, -0.575808227F, -0.573297143F, -0.570780754F, -0.568259F,
    -0.565731823F, -0.563199341F, -0.560661614F, -0.558118522F, -0.555570245F,
    -0.553016722F, -0.550458F, -0.547894061F, -0.545325041F, -0.542750776F,
    -0.540171504F, -0.537587047F, -0.534997642F, -0.532403171F, -0.529803634F,
    -0.527199149F, -0.524589717F, -0.521975279F, -0.519356F, -0.516731799F,
    -0.514102757F, -0.511468887F, -0.50883019F, -0.506186664F, -0.50353837F,
    -0.500885367F, -0.498227656F, -0.495565295F, -0.492898226F, -0.490226507F,
    -0.487550169F, -0.484869242F, -0.482183754F, -0.479493737F, -0.47679925F,
    -0.474100202F, -0.471396744F, -0.468688846F, -0.465976506F, -0.463259816F,
    -0.460538715F, -0.457813323F, -0.455083579F, -0.452349603F, -0.449611336F,
    -0.446868837F, -0.444122165F, -0.441371292F, -0.438616246F, -0.435857117F,
    -0.433093846F, -0.430326492F, -0.427555084F, -0.424779713F, -0.422000289F,
    -0.419216901F, -0.416429579F, -0.413638324F, -0.410843194F, -0.408044159F,
    -0.40524134F, -0.402434677F, -0.399624199F, -0.39681F, -0.393992066F,
    -0.391170382F, -0.388345033F, -0.385516077F, -0.382683456F, -0.379847199F,
    -0.377007425F, -0.374164075F, -0.371317208F, -0.368466824F, -0.365613F,
    -0.362755746F, -0.359895051F, -0.357031F, -0.354163527F, -0.351292759F,
    -0.348418683F, -0.345541328F, -0.342660725F, -0.339776874F, -0.336889863F,
    -0.333999664F, -0.331106305F, -0.328209847F, -0.32531032F, -0.322407693F,
    -0.319502026F, -0.316593409F, -0.313681751F, -0.310767144F, -0.307849675F,
    -0.304929256F, -0.302005947F, -0.299079835F, -0.296150893F, -0.293219179F,
    -0.290284663F, -0.287347466F, -0.284407556F, -0.281464934F, -0.27851969F,
    -0.275571823F, -0.272621363F, -0.269668311F, -0.266712785F, -0.263754696F,
    -0.260794133F, -0.257831097F, -0.254865676F, -0.251897812F, -0.248927608F,
    -0.24595505F, -0.242980197F, -0.24000302F, -0.237023607F, -0.234041959F,
    -0.231058121F, -0.228072092F, -0.225083917F, -0.222093627F, -0.219101235F,
    -0.216106802F, -0.213110328F, -0.210111842F, -0.207111388F, -0.204108968F,
    -0.201104641F, -0.198098406F, -0.195090324F, -0.192080408F, -0.18906866F,
    -0.186055154F, -0.183039889F, -0.18002291F, -0.177004218F, -0.173983872F,
    -0.170961902F, -0.167938292F, -0.164913133F, -0.161886394F, -0.15885815F,
    -0.155828416F, -0.152797192F, -0.149764538F, -0.146730468F, -0.143695042F,
    -0.140658244F, -0.137620121F, -0.134580716F, -0.13154003F, -0.128498122F,
    -0.125454977F, -0.122410677F, -0.119365215F, -0.116318636F, -0.113270953F,
    -0.110222206F, -0.10717243F, -0.10412164F, -0.101069868F, -0.0980171412F,
    -0.0949635F, -0.0919089541F, -0.0888535529F, -0.0857973173F, -0.0827402696F,
    -0.0796824396F, -0.0766238645F, -0.0735645667F, -0.070504576F,
    -0.0674439222F, -0.0643826351F, -0.0613207407F, -0.0582582653F,
    -0.0551952459F, -0.0521317087F, -0.0490676761F, -0.0460031815F,
    -0.0429382585F, -0.0398729295F, -0.0368072242F, -0.0337411761F,
    -0.030674804F, -0.027608145F, -0.024541229F, -0.021474082F, -0.0184067301F,
    -0.0153392069F, -0.0122715384F, -0.00920375437F, -0.00613588467F,
    -0.00306795677F, -0.0F };

  static const float tmp_1[1025]{ 0.0F, 0.00306795677F, 0.00613588467F,
    0.00920375437F, 0.0122715384F, 0.0153392069F, 0.0184067301F, 0.021474082F,
    0.024541229F, 0.027608145F, 0.030674804F, 0.0337411761F, 0.0368072242F,
    0.0398729295F, 0.0429382585F, 0.0460031815F, 0.0490676761F, 0.0521317087F,
    0.0551952459F, 0.0582582653F, 0.0613207407F, 0.0643826351F, 0.0674439222F,
    0.070504576F, 0.0735645667F, 0.0766238645F, 0.0796824396F, 0.0827402696F,
    0.0857973173F, 0.0888535529F, 0.0919089541F, 0.0949635F, 0.0980171412F,
    0.101069868F, 0.10412164F, 0.10717243F, 0.110222206F, 0.113270953F,
    0.116318636F, 0.119365215F, 0.122410677F, 0.125454977F, 0.128498122F,
    0.13154003F, 0.134580716F, 0.137620121F, 0.140658244F, 0.143695042F,
    0.146730468F, 0.149764538F, 0.152797192F, 0.155828416F, 0.15885815F,
    0.161886394F, 0.164913133F, 0.167938292F, 0.170961902F, 0.173983872F,
    0.177004218F, 0.18002291F, 0.183039889F, 0.186055154F, 0.18906866F,
    0.192080408F, 0.195090324F, 0.198098406F, 0.201104641F, 0.204108968F,
    0.207111388F, 0.210111842F, 0.213110328F, 0.216106802F, 0.219101235F,
    0.222093627F, 0.225083917F, 0.228072092F, 0.231058121F, 0.234041959F,
    0.237023607F, 0.24000302F, 0.242980197F, 0.24595505F, 0.248927608F,
    0.251897812F, 0.254865676F, 0.257831097F, 0.260794133F, 0.263754696F,
    0.266712785F, 0.269668311F, 0.272621363F, 0.275571823F, 0.27851969F,
    0.281464934F, 0.284407556F, 0.287347466F, 0.290284663F, 0.293219179F,
    0.296150893F, 0.299079835F, 0.302005947F, 0.304929256F, 0.307849675F,
    0.310767144F, 0.313681751F, 0.316593409F, 0.319502026F, 0.322407693F,
    0.32531032F, 0.328209847F, 0.331106305F, 0.333999664F, 0.336889863F,
    0.339776874F, 0.342660725F, 0.345541328F, 0.348418683F, 0.351292759F,
    0.354163527F, 0.357031F, 0.359895051F, 0.362755746F, 0.365613F, 0.368466824F,
    0.371317208F, 0.374164075F, 0.377007425F, 0.379847199F, 0.382683456F,
    0.385516077F, 0.388345033F, 0.391170382F, 0.393992066F, 0.39681F,
    0.399624199F, 0.402434677F, 0.40524134F, 0.408044159F, 0.410843194F,
    0.413638324F, 0.416429579F, 0.419216901F, 0.422000289F, 0.424779713F,
    0.427555084F, 0.430326492F, 0.433093846F, 0.435857117F, 0.438616246F,
    0.441371292F, 0.444122165F, 0.446868837F, 0.449611336F, 0.452349603F,
    0.455083579F, 0.457813323F, 0.460538715F, 0.463259816F, 0.465976506F,
    0.468688846F, 0.471396744F, 0.474100202F, 0.47679925F, 0.479493737F,
    0.482183754F, 0.484869242F, 0.487550169F, 0.490226507F, 0.492898226F,
    0.495565295F, 0.498227656F, 0.500885367F, 0.50353837F, 0.506186664F,
    0.50883019F, 0.511468887F, 0.514102757F, 0.516731799F, 0.519356F,
    0.521975279F, 0.524589717F, 0.527199149F, 0.529803634F, 0.532403171F,
    0.534997642F, 0.537587047F, 0.540171504F, 0.542750776F, 0.545325041F,
    0.547894061F, 0.550458F, 0.553016722F, 0.555570245F, 0.558118522F,
    0.560661614F, 0.563199341F, 0.565731823F, 0.568259F, 0.570780754F,
    0.573297143F, 0.575808227F, 0.578313828F, 0.580814F, 0.583308697F,
    0.585797906F, 0.588281572F, 0.590759695F, 0.593232274F, 0.59569931F,
    0.598160744F, 0.600616515F, 0.603066623F, 0.605511F, 0.607949793F,
    0.610382795F, 0.612810075F, 0.615231633F, 0.61764735F, 0.620057225F,
    0.622461259F, 0.624859512F, 0.627251804F, 0.629638255F, 0.632018745F,
    0.634393334F, 0.636761844F, 0.639124453F, 0.641481042F, 0.643831551F,
    0.64617604F, 0.64851445F, 0.65084672F, 0.653172851F, 0.655492842F,
    0.657806695F, 0.660114348F, 0.662415802F, 0.664711F, 0.666999936F,
    0.669282556F, 0.671559F, 0.673829F, 0.676092744F, 0.678350091F, 0.680601F,
    0.682845592F, 0.685083628F, 0.687315345F, 0.689540565F, 0.691759288F,
    0.693971455F, 0.696177125F, 0.698376298F, 0.700568795F, 0.702754736F,
    0.704934061F, 0.707106769F, 0.709272802F, 0.711432219F, 0.7135849F,
    0.715730786F, 0.71787F, 0.720002472F, 0.722128153F, 0.724247098F,
    0.726359129F, 0.728464365F, 0.730562747F, 0.732654274F, 0.734738886F,
    0.736816525F, 0.73888731F, 0.740951121F, 0.743007958F, 0.745057762F,
    0.747100592F, 0.749136388F, 0.751165092F, 0.753186822F, 0.755201399F,
    0.757208824F, 0.759209156F, 0.761202335F, 0.763188422F, 0.765167236F,
    0.767138898F, 0.769103348F, 0.771060526F, 0.773010433F, 0.774953067F,
    0.77688843F, 0.778816521F, 0.780737221F, 0.78265059F, 0.784556627F,
    0.786455214F, 0.78834641F, 0.790230215F, 0.792106569F, 0.793975472F,
    0.795836926F, 0.797690809F, 0.799537241F, 0.801376164F, 0.803207517F,
    0.8050313F, 0.806847572F, 0.808656156F, 0.81045717F, 0.812250555F,
    0.81403631F, 0.815814376F, 0.817584813F, 0.819347501F, 0.8211025F,
    0.822849751F, 0.824589252F, 0.826321065F, 0.828045F, 0.829761207F,
    0.831469595F, 0.833170176F, 0.834862828F, 0.836547732F, 0.838224709F,
    0.839893758F, 0.841555F, 0.843208253F, 0.84485358F, 0.84649092F,
    0.848120332F, 0.849741757F, 0.851355195F, 0.852960587F, 0.854558F,
    0.856147349F, 0.857728601F, 0.859301805F, 0.860866904F, 0.862423956F,
    0.863972843F, 0.865513623F, 0.867046237F, 0.868570685F, 0.870086968F,
    0.871595085F, 0.873095F, 0.874586642F, 0.876070082F, 0.877545297F,
    0.879012227F, 0.880470872F, 0.881921232F, 0.883363307F, 0.884797096F,
    0.886222541F, 0.887639642F, 0.889048338F, 0.890448749F, 0.891840696F,
    0.893224299F, 0.894599497F, 0.895966232F, 0.897324562F, 0.898674488F,
    0.900015891F, 0.901348829F, 0.902673304F, 0.903989315F, 0.905296743F,
    0.906595707F, 0.907886088F, 0.909167945F, 0.910441279F, 0.91170603F,
    0.912962198F, 0.914209723F, 0.915448725F, 0.916679084F, 0.917900741F,
    0.919113874F, 0.920318246F, 0.921514034F, 0.92270112F, 0.923879504F,
    0.925049245F, 0.926210225F, 0.927362502F, 0.928506076F, 0.929640889F,
    0.93076694F, 0.931884289F, 0.932992816F, 0.934092522F, 0.935183525F,
    0.936265647F, 0.937339F, 0.938403547F, 0.939459205F, 0.940506101F,
    0.941544056F, 0.94257319F, 0.943593442F, 0.944604814F, 0.945607305F,
    0.946600914F, 0.947585583F, 0.94856137F, 0.949528158F, 0.950486064F,
    0.951435F, 0.952375F, 0.953306F, 0.954228103F, 0.955141187F, 0.95604527F,
    0.956940353F, 0.957826376F, 0.958703458F, 0.959571481F, 0.960430503F,
    0.961280465F, 0.962121427F, 0.962953269F, 0.963776052F, 0.964589775F,
    0.965394437F, 0.96619F, 0.966976464F, 0.967753828F, 0.968522072F,
    0.969281256F, 0.970031261F, 0.970772147F, 0.971503913F, 0.972226501F,
    0.972939968F, 0.973644257F, 0.974339366F, 0.975025356F, 0.975702107F,
    0.976369739F, 0.977028131F, 0.977677345F, 0.97831738F, 0.978948176F,
    0.979569793F, 0.980182111F, 0.980785251F, 0.981379211F, 0.981963873F,
    0.982539296F, 0.983105481F, 0.983662426F, 0.984210074F, 0.984748483F,
    0.985277653F, 0.985797524F, 0.986308098F, 0.986809373F, 0.987301409F,
    0.987784147F, 0.988257587F, 0.988721669F, 0.989176512F, 0.989622F,
    0.990058184F, 0.990485072F, 0.990902662F, 0.991310835F, 0.991709769F,
    0.992099285F, 0.992479563F, 0.992850423F, 0.993211925F, 0.993564129F,
    0.993907F, 0.994240463F, 0.994564593F, 0.994879305F, 0.99518472F,
    0.995480776F, 0.995767415F, 0.996044695F, 0.996312618F, 0.996571124F,
    0.996820271F, 0.997060061F, 0.997290432F, 0.997511446F, 0.997723043F,
    0.997925282F, 0.998118103F, 0.998301566F, 0.998475552F, 0.998640239F,
    0.99879545F, 0.998941302F, 0.999077737F, 0.999204755F, 0.999322414F,
    0.999430597F, 0.999529421F, 0.999618828F, 0.999698818F, 0.99976939F,
    0.999830604F, 0.99988234F, 0.999924719F, 0.999957621F, 0.999981165F,
    0.999995291F, 1.0F, 0.999995291F, 0.999981165F, 0.999957621F, 0.999924719F,
    0.99988234F, 0.999830604F, 0.99976939F, 0.999698818F, 0.999618828F,
    0.999529421F, 0.999430597F, 0.999322414F, 0.999204755F, 0.999077737F,
    0.998941302F, 0.99879545F, 0.998640239F, 0.998475552F, 0.998301566F,
    0.998118103F, 0.997925282F, 0.997723043F, 0.997511446F, 0.997290432F,
    0.997060061F, 0.996820271F, 0.996571124F, 0.996312618F, 0.996044695F,
    0.995767415F, 0.995480776F, 0.99518472F, 0.994879305F, 0.994564593F,
    0.994240463F, 0.993907F, 0.993564129F, 0.993211925F, 0.992850423F,
    0.992479563F, 0.992099285F, 0.991709769F, 0.991310835F, 0.990902662F,
    0.990485072F, 0.990058184F, 0.989622F, 0.989176512F, 0.988721669F,
    0.988257587F, 0.987784147F, 0.987301409F, 0.986809373F, 0.986308098F,
    0.985797524F, 0.985277653F, 0.984748483F, 0.984210074F, 0.983662426F,
    0.983105481F, 0.982539296F, 0.981963873F, 0.981379211F, 0.980785251F,
    0.980182111F, 0.979569793F, 0.978948176F, 0.97831738F, 0.977677345F,
    0.977028131F, 0.976369739F, 0.975702107F, 0.975025356F, 0.974339366F,
    0.973644257F, 0.972939968F, 0.972226501F, 0.971503913F, 0.970772147F,
    0.970031261F, 0.969281256F, 0.968522072F, 0.967753828F, 0.966976464F,
    0.96619F, 0.965394437F, 0.964589775F, 0.963776052F, 0.962953269F,
    0.962121427F, 0.961280465F, 0.960430503F, 0.959571481F, 0.958703458F,
    0.957826376F, 0.956940353F, 0.95604527F, 0.955141187F, 0.954228103F,
    0.953306F, 0.952375F, 0.951435F, 0.950486064F, 0.949528158F, 0.94856137F,
    0.947585583F, 0.946600914F, 0.945607305F, 0.944604814F, 0.943593442F,
    0.94257319F, 0.941544056F, 0.940506101F, 0.939459205F, 0.938403547F,
    0.937339F, 0.936265647F, 0.935183525F, 0.934092522F, 0.932992816F,
    0.931884289F, 0.93076694F, 0.929640889F, 0.928506076F, 0.927362502F,
    0.926210225F, 0.925049245F, 0.923879504F, 0.92270112F, 0.921514034F,
    0.920318246F, 0.919113874F, 0.917900741F, 0.916679084F, 0.915448725F,
    0.914209723F, 0.912962198F, 0.91170603F, 0.910441279F, 0.909167945F,
    0.907886088F, 0.906595707F, 0.905296743F, 0.903989315F, 0.902673304F,
    0.901348829F, 0.900015891F, 0.898674488F, 0.897324562F, 0.895966232F,
    0.894599497F, 0.893224299F, 0.891840696F, 0.890448749F, 0.889048338F,
    0.887639642F, 0.886222541F, 0.884797096F, 0.883363307F, 0.881921232F,
    0.880470872F, 0.879012227F, 0.877545297F, 0.876070082F, 0.874586642F,
    0.873095F, 0.871595085F, 0.870086968F, 0.868570685F, 0.867046237F,
    0.865513623F, 0.863972843F, 0.862423956F, 0.860866904F, 0.859301805F,
    0.857728601F, 0.856147349F, 0.854558F, 0.852960587F, 0.851355195F,
    0.849741757F, 0.848120332F, 0.84649092F, 0.84485358F, 0.843208253F,
    0.841555F, 0.839893758F, 0.838224709F, 0.836547732F, 0.834862828F,
    0.833170176F, 0.831469595F, 0.829761207F, 0.828045F, 0.826321065F,
    0.824589252F, 0.822849751F, 0.8211025F, 0.819347501F, 0.817584813F,
    0.815814376F, 0.81403631F, 0.812250555F, 0.81045717F, 0.808656156F,
    0.806847572F, 0.8050313F, 0.803207517F, 0.801376164F, 0.799537241F,
    0.797690809F, 0.795836926F, 0.793975472F, 0.792106569F, 0.790230215F,
    0.78834641F, 0.786455214F, 0.784556627F, 0.78265059F, 0.780737221F,
    0.778816521F, 0.77688843F, 0.774953067F, 0.773010433F, 0.771060526F,
    0.769103348F, 0.767138898F, 0.765167236F, 0.763188422F, 0.761202335F,
    0.759209156F, 0.757208824F, 0.755201399F, 0.753186822F, 0.751165092F,
    0.749136388F, 0.747100592F, 0.745057762F, 0.743007958F, 0.740951121F,
    0.73888731F, 0.736816525F, 0.734738886F, 0.732654274F, 0.730562747F,
    0.728464365F, 0.726359129F, 0.724247098F, 0.722128153F, 0.720002472F,
    0.71787F, 0.715730786F, 0.7135849F, 0.711432219F, 0.709272802F, 0.707106769F,
    0.704934061F, 0.702754736F, 0.700568795F, 0.698376298F, 0.696177125F,
    0.693971455F, 0.691759288F, 0.689540565F, 0.687315345F, 0.685083628F,
    0.682845592F, 0.680601F, 0.678350091F, 0.676092744F, 0.673829F, 0.671559F,
    0.669282556F, 0.666999936F, 0.664711F, 0.662415802F, 0.660114348F,
    0.657806695F, 0.655492842F, 0.653172851F, 0.65084672F, 0.64851445F,
    0.64617604F, 0.643831551F, 0.641481042F, 0.639124453F, 0.636761844F,
    0.634393334F, 0.632018745F, 0.629638255F, 0.627251804F, 0.624859512F,
    0.622461259F, 0.620057225F, 0.61764735F, 0.615231633F, 0.612810075F,
    0.610382795F, 0.607949793F, 0.605511F, 0.603066623F, 0.600616515F,
    0.598160744F, 0.59569931F, 0.593232274F, 0.590759695F, 0.588281572F,
    0.585797906F, 0.583308697F, 0.580814F, 0.578313828F, 0.575808227F,
    0.573297143F, 0.570780754F, 0.568259F, 0.565731823F, 0.563199341F,
    0.560661614F, 0.558118522F, 0.555570245F, 0.553016722F, 0.550458F,
    0.547894061F, 0.545325041F, 0.542750776F, 0.540171504F, 0.537587047F,
    0.534997642F, 0.532403171F, 0.529803634F, 0.527199149F, 0.524589717F,
    0.521975279F, 0.519356F, 0.516731799F, 0.514102757F, 0.511468887F,
    0.50883019F, 0.506186664F, 0.50353837F, 0.500885367F, 0.498227656F,
    0.495565295F, 0.492898226F, 0.490226507F, 0.487550169F, 0.484869242F,
    0.482183754F, 0.479493737F, 0.47679925F, 0.474100202F, 0.471396744F,
    0.468688846F, 0.465976506F, 0.463259816F, 0.460538715F, 0.457813323F,
    0.455083579F, 0.452349603F, 0.449611336F, 0.446868837F, 0.444122165F,
    0.441371292F, 0.438616246F, 0.435857117F, 0.433093846F, 0.430326492F,
    0.427555084F, 0.424779713F, 0.422000289F, 0.419216901F, 0.416429579F,
    0.413638324F, 0.410843194F, 0.408044159F, 0.40524134F, 0.402434677F,
    0.399624199F, 0.39681F, 0.393992066F, 0.391170382F, 0.388345033F,
    0.385516077F, 0.382683456F, 0.379847199F, 0.377007425F, 0.374164075F,
    0.371317208F, 0.368466824F, 0.365613F, 0.362755746F, 0.359895051F, 0.357031F,
    0.354163527F, 0.351292759F, 0.348418683F, 0.345541328F, 0.342660725F,
    0.339776874F, 0.336889863F, 0.333999664F, 0.331106305F, 0.328209847F,
    0.32531032F, 0.322407693F, 0.319502026F, 0.316593409F, 0.313681751F,
    0.310767144F, 0.307849675F, 0.304929256F, 0.302005947F, 0.299079835F,
    0.296150893F, 0.293219179F, 0.290284663F, 0.287347466F, 0.284407556F,
    0.281464934F, 0.27851969F, 0.275571823F, 0.272621363F, 0.269668311F,
    0.266712785F, 0.263754696F, 0.260794133F, 0.257831097F, 0.254865676F,
    0.251897812F, 0.248927608F, 0.24595505F, 0.242980197F, 0.24000302F,
    0.237023607F, 0.234041959F, 0.231058121F, 0.228072092F, 0.225083917F,
    0.222093627F, 0.219101235F, 0.216106802F, 0.213110328F, 0.210111842F,
    0.207111388F, 0.204108968F, 0.201104641F, 0.198098406F, 0.195090324F,
    0.192080408F, 0.18906866F, 0.186055154F, 0.183039889F, 0.18002291F,
    0.177004218F, 0.173983872F, 0.170961902F, 0.167938292F, 0.164913133F,
    0.161886394F, 0.15885815F, 0.155828416F, 0.152797192F, 0.149764538F,
    0.146730468F, 0.143695042F, 0.140658244F, 0.137620121F, 0.134580716F,
    0.13154003F, 0.128498122F, 0.125454977F, 0.122410677F, 0.119365215F,
    0.116318636F, 0.113270953F, 0.110222206F, 0.10717243F, 0.10412164F,
    0.101069868F, 0.0980171412F, 0.0949635F, 0.0919089541F, 0.0888535529F,
    0.0857973173F, 0.0827402696F, 0.0796824396F, 0.0766238645F, 0.0735645667F,
    0.070504576F, 0.0674439222F, 0.0643826351F, 0.0613207407F, 0.0582582653F,
    0.0551952459F, 0.0521317087F, 0.0490676761F, 0.0460031815F, 0.0429382585F,
    0.0398729295F, 0.0368072242F, 0.0337411761F, 0.030674804F, 0.027608145F,
    0.024541229F, 0.021474082F, 0.0184067301F, 0.0153392069F, 0.0122715384F,
    0.00920375437F, 0.00613588467F, 0.00306795677F, 0.0F };

  cell_wrap varSizes;
  emxArray_float *c_out;
  h_dsp_internal_AsyncBuffercgHel *obj_0;
  creal32_T b_x[479];
  float x[960];
  const float *costab;
  const float *sintab;
  const float *sintabinv;
  float twid_im;
  float twid_re;
  float wwc_im;
  float xtmp_im;
  float xtmp_re;
  int32_t i;
  int32_t iDelta2;
  int32_t iheight;
  int32_t ihi;
  int32_t istart;
  int32_t iy;
  int32_t j;
  int32_t rt;
  int32_t xtmp_re_tmp_tmp;
  int16_t inSize[8];
  bool exitg1;
  bool tst;

  //  Implement algorithm. Calculate y as a function of input u and
  //  discrete states.
  for (i = 0; i < 479; i++) {
    b_x[i].re = X_0[i + 1].re;
    b_x[i].im = -X_0[i + 1].im;
  }

  for (i = 0; i < 239; i++) {
    xtmp_re = b_x[i].re;
    xtmp_im = b_x[i].im;
    b_x[i] = b_x[478 - i];
    b_x[478 - i].re = xtmp_re;
    b_x[478 - i].im = xtmp_im;
  }

  std::memcpy(&rtDW.b_X[0], &X_0[0], 480U * sizeof(creal32_T));
  rtDW.b_X[480] = X_0[0];
  std::memcpy(&rtDW.b_X[481], &b_x[0], 479U * sizeof(creal32_T));
  rtDW.b_X[0].im = 0.0F;
  rtDW.b_X[480].re = rtDW.b_X[480].im;
  rtDW.b_X[480].im = 0.0F;
  costab = &tmp[0];
  sintab = &tmp_0[0];
  sintabinv = &tmp_1[0];
  rt = 0;
  rtDW.wwc[959].re = 1.0F;
  rtDW.wwc[959].im = 0.0F;
  for (i = 0; i < 959; i++) {
    iy = ((i + 1) << 1) - 1;
    if (1920 - rt <= iy) {
      rt = (iy + rt) - 1920;
    } else {
      rt += iy;
    }

    xtmp_im = 3.14159274F * static_cast<float>(rt) / 960.0F;
    rtDW.wwc[958 - i].re = std::cos(xtmp_im);
    rtDW.wwc[958 - i].im = -std::sin(xtmp_im);
  }

  for (i = 958; i >= 0; i--) {
    rtDW.wwc[i + 960] = rtDW.wwc[958 - i];
  }

  for (i = 0; i < 960; i++) {
    xtmp_re = rtDW.b_X[i].re;
    twid_re = rtDW.b_X[i].im;
    twid_im = rtDW.wwc[i + 959].re;
    xtmp_im = rtDW.wwc[i + 959].im;
    rtDW.y[i].re = twid_im * xtmp_re + xtmp_im * twid_re;
    rtDW.y[i].im = twid_im * twid_re - xtmp_im * xtmp_re;
  }

  std::memset(&rtDW.fy[0], 0, sizeof(creal32_T) << 11U);
  iy = 0;
  rt = 0;
  for (i = 0; i < 959; i++) {
    rtDW.fy[iy] = rtDW.y[i];
    iy = 2048;
    tst = true;
    while (tst) {
      iy >>= 1;
      rt ^= iy;
      tst = ((rt & iy) == 0);
    }

    iy = rt;
  }

  rtDW.fy[iy] = rtDW.y[959];
  for (i = 0; i <= 2046; i += 2) {
    xtmp_re = rtDW.fy[i + 1].re;
    twid_re = rtDW.fy[i + 1].im;
    twid_im = rtDW.fy[i].re;
    xtmp_im = rtDW.fy[i].im;
    rtDW.fy[i + 1].re = twid_im - xtmp_re;
    rtDW.fy[i + 1].im = xtmp_im - twid_re;
    rtDW.fy[i].re = twid_im + xtmp_re;
    rtDW.fy[i].im = xtmp_im + twid_re;
  }

  iy = 2;
  iDelta2 = 4;
  rt = 512;
  iheight = 2045;
  while (rt > 0) {
    for (i = 0; i < iheight; i += iDelta2) {
      istart = i + iy;
      xtmp_re = rtDW.fy[istart].re;
      xtmp_im = rtDW.fy[istart].im;
      rtDW.fy[istart].re = rtDW.fy[i].re - xtmp_re;
      rtDW.fy[istart].im = rtDW.fy[i].im - xtmp_im;
      rtDW.fy[i].re += xtmp_re;
      rtDW.fy[i].im += xtmp_im;
    }

    istart = 1;
    for (j = rt; j < 1024; j += rt) {
      twid_re = costab[j];
      twid_im = sintab[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        xtmp_re_tmp_tmp = i + iy;
        xtmp_im = rtDW.fy[xtmp_re_tmp_tmp].im;
        wwc_im = rtDW.fy[xtmp_re_tmp_tmp].re;
        xtmp_re = wwc_im * twid_re - xtmp_im * twid_im;
        xtmp_im = xtmp_im * twid_re + wwc_im * twid_im;
        rtDW.fy[xtmp_re_tmp_tmp].re = rtDW.fy[i].re - xtmp_re;
        rtDW.fy[xtmp_re_tmp_tmp].im = rtDW.fy[i].im - xtmp_im;
        rtDW.fy[i].re += xtmp_re;
        rtDW.fy[i].im += xtmp_im;
        i += iDelta2;
      }

      istart++;
    }

    rt = static_cast<int32_t>(static_cast<uint32_t>(rt) >> 1);
    iy = iDelta2;
    iDelta2 += iDelta2;
    iheight -= iy;
  }

  std::memset(&rtDW.fv[0], 0, sizeof(creal32_T) << 11U);
  iy = 0;
  rt = 0;
  for (i = 0; i < 1918; i++) {
    rtDW.fv[iy] = rtDW.wwc[i];
    iy = 2048;
    tst = true;
    while (tst) {
      iy >>= 1;
      rt ^= iy;
      tst = ((rt & iy) == 0);
    }

    iy = rt;
  }

  rtDW.fv[iy] = rtDW.wwc[1918];
  for (i = 0; i <= 2046; i += 2) {
    xtmp_re = rtDW.fv[i + 1].re;
    twid_re = rtDW.fv[i + 1].im;
    twid_im = rtDW.fv[i].re;
    xtmp_im = rtDW.fv[i].im;
    rtDW.fv[i + 1].re = twid_im - xtmp_re;
    rtDW.fv[i + 1].im = xtmp_im - twid_re;
    rtDW.fv[i].re = twid_im + xtmp_re;
    rtDW.fv[i].im = xtmp_im + twid_re;
  }

  iy = 2;
  iDelta2 = 4;
  rt = 512;
  iheight = 2045;
  while (rt > 0) {
    for (i = 0; i < iheight; i += iDelta2) {
      istart = i + iy;
      xtmp_re = rtDW.fv[istart].re;
      xtmp_im = rtDW.fv[istart].im;
      rtDW.fv[istart].re = rtDW.fv[i].re - xtmp_re;
      rtDW.fv[istart].im = rtDW.fv[i].im - xtmp_im;
      rtDW.fv[i].re += xtmp_re;
      rtDW.fv[i].im += xtmp_im;
    }

    istart = 1;
    for (j = rt; j < 1024; j += rt) {
      twid_re = costab[j];
      twid_im = sintab[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        xtmp_re_tmp_tmp = i + iy;
        xtmp_im = rtDW.fv[xtmp_re_tmp_tmp].im;
        wwc_im = rtDW.fv[xtmp_re_tmp_tmp].re;
        xtmp_re = wwc_im * twid_re - xtmp_im * twid_im;
        xtmp_im = xtmp_im * twid_re + wwc_im * twid_im;
        rtDW.fv[xtmp_re_tmp_tmp].re = rtDW.fv[i].re - xtmp_re;
        rtDW.fv[xtmp_re_tmp_tmp].im = rtDW.fv[i].im - xtmp_im;
        rtDW.fv[i].re += xtmp_re;
        rtDW.fv[i].im += xtmp_im;
        i += iDelta2;
      }

      istart++;
    }

    rt = static_cast<int32_t>(static_cast<uint32_t>(rt) >> 1);
    iy = iDelta2;
    iDelta2 += iDelta2;
    iheight -= iy;
  }

  for (i = 0; i < 2048; i++) {
    xtmp_re = rtDW.fy[i].re;
    twid_re = rtDW.fy[i].im;
    twid_im = rtDW.fv[i].im;
    xtmp_im = rtDW.fv[i].re;
    rtDW.fy[i].re = xtmp_re * xtmp_im - twid_re * twid_im;
    rtDW.fy[i].im = xtmp_re * twid_im + twid_re * xtmp_im;
  }

  iy = 0;
  rt = 0;
  for (i = 0; i < 2047; i++) {
    rtDW.fv[iy] = rtDW.fy[i];
    iy = 2048;
    tst = true;
    while (tst) {
      iy >>= 1;
      rt ^= iy;
      tst = ((rt & iy) == 0);
    }

    iy = rt;
  }

  rtDW.fv[iy] = rtDW.fy[2047];
  for (i = 0; i <= 2046; i += 2) {
    xtmp_re = rtDW.fv[i + 1].re;
    twid_re = rtDW.fv[i + 1].im;
    twid_im = rtDW.fv[i].re;
    xtmp_im = rtDW.fv[i].im;
    rtDW.fv[i + 1].re = twid_im - xtmp_re;
    rtDW.fv[i + 1].im = xtmp_im - twid_re;
    rtDW.fv[i].re = twid_im + xtmp_re;
    rtDW.fv[i].im = xtmp_im + twid_re;
  }

  iy = 2;
  iDelta2 = 4;
  rt = 512;
  iheight = 2045;
  while (rt > 0) {
    for (i = 0; i < iheight; i += iDelta2) {
      istart = i + iy;
      xtmp_re = rtDW.fv[istart].re;
      xtmp_im = rtDW.fv[istart].im;
      rtDW.fv[istart].re = rtDW.fv[i].re - xtmp_re;
      rtDW.fv[istart].im = rtDW.fv[i].im - xtmp_im;
      rtDW.fv[i].re += xtmp_re;
      rtDW.fv[i].im += xtmp_im;
    }

    istart = 1;
    for (j = rt; j < 1024; j += rt) {
      twid_re = costab[j];
      twid_im = sintabinv[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        xtmp_re_tmp_tmp = i + iy;
        xtmp_im = rtDW.fv[xtmp_re_tmp_tmp].im;
        wwc_im = rtDW.fv[xtmp_re_tmp_tmp].re;
        xtmp_re = wwc_im * twid_re - xtmp_im * twid_im;
        xtmp_im = xtmp_im * twid_re + wwc_im * twid_im;
        rtDW.fv[xtmp_re_tmp_tmp].re = rtDW.fv[i].re - xtmp_re;
        rtDW.fv[xtmp_re_tmp_tmp].im = rtDW.fv[i].im - xtmp_im;
        rtDW.fv[i].re += xtmp_re;
        rtDW.fv[i].im += xtmp_im;
        i += iDelta2;
      }

      istart++;
    }

    rt = static_cast<int32_t>(static_cast<uint32_t>(rt) >> 1);
    iy = iDelta2;
    iDelta2 += iDelta2;
    iheight -= iy;
  }

  for (i = 0; i < 2048; i++) {
    rtDW.fv[i].re *= 0.00048828125F;
    rtDW.fv[i].im *= 0.00048828125F;
  }

  for (rt = 0; rt < 960; rt++) {
    xtmp_im = rtDW.wwc[rt + 959].re;
    wwc_im = rtDW.wwc[rt + 959].im;
    xtmp_re = rtDW.fv[rt + 959].re;
    twid_re = rtDW.fv[rt + 959].im;
    twid_im = xtmp_im * xtmp_re + wwc_im * twid_re;
    xtmp_re = xtmp_im * twid_re - wwc_im * xtmp_re;
    if (xtmp_re == 0.0F) {
      rtDW.y[rt].re = twid_im / 960.0F;
      rtDW.y[rt].im = 0.0F;
    } else if (twid_im == 0.0F) {
      rtDW.y[rt].re = 0.0F;
      rtDW.y[rt].im = xtmp_re / 960.0F;
    } else {
      rtDW.y[rt].re = twid_im / 960.0F;
      rtDW.y[rt].im = xtmp_re / 960.0F;
    }
  }

  //  Needed to catch rounding errors
  for (i = 0; i < 960; i++) {
    x[i] = static_cast<float>(obj->hs[i]) * rtDW.y[i].re;
  }

  i = obj->buff.pBuffer.WritePointer;
  emxInit_float_j(&c_out, 1);
  AsyncBuffercgHelper_ReadSampl_j(&obj->buff.pBuffer, c_out, &rt, &iy);
  iDelta2 = obj->buff.pBuffer.CumulativeUnderrun;
  if ((iDelta2 < 0) && (rt < INT32_MIN - iDelta2)) {
    obj->buff.pBuffer.CumulativeUnderrun = INT32_MIN;
  } else if ((iDelta2 > 0) && (rt > INT32_MAX - iDelta2)) {
    obj->buff.pBuffer.CumulativeUnderrun = INT32_MAX;
  } else {
    obj->buff.pBuffer.CumulativeUnderrun = iDelta2 + rt;
  }

  if (rt != 0) {
    if (i < -2147483647) {
      obj->buff.pBuffer.ReadPointer = INT32_MIN;
    } else {
      obj->buff.pBuffer.ReadPointer = i - 1;
    }
  } else {
    obj->buff.pBuffer.ReadPointer = iy;
  }

  rt = c_out->size[0];
  for (i = 0; i < rt; i++) {
    u[i] = c_out->data[i] + x[i];
  }

  emxFree_float_j(&c_out);
  obj_0 = &obj->buff.pBuffer;
  if (obj->buff.pBuffer.isInitialized != 1) {
    obj->buff.pBuffer.isSetupComplete = false;
    obj->buff.pBuffer.isInitialized = 1;
    varSizes.f1[0] = 480U;
    varSizes.f1[1] = 1U;
    for (i = 0; i < 6; i++) {
      varSizes.f1[i + 2] = 1U;
    }

    obj->buff.pBuffer.inputVarSize = varSizes;
    obj->buff.pBuffer.NumChannels = 1;
    obj->buff.pBuffer.AsyncBuffercgHelper_isInitialized = true;
    for (i = 0; i < 192001; i++) {
      obj->buff.pBuffer.Cache[i] = 0.0F;
    }

    obj->buff.pBuffer.isSetupComplete = true;
    obj->buff.pBuffer.ReadPointer = 1;
    obj->buff.pBuffer.WritePointer = 2;
    obj->buff.pBuffer.CumulativeOverrun = 0;
    obj->buff.pBuffer.CumulativeUnderrun = 0;
    for (i = 0; i < 192001; i++) {
      obj->buff.pBuffer.Cache[i] = 0.0F;
    }
  }

  inSize[0] = 480;
  inSize[1] = 1;
  for (i = 0; i < 6; i++) {
    inSize[i + 2] = 1;
  }

  i = 0;
  exitg1 = false;
  while ((!exitg1) && (i < 8)) {
    if (obj_0->inputVarSize.f1[i] != static_cast<uint32_t>(inSize[i])) {
      for (i = 0; i < 8; i++) {
        obj_0->inputVarSize.f1[i] = static_cast<uint32_t>(inSize[i]);
      }

      exitg1 = true;
    } else {
      i++;
    }
  }

  AsyncBuffercgHelper_write_j(&obj->buff.pBuffer, &x[480]);
}

void SmartMicDrvTsk_Ccode::binary_expand_op_j3xz2e4k(creal32_T in1[80], const
  LinearAECSystem *in2, int32_t in3)
{
  int32_t stride_0_0;
  int32_t stride_1_0;

  // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
  // MATLABSystem: '<S3>/MATLAB System6' incorporates:
  //   MATLABSystem: '<S3>/MATLAB System5'

  stride_0_0 = (in2->H.G->size[0] != 1);
  stride_1_0 = (in2->H.b->size[0] != 1);
  for (int32_t i{0}; i < 80; i++) {
    float tmp;
    float tmp_0;
    float tmp_1;
    float tmp_2;
    int32_t tmp_3;
    tmp = in2->H.G->data[i * stride_0_0 + in2->H.G->size[0] * in3].re;
    tmp_3 = i * stride_1_0;
    tmp_0 = in2->H.b->data[in2->H.b->size[0] * in3 + tmp_3].im;
    tmp_1 = in2->H.G->data[i * stride_0_0 + in2->H.G->size[0] * in3].im;
    tmp_2 = in2->H.b->data[in2->H.b->size[0] * in3 + tmp_3].re;
    in1[i].re -= tmp * tmp_2 - tmp_1 * tmp_0;
    in1[i].im -= tmp * tmp_0 + tmp_1 * tmp_2;
  }

  // End of MATLABSystem: '<S3>/MATLAB System6'
  // End of Outputs for SubSystem: '<Root>/LinearBandH'
}

void SmartMicDrvTsk_Ccode::binary_expand_op_j3xz2e4(LinearAECSystem *in1,
  int32_t in2, const creal32_T in3[80])
{
  emxArray_creal32_T *in1_1;
  float in3_0;
  float in3_1;
  float re;
  float re_tmp;
  int32_t i;
  int32_t in1_0;
  int32_t re_tmp_0;
  int32_t stride_0_0;
  int32_t stride_1_0;
  int32_t stride_2_0;

  // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
  // MATLABSystem: '<S3>/MATLAB System6' incorporates:
  //   MATLABSystem: '<S3>/MATLAB System5'

  in1_0 = in1->H.G->size[0];

  // End of Outputs for SubSystem: '<Root>/LinearBandH'
  emxInit_creal32_T(&in1_1, 1);

  // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
  // MATLABSystem: '<S3>/MATLAB System6' incorporates:
  //   MATLABSystem: '<S3>/MATLAB System5'

  i = in1_1->size[0];
  in1_1->size[0] = in1->H.G->size[0];
  emxEnsureCapacity_creal32_T(in1_1, i);
  stride_0_0 = (in1->H.G->size[0] != 1);
  stride_1_0 = (in1->H.mu->size[0] != 1);
  stride_2_0 = (in1->H.b->size[0] != 1);
  for (i = 0; i < in1_0; i++) {
    re_tmp = in1->H.mu->data[i * stride_1_0 + in1->H.mu->size[0] * in2] * 2.0F;
    re_tmp_0 = i * stride_2_0;
    re = in1->H.b->data[in1->H.b->size[0] * in2 + re_tmp_0].re * re_tmp;
    re_tmp *= -in1->H.b->data[in1->H.b->size[0] * in2 + re_tmp_0].im;
    in3_0 = in3[i].re;
    in3_1 = in3[i].im;
    re_tmp_0 = i * stride_0_0;
    in1_1->data[i].re = (re * in3_0 - re_tmp * in3_1) + in1->H.G->data[in1->
      H.G->size[0] * in2 + re_tmp_0].re;
    in1_1->data[i].im = (re * in3_1 + re_tmp * in3_0) + in1->H.G->data[in1->
      H.G->size[0] * in2 + re_tmp_0].im;
  }

  in1_0 = in1_1->size[0];
  for (i = 0; i < in1_0; i++) {
    in1->H.G->data[i + in1->H.G->size[0] * in2] = in1_1->data[i];
  }

  // End of Outputs for SubSystem: '<Root>/LinearBandH'
  emxFree_creal32_T(&in1_1);
}

void SmartMicDrvTsk_Ccode::FFTImplementationCallback_r2br_(const creal32_T x
  [8192], const float costab[4096], const float sintab[4096], creal32_T y[8192])
{
  float temp_im;
  float temp_re;
  float twid_im;
  float twid_re;
  int32_t i;
  int32_t iheight;
  int32_t iy;
  int32_t ju;
  int32_t k;
  iy = 0;
  ju = 0;
  for (i = 0; i < 8191; i++) {
    bool tst;
    y[iy] = x[i];
    iy = 8192;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  y[iy] = x[8191];
  for (i = 0; i <= 8190; i += 2) {
    twid_re = y[i + 1].re;
    twid_im = y[i + 1].im;
    temp_re = y[i].re;
    temp_im = y[i].im;
    y[i + 1].re = temp_re - twid_re;
    y[i + 1].im = temp_im - twid_im;
    y[i].re = temp_re + twid_re;
    y[i].im = temp_im + twid_im;
  }

  ju = 2;
  iy = 4;
  k = 2048;
  iheight = 8189;
  while (k > 0) {
    int32_t istart;
    for (i = 0; i < iheight; i += iy) {
      istart = i + ju;
      temp_re = y[istart].re;
      temp_im = y[istart].im;
      y[istart].re = y[i].re - temp_re;
      y[istart].im = y[i].im - temp_im;
      y[i].re += temp_re;
      y[i].im += temp_im;
    }

    istart = 1;
    for (int32_t j{k}; j < 4096; j += k) {
      int32_t ihi;
      twid_re = costab[j];
      twid_im = sintab[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        float temp_re_tmp;
        int32_t temp_re_tmp_tmp;
        temp_re_tmp_tmp = i + ju;
        temp_im = y[temp_re_tmp_tmp].im;
        temp_re_tmp = y[temp_re_tmp_tmp].re;
        temp_re = temp_re_tmp * twid_re - temp_im * twid_im;
        temp_im = temp_im * twid_re + temp_re_tmp * twid_im;
        y[temp_re_tmp_tmp].re = y[i].re - temp_re;
        y[temp_re_tmp_tmp].im = y[i].im - temp_im;
        y[i].re += temp_re;
        y[i].im += temp_im;
        i += iy;
      }

      istart++;
    }

    k /= 2;
    ju = iy;
    iy += iy;
    iheight -= ju;
  }

  for (i = 0; i < 8192; i++) {
    y[i].re *= 0.000122070312F;
    y[i].im *= 0.000122070312F;
  }
}

void SmartMicDrvTsk_Ccode::FFTImplementationCallback_d_j3x(const float x[6000],
  int32_t xoffInit, creal32_T y[6000], const creal32_T wwc[5999], const float
  costab[8193], const float sintab[8193], const float costabinv[8193], const
  float sintabinv[8193])
{
  static const int16_t tmp_1[3000]{ 1, 3000, 2999, 2998, 2997, 2996, 2995, 2994,
    2993, 2992, 2991, 2990, 2989, 2988, 2987, 2986, 2985, 2984, 2983, 2982, 2981,
    2980, 2979, 2978, 2977, 2976, 2975, 2974, 2973, 2972, 2971, 2970, 2969, 2968,
    2967, 2966, 2965, 2964, 2963, 2962, 2961, 2960, 2959, 2958, 2957, 2956, 2955,
    2954, 2953, 2952, 2951, 2950, 2949, 2948, 2947, 2946, 2945, 2944, 2943, 2942,
    2941, 2940, 2939, 2938, 2937, 2936, 2935, 2934, 2933, 2932, 2931, 2930, 2929,
    2928, 2927, 2926, 2925, 2924, 2923, 2922, 2921, 2920, 2919, 2918, 2917, 2916,
    2915, 2914, 2913, 2912, 2911, 2910, 2909, 2908, 2907, 2906, 2905, 2904, 2903,
    2902, 2901, 2900, 2899, 2898, 2897, 2896, 2895, 2894, 2893, 2892, 2891, 2890,
    2889, 2888, 2887, 2886, 2885, 2884, 2883, 2882, 2881, 2880, 2879, 2878, 2877,
    2876, 2875, 2874, 2873, 2872, 2871, 2870, 2869, 2868, 2867, 2866, 2865, 2864,
    2863, 2862, 2861, 2860, 2859, 2858, 2857, 2856, 2855, 2854, 2853, 2852, 2851,
    2850, 2849, 2848, 2847, 2846, 2845, 2844, 2843, 2842, 2841, 2840, 2839, 2838,
    2837, 2836, 2835, 2834, 2833, 2832, 2831, 2830, 2829, 2828, 2827, 2826, 2825,
    2824, 2823, 2822, 2821, 2820, 2819, 2818, 2817, 2816, 2815, 2814, 2813, 2812,
    2811, 2810, 2809, 2808, 2807, 2806, 2805, 2804, 2803, 2802, 2801, 2800, 2799,
    2798, 2797, 2796, 2795, 2794, 2793, 2792, 2791, 2790, 2789, 2788, 2787, 2786,
    2785, 2784, 2783, 2782, 2781, 2780, 2779, 2778, 2777, 2776, 2775, 2774, 2773,
    2772, 2771, 2770, 2769, 2768, 2767, 2766, 2765, 2764, 2763, 2762, 2761, 2760,
    2759, 2758, 2757, 2756, 2755, 2754, 2753, 2752, 2751, 2750, 2749, 2748, 2747,
    2746, 2745, 2744, 2743, 2742, 2741, 2740, 2739, 2738, 2737, 2736, 2735, 2734,
    2733, 2732, 2731, 2730, 2729, 2728, 2727, 2726, 2725, 2724, 2723, 2722, 2721,
    2720, 2719, 2718, 2717, 2716, 2715, 2714, 2713, 2712, 2711, 2710, 2709, 2708,
    2707, 2706, 2705, 2704, 2703, 2702, 2701, 2700, 2699, 2698, 2697, 2696, 2695,
    2694, 2693, 2692, 2691, 2690, 2689, 2688, 2687, 2686, 2685, 2684, 2683, 2682,
    2681, 2680, 2679, 2678, 2677, 2676, 2675, 2674, 2673, 2672, 2671, 2670, 2669,
    2668, 2667, 2666, 2665, 2664, 2663, 2662, 2661, 2660, 2659, 2658, 2657, 2656,
    2655, 2654, 2653, 2652, 2651, 2650, 2649, 2648, 2647, 2646, 2645, 2644, 2643,
    2642, 2641, 2640, 2639, 2638, 2637, 2636, 2635, 2634, 2633, 2632, 2631, 2630,
    2629, 2628, 2627, 2626, 2625, 2624, 2623, 2622, 2621, 2620, 2619, 2618, 2617,
    2616, 2615, 2614, 2613, 2612, 2611, 2610, 2609, 2608, 2607, 2606, 2605, 2604,
    2603, 2602, 2601, 2600, 2599, 2598, 2597, 2596, 2595, 2594, 2593, 2592, 2591,
    2590, 2589, 2588, 2587, 2586, 2585, 2584, 2583, 2582, 2581, 2580, 2579, 2578,
    2577, 2576, 2575, 2574, 2573, 2572, 2571, 2570, 2569, 2568, 2567, 2566, 2565,
    2564, 2563, 2562, 2561, 2560, 2559, 2558, 2557, 2556, 2555, 2554, 2553, 2552,
    2551, 2550, 2549, 2548, 2547, 2546, 2545, 2544, 2543, 2542, 2541, 2540, 2539,
    2538, 2537, 2536, 2535, 2534, 2533, 2532, 2531, 2530, 2529, 2528, 2527, 2526,
    2525, 2524, 2523, 2522, 2521, 2520, 2519, 2518, 2517, 2516, 2515, 2514, 2513,
    2512, 2511, 2510, 2509, 2508, 2507, 2506, 2505, 2504, 2503, 2502, 2501, 2500,
    2499, 2498, 2497, 2496, 2495, 2494, 2493, 2492, 2491, 2490, 2489, 2488, 2487,
    2486, 2485, 2484, 2483, 2482, 2481, 2480, 2479, 2478, 2477, 2476, 2475, 2474,
    2473, 2472, 2471, 2470, 2469, 2468, 2467, 2466, 2465, 2464, 2463, 2462, 2461,
    2460, 2459, 2458, 2457, 2456, 2455, 2454, 2453, 2452, 2451, 2450, 2449, 2448,
    2447, 2446, 2445, 2444, 2443, 2442, 2441, 2440, 2439, 2438, 2437, 2436, 2435,
    2434, 2433, 2432, 2431, 2430, 2429, 2428, 2427, 2426, 2425, 2424, 2423, 2422,
    2421, 2420, 2419, 2418, 2417, 2416, 2415, 2414, 2413, 2412, 2411, 2410, 2409,
    2408, 2407, 2406, 2405, 2404, 2403, 2402, 2401, 2400, 2399, 2398, 2397, 2396,
    2395, 2394, 2393, 2392, 2391, 2390, 2389, 2388, 2387, 2386, 2385, 2384, 2383,
    2382, 2381, 2380, 2379, 2378, 2377, 2376, 2375, 2374, 2373, 2372, 2371, 2370,
    2369, 2368, 2367, 2366, 2365, 2364, 2363, 2362, 2361, 2360, 2359, 2358, 2357,
    2356, 2355, 2354, 2353, 2352, 2351, 2350, 2349, 2348, 2347, 2346, 2345, 2344,
    2343, 2342, 2341, 2340, 2339, 2338, 2337, 2336, 2335, 2334, 2333, 2332, 2331,
    2330, 2329, 2328, 2327, 2326, 2325, 2324, 2323, 2322, 2321, 2320, 2319, 2318,
    2317, 2316, 2315, 2314, 2313, 2312, 2311, 2310, 2309, 2308, 2307, 2306, 2305,
    2304, 2303, 2302, 2301, 2300, 2299, 2298, 2297, 2296, 2295, 2294, 2293, 2292,
    2291, 2290, 2289, 2288, 2287, 2286, 2285, 2284, 2283, 2282, 2281, 2280, 2279,
    2278, 2277, 2276, 2275, 2274, 2273, 2272, 2271, 2270, 2269, 2268, 2267, 2266,
    2265, 2264, 2263, 2262, 2261, 2260, 2259, 2258, 2257, 2256, 2255, 2254, 2253,
    2252, 2251, 2250, 2249, 2248, 2247, 2246, 2245, 2244, 2243, 2242, 2241, 2240,
    2239, 2238, 2237, 2236, 2235, 2234, 2233, 2232, 2231, 2230, 2229, 2228, 2227,
    2226, 2225, 2224, 2223, 2222, 2221, 2220, 2219, 2218, 2217, 2216, 2215, 2214,
    2213, 2212, 2211, 2210, 2209, 2208, 2207, 2206, 2205, 2204, 2203, 2202, 2201,
    2200, 2199, 2198, 2197, 2196, 2195, 2194, 2193, 2192, 2191, 2190, 2189, 2188,
    2187, 2186, 2185, 2184, 2183, 2182, 2181, 2180, 2179, 2178, 2177, 2176, 2175,
    2174, 2173, 2172, 2171, 2170, 2169, 2168, 2167, 2166, 2165, 2164, 2163, 2162,
    2161, 2160, 2159, 2158, 2157, 2156, 2155, 2154, 2153, 2152, 2151, 2150, 2149,
    2148, 2147, 2146, 2145, 2144, 2143, 2142, 2141, 2140, 2139, 2138, 2137, 2136,
    2135, 2134, 2133, 2132, 2131, 2130, 2129, 2128, 2127, 2126, 2125, 2124, 2123,
    2122, 2121, 2120, 2119, 2118, 2117, 2116, 2115, 2114, 2113, 2112, 2111, 2110,
    2109, 2108, 2107, 2106, 2105, 2104, 2103, 2102, 2101, 2100, 2099, 2098, 2097,
    2096, 2095, 2094, 2093, 2092, 2091, 2090, 2089, 2088, 2087, 2086, 2085, 2084,
    2083, 2082, 2081, 2080, 2079, 2078, 2077, 2076, 2075, 2074, 2073, 2072, 2071,
    2070, 2069, 2068, 2067, 2066, 2065, 2064, 2063, 2062, 2061, 2060, 2059, 2058,
    2057, 2056, 2055, 2054, 2053, 2052, 2051, 2050, 2049, 2048, 2047, 2046, 2045,
    2044, 2043, 2042, 2041, 2040, 2039, 2038, 2037, 2036, 2035, 2034, 2033, 2032,
    2031, 2030, 2029, 2028, 2027, 2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019,
    2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011, 2010, 2009, 2008, 2007, 2006,
    2005, 2004, 2003, 2002, 2001, 2000, 1999, 1998, 1997, 1996, 1995, 1994, 1993,
    1992, 1991, 1990, 1989, 1988, 1987, 1986, 1985, 1984, 1983, 1982, 1981, 1980,
    1979, 1978, 1977, 1976, 1975, 1974, 1973, 1972, 1971, 1970, 1969, 1968, 1967,
    1966, 1965, 1964, 1963, 1962, 1961, 1960, 1959, 1958, 1957, 1956, 1955, 1954,
    1953, 1952, 1951, 1950, 1949, 1948, 1947, 1946, 1945, 1944, 1943, 1942, 1941,
    1940, 1939, 1938, 1937, 1936, 1935, 1934, 1933, 1932, 1931, 1930, 1929, 1928,
    1927, 1926, 1925, 1924, 1923, 1922, 1921, 1920, 1919, 1918, 1917, 1916, 1915,
    1914, 1913, 1912, 1911, 1910, 1909, 1908, 1907, 1906, 1905, 1904, 1903, 1902,
    1901, 1900, 1899, 1898, 1897, 1896, 1895, 1894, 1893, 1892, 1891, 1890, 1889,
    1888, 1887, 1886, 1885, 1884, 1883, 1882, 1881, 1880, 1879, 1878, 1877, 1876,
    1875, 1874, 1873, 1872, 1871, 1870, 1869, 1868, 1867, 1866, 1865, 1864, 1863,
    1862, 1861, 1860, 1859, 1858, 1857, 1856, 1855, 1854, 1853, 1852, 1851, 1850,
    1849, 1848, 1847, 1846, 1845, 1844, 1843, 1842, 1841, 1840, 1839, 1838, 1837,
    1836, 1835, 1834, 1833, 1832, 1831, 1830, 1829, 1828, 1827, 1826, 1825, 1824,
    1823, 1822, 1821, 1820, 1819, 1818, 1817, 1816, 1815, 1814, 1813, 1812, 1811,
    1810, 1809, 1808, 1807, 1806, 1805, 1804, 1803, 1802, 1801, 1800, 1799, 1798,
    1797, 1796, 1795, 1794, 1793, 1792, 1791, 1790, 1789, 1788, 1787, 1786, 1785,
    1784, 1783, 1782, 1781, 1780, 1779, 1778, 1777, 1776, 1775, 1774, 1773, 1772,
    1771, 1770, 1769, 1768, 1767, 1766, 1765, 1764, 1763, 1762, 1761, 1760, 1759,
    1758, 1757, 1756, 1755, 1754, 1753, 1752, 1751, 1750, 1749, 1748, 1747, 1746,
    1745, 1744, 1743, 1742, 1741, 1740, 1739, 1738, 1737, 1736, 1735, 1734, 1733,
    1732, 1731, 1730, 1729, 1728, 1727, 1726, 1725, 1724, 1723, 1722, 1721, 1720,
    1719, 1718, 1717, 1716, 1715, 1714, 1713, 1712, 1711, 1710, 1709, 1708, 1707,
    1706, 1705, 1704, 1703, 1702, 1701, 1700, 1699, 1698, 1697, 1696, 1695, 1694,
    1693, 1692, 1691, 1690, 1689, 1688, 1687, 1686, 1685, 1684, 1683, 1682, 1681,
    1680, 1679, 1678, 1677, 1676, 1675, 1674, 1673, 1672, 1671, 1670, 1669, 1668,
    1667, 1666, 1665, 1664, 1663, 1662, 1661, 1660, 1659, 1658, 1657, 1656, 1655,
    1654, 1653, 1652, 1651, 1650, 1649, 1648, 1647, 1646, 1645, 1644, 1643, 1642,
    1641, 1640, 1639, 1638, 1637, 1636, 1635, 1634, 1633, 1632, 1631, 1630, 1629,
    1628, 1627, 1626, 1625, 1624, 1623, 1622, 1621, 1620, 1619, 1618, 1617, 1616,
    1615, 1614, 1613, 1612, 1611, 1610, 1609, 1608, 1607, 1606, 1605, 1604, 1603,
    1602, 1601, 1600, 1599, 1598, 1597, 1596, 1595, 1594, 1593, 1592, 1591, 1590,
    1589, 1588, 1587, 1586, 1585, 1584, 1583, 1582, 1581, 1580, 1579, 1578, 1577,
    1576, 1575, 1574, 1573, 1572, 1571, 1570, 1569, 1568, 1567, 1566, 1565, 1564,
    1563, 1562, 1561, 1560, 1559, 1558, 1557, 1556, 1555, 1554, 1553, 1552, 1551,
    1550, 1549, 1548, 1547, 1546, 1545, 1544, 1543, 1542, 1541, 1540, 1539, 1538,
    1537, 1536, 1535, 1534, 1533, 1532, 1531, 1530, 1529, 1528, 1527, 1526, 1525,
    1524, 1523, 1522, 1521, 1520, 1519, 1518, 1517, 1516, 1515, 1514, 1513, 1512,
    1511, 1510, 1509, 1508, 1507, 1506, 1505, 1504, 1503, 1502, 1501, 1500, 1499,
    1498, 1497, 1496, 1495, 1494, 1493, 1492, 1491, 1490, 1489, 1488, 1487, 1486,
    1485, 1484, 1483, 1482, 1481, 1480, 1479, 1478, 1477, 1476, 1475, 1474, 1473,
    1472, 1471, 1470, 1469, 1468, 1467, 1466, 1465, 1464, 1463, 1462, 1461, 1460,
    1459, 1458, 1457, 1456, 1455, 1454, 1453, 1452, 1451, 1450, 1449, 1448, 1447,
    1446, 1445, 1444, 1443, 1442, 1441, 1440, 1439, 1438, 1437, 1436, 1435, 1434,
    1433, 1432, 1431, 1430, 1429, 1428, 1427, 1426, 1425, 1424, 1423, 1422, 1421,
    1420, 1419, 1418, 1417, 1416, 1415, 1414, 1413, 1412, 1411, 1410, 1409, 1408,
    1407, 1406, 1405, 1404, 1403, 1402, 1401, 1400, 1399, 1398, 1397, 1396, 1395,
    1394, 1393, 1392, 1391, 1390, 1389, 1388, 1387, 1386, 1385, 1384, 1383, 1382,
    1381, 1380, 1379, 1378, 1377, 1376, 1375, 1374, 1373, 1372, 1371, 1370, 1369,
    1368, 1367, 1366, 1365, 1364, 1363, 1362, 1361, 1360, 1359, 1358, 1357, 1356,
    1355, 1354, 1353, 1352, 1351, 1350, 1349, 1348, 1347, 1346, 1345, 1344, 1343,
    1342, 1341, 1340, 1339, 1338, 1337, 1336, 1335, 1334, 1333, 1332, 1331, 1330,
    1329, 1328, 1327, 1326, 1325, 1324, 1323, 1322, 1321, 1320, 1319, 1318, 1317,
    1316, 1315, 1314, 1313, 1312, 1311, 1310, 1309, 1308, 1307, 1306, 1305, 1304,
    1303, 1302, 1301, 1300, 1299, 1298, 1297, 1296, 1295, 1294, 1293, 1292, 1291,
    1290, 1289, 1288, 1287, 1286, 1285, 1284, 1283, 1282, 1281, 1280, 1279, 1278,
    1277, 1276, 1275, 1274, 1273, 1272, 1271, 1270, 1269, 1268, 1267, 1266, 1265,
    1264, 1263, 1262, 1261, 1260, 1259, 1258, 1257, 1256, 1255, 1254, 1253, 1252,
    1251, 1250, 1249, 1248, 1247, 1246, 1245, 1244, 1243, 1242, 1241, 1240, 1239,
    1238, 1237, 1236, 1235, 1234, 1233, 1232, 1231, 1230, 1229, 1228, 1227, 1226,
    1225, 1224, 1223, 1222, 1221, 1220, 1219, 1218, 1217, 1216, 1215, 1214, 1213,
    1212, 1211, 1210, 1209, 1208, 1207, 1206, 1205, 1204, 1203, 1202, 1201, 1200,
    1199, 1198, 1197, 1196, 1195, 1194, 1193, 1192, 1191, 1190, 1189, 1188, 1187,
    1186, 1185, 1184, 1183, 1182, 1181, 1180, 1179, 1178, 1177, 1176, 1175, 1174,
    1173, 1172, 1171, 1170, 1169, 1168, 1167, 1166, 1165, 1164, 1163, 1162, 1161,
    1160, 1159, 1158, 1157, 1156, 1155, 1154, 1153, 1152, 1151, 1150, 1149, 1148,
    1147, 1146, 1145, 1144, 1143, 1142, 1141, 1140, 1139, 1138, 1137, 1136, 1135,
    1134, 1133, 1132, 1131, 1130, 1129, 1128, 1127, 1126, 1125, 1124, 1123, 1122,
    1121, 1120, 1119, 1118, 1117, 1116, 1115, 1114, 1113, 1112, 1111, 1110, 1109,
    1108, 1107, 1106, 1105, 1104, 1103, 1102, 1101, 1100, 1099, 1098, 1097, 1096,
    1095, 1094, 1093, 1092, 1091, 1090, 1089, 1088, 1087, 1086, 1085, 1084, 1083,
    1082, 1081, 1080, 1079, 1078, 1077, 1076, 1075, 1074, 1073, 1072, 1071, 1070,
    1069, 1068, 1067, 1066, 1065, 1064, 1063, 1062, 1061, 1060, 1059, 1058, 1057,
    1056, 1055, 1054, 1053, 1052, 1051, 1050, 1049, 1048, 1047, 1046, 1045, 1044,
    1043, 1042, 1041, 1040, 1039, 1038, 1037, 1036, 1035, 1034, 1033, 1032, 1031,
    1030, 1029, 1028, 1027, 1026, 1025, 1024, 1023, 1022, 1021, 1020, 1019, 1018,
    1017, 1016, 1015, 1014, 1013, 1012, 1011, 1010, 1009, 1008, 1007, 1006, 1005,
    1004, 1003, 1002, 1001, 1000, 999, 998, 997, 996, 995, 994, 993, 992, 991,
    990, 989, 988, 987, 986, 985, 984, 983, 982, 981, 980, 979, 978, 977, 976,
    975, 974, 973, 972, 971, 970, 969, 968, 967, 966, 965, 964, 963, 962, 961,
    960, 959, 958, 957, 956, 955, 954, 953, 952, 951, 950, 949, 948, 947, 946,
    945, 944, 943, 942, 941, 940, 939, 938, 937, 936, 935, 934, 933, 932, 931,
    930, 929, 928, 927, 926, 925, 924, 923, 922, 921, 920, 919, 918, 917, 916,
    915, 914, 913, 912, 911, 910, 909, 908, 907, 906, 905, 904, 903, 902, 901,
    900, 899, 898, 897, 896, 895, 894, 893, 892, 891, 890, 889, 888, 887, 886,
    885, 884, 883, 882, 881, 880, 879, 878, 877, 876, 875, 874, 873, 872, 871,
    870, 869, 868, 867, 866, 865, 864, 863, 862, 861, 860, 859, 858, 857, 856,
    855, 854, 853, 852, 851, 850, 849, 848, 847, 846, 845, 844, 843, 842, 841,
    840, 839, 838, 837, 836, 835, 834, 833, 832, 831, 830, 829, 828, 827, 826,
    825, 824, 823, 822, 821, 820, 819, 818, 817, 816, 815, 814, 813, 812, 811,
    810, 809, 808, 807, 806, 805, 804, 803, 802, 801, 800, 799, 798, 797, 796,
    795, 794, 793, 792, 791, 790, 789, 788, 787, 786, 785, 784, 783, 782, 781,
    780, 779, 778, 777, 776, 775, 774, 773, 772, 771, 770, 769, 768, 767, 766,
    765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 755, 754, 753, 752, 751,
    750, 749, 748, 747, 746, 745, 744, 743, 742, 741, 740, 739, 738, 737, 736,
    735, 734, 733, 732, 731, 730, 729, 728, 727, 726, 725, 724, 723, 722, 721,
    720, 719, 718, 717, 716, 715, 714, 713, 712, 711, 710, 709, 708, 707, 706,
    705, 704, 703, 702, 701, 700, 699, 698, 697, 696, 695, 694, 693, 692, 691,
    690, 689, 688, 687, 686, 685, 684, 683, 682, 681, 680, 679, 678, 677, 676,
    675, 674, 673, 672, 671, 670, 669, 668, 667, 666, 665, 664, 663, 662, 661,
    660, 659, 658, 657, 656, 655, 654, 653, 652, 651, 650, 649, 648, 647, 646,
    645, 644, 643, 642, 641, 640, 639, 638, 637, 636, 635, 634, 633, 632, 631,
    630, 629, 628, 627, 626, 625, 624, 623, 622, 621, 620, 619, 618, 617, 616,
    615, 614, 613, 612, 611, 610, 609, 608, 607, 606, 605, 604, 603, 602, 601,
    600, 599, 598, 597, 596, 595, 594, 593, 592, 591, 590, 589, 588, 587, 586,
    585, 584, 583, 582, 581, 580, 579, 578, 577, 576, 575, 574, 573, 572, 571,
    570, 569, 568, 567, 566, 565, 564, 563, 562, 561, 560, 559, 558, 557, 556,
    555, 554, 553, 552, 551, 550, 549, 548, 547, 546, 545, 544, 543, 542, 541,
    540, 539, 538, 537, 536, 535, 534, 533, 532, 531, 530, 529, 528, 527, 526,
    525, 524, 523, 522, 521, 520, 519, 518, 517, 516, 515, 514, 513, 512, 511,
    510, 509, 508, 507, 506, 505, 504, 503, 502, 501, 500, 499, 498, 497, 496,
    495, 494, 493, 492, 491, 490, 489, 488, 487, 486, 485, 484, 483, 482, 481,
    480, 479, 478, 477, 476, 475, 474, 473, 472, 471, 470, 469, 468, 467, 466,
    465, 464, 463, 462, 461, 460, 459, 458, 457, 456, 455, 454, 453, 452, 451,
    450, 449, 448, 447, 446, 445, 444, 443, 442, 441, 440, 439, 438, 437, 436,
    435, 434, 433, 432, 431, 430, 429, 428, 427, 426, 425, 424, 423, 422, 421,
    420, 419, 418, 417, 416, 415, 414, 413, 412, 411, 410, 409, 408, 407, 406,
    405, 404, 403, 402, 401, 400, 399, 398, 397, 396, 395, 394, 393, 392, 391,
    390, 389, 388, 387, 386, 385, 384, 383, 382, 381, 380, 379, 378, 377, 376,
    375, 374, 373, 372, 371, 370, 369, 368, 367, 366, 365, 364, 363, 362, 361,
    360, 359, 358, 357, 356, 355, 354, 353, 352, 351, 350, 349, 348, 347, 346,
    345, 344, 343, 342, 341, 340, 339, 338, 337, 336, 335, 334, 333, 332, 331,
    330, 329, 328, 327, 326, 325, 324, 323, 322, 321, 320, 319, 318, 317, 316,
    315, 314, 313, 312, 311, 310, 309, 308, 307, 306, 305, 304, 303, 302, 301,
    300, 299, 298, 297, 296, 295, 294, 293, 292, 291, 290, 289, 288, 287, 286,
    285, 284, 283, 282, 281, 280, 279, 278, 277, 276, 275, 274, 273, 272, 271,
    270, 269, 268, 267, 266, 265, 264, 263, 262, 261, 260, 259, 258, 257, 256,
    255, 254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 244, 243, 242, 241,
    240, 239, 238, 237, 236, 235, 234, 233, 232, 231, 230, 229, 228, 227, 226,
    225, 224, 223, 222, 221, 220, 219, 218, 217, 216, 215, 214, 213, 212, 211,
    210, 209, 208, 207, 206, 205, 204, 203, 202, 201, 200, 199, 198, 197, 196,
    195, 194, 193, 192, 191, 190, 189, 188, 187, 186, 185, 184, 183, 182, 181,
    180, 179, 178, 177, 176, 175, 174, 173, 172, 171, 170, 169, 168, 167, 166,
    165, 164, 163, 162, 161, 160, 159, 158, 157, 156, 155, 154, 153, 152, 151,
    150, 149, 148, 147, 146, 145, 144, 143, 142, 141, 140, 139, 138, 137, 136,
    135, 134, 133, 132, 131, 130, 129, 128, 127, 126, 125, 124, 123, 122, 121,
    120, 119, 118, 117, 116, 115, 114, 113, 112, 111, 110, 109, 108, 107, 106,
    105, 104, 103, 102, 101, 100, 99, 98, 97, 96, 95, 94, 93, 92, 91, 90, 89, 88,
    87, 86, 85, 84, 83, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 72, 71, 70, 69,
    68, 67, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50,
    49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31,
    30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12,
    11, 10, 9, 8, 7, 6, 5, 4, 3, 2 };

  float reconVar2;
  float reconVar2_0;
  float temp_im;
  float temp_re;
  float tmp;
  float tmp_0;
  float twid_im;
  float twid_re;
  int32_t i;
  int32_t iDelta2;
  int32_t iheight;
  int32_t ihi;
  int32_t istart;
  int32_t iy;
  int32_t j;
  int32_t ju;
  int32_t temp_re_tmp_tmp;
  int16_t wrapIndex;
  bool tst;
  rtDW.costab1q_l[0] = 1.0F;
  for (i = 0; i < 1500; i++) {
    rtDW.costab1q_l[i + 1] = std::cos(static_cast<float>(i + 1) *
      0.000523598806F);
  }

  for (i = 0; i < 1499; i++) {
    rtDW.costab1q_l[i + 1501] = std::sin((1499.0F - static_cast<float>(i)) *
      0.000523598806F);
  }

  rtDW.costab1q_l[3000] = 0.0F;
  rtDW.b_costab_j[0] = 1.0F;
  rtDW.b_sintab_d[0] = 0.0F;
  for (i = 0; i < 3000; i++) {
    temp_re = rtDW.costab1q_l[i + 1];
    rtDW.b_costab_j[i + 1] = temp_re;
    temp_im = -rtDW.costab1q_l[2999 - i];
    rtDW.b_sintab_d[i + 1] = temp_im;
    rtDW.b_costab_j[i + 3001] = temp_im;
    rtDW.b_sintab_d[i + 3001] = -temp_re;
  }

  for (i = 0; i < 4096; i++) {
    ju = ((i + 1) << 1) - 2;
    rtDW.hcostab[i] = costab[ju];
    rtDW.hsintab[i] = sintab[ju];
    rtDW.hcostabinv[i] = costabinv[ju];
    rtDW.hsintabinv[i] = sintabinv[ju];
  }

  for (i = 0; i < 3000; i++) {
    ju = i << 1;
    temp_re = rtDW.b_sintab_d[ju];
    temp_im = rtDW.b_costab_j[ju];
    rtDW.reconVar1[i].re = temp_re + 1.0F;
    rtDW.reconVar1[i].im = -temp_im;
    rtDW.reconVar2[i].re = 1.0F - temp_re;
    rtDW.reconVar2[i].im = temp_im;
    istart = ju + xoffInit;
    temp_re = x[istart];
    temp_im = x[istart + 1];
    twid_re = wwc[i + 2999].re;
    twid_im = wwc[i + 2999].im;
    rtDW.ytmp[i].re = twid_re * temp_re + twid_im * temp_im;
    rtDW.ytmp[i].im = twid_re * temp_im - twid_im * temp_re;
  }

  std::memset(&rtDW.fy_b[0], 0, sizeof(creal32_T) << 13U);
  iy = 0;
  ju = 0;
  for (i = 0; i < 2999; i++) {
    rtDW.fy_b[iy] = rtDW.ytmp[i];
    iy = 8192;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  rtDW.fy_b[iy] = rtDW.ytmp[2999];
  for (i = 0; i <= 8190; i += 2) {
    temp_re = rtDW.fy_b[i + 1].re;
    temp_im = rtDW.fy_b[i + 1].im;
    twid_re = rtDW.fy_b[i].re;
    twid_im = rtDW.fy_b[i].im;
    rtDW.fy_b[i + 1].re = twid_re - temp_re;
    rtDW.fy_b[i + 1].im = twid_im - temp_im;
    rtDW.fy_b[i].re = twid_re + temp_re;
    rtDW.fy_b[i].im = twid_im + temp_im;
  }

  iy = 2;
  iDelta2 = 4;
  ju = 2048;
  iheight = 8189;
  while (ju > 0) {
    for (i = 0; i < iheight; i += iDelta2) {
      istart = i + iy;
      temp_re = rtDW.fy_b[istart].re;
      temp_im = rtDW.fy_b[istart].im;
      rtDW.fy_b[istart].re = rtDW.fy_b[i].re - temp_re;
      rtDW.fy_b[istart].im = rtDW.fy_b[i].im - temp_im;
      rtDW.fy_b[i].re += temp_re;
      rtDW.fy_b[i].im += temp_im;
    }

    istart = 1;
    for (j = ju; j < 4096; j += ju) {
      twid_re = rtDW.hcostab[j];
      twid_im = rtDW.hsintab[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        temp_re_tmp_tmp = i + iy;
        temp_im = rtDW.fy_b[temp_re_tmp_tmp].im;
        reconVar2 = rtDW.fy_b[temp_re_tmp_tmp].re;
        temp_re = reconVar2 * twid_re - temp_im * twid_im;
        temp_im = temp_im * twid_re + reconVar2 * twid_im;
        rtDW.fy_b[temp_re_tmp_tmp].re = rtDW.fy_b[i].re - temp_re;
        rtDW.fy_b[temp_re_tmp_tmp].im = rtDW.fy_b[i].im - temp_im;
        rtDW.fy_b[i].re += temp_re;
        rtDW.fy_b[i].im += temp_im;
        i += iDelta2;
      }

      istart++;
    }

    ju /= 2;
    iy = iDelta2;
    iDelta2 += iDelta2;
    iheight -= iy;
  }

  std::memset(&rtDW.fv_p[0], 0, sizeof(creal32_T) << 13U);
  iy = 0;
  ju = 0;
  for (i = 0; i < 5998; i++) {
    rtDW.fv_p[iy] = wwc[i];
    iy = 8192;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  rtDW.fv_p[iy] = wwc[5998];
  for (i = 0; i <= 8190; i += 2) {
    temp_re = rtDW.fv_p[i + 1].re;
    temp_im = rtDW.fv_p[i + 1].im;
    twid_re = rtDW.fv_p[i].re;
    twid_im = rtDW.fv_p[i].im;
    rtDW.fv_p[i + 1].re = twid_re - temp_re;
    rtDW.fv_p[i + 1].im = twid_im - temp_im;
    rtDW.fv_p[i].re = twid_re + temp_re;
    rtDW.fv_p[i].im = twid_im + temp_im;
  }

  iy = 2;
  iDelta2 = 4;
  ju = 2048;
  iheight = 8189;
  while (ju > 0) {
    for (i = 0; i < iheight; i += iDelta2) {
      istart = i + iy;
      temp_re = rtDW.fv_p[istart].re;
      temp_im = rtDW.fv_p[istart].im;
      rtDW.fv_p[istart].re = rtDW.fv_p[i].re - temp_re;
      rtDW.fv_p[istart].im = rtDW.fv_p[i].im - temp_im;
      rtDW.fv_p[i].re += temp_re;
      rtDW.fv_p[i].im += temp_im;
    }

    istart = 1;
    for (j = ju; j < 4096; j += ju) {
      twid_re = rtDW.hcostab[j];
      twid_im = rtDW.hsintab[j];
      i = istart;
      ihi = istart + iheight;
      while (i < ihi) {
        temp_re_tmp_tmp = i + iy;
        temp_im = rtDW.fv_p[temp_re_tmp_tmp].im;
        reconVar2 = rtDW.fv_p[temp_re_tmp_tmp].re;
        temp_re = reconVar2 * twid_re - temp_im * twid_im;
        temp_im = temp_im * twid_re + reconVar2 * twid_im;
        rtDW.fv_p[temp_re_tmp_tmp].re = rtDW.fv_p[i].re - temp_re;
        rtDW.fv_p[temp_re_tmp_tmp].im = rtDW.fv_p[i].im - temp_im;
        rtDW.fv_p[i].re += temp_re;
        rtDW.fv_p[i].im += temp_im;
        i += iDelta2;
      }

      istart++;
    }

    ju /= 2;
    iy = iDelta2;
    iDelta2 += iDelta2;
    iheight -= iy;
  }

  for (i = 0; i < 8192; i++) {
    temp_re = rtDW.fy_b[i].re;
    temp_im = rtDW.fy_b[i].im;
    twid_re = rtDW.fv_p[i].re;
    twid_im = rtDW.fv_p[i].im;
    rtDW.fy_c[i].re = temp_re * twid_re - temp_im * twid_im;
    rtDW.fy_c[i].im = temp_re * twid_im + temp_im * twid_re;
  }

  FFTImplementationCallback_r2br_(rtDW.fy_c, rtDW.hcostabinv, rtDW.hsintabinv,
    rtDW.fv_p);
  for (ju = 0; ju < 3000; ju++) {
    twid_re = wwc[ju + 2999].re;
    twid_im = wwc[ju + 2999].im;
    temp_re = rtDW.fv_p[ju + 2999].re;
    temp_im = rtDW.fv_p[ju + 2999].im;
    rtDW.ytmp[ju].re = twid_re * temp_re + twid_im * temp_im;
    rtDW.ytmp[ju].im = twid_re * temp_im - twid_im * temp_re;
    rtDW.wrapIndex[ju] = tmp_1[ju];
  }

  for (i = 0; i < 3000; i++) {
    wrapIndex = rtDW.wrapIndex[i];
    temp_re = rtDW.ytmp[wrapIndex - 1].re;
    temp_im = -rtDW.ytmp[wrapIndex - 1].im;
    twid_re = rtDW.reconVar1[i].re;
    twid_im = rtDW.reconVar1[i].im;
    reconVar2 = rtDW.reconVar2[i].re;
    reconVar2_0 = rtDW.reconVar2[i].im;
    tmp = rtDW.ytmp[i].re;
    tmp_0 = rtDW.ytmp[i].im;
    y[i].re = ((tmp * twid_re - tmp_0 * twid_im) + (temp_re * reconVar2 -
                temp_im * reconVar2_0)) * 0.5F;
    y[i].im = ((tmp * twid_im + tmp_0 * twid_re) + (temp_re * reconVar2_0 +
                temp_im * reconVar2)) * 0.5F;
    y[i + 3000].re = ((tmp * reconVar2 - tmp_0 * reconVar2_0) + (temp_re *
      twid_re - temp_im * twid_im)) * 0.5F;
    y[i + 3000].im = ((tmp * reconVar2_0 + tmp_0 * reconVar2) + (temp_re *
      twid_im + temp_im * twid_re)) * 0.5F;
  }
}

void SmartMicDrvTsk_Ccode::fft(const float x[6000], creal32_T y[6000])
{
  float b_sintabinv_tmp;
  float nt_im;
  int32_t b_k;
  int32_t rt;
  int32_t y_0;
  rtDW.costab1q_g[0] = 1.0F;
  for (b_k = 0; b_k < 2048; b_k++) {
    rtDW.costab1q_g[b_k + 1] = std::cos(static_cast<float>(b_k + 1) *
      0.000383495208F);
  }

  for (b_k = 0; b_k < 2047; b_k++) {
    rtDW.costab1q_g[b_k + 2049] = std::sin((2047.0F - static_cast<float>(b_k)) *
      0.000383495208F);
  }

  rtDW.costab1q_g[4096] = 0.0F;
  rtDW.b_costab_m[0] = 1.0F;
  rtDW.b_sintab_n[0] = 0.0F;
  for (b_k = 0; b_k < 4096; b_k++) {
    nt_im = rtDW.costab1q_g[4095 - b_k];
    rtDW.b_sintabinv_p[b_k + 1] = nt_im;
    b_sintabinv_tmp = rtDW.costab1q_g[b_k + 1];
    rtDW.b_sintabinv_p[b_k + 4097] = b_sintabinv_tmp;
    rtDW.b_costab_m[b_k + 1] = b_sintabinv_tmp;
    rtDW.b_sintab_n[b_k + 1] = -nt_im;
    rtDW.b_costab_m[b_k + 4097] = -nt_im;
    rtDW.b_sintab_n[b_k + 4097] = -b_sintabinv_tmp;
  }

  rt = 0;
  rtDW.wwc_m[2999].re = 1.0F;
  rtDW.wwc_m[2999].im = 0.0F;
  for (b_k = 0; b_k < 2999; b_k++) {
    y_0 = ((b_k + 1) << 1) - 1;
    if (6000 - rt <= y_0) {
      rt = (y_0 + rt) - 6000;
    } else {
      rt += y_0;
    }

    nt_im = -3.14159274F * static_cast<float>(rt) / 3000.0F;
    rtDW.wwc_m[2998 - b_k].re = std::cos(nt_im);
    rtDW.wwc_m[2998 - b_k].im = -std::sin(nt_im);
  }

  for (b_k = 2998; b_k >= 0; b_k--) {
    rtDW.wwc_m[b_k + 3000] = rtDW.wwc_m[2998 - b_k];
  }

  FFTImplementationCallback_d_j3x(x, 0, y, rtDW.wwc_m, rtDW.b_costab_m,
    rtDW.b_sintab_n, rtDW.b_costab_m, rtDW.b_sintabinv_p);
}

void SmartMicDrvTsk_Ccode::FFTImplementationCallback_doblu(const creal32_T x
  [6000], const float costab[8193], const float sintab[8193], const float
  sintabinv[8193], creal32_T y[6000])
{
  float nt_im;
  float nt_re;
  float twid_im;
  float twid_re;
  float wwc_im;
  int32_t iheight;
  int32_t ihi;
  int32_t istart;
  int32_t iy;
  int32_t ju;
  int32_t k;
  int32_t nt_re_tmp_tmp;
  int32_t rt;
  bool tst;
  rt = 0;
  rtDW.wwc_c[5999].re = 1.0F;
  rtDW.wwc_c[5999].im = 0.0F;
  for (ju = 0; ju < 5999; ju++) {
    iy = ((ju + 1) << 1) - 1;
    if (12000 - rt <= iy) {
      rt = (iy + rt) - 12000;
    } else {
      rt += iy;
    }

    nt_im = 3.14159274F * static_cast<float>(rt) / 6000.0F;
    rtDW.wwc_c[5998 - ju].re = std::cos(nt_im);
    rtDW.wwc_c[5998 - ju].im = -std::sin(nt_im);
  }

  for (rt = 5998; rt >= 0; rt--) {
    rtDW.wwc_c[rt + 6000] = rtDW.wwc_c[5998 - rt];
  }

  for (ju = 0; ju < 6000; ju++) {
    twid_re = x[ju].re;
    twid_im = x[ju].im;
    nt_re = rtDW.wwc_c[ju + 5999].re;
    nt_im = rtDW.wwc_c[ju + 5999].im;
    y[ju].re = nt_re * twid_re + nt_im * twid_im;
    y[ju].im = nt_re * twid_im - nt_im * twid_re;
  }

  std::memset(&rtDW.fy_k[0], 0, sizeof(creal32_T) << 14U);
  iy = 0;
  ju = 0;
  for (rt = 0; rt < 5999; rt++) {
    rtDW.fy_k[iy] = y[rt];
    iy = 16384;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  rtDW.fy_k[iy] = y[5999];
  for (rt = 0; rt <= 16382; rt += 2) {
    twid_re = rtDW.fy_k[rt + 1].re;
    twid_im = rtDW.fy_k[rt + 1].im;
    nt_re = rtDW.fy_k[rt].re;
    nt_im = rtDW.fy_k[rt].im;
    rtDW.fy_k[rt + 1].re = nt_re - twid_re;
    rtDW.fy_k[rt + 1].im = nt_im - twid_im;
    rtDW.fy_k[rt].re = nt_re + twid_re;
    rtDW.fy_k[rt].im = nt_im + twid_im;
  }

  ju = 2;
  iy = 4;
  k = 4096;
  iheight = 16381;
  while (k > 0) {
    for (rt = 0; rt < iheight; rt += iy) {
      istart = rt + ju;
      nt_re = rtDW.fy_k[istart].re;
      nt_im = rtDW.fy_k[istart].im;
      rtDW.fy_k[istart].re = rtDW.fy_k[rt].re - nt_re;
      rtDW.fy_k[istart].im = rtDW.fy_k[rt].im - nt_im;
      rtDW.fy_k[rt].re += nt_re;
      rtDW.fy_k[rt].im += nt_im;
    }

    istart = 1;
    for (int32_t j{k}; j < 8192; j += k) {
      twid_re = costab[j];
      twid_im = sintab[j];
      rt = istart;
      ihi = istart + iheight;
      while (rt < ihi) {
        nt_re_tmp_tmp = rt + ju;
        nt_im = rtDW.fy_k[nt_re_tmp_tmp].im;
        wwc_im = rtDW.fy_k[nt_re_tmp_tmp].re;
        nt_re = wwc_im * twid_re - nt_im * twid_im;
        nt_im = nt_im * twid_re + wwc_im * twid_im;
        rtDW.fy_k[nt_re_tmp_tmp].re = rtDW.fy_k[rt].re - nt_re;
        rtDW.fy_k[nt_re_tmp_tmp].im = rtDW.fy_k[rt].im - nt_im;
        rtDW.fy_k[rt].re += nt_re;
        rtDW.fy_k[rt].im += nt_im;
        rt += iy;
      }

      istart++;
    }

    k /= 2;
    ju = iy;
    iy += iy;
    iheight -= ju;
  }

  std::memset(&rtDW.fv_c[0], 0, sizeof(creal32_T) << 14U);
  iy = 0;
  ju = 0;
  for (rt = 0; rt < 11998; rt++) {
    rtDW.fv_c[iy] = rtDW.wwc_c[rt];
    iy = 16384;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  rtDW.fv_c[iy] = rtDW.wwc_c[11998];
  for (rt = 0; rt <= 16382; rt += 2) {
    twid_re = rtDW.fv_c[rt + 1].re;
    twid_im = rtDW.fv_c[rt + 1].im;
    nt_re = rtDW.fv_c[rt].re;
    nt_im = rtDW.fv_c[rt].im;
    rtDW.fv_c[rt + 1].re = nt_re - twid_re;
    rtDW.fv_c[rt + 1].im = nt_im - twid_im;
    rtDW.fv_c[rt].re = nt_re + twid_re;
    rtDW.fv_c[rt].im = nt_im + twid_im;
  }

  ju = 2;
  iy = 4;
  k = 4096;
  iheight = 16381;
  while (k > 0) {
    for (rt = 0; rt < iheight; rt += iy) {
      istart = rt + ju;
      nt_re = rtDW.fv_c[istart].re;
      nt_im = rtDW.fv_c[istart].im;
      rtDW.fv_c[istart].re = rtDW.fv_c[rt].re - nt_re;
      rtDW.fv_c[istart].im = rtDW.fv_c[rt].im - nt_im;
      rtDW.fv_c[rt].re += nt_re;
      rtDW.fv_c[rt].im += nt_im;
    }

    istart = 1;
    for (int32_t j{k}; j < 8192; j += k) {
      twid_re = costab[j];
      twid_im = sintab[j];
      rt = istart;
      ihi = istart + iheight;
      while (rt < ihi) {
        nt_re_tmp_tmp = rt + ju;
        nt_im = rtDW.fv_c[nt_re_tmp_tmp].im;
        wwc_im = rtDW.fv_c[nt_re_tmp_tmp].re;
        nt_re = wwc_im * twid_re - nt_im * twid_im;
        nt_im = nt_im * twid_re + wwc_im * twid_im;
        rtDW.fv_c[nt_re_tmp_tmp].re = rtDW.fv_c[rt].re - nt_re;
        rtDW.fv_c[nt_re_tmp_tmp].im = rtDW.fv_c[rt].im - nt_im;
        rtDW.fv_c[rt].re += nt_re;
        rtDW.fv_c[rt].im += nt_im;
        rt += iy;
      }

      istart++;
    }

    k /= 2;
    ju = iy;
    iy += iy;
    iheight -= ju;
  }

  for (rt = 0; rt < 16384; rt++) {
    twid_re = rtDW.fy_k[rt].re;
    twid_im = rtDW.fy_k[rt].im;
    nt_re = rtDW.fv_c[rt].im;
    nt_im = rtDW.fv_c[rt].re;
    rtDW.fy_k[rt].re = twid_re * nt_im - twid_im * nt_re;
    rtDW.fy_k[rt].im = twid_re * nt_re + twid_im * nt_im;
  }

  iy = 0;
  ju = 0;
  for (rt = 0; rt < 16383; rt++) {
    rtDW.fv_c[iy] = rtDW.fy_k[rt];
    iy = 16384;
    tst = true;
    while (tst) {
      iy >>= 1;
      ju ^= iy;
      tst = ((ju & iy) == 0);
    }

    iy = ju;
  }

  rtDW.fv_c[iy] = rtDW.fy_k[16383];
  for (rt = 0; rt <= 16382; rt += 2) {
    twid_re = rtDW.fv_c[rt + 1].re;
    twid_im = rtDW.fv_c[rt + 1].im;
    nt_re = rtDW.fv_c[rt].re;
    nt_im = rtDW.fv_c[rt].im;
    rtDW.fv_c[rt + 1].re = nt_re - twid_re;
    rtDW.fv_c[rt + 1].im = nt_im - twid_im;
    rtDW.fv_c[rt].re = nt_re + twid_re;
    rtDW.fv_c[rt].im = nt_im + twid_im;
  }

  ju = 2;
  iy = 4;
  k = 4096;
  iheight = 16381;
  while (k > 0) {
    for (rt = 0; rt < iheight; rt += iy) {
      istart = rt + ju;
      nt_re = rtDW.fv_c[istart].re;
      nt_im = rtDW.fv_c[istart].im;
      rtDW.fv_c[istart].re = rtDW.fv_c[rt].re - nt_re;
      rtDW.fv_c[istart].im = rtDW.fv_c[rt].im - nt_im;
      rtDW.fv_c[rt].re += nt_re;
      rtDW.fv_c[rt].im += nt_im;
    }

    istart = 1;
    for (int32_t j{k}; j < 8192; j += k) {
      twid_re = costab[j];
      twid_im = sintabinv[j];
      rt = istart;
      ihi = istart + iheight;
      while (rt < ihi) {
        nt_re_tmp_tmp = rt + ju;
        nt_im = rtDW.fv_c[nt_re_tmp_tmp].im;
        wwc_im = rtDW.fv_c[nt_re_tmp_tmp].re;
        nt_re = wwc_im * twid_re - nt_im * twid_im;
        nt_im = nt_im * twid_re + wwc_im * twid_im;
        rtDW.fv_c[nt_re_tmp_tmp].re = rtDW.fv_c[rt].re - nt_re;
        rtDW.fv_c[nt_re_tmp_tmp].im = rtDW.fv_c[rt].im - nt_im;
        rtDW.fv_c[rt].re += nt_re;
        rtDW.fv_c[rt].im += nt_im;
        rt += iy;
      }

      istart++;
    }

    k /= 2;
    ju = iy;
    iy += iy;
    iheight -= ju;
  }

  for (rt = 0; rt < 16384; rt++) {
    rtDW.fv_c[rt].re *= 6.10351562E-5F;
    rtDW.fv_c[rt].im *= 6.10351562E-5F;
  }

  for (k = 0; k < 6000; k++) {
    nt_im = rtDW.wwc_c[k + 5999].re;
    wwc_im = rtDW.wwc_c[k + 5999].im;
    twid_re = rtDW.fv_c[k + 5999].re;
    twid_im = rtDW.fv_c[k + 5999].im;
    nt_re = nt_im * twid_re + wwc_im * twid_im;
    twid_re = nt_im * twid_im - wwc_im * twid_re;
    if (twid_re == 0.0F) {
      y[k].re = nt_re / 6000.0F;
      y[k].im = 0.0F;
    } else if (nt_re == 0.0F) {
      y[k].re = 0.0F;
      y[k].im = twid_re / 6000.0F;
    } else {
      y[k].re = nt_re / 6000.0F;
      y[k].im = twid_re / 6000.0F;
    }
  }
}

void SmartMicDrvTsk_Ccode::emxFreeStruct_c_GAL2(c_GAL2 *pStruct)
{
  emxFree_creal32_T(&pStruct->K);
  emxFree_creal32_T(&pStruct->f);
  emxFree_creal32_T(&pStruct->b);
  emxFree_float_j(&pStruct->mu);
  emxFree_creal32_T(&pStruct->G);
}

void SmartMicDrvTsk_Ccode::emxFreeStruct_LinearAECSystem(LinearAECSystem
  *pStruct)
{
  emxFreeStruct_c_GAL2(&pStruct->H);
}

void SmartMicDrvTsk_Ccode::emxInitStruct_c_GAL2(c_GAL2 *pStruct)
{
  emxInit_creal32_T(&pStruct->K, 2);
  emxInit_creal32_T(&pStruct->f, 2);
  emxInit_creal32_T(&pStruct->b, 2);
  emxInit_float_j(&pStruct->mu, 2);
  emxInit_creal32_T(&pStruct->G, 2);
}

void SmartMicDrvTsk_Ccode::emxInitStruct_LinearAECSystem(LinearAECSystem
  *pStruct)
{
  emxInitStruct_c_GAL2(&pStruct->H);
}

void SmartMicDrvTsk_Ccode::iFFTSystem_setupImpl(iFFTSystem *obj)
{
  cell_wrap varSizes;
  h_dsp_internal_AsyncBuffercgHel *obj_0;
  double b_tmp;
  float tmp[480];
  int32_t i;
  int16_t inSize[8];
  bool exitg1;

  //  Perform one-time calculations, such as computing constants
  //  Prepare the overlap buffer
  obj->buff.pBuffer.NumChannels = -1;
  obj->buff.pBuffer.isInitialized = 0;
  obj->buff.pBuffer.matlabCodegenIsDeleted = false;
  obj->buff.matlabCodegenIsDeleted = false;
  obj_0 = &obj->buff.pBuffer;
  if (obj->buff.pBuffer.isInitialized != 1) {
    obj->buff.pBuffer.isSetupComplete = false;
    obj->buff.pBuffer.isInitialized = 1;
    varSizes.f1[0] = 480U;
    varSizes.f1[1] = 1U;
    for (i = 0; i < 6; i++) {
      varSizes.f1[i + 2] = 1U;
    }

    obj->buff.pBuffer.inputVarSize = varSizes;
    obj->buff.pBuffer.NumChannels = 1;
    obj->buff.pBuffer.AsyncBuffercgHelper_isInitialized = true;
    for (i = 0; i < 192001; i++) {
      obj->buff.pBuffer.Cache[i] = 0.0F;
    }

    obj->buff.pBuffer.isSetupComplete = true;
    obj->buff.pBuffer.ReadPointer = 1;
    obj->buff.pBuffer.WritePointer = 2;
    obj->buff.pBuffer.CumulativeOverrun = 0;
    obj->buff.pBuffer.CumulativeUnderrun = 0;
    for (i = 0; i < 192001; i++) {
      obj->buff.pBuffer.Cache[i] = 0.0F;
    }
  }

  inSize[0] = 480;
  inSize[1] = 1;
  for (i = 0; i < 6; i++) {
    inSize[i + 2] = 1;
  }

  i = 0;
  exitg1 = false;
  while ((!exitg1) && (i < 8)) {
    if (obj_0->inputVarSize.f1[i] != static_cast<uint32_t>(inSize[i])) {
      for (i = 0; i < 8; i++) {
        obj_0->inputVarSize.f1[i] = static_cast<uint32_t>(inSize[i]);
      }

      exitg1 = true;
    } else {
      i++;
    }
  }

  std::memset(&tmp[0], 0, 480U * sizeof(float));
  AsyncBuffercgHelper_write_j(&obj->buff.pBuffer, tmp);
  for (i = 0; i < 960; i++) {
    b_tmp = std::sin((static_cast<double>(i) + 0.5) * 1.5707963267948966 / 480.0);
    rtDW.b[i] = std::sin(1.5707963267948966 * b_tmp * b_tmp);
  }

  for (i = 0; i < 960; i++) {
    obj->hs[i] = rtDW.b[i];
  }

  //  hann(2*obj.frame_len);
}

// OutputUpdate for Task: Periodic_TSK_2
void SmartMicDrvTsk_Ccode::Periodic_TSK_2_step(void) // Sample time: [0.01s, 0.0s] 
{
  // local block i/o variables
  float rtb_TmpTaskTransAtDownSamplerIn[480];
  float rtb_TmpTaskTransAtDownSampler_c[480];

  // Update the flag to indicate when data transfers from
  //   Sample time: [0.01s, 0.0s] to Sample time: [0.5s, 0.0s]
  ((&task_M[0])->Timing.RateInteraction.TID0_1)++;
  if (((&task_M[0])->Timing.RateInteraction.TID0_1) > 49) {
    (&task_M[0])->Timing.RateInteraction.TID0_1 = 0;
  }

  {
    emxArray_creal32_T *b_;
    emxArray_creal32_T *b__tmp;
    emxArray_creal32_T *tmp;
    emxArray_float *mu1;
    emxArray_float *old_b2_;
    creal32_T e__data[80];
    creal32_T rtb_TmpTaskTransAtLinearBandHIn[80];
    creal32_T rtb_TmpTaskTransAtLinearBandH_h[80];
    creal32_T rtb_TmpTaskTransAtLinearBand_e4[80];
    creal32_T rtb_TmpTaskTransAtLinearBand_nc[80];
    float D2[80];
    float E2[80];
    float p_data[80];
    float forgettingfactor_;
    float im;
    float mu1_tmp;
    float mu1_tmp_0;
    float re;
    int32_t q_data[80];
    int32_t q_data_0[80];
    int32_t b__tmp_0;
    int32_t b__tmp_1;
    int32_t i;
    int32_t loop_ub;
    int32_t q_size;
    int32_t v_tmp;

    // TaskTransBlk generated from: '<Root>/DownSampler'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_51);
    for (i = 0; i < 480; i++) {
      // TaskTransBlk generated from: '<Root>/DownSampler'
      rtb_TmpTaskTransAtDownSamplerIn[i] =
        rtDW.TmpTaskTransAtInputSubsystemOut[i];
    }

    // TaskTransBlk generated from: '<Root>/DownSampler'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_61);
    for (i = 0; i < 480; i++) {
      // TaskTransBlk generated from: '<Root>/DownSampler'
      rtb_TmpTaskTransAtDownSampler_c[i] =
        rtDW.TmpTaskTransAtInputSubsystemO_n[i];
    }

    // Outputs for Atomic SubSystem: '<Root>/DownSampler'
    SampleRateConverter(rtb_TmpTaskTransAtDownSamplerIn,
                        &rtDW.SampleRateConverter_p);
    MATLABSystem(rtDW.SampleRateConverter_p.SampleRateConverter_b,
                 &rtDW.MATLABSystem_p);
    SampleRateConverter(rtb_TmpTaskTransAtDownSampler_c,
                        &rtDW.SampleRateConverter1);
    MATLABSystem(rtDW.SampleRateConverter1.SampleRateConverter_b,
                 &rtDW.MATLABSystem2);

    // End of Outputs for SubSystem: '<Root>/DownSampler'

    // TaskTransBlk generated from: '<Root>/DownSampler' incorporates:
    //   MATLABSystem: '<S1>/MATLAB System'

    for (i = 0; i < 6000; i++) {
      rtDW.TmpTaskTransAtDownSamplerOutpor[i] =
        rtDW.MATLABSystem_p.MATLABSystem_o1[i];
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_11);

    // End of TaskTransBlk generated from: '<Root>/DownSampler'

    // TaskTransBlk generated from: '<Root>/DownSampler'
    rtDW.TmpTaskTransAtDownSamplerOutp_g = rtDW.MATLABSystem_p.MATLABSystem_o2;
    rtw_pthread_sem_post_mac(rtDW.sw_buf_21);

    // TaskTransBlk generated from: '<Root>/DownSampler' incorporates:
    //   MATLABSystem: '<S1>/MATLAB System2'

    for (i = 0; i < 6000; i++) {
      rtDW.TmpTaskTransAtDownSamplerOutp_i[i] =
        rtDW.MATLABSystem2.MATLABSystem_o1[i];
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_31);

    // End of TaskTransBlk generated from: '<Root>/DownSampler'

    // TaskTransBlk generated from: '<Root>/DownSampler'
    rtDW.TmpTaskTransAtDownSamplerOutp_p = rtDW.MATLABSystem2.MATLABSystem_o2;
    rtw_pthread_sem_post_mac(rtDW.sw_buf_41);

    // TaskTransBlk generated from: '<Root>/LinearBandH'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_91);
    for (i = 0; i < 80; i++) {
      rtb_TmpTaskTransAtLinearBandHIn[i] =
        rtDW.TmpTaskTransAtTransformSubsyste[i];
    }

    // End of TaskTransBlk generated from: '<Root>/LinearBandH'

    // TaskTransBlk generated from: '<Root>/LinearBandH'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_101);
    for (i = 0; i < 80; i++) {
      rtb_TmpTaskTransAtLinearBand_e4[i] =
        rtDW.TmpTaskTransAtTransformSubsys_k[i];
    }

    // End of TaskTransBlk generated from: '<Root>/LinearBandH'

    // TaskTransBlk generated from: '<Root>/LinearBandH'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_111);
    for (i = 0; i < 80; i++) {
      rtb_TmpTaskTransAtLinearBand_nc[i] =
        rtDW.TmpTaskTransAtTransformSubsys_b[i];
    }

    // End of TaskTransBlk generated from: '<Root>/LinearBandH'

    // TaskTransBlk generated from: '<Root>/LinearBandH'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_121);
    for (i = 0; i < 80; i++) {
      rtb_TmpTaskTransAtLinearBandH_h[i] =
        rtDW.TmpTaskTransAtTransformSubsys_g[i];
    }

    // End of TaskTransBlk generated from: '<Root>/LinearBandH'

    // TaskTransBlk generated from: '<Root>/LinearBandH'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_131);

    // TaskTransBlk generated from: '<Root>/LinearBandH'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_141);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System6'
    if (rtDW.obj_d.alphaDT != 0.015) {
      rtDW.obj_d.alphaDT = 0.015;
    }

    if (rtDW.obj_d.alphaFEST != 0.15) {
      rtDW.obj_d.alphaFEST = 0.15;
    }

    if (rtDW.obj_d.dBignore != -50.0) {
      rtDW.obj_d.dBignore = -50.0;
    }

    //  Implement algorithm. Calculate y as a function of input u and
    //  discrete states.
    //  X signal
    forgettingfactor_ = static_cast<float>(rtDW.obj_d.alphaDT -
      rtDW.obj_d.alphaFEST) + static_cast<float>(rtDW.obj_d.alphaFEST);

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    // stepSpeaker Summary of this method goes here
    //    Detailed explanation goes here
    emxInit_creal32_T(&b__tmp, 2);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System6'
    q_size = b__tmp->size[0] * b__tmp->size[1];
    b__tmp->size[0] = rtDW.obj_d.H.b->size[0];
    b__tmp->size[1] = rtDW.obj_d.H.b->size[1];
    emxEnsureCapacity_creal32_T(b__tmp, q_size);
    loop_ub = rtDW.obj_d.H.b->size[0] * rtDW.obj_d.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      b__tmp->data[i] = rtDW.obj_d.H.b->data[i];
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    emxInit_creal32_T(&b_, 2);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System6'
    q_size = b_->size[0] * b_->size[1];
    b_->size[0] = rtDW.obj_d.H.b->size[0];
    b_->size[1] = rtDW.obj_d.H.b->size[1];
    emxEnsureCapacity_creal32_T(b_, q_size);
    loop_ub = rtDW.obj_d.H.b->size[0] * rtDW.obj_d.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      b_->data[i] = rtDW.obj_d.H.b->data[i];
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    emxInit_float_j(&old_b2_, 2);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System6' incorporates:
    //   TaskTransBlk generated from: '<Root>/LinearBandH'

    q_size = old_b2_->size[0] * old_b2_->size[1];
    old_b2_->size[0] = rtDW.obj_d.H.b->size[0];
    old_b2_->size[1] = rtDW.obj_d.H.b->size[1];
    emxEnsureCapacity_float_j(old_b2_, q_size);
    loop_ub = rtDW.obj_d.H.b->size[0] * rtDW.obj_d.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      old_b2_->data[i] = rtDW.obj_d.H.b->data[i].re * rtDW.obj_d.H.b->data[i].re
        - rtDW.obj_d.H.b->data[i].im * -rtDW.obj_d.H.b->data[i].im;
    }

    b__tmp_0 = rtDW.obj_d.H.f->size[0];
    for (i = 0; i < b__tmp_0; i++) {
      rtDW.obj_d.H.f->data[i] = rtb_TmpTaskTransAtLinearBandHIn[i];
    }

    b__tmp_0 = rtDW.obj_d.H.b->size[0];
    if (b__tmp_0 - 1 >= 0) {
      std::memcpy(&b_->data[0], &rtb_TmpTaskTransAtLinearBandHIn[0],
                  static_cast<uint32_t>(b__tmp_0) * sizeof(creal32_T));
    }

    b__tmp_1 = static_cast<int32_t>((rtDW.obj_d.H.ntap + 1.0) - 1.0) - 1;

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    emxInit_creal32_T(&tmp, 1);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System6'
    for (b__tmp_0 = 0; b__tmp_0 <= b__tmp_1; b__tmp_0++) {
      //  Lattice signal
      loop_ub = rtDW.obj_d.H.f->size[0];
      if ((rtDW.obj_d.H.K->size[0] == rtDW.obj_d.H.b->size[0]) &&
          ((rtDW.obj_d.H.K->size[0] == 1 ? rtDW.obj_d.H.b->size[0] :
            rtDW.obj_d.H.K->size[0]) == rtDW.obj_d.H.f->size[0])) {
        q_size = tmp->size[0];
        tmp->size[0] = rtDW.obj_d.H.f->size[0];
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = rtDW.obj_d.H.K->data[(static_cast<int32_t>((static_cast<
            double>(b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_d.H.K->size[0] + i].
            re;
          mu1_tmp_0 = rtDW.obj_d.H.b->data[(static_cast<int32_t>((static_cast<
            double>(b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_d.H.b->size[0] + i].
            im;
          re = rtDW.obj_d.H.K->data[(static_cast<int32_t>((static_cast<double>
            (b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_d.H.K->size[0] + i].im;
          im = rtDW.obj_d.H.b->data[(static_cast<int32_t>((static_cast<double>
            (b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_d.H.b->size[0] + i].re;
          tmp->data[i].re = rtDW.obj_d.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 2.0) - 1.0) - 1) *
            rtDW.obj_d.H.f->size[0] + i].re - (mu1_tmp * im - re * mu1_tmp_0);
          tmp->data[i].im = rtDW.obj_d.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 2.0) - 1.0) - 1) *
            rtDW.obj_d.H.f->size[0] + i].im - (mu1_tmp * mu1_tmp_0 + re * im);
        }

        loop_ub = tmp->size[0];
        for (i = 0; i < loop_ub; i++) {
          rtDW.obj_d.H.f->data[i + rtDW.obj_d.H.f->size[0] * (b__tmp_0 + 1)] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j(&rtDW.obj_d, b__tmp_0);
      }

      loop_ub = rtDW.obj_d.H.b->size[0];
      if ((rtDW.obj_d.H.K->size[0] == rtDW.obj_d.H.f->size[0]) &&
          ((rtDW.obj_d.H.K->size[0] == 1 ? rtDW.obj_d.H.f->size[0] :
            rtDW.obj_d.H.K->size[0]) == rtDW.obj_d.H.b->size[0])) {
        for (i = 0; i < loop_ub; i++) {
          re = rtDW.obj_d.H.K->data[(static_cast<int32_t>((static_cast<double>
            (b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_d.H.K->size[0] + i].re;
          im = -rtDW.obj_d.H.K->data[(static_cast<int32_t>((static_cast<double>
            (b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_d.H.K->size[0] + i].im;
          mu1_tmp = rtDW.obj_d.H.f->data[(static_cast<int32_t>((static_cast<
            double>(b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_d.H.f->size[0] + i].
            im;
          mu1_tmp_0 = rtDW.obj_d.H.f->data[(static_cast<int32_t>((static_cast<
            double>(b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_d.H.f->size[0] + i].
            re;
          b_->data[i + b_->size[0] * (b__tmp_0 + 1)].re = rtDW.obj_d.H.b->data[(
            static_cast<int32_t>((static_cast<double>(b__tmp_0) + 2.0) - 1.0) -
            1) * rtDW.obj_d.H.b->size[0] + i].re - (mu1_tmp_0 * re - mu1_tmp *
            im);
          b_->data[i + b_->size[0] * (b__tmp_0 + 1)].im = rtDW.obj_d.H.b->data[(
            static_cast<int32_t>((static_cast<double>(b__tmp_0) + 2.0) - 1.0) -
            1) * rtDW.obj_d.H.b->size[0] + i].im - (mu1_tmp * re + mu1_tmp_0 *
            im);
        }
      } else {
        binary_expand_op(b_, b__tmp_0, &rtDW.obj_d);
      }
    }

    q_size = rtDW.obj_d.H.b->size[0] * rtDW.obj_d.H.b->size[1];
    rtDW.obj_d.H.b->size[0] = b_->size[0];
    rtDW.obj_d.H.b->size[1] = b_->size[1];
    emxEnsureCapacity_creal32_T(rtDW.obj_d.H.b, q_size);
    loop_ub = b_->size[0] * b_->size[1];
    for (b__tmp_1 = 0; b__tmp_1 < loop_ub; b__tmp_1++) {
      rtDW.obj_d.H.b->data[b__tmp_1] = b_->data[b__tmp_1];
    }

    v_tmp = static_cast<int32_t>(rtDW.obj_d.H.ntap) - 1;

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    emxInit_float_j(&mu1, 1);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System6' incorporates:
    //   TaskTransBlk generated from: '<Root>/LinearBandH'

    for (b__tmp_0 = 0; b__tmp_0 <= v_tmp; b__tmp_0++) {
      //  Step size recursion
      loop_ub = rtDW.obj_d.H.mu->size[0];
      if ((rtDW.obj_d.H.f->size[0] == old_b2_->size[0]) &&
          ((rtDW.obj_d.H.f->size[0] == 1 ? old_b2_->size[0] :
            rtDW.obj_d.H.f->size[0]) == rtDW.obj_d.H.mu->size[0])) {
        q_size = mu1->size[0];
        mu1->size[0] = rtDW.obj_d.H.mu->size[0];
        emxEnsureCapacity_float_j(mu1, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = rtDW.obj_d.H.f->data[rtDW.obj_d.H.f->size[0] * b__tmp_0 + i]
            .re;
          mu1_tmp_0 = rtDW.obj_d.H.f->data[rtDW.obj_d.H.f->size[0] * b__tmp_0 +
            i].im;
          mu1->data[i] = 1.0F / rtDW.obj_d.H.mu->data[rtDW.obj_d.H.mu->size[0] *
            b__tmp_0 + i] * (1.0F - forgettingfactor_) + ((mu1_tmp * mu1_tmp -
            mu1_tmp_0 * -mu1_tmp_0) + old_b2_->data[old_b2_->size[0] * b__tmp_0
            + i]);
        }
      } else {
        binary_expand_op_j3x(mu1, forgettingfactor_, &rtDW.obj_d, b__tmp_0,
                             old_b2_);
      }

      b__tmp_1 = mu1->size[0] - 1;
      for (i = 0; i <= b__tmp_1; i++) {
        if (mu1->data[i] < 1.0E-8) {
          mu1->data[i] = 1.0E-8F;
        }
      }

      loop_ub = mu1->size[0];
      for (i = 0; i < loop_ub; i++) {
        rtDW.obj_d.H.mu->data[i + rtDW.obj_d.H.mu->size[0] * b__tmp_0] = 1.0F /
          mu1->data[i];
      }

      //  PARCOR recursion
      loop_ub = rtDW.obj_d.H.K->size[0];
      i = rtDW.obj_d.H.f->size[0] == 1 ? b__tmp->size[0] : rtDW.obj_d.H.f->size
        [0];
      q_size = b_->size[0] == 1 ? rtDW.obj_d.H.f->size[0] : b_->size[0];
      b__tmp_1 = i == 1 ? q_size : i;
      if ((rtDW.obj_d.H.f->size[0] == b__tmp->size[0]) && (b_->size[0] ==
           rtDW.obj_d.H.f->size[0]) && (i == q_size) && (b__tmp_1 ==
           rtDW.obj_d.H.mu->size[0]) && ((rtDW.obj_d.H.mu->size[0] == 1 ?
            b__tmp_1 : rtDW.obj_d.H.mu->size[0]) == rtDW.obj_d.H.K->size[0])) {
        q_size = tmp->size[0];
        tmp->size[0] = rtDW.obj_d.H.K->size[0];
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = b__tmp->data[b__tmp->size[0] * b__tmp_0 + i].re;
          mu1_tmp_0 = -b__tmp->data[b__tmp->size[0] * b__tmp_0 + i].im;
          re = b_->data[(static_cast<int32_t>((static_cast<double>(b__tmp_0) +
            1.0) + 1.0) - 1) * b_->size[0] + i].re;
          im = -b_->data[(static_cast<int32_t>((static_cast<double>(b__tmp_0) +
            1.0) + 1.0) - 1) * b_->size[0] + i].im;
          tmp->data[i].re = ((rtDW.obj_d.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 1.0) + 1.0) - 1) *
                              rtDW.obj_d.H.f->size[0] + i].re * mu1_tmp -
                              rtDW.obj_d.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 1.0) + 1.0) - 1) *
                              rtDW.obj_d.H.f->size[0] + i].im * mu1_tmp_0) +
                             (rtDW.obj_d.H.f->data[rtDW.obj_d.H.f->size[0] *
                              b__tmp_0 + i].re * re - rtDW.obj_d.H.f->
                              data[rtDW.obj_d.H.f->size[0] * b__tmp_0 + i].im *
                              im)) * rtDW.obj_d.H.mu->data[rtDW.obj_d.H.mu->
            size[0] * b__tmp_0 + i] + rtDW.obj_d.H.K->data[rtDW.obj_d.H.K->size
            [0] * b__tmp_0 + i].re;
          tmp->data[i].im = ((rtDW.obj_d.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 1.0) + 1.0) - 1) *
                              rtDW.obj_d.H.f->size[0] + i].re * mu1_tmp_0 +
                              rtDW.obj_d.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 1.0) + 1.0) - 1) *
                              rtDW.obj_d.H.f->size[0] + i].im * mu1_tmp) +
                             (rtDW.obj_d.H.f->data[rtDW.obj_d.H.f->size[0] *
                              b__tmp_0 + i].im * re + rtDW.obj_d.H.f->
                              data[rtDW.obj_d.H.f->size[0] * b__tmp_0 + i].re *
                              im)) * rtDW.obj_d.H.mu->data[rtDW.obj_d.H.mu->
            size[0] * b__tmp_0 + i] + rtDW.obj_d.H.K->data[rtDW.obj_d.H.K->size
            [0] * b__tmp_0 + i].im;
        }

        loop_ub = tmp->size[0];
        for (i = 0; i < loop_ub; i++) {
          rtDW.obj_d.H.K->data[i + rtDW.obj_d.H.K->size[0] * b__tmp_0] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j3(&rtDW.obj_d, b__tmp_0, b__tmp, b_);
      }
    }

    //  One speaker
    // stepMic Summary of this method goes here
    //    Detailed explanation goes here
    //  Y - Reconstructed speaker channel
    //  E - Near end signal
    //  Start with am empty FE
    std::memcpy(&rtb_TmpTaskTransAtLinearBandHIn[0],
                &rtb_TmpTaskTransAtLinearBand_e4[0], 80U * sizeof(creal32_T));

    //  Start with a non echo cancelled NE
    for (b__tmp_0 = 0; b__tmp_0 <= v_tmp; b__tmp_0++) {
      //  Combiner
      //  Reconstruct the FE
      if ((rtDW.obj_d.H.G->size[0] == rtDW.obj_d.H.b->size[0]) &&
          ((rtDW.obj_d.H.G->size[0] == 1 ? rtDW.obj_d.H.b->size[0] :
            rtDW.obj_d.H.G->size[0]) == 80)) {
        for (i = 0; i < 80; i++) {
          forgettingfactor_ = rtDW.obj_d.H.G->data[rtDW.obj_d.H.G->size[0] *
            b__tmp_0 + i].re;
          mu1_tmp = rtDW.obj_d.H.b->data[rtDW.obj_d.H.b->size[0] * b__tmp_0 + i]
            .re;
          mu1_tmp_0 = rtDW.obj_d.H.G->data[rtDW.obj_d.H.G->size[0] * b__tmp_0 +
            i].im;
          re = rtDW.obj_d.H.b->data[rtDW.obj_d.H.b->size[0] * b__tmp_0 + i].im;
          rtb_TmpTaskTransAtLinearBandHIn[i].re -= forgettingfactor_ * mu1_tmp -
            mu1_tmp_0 * re;
          rtb_TmpTaskTransAtLinearBandHIn[i].im -= forgettingfactor_ * re +
            mu1_tmp_0 * mu1_tmp;
        }
      } else {
        binary_expand_op_j3xz2e4k(rtb_TmpTaskTransAtLinearBandHIn, &rtDW.obj_d,
          b__tmp_0);
      }

      //  Remove FE from NE signal
      if ((rtDW.obj_d.H.mu->size[0] == rtDW.obj_d.H.b->size[0]) &&
          ((rtDW.obj_d.H.mu->size[0] == 1 ? rtDW.obj_d.H.b->size[0] :
            rtDW.obj_d.H.mu->size[0]) == 80) && (rtDW.obj_d.H.G->size[0] == 80))
      {
        q_size = tmp->size[0];
        tmp->size[0] = 80;
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < 80; i++) {
          re = rtDW.obj_d.H.mu->data[rtDW.obj_d.H.mu->size[0] * b__tmp_0 + i] *
            2.0F * rtDW.obj_d.H.b->data[rtDW.obj_d.H.b->size[0] * b__tmp_0 + i].
            re;
          im = rtDW.obj_d.H.mu->data[rtDW.obj_d.H.mu->size[0] * b__tmp_0 + i] *
            2.0F * -rtDW.obj_d.H.b->data[rtDW.obj_d.H.b->size[0] * b__tmp_0 + i]
            .im;
          forgettingfactor_ = rtb_TmpTaskTransAtLinearBandHIn[i].re;
          mu1_tmp = rtb_TmpTaskTransAtLinearBandHIn[i].im;
          tmp->data[i].re = (re * forgettingfactor_ - im * mu1_tmp) +
            rtDW.obj_d.H.G->data[rtDW.obj_d.H.G->size[0] * b__tmp_0 + i].re;
          tmp->data[i].im = (re * mu1_tmp + im * forgettingfactor_) +
            rtDW.obj_d.H.G->data[rtDW.obj_d.H.G->size[0] * b__tmp_0 + i].im;
          rtDW.obj_d.H.G->data[i + rtDW.obj_d.H.G->size[0] * b__tmp_0] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j3xz2e4(&rtDW.obj_d, b__tmp_0,
          rtb_TmpTaskTransAtLinearBandHIn);
      }
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    //  Make sure we do not introduce energy
    //  Avoid using abs because it is an expensive function
    b__tmp_0 = 0;

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System6' incorporates:
    //   TaskTransBlk generated from: '<Root>/LinearBandH'

    for (i = 0; i < 80; i++) {
      // TaskTransBlk generated from: '<Root>/LinearBandH'
      forgettingfactor_ = rtb_TmpTaskTransAtLinearBand_e4[i].re;
      mu1_tmp = rtb_TmpTaskTransAtLinearBand_e4[i].im;
      forgettingfactor_ = forgettingfactor_ * forgettingfactor_ - mu1_tmp *
        -mu1_tmp;
      D2[i] = forgettingfactor_;
      mu1_tmp = rtb_TmpTaskTransAtLinearBandHIn[i].re;
      mu1_tmp_0 = rtb_TmpTaskTransAtLinearBandHIn[i].im;
      mu1_tmp = mu1_tmp * mu1_tmp - mu1_tmp_0 * -mu1_tmp_0;
      E2[i] = mu1_tmp;
      if (mu1_tmp > forgettingfactor_) {
        b__tmp_0++;
      }
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    q_size = b__tmp_0;
    b__tmp_0 = 0;
    for (i = 0; i < 80; i++) {
      // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
      // MATLABSystem: '<S3>/MATLAB System6'
      if (E2[i] > D2[i]) {
        q_data[b__tmp_0] = i;
        b__tmp_0++;
      }

      // End of Outputs for SubSystem: '<Root>/LinearBandH'
    }

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System6'
    for (i = 0; i < q_size; i++) {
      b__tmp_0 = q_data[i];
      p_data[i] = D2[b__tmp_0] / E2[b__tmp_0];
    }

    b__tmp_1 = q_size - 1;
    for (i = 0; i <= b__tmp_1; i++) {
      p_data[i] = std::sqrt(p_data[i]);
    }

    for (i = 0; i < q_size; i++) {
      forgettingfactor_ = p_data[i];
      b__tmp_0 = q_data[i];
      e__data[i].re = forgettingfactor_ *
        rtb_TmpTaskTransAtLinearBandHIn[b__tmp_0].re;
      e__data[i].im = forgettingfactor_ *
        rtb_TmpTaskTransAtLinearBandHIn[b__tmp_0].im;
    }

    for (i = 0; i < q_size; i++) {
      rtb_TmpTaskTransAtLinearBandHIn[q_data[i]] = e__data[i];
    }

    // MATLABSystem: '<S3>/MATLAB System5' incorporates:
    //   TaskTransBlk generated from: '<Root>/LinearBandH'

    //  Multiple mic channels
    if (rtDW.obj_k.alphaDT != 0.02) {
      rtDW.obj_k.alphaDT = 0.02;
    }

    if (rtDW.obj_k.alphaFEST != 0.2) {
      rtDW.obj_k.alphaFEST = 0.2;
    }

    if (rtDW.obj_k.dBignore != -50.0) {
      rtDW.obj_k.dBignore = -50.0;
    }

    //  Implement algorithm. Calculate y as a function of input u and
    //  discrete states.
    //  X signal
    forgettingfactor_ = static_cast<float>(rtDW.obj_k.alphaDT -
      rtDW.obj_k.alphaFEST) + static_cast<float>(rtDW.obj_k.alphaFEST);

    // stepSpeaker Summary of this method goes here
    //    Detailed explanation goes here
    q_size = b__tmp->size[0] * b__tmp->size[1];
    b__tmp->size[0] = rtDW.obj_k.H.b->size[0];
    b__tmp->size[1] = rtDW.obj_k.H.b->size[1];
    emxEnsureCapacity_creal32_T(b__tmp, q_size);
    loop_ub = rtDW.obj_k.H.b->size[0] * rtDW.obj_k.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      b__tmp->data[i] = rtDW.obj_k.H.b->data[i];
    }

    q_size = b_->size[0] * b_->size[1];
    b_->size[0] = rtDW.obj_k.H.b->size[0];
    b_->size[1] = rtDW.obj_k.H.b->size[1];
    emxEnsureCapacity_creal32_T(b_, q_size);
    loop_ub = rtDW.obj_k.H.b->size[0] * rtDW.obj_k.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      b_->data[i] = rtDW.obj_k.H.b->data[i];
    }

    q_size = old_b2_->size[0] * old_b2_->size[1];
    old_b2_->size[0] = rtDW.obj_k.H.b->size[0];
    old_b2_->size[1] = rtDW.obj_k.H.b->size[1];
    emxEnsureCapacity_float_j(old_b2_, q_size);
    loop_ub = rtDW.obj_k.H.b->size[0] * rtDW.obj_k.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      old_b2_->data[i] = rtDW.obj_k.H.b->data[i].re * rtDW.obj_k.H.b->data[i].re
        - rtDW.obj_k.H.b->data[i].im * -rtDW.obj_k.H.b->data[i].im;
    }

    b__tmp_0 = rtDW.obj_k.H.f->size[0];
    for (i = 0; i < b__tmp_0; i++) {
      rtDW.obj_k.H.f->data[i] = rtb_TmpTaskTransAtLinearBand_nc[i];
    }

    b__tmp_0 = rtDW.obj_k.H.b->size[0];
    if (b__tmp_0 - 1 >= 0) {
      std::memcpy(&b_->data[0], &rtb_TmpTaskTransAtLinearBand_nc[0],
                  static_cast<uint32_t>(b__tmp_0) * sizeof(creal32_T));
    }

    b__tmp_1 = static_cast<int32_t>((rtDW.obj_k.H.ntap + 1.0) - 1.0) - 1;
    for (b__tmp_0 = 0; b__tmp_0 <= b__tmp_1; b__tmp_0++) {
      //  Lattice signal
      loop_ub = rtDW.obj_k.H.f->size[0];
      if ((rtDW.obj_k.H.K->size[0] == rtDW.obj_k.H.b->size[0]) &&
          ((rtDW.obj_k.H.K->size[0] == 1 ? rtDW.obj_k.H.b->size[0] :
            rtDW.obj_k.H.K->size[0]) == rtDW.obj_k.H.f->size[0])) {
        q_size = tmp->size[0];
        tmp->size[0] = rtDW.obj_k.H.f->size[0];
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = rtDW.obj_k.H.K->data[(static_cast<int32_t>((static_cast<
            double>(b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_k.H.K->size[0] + i].
            re;
          mu1_tmp_0 = rtDW.obj_k.H.b->data[(static_cast<int32_t>((static_cast<
            double>(b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_k.H.b->size[0] + i].
            im;
          re = rtDW.obj_k.H.K->data[(static_cast<int32_t>((static_cast<double>
            (b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_k.H.K->size[0] + i].im;
          im = rtDW.obj_k.H.b->data[(static_cast<int32_t>((static_cast<double>
            (b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_k.H.b->size[0] + i].re;
          tmp->data[i].re = rtDW.obj_k.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 2.0) - 1.0) - 1) *
            rtDW.obj_k.H.f->size[0] + i].re - (mu1_tmp * im - re * mu1_tmp_0);
          tmp->data[i].im = rtDW.obj_k.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 2.0) - 1.0) - 1) *
            rtDW.obj_k.H.f->size[0] + i].im - (mu1_tmp * mu1_tmp_0 + re * im);
        }

        loop_ub = tmp->size[0];
        for (i = 0; i < loop_ub; i++) {
          rtDW.obj_k.H.f->data[i + rtDW.obj_k.H.f->size[0] * (b__tmp_0 + 1)] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j(&rtDW.obj_k, b__tmp_0);
      }

      loop_ub = rtDW.obj_k.H.b->size[0];
      if ((rtDW.obj_k.H.K->size[0] == rtDW.obj_k.H.f->size[0]) &&
          ((rtDW.obj_k.H.K->size[0] == 1 ? rtDW.obj_k.H.f->size[0] :
            rtDW.obj_k.H.K->size[0]) == rtDW.obj_k.H.b->size[0])) {
        for (i = 0; i < loop_ub; i++) {
          re = rtDW.obj_k.H.K->data[(static_cast<int32_t>((static_cast<double>
            (b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_k.H.K->size[0] + i].re;
          im = -rtDW.obj_k.H.K->data[(static_cast<int32_t>((static_cast<double>
            (b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_k.H.K->size[0] + i].im;
          mu1_tmp = rtDW.obj_k.H.f->data[(static_cast<int32_t>((static_cast<
            double>(b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_k.H.f->size[0] + i].
            im;
          mu1_tmp_0 = rtDW.obj_k.H.f->data[(static_cast<int32_t>((static_cast<
            double>(b__tmp_0) + 2.0) - 1.0) - 1) * rtDW.obj_k.H.f->size[0] + i].
            re;
          b_->data[i + b_->size[0] * (b__tmp_0 + 1)].re = rtDW.obj_k.H.b->data[(
            static_cast<int32_t>((static_cast<double>(b__tmp_0) + 2.0) - 1.0) -
            1) * rtDW.obj_k.H.b->size[0] + i].re - (mu1_tmp_0 * re - mu1_tmp *
            im);
          b_->data[i + b_->size[0] * (b__tmp_0 + 1)].im = rtDW.obj_k.H.b->data[(
            static_cast<int32_t>((static_cast<double>(b__tmp_0) + 2.0) - 1.0) -
            1) * rtDW.obj_k.H.b->size[0] + i].im - (mu1_tmp * re + mu1_tmp_0 *
            im);
        }
      } else {
        binary_expand_op(b_, b__tmp_0, &rtDW.obj_k);
      }
    }

    q_size = rtDW.obj_k.H.b->size[0] * rtDW.obj_k.H.b->size[1];
    rtDW.obj_k.H.b->size[0] = b_->size[0];
    rtDW.obj_k.H.b->size[1] = b_->size[1];
    emxEnsureCapacity_creal32_T(rtDW.obj_k.H.b, q_size);
    loop_ub = b_->size[0] * b_->size[1];
    for (b__tmp_1 = 0; b__tmp_1 < loop_ub; b__tmp_1++) {
      rtDW.obj_k.H.b->data[b__tmp_1] = b_->data[b__tmp_1];
    }

    v_tmp = static_cast<int32_t>(rtDW.obj_k.H.ntap) - 1;
    for (b__tmp_0 = 0; b__tmp_0 <= v_tmp; b__tmp_0++) {
      //  Step size recursion
      loop_ub = rtDW.obj_k.H.mu->size[0];
      if ((rtDW.obj_k.H.f->size[0] == old_b2_->size[0]) &&
          ((rtDW.obj_k.H.f->size[0] == 1 ? old_b2_->size[0] :
            rtDW.obj_k.H.f->size[0]) == rtDW.obj_k.H.mu->size[0])) {
        q_size = mu1->size[0];
        mu1->size[0] = rtDW.obj_k.H.mu->size[0];
        emxEnsureCapacity_float_j(mu1, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = rtDW.obj_k.H.f->data[rtDW.obj_k.H.f->size[0] * b__tmp_0 + i]
            .re;
          mu1_tmp_0 = rtDW.obj_k.H.f->data[rtDW.obj_k.H.f->size[0] * b__tmp_0 +
            i].im;
          mu1->data[i] = 1.0F / rtDW.obj_k.H.mu->data[rtDW.obj_k.H.mu->size[0] *
            b__tmp_0 + i] * (1.0F - forgettingfactor_) + ((mu1_tmp * mu1_tmp -
            mu1_tmp_0 * -mu1_tmp_0) + old_b2_->data[old_b2_->size[0] * b__tmp_0
            + i]);
        }
      } else {
        binary_expand_op_j3x(mu1, forgettingfactor_, &rtDW.obj_k, b__tmp_0,
                             old_b2_);
      }

      b__tmp_1 = mu1->size[0] - 1;
      for (i = 0; i <= b__tmp_1; i++) {
        if (mu1->data[i] < 1.0E-8) {
          mu1->data[i] = 1.0E-8F;
        }
      }

      loop_ub = mu1->size[0];
      for (i = 0; i < loop_ub; i++) {
        rtDW.obj_k.H.mu->data[i + rtDW.obj_k.H.mu->size[0] * b__tmp_0] = 1.0F /
          mu1->data[i];
      }

      //  PARCOR recursion
      loop_ub = rtDW.obj_k.H.K->size[0];
      i = rtDW.obj_k.H.f->size[0] == 1 ? b__tmp->size[0] : rtDW.obj_k.H.f->size
        [0];
      q_size = b_->size[0] == 1 ? rtDW.obj_k.H.f->size[0] : b_->size[0];
      b__tmp_1 = i == 1 ? q_size : i;
      if ((rtDW.obj_k.H.f->size[0] == b__tmp->size[0]) && (b_->size[0] ==
           rtDW.obj_k.H.f->size[0]) && (i == q_size) && (b__tmp_1 ==
           rtDW.obj_k.H.mu->size[0]) && ((rtDW.obj_k.H.mu->size[0] == 1 ?
            b__tmp_1 : rtDW.obj_k.H.mu->size[0]) == rtDW.obj_k.H.K->size[0])) {
        q_size = tmp->size[0];
        tmp->size[0] = rtDW.obj_k.H.K->size[0];
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = b__tmp->data[b__tmp->size[0] * b__tmp_0 + i].re;
          mu1_tmp_0 = -b__tmp->data[b__tmp->size[0] * b__tmp_0 + i].im;
          re = b_->data[(static_cast<int32_t>((static_cast<double>(b__tmp_0) +
            1.0) + 1.0) - 1) * b_->size[0] + i].re;
          im = -b_->data[(static_cast<int32_t>((static_cast<double>(b__tmp_0) +
            1.0) + 1.0) - 1) * b_->size[0] + i].im;
          tmp->data[i].re = ((rtDW.obj_k.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 1.0) + 1.0) - 1) *
                              rtDW.obj_k.H.f->size[0] + i].re * mu1_tmp -
                              rtDW.obj_k.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 1.0) + 1.0) - 1) *
                              rtDW.obj_k.H.f->size[0] + i].im * mu1_tmp_0) +
                             (rtDW.obj_k.H.f->data[rtDW.obj_k.H.f->size[0] *
                              b__tmp_0 + i].re * re - rtDW.obj_k.H.f->
                              data[rtDW.obj_k.H.f->size[0] * b__tmp_0 + i].im *
                              im)) * rtDW.obj_k.H.mu->data[rtDW.obj_k.H.mu->
            size[0] * b__tmp_0 + i] + rtDW.obj_k.H.K->data[rtDW.obj_k.H.K->size
            [0] * b__tmp_0 + i].re;
          tmp->data[i].im = ((rtDW.obj_k.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 1.0) + 1.0) - 1) *
                              rtDW.obj_k.H.f->size[0] + i].re * mu1_tmp_0 +
                              rtDW.obj_k.H.f->data[(static_cast<int32_t>((
            static_cast<double>(b__tmp_0) + 1.0) + 1.0) - 1) *
                              rtDW.obj_k.H.f->size[0] + i].im * mu1_tmp) +
                             (rtDW.obj_k.H.f->data[rtDW.obj_k.H.f->size[0] *
                              b__tmp_0 + i].im * re + rtDW.obj_k.H.f->
                              data[rtDW.obj_k.H.f->size[0] * b__tmp_0 + i].re *
                              im)) * rtDW.obj_k.H.mu->data[rtDW.obj_k.H.mu->
            size[0] * b__tmp_0 + i] + rtDW.obj_k.H.K->data[rtDW.obj_k.H.K->size
            [0] * b__tmp_0 + i].im;
        }

        loop_ub = tmp->size[0];
        for (i = 0; i < loop_ub; i++) {
          rtDW.obj_k.H.K->data[i + rtDW.obj_k.H.K->size[0] * b__tmp_0] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j3(&rtDW.obj_k, b__tmp_0, b__tmp, b_);
      }
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    emxFree_creal32_T(&b__tmp);
    emxFree_float_j(&mu1);
    emxFree_float_j(&old_b2_);
    emxFree_creal32_T(&b_);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System5' incorporates:
    //   TaskTransBlk generated from: '<Root>/LinearBandH'

    //  One speaker
    // stepMic Summary of this method goes here
    //    Detailed explanation goes here
    //  Y - Reconstructed speaker channel
    //  E - Near end signal
    //  Start with am empty FE
    std::memcpy(&rtb_TmpTaskTransAtLinearBand_e4[0],
                &rtb_TmpTaskTransAtLinearBandH_h[0], 80U * sizeof(creal32_T));

    //  Start with a non echo cancelled NE
    for (b__tmp_0 = 0; b__tmp_0 <= v_tmp; b__tmp_0++) {
      //  Combiner
      //  Reconstruct the FE
      if ((rtDW.obj_k.H.G->size[0] == rtDW.obj_k.H.b->size[0]) &&
          ((rtDW.obj_k.H.G->size[0] == 1 ? rtDW.obj_k.H.b->size[0] :
            rtDW.obj_k.H.G->size[0]) == 80)) {
        for (i = 0; i < 80; i++) {
          forgettingfactor_ = rtDW.obj_k.H.G->data[rtDW.obj_k.H.G->size[0] *
            b__tmp_0 + i].re;
          mu1_tmp = rtDW.obj_k.H.b->data[rtDW.obj_k.H.b->size[0] * b__tmp_0 + i]
            .re;
          mu1_tmp_0 = rtDW.obj_k.H.G->data[rtDW.obj_k.H.G->size[0] * b__tmp_0 +
            i].im;
          re = rtDW.obj_k.H.b->data[rtDW.obj_k.H.b->size[0] * b__tmp_0 + i].im;
          rtb_TmpTaskTransAtLinearBand_e4[i].re -= forgettingfactor_ * mu1_tmp -
            mu1_tmp_0 * re;
          rtb_TmpTaskTransAtLinearBand_e4[i].im -= forgettingfactor_ * re +
            mu1_tmp_0 * mu1_tmp;
        }
      } else {
        binary_expand_op_j3xz2e4k(rtb_TmpTaskTransAtLinearBand_e4, &rtDW.obj_k,
          b__tmp_0);
      }

      //  Remove FE from NE signal
      if ((rtDW.obj_k.H.mu->size[0] == rtDW.obj_k.H.b->size[0]) &&
          ((rtDW.obj_k.H.mu->size[0] == 1 ? rtDW.obj_k.H.b->size[0] :
            rtDW.obj_k.H.mu->size[0]) == 80) && (rtDW.obj_k.H.G->size[0] == 80))
      {
        q_size = tmp->size[0];
        tmp->size[0] = 80;
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < 80; i++) {
          re = rtDW.obj_k.H.mu->data[rtDW.obj_k.H.mu->size[0] * b__tmp_0 + i] *
            2.0F * rtDW.obj_k.H.b->data[rtDW.obj_k.H.b->size[0] * b__tmp_0 + i].
            re;
          im = rtDW.obj_k.H.mu->data[rtDW.obj_k.H.mu->size[0] * b__tmp_0 + i] *
            2.0F * -rtDW.obj_k.H.b->data[rtDW.obj_k.H.b->size[0] * b__tmp_0 + i]
            .im;
          forgettingfactor_ = rtb_TmpTaskTransAtLinearBand_e4[i].re;
          mu1_tmp = rtb_TmpTaskTransAtLinearBand_e4[i].im;
          tmp->data[i].re = (re * forgettingfactor_ - im * mu1_tmp) +
            rtDW.obj_k.H.G->data[rtDW.obj_k.H.G->size[0] * b__tmp_0 + i].re;
          tmp->data[i].im = (re * mu1_tmp + im * forgettingfactor_) +
            rtDW.obj_k.H.G->data[rtDW.obj_k.H.G->size[0] * b__tmp_0 + i].im;
          rtDW.obj_k.H.G->data[i + rtDW.obj_k.H.G->size[0] * b__tmp_0] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j3xz2e4(&rtDW.obj_k, b__tmp_0,
          rtb_TmpTaskTransAtLinearBand_e4);
      }
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    emxFree_creal32_T(&tmp);

    //  Make sure we do not introduce energy
    //  Avoid using abs because it is an expensive function
    b__tmp_0 = 0;

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System5' incorporates:
    //   TaskTransBlk generated from: '<Root>/LinearBandH'

    for (i = 0; i < 80; i++) {
      // TaskTransBlk generated from: '<Root>/LinearBandH'
      forgettingfactor_ = rtb_TmpTaskTransAtLinearBandH_h[i].re;
      mu1_tmp = rtb_TmpTaskTransAtLinearBandH_h[i].im;
      forgettingfactor_ = forgettingfactor_ * forgettingfactor_ - mu1_tmp *
        -mu1_tmp;
      D2[i] = forgettingfactor_;
      mu1_tmp = rtb_TmpTaskTransAtLinearBand_e4[i].re;
      mu1_tmp_0 = rtb_TmpTaskTransAtLinearBand_e4[i].im;
      mu1_tmp = mu1_tmp * mu1_tmp - mu1_tmp_0 * -mu1_tmp_0;
      E2[i] = mu1_tmp;
      if (mu1_tmp > forgettingfactor_) {
        b__tmp_0++;
      }
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandH'
    q_size = b__tmp_0;
    b__tmp_0 = 0;
    for (i = 0; i < 80; i++) {
      // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
      // MATLABSystem: '<S3>/MATLAB System5'
      if (E2[i] > D2[i]) {
        q_data_0[b__tmp_0] = i;
        b__tmp_0++;
      }

      // End of Outputs for SubSystem: '<Root>/LinearBandH'
    }

    // Outputs for Atomic SubSystem: '<Root>/LinearBandH'
    // MATLABSystem: '<S3>/MATLAB System5'
    for (i = 0; i < q_size; i++) {
      b__tmp_0 = q_data_0[i];
      p_data[i] = D2[b__tmp_0] / E2[b__tmp_0];
    }

    b__tmp_1 = q_size - 1;
    for (i = 0; i <= b__tmp_1; i++) {
      p_data[i] = std::sqrt(p_data[i]);
    }

    for (i = 0; i < q_size; i++) {
      forgettingfactor_ = p_data[i];
      b__tmp_0 = q_data_0[i];
      e__data[i].re = forgettingfactor_ *
        rtb_TmpTaskTransAtLinearBand_e4[b__tmp_0].re;
      e__data[i].im = forgettingfactor_ *
        rtb_TmpTaskTransAtLinearBand_e4[b__tmp_0].im;
    }

    for (i = 0; i < q_size; i++) {
      rtb_TmpTaskTransAtLinearBand_e4[q_data_0[i]] = e__data[i];
    }

    // SignalConversion generated from: '<S3>/MATLAB System5' incorporates:
    //   MATLABSystem: '<S3>/MATLAB System5'
    //   TaskTransBlk generated from: '<Root>/LinearBandH'

    //  Multiple mic channels
    for (i = 0; i < 80; i++) {
      rtDW.TmpTaskTransAtLinearBandHOutpor[i + 80] =
        rtb_TmpTaskTransAtLinearBand_e4[i];
    }

    // End of SignalConversion generated from: '<S3>/MATLAB System5'

    // SignalConversion generated from: '<S3>/MATLAB System6' incorporates:
    //   MATLABSystem: '<S3>/MATLAB System6'
    //   TaskTransBlk generated from: '<Root>/LinearBandH'

    for (i = 0; i < 80; i++) {
      rtDW.TmpTaskTransAtLinearBandHOutpor[i] =
        rtb_TmpTaskTransAtLinearBandHIn[i];
    }

    // End of SignalConversion generated from: '<S3>/MATLAB System6'

    // SignalConversion generated from: '<S3>/D4' incorporates:
    //   TaskTransBlk generated from: '<Root>/LinearBandH'
    //
    for (i = 0; i < 159; i++) {
      rtDW.TmpTaskTransAtLinearBandHOutpor[i + 160] =
        rtDW.TmpTaskTransAtTransformSubsy_hs[i];
    }

    // End of SignalConversion generated from: '<S3>/D4'
    // End of Outputs for SubSystem: '<Root>/LinearBandH'

    // TaskTransBlk generated from: '<Root>/LinearBandH'
    rtw_pthread_sem_post_mac(rtDW.sw_buf_71);
  }
}

// OutputUpdate for Task: Periodic_TSK_Main
void SmartMicDrvTsk_Ccode::Periodic_TSK_Main_step(void) // Sample time: [0.01s, 0.0s] 
{
  // local block i/o variables
  float rtb_VariableIntegerDelay[480];
  float rtb_Product[480];

  // Update the flag to indicate when data transfers from
  //   Sample time: [0.01s, 0.0s] to Sample time: [0.5s, 0.0s]
  ((&task_M[1])->Timing.RateInteraction.TID0_1)++;
  if (((&task_M[1])->Timing.RateInteraction.TID0_1) > 49) {
    (&task_M[1])->Timing.RateInteraction.TID0_1 = 0;
  }

  {
    emxArray_creal32_T *b_;
    emxArray_creal32_T *b__tmp;
    emxArray_creal32_T *tmp;
    emxArray_float *mu1;
    emxArray_float *old_b2_;
    creal32_T rtb_MatrixConcatenate[480];
    creal32_T rtb_MultiportSelector1_o1[161];
    creal32_T rtb_MultiportSelector2_o1[161];
    creal32_T *rtb_MultiportSelector1_o2_0;
    creal32_T *rtb_MultiportSelector1_o3_0;
    creal32_T *rtb_MultiportSelector1_o4_0;
    creal32_T *rtb_MultiportSelector2_o2_0;
    creal32_T *rtb_MultiportSelector2_o3_0;
    float D2[161];
    float E2[161];
    float p_data[161];
    float forgettingfactor_;
    float im;
    float mu1_tmp;
    float mu1_tmp_0;
    float re;
    int32_t q_data[161];
    int32_t currIdx;
    int32_t delayLen;
    int32_t i;
    int32_t loop_ub;
    int32_t q_size;
    int32_t v_tmp;

    // Outputs for Atomic SubSystem: '<Root>/InputSubsystem'
    for (i = 0; i < 480; i++) {
      // Product: '<S2>/Product' incorporates:
      //   Inport: '<Root>/MicIn'

      rtb_Product[i] = rtU.MicIn[i] * 31.622776F;
    }

    // End of Outputs for SubSystem: '<Root>/InputSubsystem'

    // TaskTransBlk generated from: '<Root>/InputSubsystem' incorporates:
    //   SignalConversion generated from: '<S2>/FERef'

    for (i = 0; i < 480; i++) {
      // Outputs for Atomic SubSystem: '<Root>/InputSubsystem'
      rtDW.TmpTaskTransAtInputSubsystemOut[i] = rtU.FE[i];

      // End of Outputs for SubSystem: '<Root>/InputSubsystem'
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_51);

    // End of TaskTransBlk generated from: '<Root>/InputSubsystem'

    // TaskTransBlk generated from: '<Root>/InputSubsystem'
    for (i = 0; i < 480; i++) {
      rtDW.TmpTaskTransAtInputSubsystemO_n[i] = rtb_Product[i];
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_61);

    // End of TaskTransBlk generated from: '<Root>/InputSubsystem'

    // TaskTransBlk generated from: '<Root>/TransformSubsystem'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_81);

    // Outputs for Atomic SubSystem: '<Root>/TransformSubsystem'
    // Delay: '<S7>/Variable Integer Delay' incorporates:
    //   TaskTransBlk generated from: '<Root>/TransformSubsystem'

    if (rtDW.TmpTaskTransAtSpkDelayTaskOutpo <= 0) {
      // Delay: '<S7>/Variable Integer Delay' incorporates:
      //   Inport: '<Root>/FE'

      std::memcpy(&rtb_VariableIntegerDelay[0], &rtU.FE[0], 480U * sizeof(float));
    } else {
      if (rtDW.TmpTaskTransAtSpkDelayTaskOutpo > 48000) {
        delayLen = 48000;
      } else {
        delayLen = rtDW.TmpTaskTransAtSpkDelayTaskOutpo;
      }

      if (delayLen <= rtDW.CircBufIdx) {
        currIdx = rtDW.CircBufIdx - delayLen;
      } else {
        currIdx = (rtDW.CircBufIdx - delayLen) + 48000;
      }

      for (i = 0; i < 480; i++) {
        if (i < delayLen) {
          rtb_VariableIntegerDelay[i] = rtDW.VariableIntegerDelay_DSTATE[currIdx];
          currIdx++;
          if (currIdx >= 48000) {
            currIdx = 0;
          }
        } else {
          rtb_VariableIntegerDelay[i] = rtU.FE[i - delayLen];
        }
      }
    }

    // End of Delay: '<S7>/Variable Integer Delay'
    FFTSystem(rtb_VariableIntegerDelay, &rtDW.FFTSystem_p);
    FFTSystem(rtb_Product, &rtDW.FFTSystem1);

    // S-Function (sdspmultiportsel): '<S7>/Multiport Selector2' incorporates:
    //   MATLABSystem: '<S7>/FFTSystem'

    std::memcpy(&rtb_MultiportSelector2_o1[0], &rtDW.FFTSystem_p.FFTSystem_k[0],
                161U * sizeof(creal32_T));
    rtb_MultiportSelector2_o2_0 = &rtDW.FFTSystem_p.FFTSystem_k[161];
    rtb_MultiportSelector2_o3_0 = &rtDW.FFTSystem_p.FFTSystem_k[241];

    // S-Function (sdspmultiportsel): '<S7>/Multiport Selector1' incorporates:
    //   MATLABSystem: '<S7>/FFTSystem1'

    std::memcpy(&rtb_MultiportSelector1_o1[0], &rtDW.FFTSystem1.FFTSystem_k[0],
                161U * sizeof(creal32_T));
    rtb_MultiportSelector1_o2_0 = &rtDW.FFTSystem1.FFTSystem_k[161];
    rtb_MultiportSelector1_o3_0 = &rtDW.FFTSystem1.FFTSystem_k[241];
    rtb_MultiportSelector1_o4_0 = &rtDW.FFTSystem1.FFTSystem_k[321];

    // Update for Delay: '<S7>/Variable Integer Delay'
    currIdx = rtDW.CircBufIdx;
    for (i = 0; i < 480; i++) {
      rtDW.VariableIntegerDelay_DSTATE[currIdx] = rtU.FE[i];
      currIdx++;
      if (currIdx >= 48000) {
        currIdx = 0;
      }
    }

    if (rtDW.CircBufIdx < 47520) {
      rtDW.CircBufIdx += 480;
    } else {
      rtDW.CircBufIdx -= 47520;
    }

    // End of Update for Delay: '<S7>/Variable Integer Delay'
    // End of Outputs for SubSystem: '<Root>/TransformSubsystem'

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL'
    if (rtDW.obj_o.alphaDT != 0.01) {
      rtDW.obj_o.alphaDT = 0.01;
    }

    if (rtDW.obj_o.alphaFEST != 0.1) {
      rtDW.obj_o.alphaFEST = 0.1;
    }

    if (rtDW.obj_o.dBignore != -50.0) {
      rtDW.obj_o.dBignore = -50.0;
    }

    //  Implement algorithm. Calculate y as a function of input u and
    //  discrete states.
    //  X signal
    forgettingfactor_ = static_cast<float>(rtDW.obj_o.alphaDT -
      rtDW.obj_o.alphaFEST) + static_cast<float>(rtDW.obj_o.alphaFEST);

    // End of Outputs for SubSystem: '<Root>/LinearBandL'
    // stepSpeaker Summary of this method goes here
    //    Detailed explanation goes here
    emxInit_creal32_T(&b__tmp, 2);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL'
    q_size = b__tmp->size[0] * b__tmp->size[1];
    b__tmp->size[0] = rtDW.obj_o.H.b->size[0];
    b__tmp->size[1] = rtDW.obj_o.H.b->size[1];
    emxEnsureCapacity_creal32_T(b__tmp, q_size);
    loop_ub = rtDW.obj_o.H.b->size[0] * rtDW.obj_o.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      b__tmp->data[i] = rtDW.obj_o.H.b->data[i];
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandL'
    emxInit_creal32_T(&b_, 2);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL'
    q_size = b_->size[0] * b_->size[1];
    b_->size[0] = rtDW.obj_o.H.b->size[0];
    b_->size[1] = rtDW.obj_o.H.b->size[1];
    emxEnsureCapacity_creal32_T(b_, q_size);
    loop_ub = rtDW.obj_o.H.b->size[0] * rtDW.obj_o.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      b_->data[i] = rtDW.obj_o.H.b->data[i];
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandL'
    emxInit_float_j(&old_b2_, 2);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL' incorporates:
    //   S-Function (sdspmultiportsel): '<S7>/Multiport Selector2'

    q_size = old_b2_->size[0] * old_b2_->size[1];
    old_b2_->size[0] = rtDW.obj_o.H.b->size[0];
    old_b2_->size[1] = rtDW.obj_o.H.b->size[1];
    emxEnsureCapacity_float_j(old_b2_, q_size);
    loop_ub = rtDW.obj_o.H.b->size[0] * rtDW.obj_o.H.b->size[1];
    for (i = 0; i < loop_ub; i++) {
      old_b2_->data[i] = rtDW.obj_o.H.b->data[i].re * rtDW.obj_o.H.b->data[i].re
        - rtDW.obj_o.H.b->data[i].im * -rtDW.obj_o.H.b->data[i].im;
    }

    delayLen = rtDW.obj_o.H.f->size[0];
    for (i = 0; i < delayLen; i++) {
      rtDW.obj_o.H.f->data[i] = rtb_MultiportSelector2_o1[i];
    }

    delayLen = rtDW.obj_o.H.b->size[0];
    if (delayLen - 1 >= 0) {
      std::memcpy(&b_->data[0], &rtb_MultiportSelector2_o1[0],
                  static_cast<uint32_t>(delayLen) * sizeof(creal32_T));
    }

    currIdx = static_cast<int32_t>((rtDW.obj_o.H.ntap + 1.0) - 1.0) - 1;

    // End of Outputs for SubSystem: '<Root>/LinearBandL'
    emxInit_creal32_T(&tmp, 1);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL'
    for (delayLen = 0; delayLen <= currIdx; delayLen++) {
      //  Lattice signal
      loop_ub = rtDW.obj_o.H.f->size[0];
      if ((rtDW.obj_o.H.K->size[0] == rtDW.obj_o.H.b->size[0]) &&
          ((rtDW.obj_o.H.K->size[0] == 1 ? rtDW.obj_o.H.b->size[0] :
            rtDW.obj_o.H.K->size[0]) == rtDW.obj_o.H.f->size[0])) {
        q_size = tmp->size[0];
        tmp->size[0] = rtDW.obj_o.H.f->size[0];
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = rtDW.obj_o.H.K->data[(static_cast<int32_t>((static_cast<
            double>(delayLen) + 2.0) - 1.0) - 1) * rtDW.obj_o.H.K->size[0] + i].
            re;
          mu1_tmp_0 = rtDW.obj_o.H.b->data[(static_cast<int32_t>((static_cast<
            double>(delayLen) + 2.0) - 1.0) - 1) * rtDW.obj_o.H.b->size[0] + i].
            im;
          re = rtDW.obj_o.H.K->data[(static_cast<int32_t>((static_cast<double>
            (delayLen) + 2.0) - 1.0) - 1) * rtDW.obj_o.H.K->size[0] + i].im;
          im = rtDW.obj_o.H.b->data[(static_cast<int32_t>((static_cast<double>
            (delayLen) + 2.0) - 1.0) - 1) * rtDW.obj_o.H.b->size[0] + i].re;
          tmp->data[i].re = rtDW.obj_o.H.f->data[(static_cast<int32_t>((
            static_cast<double>(delayLen) + 2.0) - 1.0) - 1) *
            rtDW.obj_o.H.f->size[0] + i].re - (mu1_tmp * im - re * mu1_tmp_0);
          tmp->data[i].im = rtDW.obj_o.H.f->data[(static_cast<int32_t>((
            static_cast<double>(delayLen) + 2.0) - 1.0) - 1) *
            rtDW.obj_o.H.f->size[0] + i].im - (mu1_tmp * mu1_tmp_0 + re * im);
        }

        loop_ub = tmp->size[0];
        for (i = 0; i < loop_ub; i++) {
          rtDW.obj_o.H.f->data[i + rtDW.obj_o.H.f->size[0] * (delayLen + 1)] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j(&rtDW.obj_o, delayLen);
      }

      loop_ub = rtDW.obj_o.H.b->size[0];
      if ((rtDW.obj_o.H.K->size[0] == rtDW.obj_o.H.f->size[0]) &&
          ((rtDW.obj_o.H.K->size[0] == 1 ? rtDW.obj_o.H.f->size[0] :
            rtDW.obj_o.H.K->size[0]) == rtDW.obj_o.H.b->size[0])) {
        for (i = 0; i < loop_ub; i++) {
          re = rtDW.obj_o.H.K->data[(static_cast<int32_t>((static_cast<double>
            (delayLen) + 2.0) - 1.0) - 1) * rtDW.obj_o.H.K->size[0] + i].re;
          im = -rtDW.obj_o.H.K->data[(static_cast<int32_t>((static_cast<double>
            (delayLen) + 2.0) - 1.0) - 1) * rtDW.obj_o.H.K->size[0] + i].im;
          mu1_tmp = rtDW.obj_o.H.f->data[(static_cast<int32_t>((static_cast<
            double>(delayLen) + 2.0) - 1.0) - 1) * rtDW.obj_o.H.f->size[0] + i].
            im;
          mu1_tmp_0 = rtDW.obj_o.H.f->data[(static_cast<int32_t>((static_cast<
            double>(delayLen) + 2.0) - 1.0) - 1) * rtDW.obj_o.H.f->size[0] + i].
            re;
          b_->data[i + b_->size[0] * (delayLen + 1)].re = rtDW.obj_o.H.b->data[(
            static_cast<int32_t>((static_cast<double>(delayLen) + 2.0) - 1.0) -
            1) * rtDW.obj_o.H.b->size[0] + i].re - (mu1_tmp_0 * re - mu1_tmp *
            im);
          b_->data[i + b_->size[0] * (delayLen + 1)].im = rtDW.obj_o.H.b->data[(
            static_cast<int32_t>((static_cast<double>(delayLen) + 2.0) - 1.0) -
            1) * rtDW.obj_o.H.b->size[0] + i].im - (mu1_tmp * re + mu1_tmp_0 *
            im);
        }
      } else {
        binary_expand_op(b_, delayLen, &rtDW.obj_o);
      }
    }

    q_size = rtDW.obj_o.H.b->size[0] * rtDW.obj_o.H.b->size[1];
    rtDW.obj_o.H.b->size[0] = b_->size[0];
    rtDW.obj_o.H.b->size[1] = b_->size[1];
    emxEnsureCapacity_creal32_T(rtDW.obj_o.H.b, q_size);
    loop_ub = b_->size[0] * b_->size[1];
    for (currIdx = 0; currIdx < loop_ub; currIdx++) {
      rtDW.obj_o.H.b->data[currIdx] = b_->data[currIdx];
    }

    v_tmp = static_cast<int32_t>(rtDW.obj_o.H.ntap) - 1;

    // End of Outputs for SubSystem: '<Root>/LinearBandL'
    emxInit_float_j(&mu1, 1);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL'
    for (delayLen = 0; delayLen <= v_tmp; delayLen++) {
      //  Step size recursion
      loop_ub = rtDW.obj_o.H.mu->size[0];
      if ((rtDW.obj_o.H.f->size[0] == old_b2_->size[0]) &&
          ((rtDW.obj_o.H.f->size[0] == 1 ? old_b2_->size[0] :
            rtDW.obj_o.H.f->size[0]) == rtDW.obj_o.H.mu->size[0])) {
        q_size = mu1->size[0];
        mu1->size[0] = rtDW.obj_o.H.mu->size[0];
        emxEnsureCapacity_float_j(mu1, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = rtDW.obj_o.H.f->data[rtDW.obj_o.H.f->size[0] * delayLen + i]
            .re;
          mu1_tmp_0 = rtDW.obj_o.H.f->data[rtDW.obj_o.H.f->size[0] * delayLen +
            i].im;
          mu1->data[i] = 1.0F / rtDW.obj_o.H.mu->data[rtDW.obj_o.H.mu->size[0] *
            delayLen + i] * (1.0F - forgettingfactor_) + ((mu1_tmp * mu1_tmp -
            mu1_tmp_0 * -mu1_tmp_0) + old_b2_->data[old_b2_->size[0] * delayLen
            + i]);
        }
      } else {
        binary_expand_op_j3x(mu1, forgettingfactor_, &rtDW.obj_o, delayLen,
                             old_b2_);
      }

      currIdx = mu1->size[0] - 1;
      for (i = 0; i <= currIdx; i++) {
        if (mu1->data[i] < 1.0E-8) {
          mu1->data[i] = 1.0E-8F;
        }
      }

      loop_ub = mu1->size[0];
      for (i = 0; i < loop_ub; i++) {
        rtDW.obj_o.H.mu->data[i + rtDW.obj_o.H.mu->size[0] * delayLen] = 1.0F /
          mu1->data[i];
      }

      //  PARCOR recursion
      loop_ub = rtDW.obj_o.H.K->size[0];
      i = rtDW.obj_o.H.f->size[0] == 1 ? b__tmp->size[0] : rtDW.obj_o.H.f->size
        [0];
      q_size = b_->size[0] == 1 ? rtDW.obj_o.H.f->size[0] : b_->size[0];
      currIdx = i == 1 ? q_size : i;
      if ((rtDW.obj_o.H.f->size[0] == b__tmp->size[0]) && (b_->size[0] ==
           rtDW.obj_o.H.f->size[0]) && (i == q_size) && (currIdx ==
           rtDW.obj_o.H.mu->size[0]) && ((rtDW.obj_o.H.mu->size[0] == 1 ?
            currIdx : rtDW.obj_o.H.mu->size[0]) == rtDW.obj_o.H.K->size[0])) {
        q_size = tmp->size[0];
        tmp->size[0] = rtDW.obj_o.H.K->size[0];
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < loop_ub; i++) {
          mu1_tmp = b__tmp->data[b__tmp->size[0] * delayLen + i].re;
          mu1_tmp_0 = -b__tmp->data[b__tmp->size[0] * delayLen + i].im;
          re = b_->data[(static_cast<int32_t>((static_cast<double>(delayLen) +
            1.0) + 1.0) - 1) * b_->size[0] + i].re;
          im = -b_->data[(static_cast<int32_t>((static_cast<double>(delayLen) +
            1.0) + 1.0) - 1) * b_->size[0] + i].im;
          tmp->data[i].re = ((rtDW.obj_o.H.f->data[(static_cast<int32_t>((
            static_cast<double>(delayLen) + 1.0) + 1.0) - 1) *
                              rtDW.obj_o.H.f->size[0] + i].re * mu1_tmp -
                              rtDW.obj_o.H.f->data[(static_cast<int32_t>((
            static_cast<double>(delayLen) + 1.0) + 1.0) - 1) *
                              rtDW.obj_o.H.f->size[0] + i].im * mu1_tmp_0) +
                             (rtDW.obj_o.H.f->data[rtDW.obj_o.H.f->size[0] *
                              delayLen + i].re * re - rtDW.obj_o.H.f->
                              data[rtDW.obj_o.H.f->size[0] * delayLen + i].im *
                              im)) * rtDW.obj_o.H.mu->data[rtDW.obj_o.H.mu->
            size[0] * delayLen + i] + rtDW.obj_o.H.K->data[rtDW.obj_o.H.K->size
            [0] * delayLen + i].re;
          tmp->data[i].im = ((rtDW.obj_o.H.f->data[(static_cast<int32_t>((
            static_cast<double>(delayLen) + 1.0) + 1.0) - 1) *
                              rtDW.obj_o.H.f->size[0] + i].re * mu1_tmp_0 +
                              rtDW.obj_o.H.f->data[(static_cast<int32_t>((
            static_cast<double>(delayLen) + 1.0) + 1.0) - 1) *
                              rtDW.obj_o.H.f->size[0] + i].im * mu1_tmp) +
                             (rtDW.obj_o.H.f->data[rtDW.obj_o.H.f->size[0] *
                              delayLen + i].im * re + rtDW.obj_o.H.f->
                              data[rtDW.obj_o.H.f->size[0] * delayLen + i].re *
                              im)) * rtDW.obj_o.H.mu->data[rtDW.obj_o.H.mu->
            size[0] * delayLen + i] + rtDW.obj_o.H.K->data[rtDW.obj_o.H.K->size
            [0] * delayLen + i].im;
        }

        loop_ub = tmp->size[0];
        for (i = 0; i < loop_ub; i++) {
          rtDW.obj_o.H.K->data[i + rtDW.obj_o.H.K->size[0] * delayLen] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j3(&rtDW.obj_o, delayLen, b__tmp, b_);
      }
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandL'
    emxFree_creal32_T(&b__tmp);
    emxFree_float_j(&mu1);
    emxFree_float_j(&old_b2_);
    emxFree_creal32_T(&b_);

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL' incorporates:
    //   S-Function (sdspmultiportsel): '<S7>/Multiport Selector1'

    //  One speaker
    // stepMic Summary of this method goes here
    //    Detailed explanation goes here
    //  Y - Reconstructed speaker channel
    //  E - Near end signal
    //  Start with am empty FE
    std::memcpy(&rtb_MultiportSelector2_o1[0], &rtb_MultiportSelector1_o1[0],
                161U * sizeof(creal32_T));

    //  Start with a non echo cancelled NE
    for (delayLen = 0; delayLen <= v_tmp; delayLen++) {
      //  Combiner
      //  Reconstruct the FE
      if ((rtDW.obj_o.H.G->size[0] == rtDW.obj_o.H.b->size[0]) &&
          ((rtDW.obj_o.H.G->size[0] == 1 ? rtDW.obj_o.H.b->size[0] :
            rtDW.obj_o.H.G->size[0]) == 161)) {
        for (i = 0; i < 161; i++) {
          forgettingfactor_ = rtDW.obj_o.H.G->data[rtDW.obj_o.H.G->size[0] *
            delayLen + i].re;
          mu1_tmp = rtDW.obj_o.H.b->data[rtDW.obj_o.H.b->size[0] * delayLen + i]
            .re;
          mu1_tmp_0 = rtDW.obj_o.H.G->data[rtDW.obj_o.H.G->size[0] * delayLen +
            i].im;
          re = rtDW.obj_o.H.b->data[rtDW.obj_o.H.b->size[0] * delayLen + i].im;
          rtb_MultiportSelector2_o1[i].re -= forgettingfactor_ * mu1_tmp -
            mu1_tmp_0 * re;
          rtb_MultiportSelector2_o1[i].im -= forgettingfactor_ * re + mu1_tmp_0 *
            mu1_tmp;
        }
      } else {
        binary_expand_op_j3xz2(rtb_MultiportSelector2_o1, &rtDW.obj_o, delayLen);
      }

      //  Remove FE from NE signal
      if ((rtDW.obj_o.H.mu->size[0] == rtDW.obj_o.H.b->size[0]) &&
          ((rtDW.obj_o.H.mu->size[0] == 1 ? rtDW.obj_o.H.b->size[0] :
            rtDW.obj_o.H.mu->size[0]) == 161) && (rtDW.obj_o.H.G->size[0] == 161))
      {
        q_size = tmp->size[0];
        tmp->size[0] = 161;
        emxEnsureCapacity_creal32_T(tmp, q_size);
        for (i = 0; i < 161; i++) {
          re = rtDW.obj_o.H.mu->data[rtDW.obj_o.H.mu->size[0] * delayLen + i] *
            2.0F * rtDW.obj_o.H.b->data[rtDW.obj_o.H.b->size[0] * delayLen + i].
            re;
          im = rtDW.obj_o.H.mu->data[rtDW.obj_o.H.mu->size[0] * delayLen + i] *
            2.0F * -rtDW.obj_o.H.b->data[rtDW.obj_o.H.b->size[0] * delayLen + i]
            .im;
          forgettingfactor_ = rtb_MultiportSelector2_o1[i].re;
          mu1_tmp = rtb_MultiportSelector2_o1[i].im;
          tmp->data[i].re = (re * forgettingfactor_ - im * mu1_tmp) +
            rtDW.obj_o.H.G->data[rtDW.obj_o.H.G->size[0] * delayLen + i].re;
          tmp->data[i].im = (re * mu1_tmp + im * forgettingfactor_) +
            rtDW.obj_o.H.G->data[rtDW.obj_o.H.G->size[0] * delayLen + i].im;
          rtDW.obj_o.H.G->data[i + rtDW.obj_o.H.G->size[0] * delayLen] =
            tmp->data[i];
        }
      } else {
        binary_expand_op_j3xz(&rtDW.obj_o, delayLen, rtb_MultiportSelector2_o1);
      }
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandL'
    emxFree_creal32_T(&tmp);

    //  Make sure we do not introduce energy
    //  Avoid using abs because it is an expensive function
    delayLen = 0;

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL' incorporates:
    //   S-Function (sdspmultiportsel): '<S7>/Multiport Selector1'

    for (i = 0; i < 161; i++) {
      // S-Function (sdspmultiportsel): '<S7>/Multiport Selector1'
      forgettingfactor_ = rtb_MultiportSelector1_o1[i].re;
      mu1_tmp = rtb_MultiportSelector1_o1[i].im;
      forgettingfactor_ = forgettingfactor_ * forgettingfactor_ - mu1_tmp *
        -mu1_tmp;
      D2[i] = forgettingfactor_;
      mu1_tmp = rtb_MultiportSelector2_o1[i].re;
      mu1_tmp_0 = rtb_MultiportSelector2_o1[i].im;
      mu1_tmp = mu1_tmp * mu1_tmp - mu1_tmp_0 * -mu1_tmp_0;
      E2[i] = mu1_tmp;
      if (mu1_tmp > forgettingfactor_) {
        delayLen++;
      }
    }

    // End of Outputs for SubSystem: '<Root>/LinearBandL'
    q_size = delayLen;
    delayLen = 0;
    for (i = 0; i < 161; i++) {
      // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
      // MATLABSystem: '<S4>/LinearAECL'
      if (E2[i] > D2[i]) {
        q_data[delayLen] = i;
        delayLen++;
      }

      // End of Outputs for SubSystem: '<Root>/LinearBandL'
    }

    // Outputs for Atomic SubSystem: '<Root>/LinearBandL'
    // MATLABSystem: '<S4>/LinearAECL'
    for (i = 0; i < q_size; i++) {
      delayLen = q_data[i];
      p_data[i] = D2[delayLen] / E2[delayLen];
    }

    currIdx = q_size - 1;
    for (i = 0; i <= currIdx; i++) {
      p_data[i] = std::sqrt(p_data[i]);
    }

    for (i = 0; i < q_size; i++) {
      forgettingfactor_ = p_data[i];
      delayLen = q_data[i];
      rtb_MultiportSelector1_o1[i].re = forgettingfactor_ *
        rtb_MultiportSelector2_o1[delayLen].re;
      rtb_MultiportSelector1_o1[i].im = forgettingfactor_ *
        rtb_MultiportSelector2_o1[delayLen].im;
    }

    for (i = 0; i < q_size; i++) {
      rtb_MultiportSelector2_o1[q_data[i]] = rtb_MultiportSelector1_o1[i];
    }

    // SignalConversion generated from: '<S4>/LinearAECL' incorporates:
    //   MATLABSystem: '<S4>/LinearAECL'

    //  Multiple mic channels
    std::memcpy(&rtb_MatrixConcatenate[0], &rtb_MultiportSelector2_o1[0], 161U *
                sizeof(creal32_T));

    // End of Outputs for SubSystem: '<Root>/LinearBandL'

    // TaskTransBlk generated from: '<Root>/TransformSubsystem' incorporates:
    //   S-Function (sdspmultiportsel): '<S7>/Multiport Selector2'

    for (i = 0; i < 80; i++) {
      rtDW.TmpTaskTransAtTransformSubsyste[i] = rtb_MultiportSelector2_o2_0[i];
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_91);

    // End of TaskTransBlk generated from: '<Root>/TransformSubsystem'

    // TaskTransBlk generated from: '<Root>/TransformSubsystem' incorporates:
    //   S-Function (sdspmultiportsel): '<S7>/Multiport Selector1'

    for (i = 0; i < 80; i++) {
      rtDW.TmpTaskTransAtTransformSubsys_k[i] = rtb_MultiportSelector1_o2_0[i];
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_101);

    // End of TaskTransBlk generated from: '<Root>/TransformSubsystem'

    // TaskTransBlk generated from: '<Root>/TransformSubsystem' incorporates:
    //   S-Function (sdspmultiportsel): '<S7>/Multiport Selector2'

    for (i = 0; i < 80; i++) {
      rtDW.TmpTaskTransAtTransformSubsys_b[i] = rtb_MultiportSelector2_o3_0[i];
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_111);

    // End of TaskTransBlk generated from: '<Root>/TransformSubsystem'

    // TaskTransBlk generated from: '<Root>/TransformSubsystem' incorporates:
    //   S-Function (sdspmultiportsel): '<S7>/Multiport Selector1'

    for (i = 0; i < 80; i++) {
      rtDW.TmpTaskTransAtTransformSubsys_g[i] = rtb_MultiportSelector1_o3_0[i];
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_121);

    // End of TaskTransBlk generated from: '<Root>/TransformSubsystem'

    // TaskTransBlk generated from: '<Root>/TransformSubsystem'
    rtw_pthread_sem_post_mac(rtDW.sw_buf_131);

    // TaskTransBlk generated from: '<Root>/TransformSubsystem' incorporates:
    //   S-Function (sdspmultiportsel): '<S7>/Multiport Selector1'

    for (i = 0; i < 159; i++) {
      rtDW.TmpTaskTransAtTransformSubsy_hs[i] = rtb_MultiportSelector1_o4_0[i];
    }

    rtw_pthread_sem_post_mac(rtDW.sw_buf_141);

    // End of TaskTransBlk generated from: '<Root>/TransformSubsystem'

    // TaskTransBlk generated from: '<Root>/OutputSubsystem'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_71);
    for (i = 0; i < 319; i++) {
      rtb_MatrixConcatenate[i + 161] = rtDW.TmpTaskTransAtLinearBandHOutpor[i];
    }

    // End of TaskTransBlk generated from: '<Root>/OutputSubsystem'

    // Outputs for Atomic SubSystem: '<Root>/OutputSubsystem'
    // MATLABSystem: '<S5>/iFFTSystem' incorporates:
    //   Concatenate: '<S5>/Matrix Concatenate'
    //   Outport: '<Root>/toFE'

    iFFTSystem_stepImpl(&rtDW.obj, rtb_MatrixConcatenate, rtY.toFE);

    // End of Outputs for SubSystem: '<Root>/OutputSubsystem'
  }
}

// OutputUpdate for Task: Discrete1
void SmartMicDrvTsk_Ccode::Discrete1_step(void) // Sample time: [0.01s, 0.0s]
{
  // Update the flag to indicate when data transfers from
  //   Sample time: [0.01s, 0.0s] to Sample time: [0.5s, 0.0s]
  ((&task_M[2])->Timing.RateInteraction.TID0_1)++;
  if (((&task_M[2])->Timing.RateInteraction.TID0_1) > 49) {
    (&task_M[2])->Timing.RateInteraction.TID0_1 = 0;
  }

  {
    int32_t TmpTaskTransAtSpkDelayTaskInp_n;
    int32_t i;

    // TaskTransBlk generated from: '<Root>/SpkDelayTask'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_11);
    for (i = 0; i < 6000; i++) {
      // TaskTransBlk generated from: '<Root>/SpkDelayTask'
      rtDW.TmpTaskTransAtSpkDelayTaskInp_f[i] =
        rtDW.TmpTaskTransAtDownSamplerOutpor[i];
    }

    // TaskTransBlk generated from: '<Root>/SpkDelayTask'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_21);

    // TaskTransBlk generated from: '<Root>/SpkDelayTask'
    TmpTaskTransAtSpkDelayTaskInp_n = rtDW.TmpTaskTransAtDownSamplerOutp_g;

    // TaskTransBlk generated from: '<Root>/SpkDelayTask'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_31);
    for (i = 0; i < 6000; i++) {
      // TaskTransBlk generated from: '<Root>/SpkDelayTask'
      rtDW.TmpTaskTransAtSpkDelayTaskInp_g[i] =
        rtDW.TmpTaskTransAtDownSamplerOutp_i[i];
    }

    // TaskTransBlk generated from: '<Root>/SpkDelayTask'
    rtw_pthread_sem_wait_mac(rtDW.sw_buf_41);

    // Outputs for Atomic SubSystem: '<Root>/SpkDelayTask'
    // RateTransition: '<S6>/RT' incorporates:
    //   RateTransition: '<S6>/Rate Transition'

    if ((&task_M[2])->Timing.RateInteraction.TID0_1 == 1) {
      rtDW.RT_RdBufIdx = static_cast<int8_t>(rtDW.RT_RdBufIdx == 0);
      rtDW.RateTransition_WrBufIdx = static_cast<int8_t>
        (rtDW.RateTransition_WrBufIdx == 0);
    }

    // RateTransition: '<S6>/Rate Transition' incorporates:
    //   TaskTransBlk generated from: '<Root>/SpkDelayTask'

    for (i = 0; i < 6000; i++) {
      rtDW.RateTransition_Buf[i + rtDW.RateTransition_WrBufIdx * 6000] =
        rtDW.TmpTaskTransAtSpkDelayTaskInp_f[i];
    }

    // RateTransition: '<S6>/Rate Transition1' incorporates:
    //   TaskTransBlk generated from: '<Root>/SpkDelayTask'

    if ((&task_M[2])->Timing.RateInteraction.TID0_1 == 1) {
      rtDW.RateTransition1_WrBufIdx = static_cast<int8_t>
        (rtDW.RateTransition1_WrBufIdx == 0);
    }

    for (i = 0; i < 6000; i++) {
      rtDW.RateTransition1_Buf[i + rtDW.RateTransition1_WrBufIdx * 6000] =
        rtDW.TmpTaskTransAtSpkDelayTaskInp_g[i];
    }

    // End of RateTransition: '<S6>/Rate Transition1'

    // RateTransition: '<S6>/Rate Transition2'
    if ((&task_M[2])->Timing.RateInteraction.TID0_1 == 1) {
      rtDW.RateTransition2_WrBufIdx = static_cast<int8_t>
        (rtDW.RateTransition2_WrBufIdx == 0);
    }

    rtDW.RateTransition2_Buf[rtDW.RateTransition2_WrBufIdx] =
      TmpTaskTransAtSpkDelayTaskInp_n;

    // End of RateTransition: '<S6>/Rate Transition2'

    // RateTransition: '<S6>/Rate Transition3'
    if ((&task_M[2])->Timing.RateInteraction.TID0_1 == 1) {
      rtDW.RateTransition3_WrBufIdx = static_cast<int8_t>
        (rtDW.RateTransition3_WrBufIdx == 0);
    }

    // End of RateTransition: '<S6>/Rate Transition3'

    // TaskTransBlk generated from: '<Root>/SpkDelayTask' incorporates:
    //   RateTransition: '<S6>/RT'

    rtDW.TmpTaskTransAtSpkDelayTaskOutpo = rtDW.RT_Buf[rtDW.RT_RdBufIdx];

    // End of Outputs for SubSystem: '<Root>/SpkDelayTask'
    rtw_pthread_sem_post_mac(rtDW.sw_buf_81);
  }
}

// OutputUpdate for Task: Periodic_TSK_SpkDelay
void SmartMicDrvTsk_Ccode::Periodic_TSK_SpkDelay_step(void) // Sample time: [0.5s, 0.0s] 
{
  {
    double slot[60];
    double slot_0;
    float a;
    float b_sintabinv_tmp;
    float dly;
    float tmp;
    float tmp_0;
    float *RateTransition1;
    int32_t d__tmp;
    int32_t i;
    int32_t k;
    int32_t xpageoffset;
    uint32_t qY;
    bool x[100];
    bool exitg1;
    bool y;

    // Outputs for Atomic SubSystem: '<Root>/SpkDelayTask'
    // RateTransition: '<S6>/Rate Transition'
    rtDW.RateTransition_RdBufIdx = static_cast<int8_t>
      (rtDW.RateTransition_RdBufIdx == 0);
    k = rtDW.RateTransition_RdBufIdx * 6000;

    // RateTransition: '<S6>/Rate Transition'
    std::memcpy(&rtDW.RateTransition[0], &rtDW.RateTransition_Buf[k], 6000U *
                sizeof(float));

    // RateTransition: '<S6>/Rate Transition2'
    rtDW.RateTransition2_RdBufIdx = static_cast<int8_t>
      (rtDW.RateTransition2_RdBufIdx == 0);

    // RateTransition: '<S6>/Rate Transition1'
    rtDW.RateTransition1_RdBufIdx = static_cast<int8_t>
      (rtDW.RateTransition1_RdBufIdx == 0);
    k = rtDW.RateTransition1_RdBufIdx * 6000;

    // RateTransition: '<S6>/Rate Transition1'
    RateTransition1 = &rtDW.RateTransition1_Buf[k];

    // RateTransition: '<S6>/Rate Transition3'
    rtDW.RateTransition3_RdBufIdx = static_cast<int8_t>
      (rtDW.RateTransition3_RdBufIdx == 0);

    // MATLABSystem: '<S6>/SpkDelaySystem' incorporates:
    //   RateTransition: '<S6>/Rate Transition'
    //   RateTransition: '<S6>/Rate Transition1'
    //   RateTransition: '<S6>/Rate Transition2'

    //  Computes the current speaker delay
    //  playix and recix are the index of the oldest frame
    //  Note that playix and recix shold always be the same
    //  if recix ~= playix
    //      fprintf("Internal error %f ~ %f\n", playix, recix);
    //  end
    for (i = 0; i < 6000; i++) {
      // RateTransition: '<S6>/Rate Transition'
      dly = rtDW.RateTransition[i];
      rtDW.d_[i] = dly * dly;
    }

    for (i = 0; i < 100; i++) {
      xpageoffset = i * 60;
      a = rtDW.d_[xpageoffset];
      for (k = 0; k < 59; k++) {
        a += rtDW.d_[(xpageoffset + k) + 1];
      }

      x[i] = (std::log10(std::sqrt(a / 60.0F) + 1.0E-8F) * 20.0F < -40.0F);
    }

    y = true;
    k = 0;
    exitg1 = false;
    while ((!exitg1) && (k < 100)) {
      if (!x[k]) {
        y = false;
        exitg1 = true;
      } else {
        k++;
      }
    }

    if (y) {
      k = rtDW.obj_kt.samples;
    } else {
      qY = rtDW.obj_kt.count + 1U;
      if (rtDW.obj_kt.count + 1U < rtDW.obj_kt.count) {
        qY = UINT32_MAX;
      }

      rtDW.obj_kt.count = qY;
      if (rtDW.obj_kt.count > 100000U) {
        rtDW.obj_kt.count = 100U;
      }

      if (rtDW.obj_kt.count < 20U) {
        a = 0.6F;
      } else {
        a = 0.9F;
      }

      std::memset(&rtDW.d_[0], 0, 6000U * sizeof(float));
      std::memset(&rtDW.y_[0], 0, 6000U * sizeof(float));
      for (k = 0; k < 60; k++) {
        slot[k] = static_cast<double>(k) + 1.0;
      }

      xpageoffset = rtDW.RateTransition2_Buf[rtDW.RateTransition2_RdBufIdx];
      for (i = 0; i < 100; i++) {
        for (k = 0; k < 60; k++) {
          slot_0 = slot[k];
          d__tmp = (xpageoffset - 1) * 60 + k;
          rtDW.d_[static_cast<int32_t>(slot_0) - 1] = RateTransition1[d__tmp];
          rtDW.y_[static_cast<int32_t>(slot_0) - 1] = rtDW.RateTransition[d__tmp];
          slot[k] = slot_0 + 60.0;
        }

        if (xpageoffset > 2147483646) {
          xpageoffset = INT32_MAX;
        } else {
          xpageoffset++;
        }

        if (xpageoffset > 100) {
          xpageoffset = 1;
        }
      }

      rtDW.costab1q[0] = 1.0F;
      for (k = 0; k < 2048; k++) {
        rtDW.costab1q[k + 1] = std::cos(static_cast<float>(k + 1) *
          0.000383495208F);
      }

      for (k = 0; k < 2047; k++) {
        rtDW.costab1q[k + 2049] = std::sin((2047.0F - static_cast<float>(k)) *
          0.000383495208F);
      }

      rtDW.costab1q[4096] = 0.0F;
      rtDW.b_costab[0] = 1.0F;
      rtDW.b_sintab[0] = 0.0F;
      for (k = 0; k < 4096; k++) {
        dly = rtDW.costab1q[4095 - k];
        rtDW.b_sintabinv[k + 1] = dly;
        b_sintabinv_tmp = rtDW.costab1q[k + 1];
        rtDW.b_sintabinv[k + 4097] = b_sintabinv_tmp;
        rtDW.b_costab[k + 1] = b_sintabinv_tmp;
        rtDW.b_sintab[k + 1] = -dly;
        rtDW.b_costab[k + 4097] = -dly;
        rtDW.b_sintab[k + 4097] = -b_sintabinv_tmp;
      }

      fft(rtDW.d_, rtDW.fcv);
      fft(rtDW.y_, rtDW.fcv1);
      for (k = 0; k < 6000; k++) {
        dly = rtDW.fcv1[k].re;
        b_sintabinv_tmp = -rtDW.fcv1[k].im;
        tmp = rtDW.fcv[k].re;
        tmp_0 = rtDW.fcv[k].im;
        rtDW.fcv2[k].re = tmp * dly - tmp_0 * b_sintabinv_tmp;
        rtDW.fcv2[k].im = tmp * b_sintabinv_tmp + tmp_0 * dly;
      }

      FFTImplementationCallback_doblu(rtDW.fcv2, rtDW.b_costab, rtDW.b_sintab,
        rtDW.b_sintabinv, rtDW.fcv);
      for (i = 0; i < 6000; i++) {
        rtDW.RateTransition[i] = rtDW.fcv[i].re;
      }

      b_sintabinv_tmp = rtDW.RateTransition[0];
      i = 1;
      for (k = 2; k < 6001; k++) {
        dly = rtDW.RateTransition[k - 1];
        if (b_sintabinv_tmp < dly) {
          b_sintabinv_tmp = dly;
          i = k;
        }
      }

      if (i > 3000) {
        i -= 6000;
      }

      dly = static_cast<float>(i) / 6000.0F;

      //  Make sure we do not jump too much, too fast.
      if (dly > rtDW.obj_kt.SpkDelayInstant + 0.1F) {
        dly = rtDW.obj_kt.SpkDelayInstant + 0.1F;
      } else if (dly < rtDW.obj_kt.SpkDelayInstant - 0.1F) {
        dly = rtDW.obj_kt.SpkDelayInstant - 0.1F;
      }

      rtDW.obj_kt.SpkDelayInstant = (1.0F - a) * dly + a *
        rtDW.obj_kt.SpkDelayInstant;

      //  We want the speaker to be about 1/2 frame early than the mic
      if (std::abs((rtDW.obj_kt.SpkDelayInstant - 0.005F) - rtDW.obj_kt.SpkDelay)
          > 0.002) {
        rtDW.obj_kt.SpkDelay = rtDW.obj_kt.SpkDelayInstant - 0.005F;
        tmp = std::round(rtDW.obj_kt.SpkDelay * 48000.0F);
        if (tmp < 2.14748365E+9F) {
          if (tmp >= -2.14748365E+9F) {
            rtDW.obj_kt.samples = static_cast<int32_t>(tmp);
          } else {
            rtDW.obj_kt.samples = INT32_MIN;
          }
        } else {
          rtDW.obj_kt.samples = INT32_MAX;
        }
      }

      k = rtDW.obj_kt.samples;
    }

    // RateTransition: '<S6>/RT' incorporates:
    //   MATLABSystem: '<S6>/SpkDelaySystem'

    rtDW.RT_WrBufIdx = static_cast<int8_t>(rtDW.RT_WrBufIdx == 0);
    rtDW.RT_Buf[rtDW.RT_WrBufIdx] = k;

    // End of Outputs for SubSystem: '<Root>/SpkDelayTask'
  }
}

// Model initialize function
void SmartMicDrvTsk_Ccode::initialize()
{
  // Registration code
  {
    // user code (registration function declaration)
    int tIdx;
    for (tIdx = 0; tIdx < 4; tIdx++) {
      // initialize real-time model
      (void) std::memset((void**)static_cast<void *>(&task_M[tIdx]), 0,
                         sizeof(RT_MODEL));
    }
  }

  {
    float tmp;
    int32_t i;
    int32_t loop_ub_tmp;

    // InitializeConditions for TaskTransBlk generated from: '<Root>/InputSubsystem' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_51, &rtDW.sw_buf_52, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/InputSubsystem' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_61, &rtDW.sw_buf_62, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/DownSampler' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_11, &rtDW.sw_buf_12, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/DownSampler' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_21, &rtDW.sw_buf_22, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/DownSampler' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_31, &rtDW.sw_buf_32, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/DownSampler' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_41, &rtDW.sw_buf_42, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/SpkDelayTask' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_81, &rtDW.sw_buf_82, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/TransformSubsystem' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_91, &rtDW.sw_buf_92, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/TransformSubsystem' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_101, &rtDW.sw_buf_102, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/TransformSubsystem' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_111, &rtDW.sw_buf_112, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/TransformSubsystem' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_121, &rtDW.sw_buf_122, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/TransformSubsystem' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_131, &rtDW.sw_buf_132, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/TransformSubsystem' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_141, &rtDW.sw_buf_142, 0);

    // InitializeConditions for TaskTransBlk generated from: '<Root>/LinearBandH' 
    rtw_pthread_sem_create_mac(&rtDW.sw_buf_71, &rtDW.sw_buf_72, 0);

    // SystemInitialize for Atomic SubSystem: '<Root>/DownSampler'
    SampleRateConverter_Init(&rtDW.SampleRateConverter_p);
    MATLABSystem_Init(&rtDW.MATLABSystem_p);
    SampleRateConverter_Init(&rtDW.SampleRateConverter1);
    MATLABSystem_Init(&rtDW.MATLABSystem2);

    // End of SystemInitialize for SubSystem: '<Root>/DownSampler'
    emxInitStruct_LinearAECSystem(&rtDW.obj_d);

    // SystemInitialize for Atomic SubSystem: '<Root>/LinearBandH'
    // Start for MATLABSystem: '<S3>/MATLAB System6'
    rtDW.obj_d.alphaDT = 0.015;
    rtDW.obj_d.alphaFEST = 0.15;
    rtDW.obj_d.dBignore = -50.0;
    rtDW.obj_d.isInitialized = 1;

    //  Perform one-time calculations, such as computing constants
    //  X signal
    // GAL2 Construct an instance of this class
    //    Detailed explanation goes here
    rtDW.obj_d.H.ntap = 12.0;
    rtDW.obj_d.H.N = 80.0;
    i = rtDW.obj_d.H.K->size[0] * rtDW.obj_d.H.K->size[1];
    rtDW.obj_d.H.K->size[0] = static_cast<int32_t>(rtDW.obj_d.H.N);
    rtDW.obj_d.H.K->size[1] = static_cast<int32_t>(rtDW.obj_d.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_d.H.K, i);
    loop_ub_tmp = static_cast<int32_t>(rtDW.obj_d.H.ntap + 1.0) *
      static_cast<int32_t>(rtDW.obj_d.H.N);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_d.H.K->data[i].re = 0.0F;
      rtDW.obj_d.H.K->data[i].im = 0.0F;
    }

    i = rtDW.obj_d.H.G->size[0] * rtDW.obj_d.H.G->size[1];
    rtDW.obj_d.H.G->size[0] = static_cast<int32_t>(rtDW.obj_d.H.N);
    rtDW.obj_d.H.G->size[1] = static_cast<int32_t>(rtDW.obj_d.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_d.H.G, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_d.H.G->data[i].re = 0.0F;
      rtDW.obj_d.H.G->data[i].im = 0.0F;
    }

    i = rtDW.obj_d.H.f->size[0] * rtDW.obj_d.H.f->size[1];
    rtDW.obj_d.H.f->size[0] = static_cast<int32_t>(rtDW.obj_d.H.N);
    rtDW.obj_d.H.f->size[1] = static_cast<int32_t>(rtDW.obj_d.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_d.H.f, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_d.H.f->data[i].re = 0.0F;
      rtDW.obj_d.H.f->data[i].im = 0.0F;
    }

    i = rtDW.obj_d.H.b->size[0] * rtDW.obj_d.H.b->size[1];
    rtDW.obj_d.H.b->size[0] = static_cast<int32_t>(rtDW.obj_d.H.N);
    rtDW.obj_d.H.b->size[1] = static_cast<int32_t>(rtDW.obj_d.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_d.H.b, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_d.H.b->data[i].re = 0.0F;
      rtDW.obj_d.H.b->data[i].im = 0.0F;
    }

    i = rtDW.obj_d.H.mu->size[0] * rtDW.obj_d.H.mu->size[1];
    rtDW.obj_d.H.mu->size[0] = static_cast<int32_t>(rtDW.obj_d.H.N);
    rtDW.obj_d.H.mu->size[1] = static_cast<int32_t>(rtDW.obj_d.H.ntap + 1.0);
    emxEnsureCapacity_float_j(rtDW.obj_d.H.mu, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_d.H.mu->data[i] = 1.0F;
    }

    // End of Start for MATLABSystem: '<S3>/MATLAB System6'
    // End of SystemInitialize for SubSystem: '<Root>/LinearBandH'
    //  Initialize / reset discrete-state properties
    emxInitStruct_LinearAECSystem(&rtDW.obj_k);

    // SystemInitialize for Atomic SubSystem: '<Root>/LinearBandH'
    // Start for MATLABSystem: '<S3>/MATLAB System5'
    rtDW.obj_k.alphaDT = 0.02;
    rtDW.obj_k.alphaFEST = 0.2;
    rtDW.obj_k.dBignore = -50.0;
    rtDW.obj_k.isInitialized = 1;

    //  Perform one-time calculations, such as computing constants
    //  X signal
    // GAL2 Construct an instance of this class
    //    Detailed explanation goes here
    rtDW.obj_k.H.ntap = 6.0;
    rtDW.obj_k.H.N = 80.0;
    i = rtDW.obj_k.H.K->size[0] * rtDW.obj_k.H.K->size[1];
    rtDW.obj_k.H.K->size[0] = static_cast<int32_t>(rtDW.obj_k.H.N);
    rtDW.obj_k.H.K->size[1] = static_cast<int32_t>(rtDW.obj_k.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_k.H.K, i);
    loop_ub_tmp = static_cast<int32_t>(rtDW.obj_k.H.ntap + 1.0) * static_cast<
      int32_t>(rtDW.obj_k.H.N);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_k.H.K->data[i].re = 0.0F;
      rtDW.obj_k.H.K->data[i].im = 0.0F;
    }

    i = rtDW.obj_k.H.G->size[0] * rtDW.obj_k.H.G->size[1];
    rtDW.obj_k.H.G->size[0] = static_cast<int32_t>(rtDW.obj_k.H.N);
    rtDW.obj_k.H.G->size[1] = static_cast<int32_t>(rtDW.obj_k.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_k.H.G, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_k.H.G->data[i].re = 0.0F;
      rtDW.obj_k.H.G->data[i].im = 0.0F;
    }

    i = rtDW.obj_k.H.f->size[0] * rtDW.obj_k.H.f->size[1];
    rtDW.obj_k.H.f->size[0] = static_cast<int32_t>(rtDW.obj_k.H.N);
    rtDW.obj_k.H.f->size[1] = static_cast<int32_t>(rtDW.obj_k.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_k.H.f, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_k.H.f->data[i].re = 0.0F;
      rtDW.obj_k.H.f->data[i].im = 0.0F;
    }

    i = rtDW.obj_k.H.b->size[0] * rtDW.obj_k.H.b->size[1];
    rtDW.obj_k.H.b->size[0] = static_cast<int32_t>(rtDW.obj_k.H.N);
    rtDW.obj_k.H.b->size[1] = static_cast<int32_t>(rtDW.obj_k.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_k.H.b, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_k.H.b->data[i].re = 0.0F;
      rtDW.obj_k.H.b->data[i].im = 0.0F;
    }

    i = rtDW.obj_k.H.mu->size[0] * rtDW.obj_k.H.mu->size[1];
    rtDW.obj_k.H.mu->size[0] = static_cast<int32_t>(rtDW.obj_k.H.N);
    rtDW.obj_k.H.mu->size[1] = static_cast<int32_t>(rtDW.obj_k.H.ntap + 1.0);
    emxEnsureCapacity_float_j(rtDW.obj_k.H.mu, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_k.H.mu->data[i] = 1.0F;
    }

    // End of Start for MATLABSystem: '<S3>/MATLAB System5'
    // End of SystemInitialize for SubSystem: '<Root>/LinearBandH'
    //  Initialize / reset discrete-state properties
    emxInitStruct_LinearAECSystem(&rtDW.obj_o);

    // SystemInitialize for Atomic SubSystem: '<Root>/LinearBandL'
    // Start for MATLABSystem: '<S4>/LinearAECL'
    rtDW.obj_o.alphaDT = 0.01;
    rtDW.obj_o.alphaFEST = 0.1;
    rtDW.obj_o.dBignore = -50.0;
    rtDW.obj_o.isInitialized = 1;

    //  Perform one-time calculations, such as computing constants
    //  X signal
    // GAL2 Construct an instance of this class
    //    Detailed explanation goes here
    rtDW.obj_o.H.ntap = 18.0;
    rtDW.obj_o.H.N = 161.0;
    i = rtDW.obj_o.H.K->size[0] * rtDW.obj_o.H.K->size[1];
    rtDW.obj_o.H.K->size[0] = static_cast<int32_t>(rtDW.obj_o.H.N);
    rtDW.obj_o.H.K->size[1] = static_cast<int32_t>(rtDW.obj_o.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_o.H.K, i);
    loop_ub_tmp = static_cast<int32_t>(rtDW.obj_o.H.ntap + 1.0) * static_cast<
      int32_t>(rtDW.obj_o.H.N);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_o.H.K->data[i].re = 0.0F;
      rtDW.obj_o.H.K->data[i].im = 0.0F;
    }

    i = rtDW.obj_o.H.G->size[0] * rtDW.obj_o.H.G->size[1];
    rtDW.obj_o.H.G->size[0] = static_cast<int32_t>(rtDW.obj_o.H.N);
    rtDW.obj_o.H.G->size[1] = static_cast<int32_t>(rtDW.obj_o.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_o.H.G, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_o.H.G->data[i].re = 0.0F;
      rtDW.obj_o.H.G->data[i].im = 0.0F;
    }

    i = rtDW.obj_o.H.f->size[0] * rtDW.obj_o.H.f->size[1];
    rtDW.obj_o.H.f->size[0] = static_cast<int32_t>(rtDW.obj_o.H.N);
    rtDW.obj_o.H.f->size[1] = static_cast<int32_t>(rtDW.obj_o.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_o.H.f, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_o.H.f->data[i].re = 0.0F;
      rtDW.obj_o.H.f->data[i].im = 0.0F;
    }

    i = rtDW.obj_o.H.b->size[0] * rtDW.obj_o.H.b->size[1];
    rtDW.obj_o.H.b->size[0] = static_cast<int32_t>(rtDW.obj_o.H.N);
    rtDW.obj_o.H.b->size[1] = static_cast<int32_t>(rtDW.obj_o.H.ntap + 1.0);
    emxEnsureCapacity_creal32_T(rtDW.obj_o.H.b, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_o.H.b->data[i].re = 0.0F;
      rtDW.obj_o.H.b->data[i].im = 0.0F;
    }

    i = rtDW.obj_o.H.mu->size[0] * rtDW.obj_o.H.mu->size[1];
    rtDW.obj_o.H.mu->size[0] = static_cast<int32_t>(rtDW.obj_o.H.N);
    rtDW.obj_o.H.mu->size[1] = static_cast<int32_t>(rtDW.obj_o.H.ntap + 1.0);
    emxEnsureCapacity_float_j(rtDW.obj_o.H.mu, i);
    for (i = 0; i < loop_ub_tmp; i++) {
      rtDW.obj_o.H.mu->data[i] = 1.0F;
    }

    // End of Start for MATLABSystem: '<S4>/LinearAECL'
    // End of SystemInitialize for SubSystem: '<Root>/LinearBandL'

    // SystemInitialize for Atomic SubSystem: '<Root>/OutputSubsystem'
    // Start for MATLABSystem: '<S5>/iFFTSystem'
    //  Initialize / reset discrete-state properties
    rtDW.obj.buff.pBuffer.matlabCodegenIsDeleted = true;
    rtDW.obj.buff.matlabCodegenIsDeleted = true;
    rtDW.obj.matlabCodegenIsDeleted = false;
    rtDW.obj.isInitialized = 1;
    iFFTSystem_setupImpl(&rtDW.obj);

    // End of SystemInitialize for SubSystem: '<Root>/OutputSubsystem'

    // SystemInitialize for Atomic SubSystem: '<Root>/SpkDelayTask'
    // InitializeConditions for RateTransition: '<S6>/RT'
    //  Initialize / reset discrete-state properties
    rtDW.RT_RdBufIdx = 1;

    // InitializeConditions for RateTransition: '<S6>/Rate Transition'
    rtDW.RateTransition_RdBufIdx = 1;

    // InitializeConditions for RateTransition: '<S6>/Rate Transition1'
    rtDW.RateTransition1_RdBufIdx = 1;

    // InitializeConditions for RateTransition: '<S6>/Rate Transition2'
    rtDW.RateTransition2_RdBufIdx = 1;

    // InitializeConditions for RateTransition: '<S6>/Rate Transition3'
    rtDW.RateTransition3_RdBufIdx = 1;

    // Start for MATLABSystem: '<S6>/SpkDelaySystem'
    //  Perform one-time calculations, such as computing constants
    rtDW.obj_kt.SpkDelay = 0.1F;
    rtDW.obj_kt.SpkDelayInstant = 0.1F;
    tmp = std::round(rtDW.obj_kt.SpkDelay * 48000.0F);
    if (tmp < 2.14748365E+9F) {
      if (tmp >= -2.14748365E+9F) {
        rtDW.obj_kt.samples = static_cast<int32_t>(tmp);
      } else {
        rtDW.obj_kt.samples = INT32_MIN;
      }
    } else {
      rtDW.obj_kt.samples = INT32_MAX;
    }

    rtDW.obj_kt.count = 0U;

    // End of Start for MATLABSystem: '<S6>/SpkDelaySystem'
    // End of SystemInitialize for SubSystem: '<Root>/SpkDelayTask'

    // SystemInitialize for Atomic SubSystem: '<Root>/TransformSubsystem'
    //  Initialize / reset discrete-state properties
    FFTSystem_Init(&rtDW.FFTSystem_p);
    FFTSystem_Init(&rtDW.FFTSystem1);

    // End of SystemInitialize for SubSystem: '<Root>/TransformSubsystem'
  }
}

// Constructor
SmartMicDrvTsk_Ccode::SmartMicDrvTsk_Ccode() :
  rtU(),
  rtY(),
  rtDW(),
  rtM()
{
  // Currently there is no constructor body generated.
}

// Destructor
// Currently there is no destructor body generated.
SmartMicDrvTsk_Ccode::~SmartMicDrvTsk_Ccode() = default;

// Real-Time Model get method
SmartMicDrvTsk_Ccode::RT_MODEL * SmartMicDrvTsk_Ccode::getRTM()
{
  return (&rtM);
}

// Task Real-Time Model get method
SmartMicDrvTsk_Ccode::RT_MODEL * SmartMicDrvTsk_Ccode::getTaskRTM()
{
  return task_M;
}

//
// File trailer for generated code.
//
// [EOF]
//
