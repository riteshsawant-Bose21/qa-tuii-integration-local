//
// File: SmartMicDrvTsk_Ccode.h
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
#ifndef RTW_HEADER_SmartMicDrvTsk_Ccode_h_
#define RTW_HEADER_SmartMicDrvTsk_Ccode_h_
#include <stdbool.h>
#include <stdint.h>
#include "complex_types.h"
#include <cstring>

// Macros for accessing real-time model data structure
#ifndef rtmStepTask
#define rtmStepTask(rtm, idx)          ((rtm)->Timing.TaskCounters.TID[(idx)] == 0)
#endif

#ifndef rtmTaskCounter
#define rtmTaskCounter(rtm, idx)       ((rtm)->Timing.TaskCounters.TID[(idx)])
#endif

#ifndef struct_BufferSystem
#define struct_BufferSystem

struct BufferSystem
{
  float B[6000];
  int32_t ix;
};

#endif                                 // struct_BufferSystem

#ifndef struct_b_dsp_FIRDecimator_0
#define struct_b_dsp_FIRDecimator_0

struct b_dsp_FIRDecimator_0
{
  int32_t S0_isInitialized;
  int32_t W0_PhaseIdx;
  float W1_Sums;
  int32_t W2_CoeffIdx;
  float W3_StatesBuff[6];
  int32_t W4_TapDelayIndex;
  int32_t W5_PrevNumChan;
  float P0_IC;
  float P1_FILT[8];
  float O0_Y0[240];
};

#endif                                 // struct_b_dsp_FIRDecimator_0

#ifndef struct_b_dspcodegen_FIRDecimator
#define struct_b_dspcodegen_FIRDecimator

struct b_dspcodegen_FIRDecimator
{
  bool matlabCodegenIsDeleted;
  int32_t isInitialized;
  bool isSetupComplete;
  b_dsp_FIRDecimator_0 cSFunObject;
};

#endif                                 // struct_b_dspcodegen_FIRDecimator

#ifndef struct_b_dsp_FIRDecimator_1
#define struct_b_dsp_FIRDecimator_1

struct b_dsp_FIRDecimator_1
{
  int32_t S0_isInitialized;
  int32_t W0_PhaseIdx;
  float W1_Sums;
  int32_t W2_CoeffIdx;
  float W3_StatesBuff[12];
  int32_t W4_TapDelayIndex;
  int32_t W5_PrevNumChan;
  float P0_IC;
  float P1_FILT[16];
  float O0_Y0[60];
};

#endif                                 // struct_b_dsp_FIRDecimator_1

#ifndef struct_b_dspcodegen_FIRDecimator_1
#define struct_b_dspcodegen_FIRDecimator_1

struct b_dspcodegen_FIRDecimator_1
{
  bool matlabCodegenIsDeleted;
  int32_t isInitialized;
  bool isSetupComplete;
  b_dsp_FIRDecimator_1 cSFunObject;
};

#endif                                 // struct_b_dspcodegen_FIRDecimator_1

#ifndef struct_cell_wrap
#define struct_cell_wrap

struct cell_wrap
{
  uint32_t f1[8];
};

#endif                                 // struct_cell_wrap

#ifndef struct_dsp_simulink_SampleRateConverte
#define struct_dsp_simulink_SampleRateConverte

struct dsp_simulink_SampleRateConverte
{
  bool matlabCodegenIsDeleted;
  int32_t isInitialized;
  bool isSetupComplete;
  cell_wrap inputVarSize;
  int32_t NumChannels;
  b_dspcodegen_FIRDecimator *filt1;
  b_dspcodegen_FIRDecimator_1 *filt2;
  b_dspcodegen_FIRDecimator_1 _pobj0;
  b_dspcodegen_FIRDecimator _pobj1;
};

#endif                                // struct_dsp_simulink_SampleRateConverte

#ifndef struct_emxArray_float
#define struct_emxArray_float

struct emxArray_float
{
  float *data;
  int32_t *size;
  int32_t allocatedSize;
  int32_t numDimensions;
  bool canFreeData;
};

#endif                                 // struct_emxArray_float

#ifndef struct_emxArray_int32_t
#define struct_emxArray_int32_t

struct emxArray_int32_t
{
  int32_t *data;
  int32_t *size;
  int32_t allocatedSize;
  int32_t numDimensions;
  bool canFreeData;
};

#endif                                 // struct_emxArray_int32_t

#ifndef struct_h_dsp_internal_AsyncBuffercgHel
#define struct_h_dsp_internal_AsyncBuffercgHel

struct h_dsp_internal_AsyncBuffercgHel
{
  bool matlabCodegenIsDeleted;
  int32_t isInitialized;
  bool isSetupComplete;
  cell_wrap inputVarSize;
  int32_t NumChannels;
  float Cache[192001];
  int32_t CumulativeOverrun;
  int32_t CumulativeUnderrun;
  int32_t ReadPointer;
  int32_t WritePointer;
  bool AsyncBuffercgHelper_isInitialized;
};

#endif                                // struct_h_dsp_internal_AsyncBuffercgHel

#ifndef struct_b_dsp_AsyncBuffer
#define struct_b_dsp_AsyncBuffer

struct b_dsp_AsyncBuffer
{
  bool matlabCodegenIsDeleted;
  h_dsp_internal_AsyncBuffercgHel pBuffer;
};

#endif                                 // struct_b_dsp_AsyncBuffer

#ifndef struct_FFTSystem_p
#define struct_FFTSystem_p

struct FFTSystem_p
{
  bool matlabCodegenIsDeleted;
  int32_t isInitialized;
  b_dsp_AsyncBuffer buff;
  double ha[960];
};

#endif                                 // struct_FFTSystem_p

#ifndef struct_SpkDelaySystem
#define struct_SpkDelaySystem

struct SpkDelaySystem
{
  float SpkDelayInstant;
  float SpkDelay;
  int32_t samples;
  uint32_t count;
};

#endif                                 // struct_SpkDelaySystem

#ifndef struct_emxArray_creal32_T
#define struct_emxArray_creal32_T

struct emxArray_creal32_T
{
  creal32_T *data;
  int32_t *size;
  int32_t allocatedSize;
  int32_t numDimensions;
  bool canFreeData;
};

#endif                                 // struct_emxArray_creal32_T

#ifndef struct_c_GAL2
#define struct_c_GAL2

struct c_GAL2
{
  double ntap;
  double N;
  emxArray_creal32_T *K;
  emxArray_creal32_T *f;
  emxArray_creal32_T *b;
  emxArray_float *mu;
  emxArray_creal32_T *G;
};

#endif                                 // struct_c_GAL2

#ifndef struct_LinearAECSystem
#define struct_LinearAECSystem

struct LinearAECSystem
{
  int32_t isInitialized;
  double alphaDT;
  double alphaFEST;
  double dBignore;
  c_GAL2 H;
};

#endif                                 // struct_LinearAECSystem

#ifndef struct_iFFTSystem
#define struct_iFFTSystem

struct iFFTSystem
{
  bool matlabCodegenIsDeleted;
  int32_t isInitialized;
  b_dsp_AsyncBuffer buff;
  double hs[960];
};

#endif                                 // struct_iFFTSystem

// Class declaration for model SmartMicDrvTsk_Ccode
class SmartMicDrvTsk_Ccode final
{
  // public data and function members
 public:
  // Block signals and states (default storage) for system '<S1>/MATLAB System'
  struct DW_MATLABSystem {
    BufferSystem obj;                  // '<S1>/MATLAB System'
    float MATLABSystem_o1[6000];       // '<S1>/MATLAB System'
    int32_t MATLABSystem_o2;           // '<S1>/MATLAB System'
    bool objisempty;                   // '<S1>/MATLAB System'
  };

  // Block signals and states (default storage) for system '<S1>/Sample-Rate Converter' 
  struct DW_SampleRateConverter {
    dsp_simulink_SampleRateConverte obj;// '<S1>/Sample-Rate Converter'
    float SampleRateConverter_b[60];   // '<S1>/Sample-Rate Converter'
    bool objisempty;                   // '<S1>/Sample-Rate Converter'
    bool isInitialized;                // '<S1>/Sample-Rate Converter'
    bool isInitialized_f;              // '<S1>/Sample-Rate Converter'
  };

  // Block signals and states (default storage) for system '<S7>/FFTSystem'
  struct DW_FFTSystem {
    FFTSystem_p obj;                   // '<S7>/FFTSystem'
    double b[960];
    creal32_T FFTSystem_k[480];        // '<S7>/FFTSystem'
    creal32_T b_X[960];
    creal32_T wwc[959];
    creal32_T fy[1024];
    creal32_T fv[1024];
    bool objisempty;                   // '<S7>/FFTSystem'
  };

  // Block signals and states (default storage) for system '<Root>'
  struct DW {
    DW_FFTSystem FFTSystem1;           // '<S7>/FFTSystem'
    DW_FFTSystem FFTSystem_p;          // '<S7>/FFTSystem'
    DW_SampleRateConverter SampleRateConverter1;// '<S1>/Sample-Rate Converter'
    DW_SampleRateConverter SampleRateConverter_p;// '<S1>/Sample-Rate Converter' 
    DW_MATLABSystem MATLABSystem2;     // '<S1>/MATLAB System'
    DW_MATLABSystem MATLABSystem_p;    // '<S1>/MATLAB System'
    iFFTSystem obj;                    // '<S5>/iFFTSystem'
    LinearAECSystem obj_o;             // '<S4>/LinearAECL'
    LinearAECSystem obj_d;             // '<S3>/MATLAB System6'
    LinearAECSystem obj_k;             // '<S3>/MATLAB System5'
    SpkDelaySystem obj_kt;             // '<S6>/SpkDelaySystem'
    double b[960];
    creal32_T TmpTaskTransAtTransformSubsyste[80];// synthesized block
    creal32_T TmpTaskTransAtTransformSubsys_k[80];// synthesized block
    creal32_T TmpTaskTransAtTransformSubsys_b[80];// synthesized block
    creal32_T TmpTaskTransAtTransformSubsys_g[80];// synthesized block
    creal32_T TmpTaskTransAtTransformSubsy_hs[159];// synthesized block
    creal32_T TmpTaskTransAtLinearBandHOutpor[319];// synthesized block
    creal32_T fcv[6000];
    creal32_T fcv1[6000];
    creal32_T fcv2[6000];
    creal32_T b_X[960];
    creal32_T y[960];
    creal32_T wwc[1919];
    creal32_T fy[2048];
    creal32_T fv[2048];
    creal32_T wwc_m[5999];
    creal32_T wwc_c[11999];
    creal32_T fy_k[16384];
    creal32_T fv_c[16384];
    creal32_T ytmp[3000];
    creal32_T reconVar1[3000];
    creal32_T reconVar2[3000];
    creal32_T fy_b[8192];
    creal32_T fv_p[8192];
    creal32_T fy_c[8192];
    float VariableIntegerDelay_DSTATE[48000];// '<S7>/Variable Integer Delay'
    float TmpTaskTransAtInputSubsystemOut[480];// synthesized block
    float TmpTaskTransAtInputSubsystemO_n[480];// synthesized block
    float TmpTaskTransAtDownSamplerOutpor[6000];// synthesized block
    float TmpTaskTransAtDownSamplerOutp_i[6000];// synthesized block
    float RateTransition_Buf[12000];   // '<S6>/Rate Transition'
    float RateTransition1_Buf[12000];  // '<S6>/Rate Transition1'
    float TmpTaskTransAtSpkDelayTaskInp_f[6000];
    float TmpTaskTransAtSpkDelayTaskInp_g[6000];
    float d_[6000];
    float y_[6000];
    float costab1q[4097];
    float b_costab[8193];
    float b_sintab[8193];
    float b_sintabinv[8193];
    float RateTransition[6000];
    float costab1q_g[4097];
    float b_costab_m[8193];
    float b_sintab_n[8193];
    float b_sintabinv_p[8193];
    float hcostab[4096];
    float hsintab[4096];
    float hcostabinv[4096];
    float hsintabinv[4096];
    float costab1q_l[3001];
    float b_costab_j[6001];
    float b_sintab_d[6001];
    int32_t RT_Buf[2];                 // '<S6>/RT'
    int32_t RateTransition2_Buf[2];    // '<S6>/Rate Transition2'
    int32_t TmpTaskTransAtDownSamplerOutp_g;// synthesized block
    int32_t TmpTaskTransAtDownSamplerOutp_p;// synthesized block
    int32_t TmpTaskTransAtSpkDelayTaskOutpo;// synthesized block
    int32_t CircBufIdx;                // '<S7>/Variable Integer Delay'
    void* sw_buf_51;                   // synthesized block
    void* sw_buf_52;                   // synthesized block
    void* sw_buf_61;                   // synthesized block
    void* sw_buf_62;                   // synthesized block
    void* sw_buf_11;                   // synthesized block
    void* sw_buf_12;                   // synthesized block
    void* sw_buf_21;                   // synthesized block
    void* sw_buf_22;                   // synthesized block
    void* sw_buf_31;                   // synthesized block
    void* sw_buf_32;                   // synthesized block
    void* sw_buf_41;                   // synthesized block
    void* sw_buf_42;                   // synthesized block
    void* sw_buf_81;                   // synthesized block
    void* sw_buf_82;                   // synthesized block
    void* sw_buf_91;                   // synthesized block
    void* sw_buf_92;                   // synthesized block
    void* sw_buf_101;                  // synthesized block
    void* sw_buf_102;                  // synthesized block
    void* sw_buf_111;                  // synthesized block
    void* sw_buf_112;                  // synthesized block
    void* sw_buf_121;                  // synthesized block
    void* sw_buf_122;                  // synthesized block
    void* sw_buf_131;                  // synthesized block
    void* sw_buf_132;                  // synthesized block
    void* sw_buf_141;                  // synthesized block
    void* sw_buf_142;                  // synthesized block
    void* sw_buf_71;                   // synthesized block
    void* sw_buf_72;                   // synthesized block
    int16_t wrapIndex[3000];
    int8_t RT_RdBufIdx;                // '<S6>/RT'
    int8_t RT_WrBufIdx;                // '<S6>/RT'
    int8_t RateTransition_RdBufIdx;    // '<S6>/Rate Transition'
    int8_t RateTransition_WrBufIdx;    // '<S6>/Rate Transition'
    int8_t RateTransition1_RdBufIdx;   // '<S6>/Rate Transition1'
    int8_t RateTransition1_WrBufIdx;   // '<S6>/Rate Transition1'
    int8_t RateTransition2_RdBufIdx;   // '<S6>/Rate Transition2'
    int8_t RateTransition2_WrBufIdx;   // '<S6>/Rate Transition2'
    int8_t RateTransition3_RdBufIdx;   // '<S6>/Rate Transition3'
    int8_t RateTransition3_WrBufIdx;   // '<S6>/Rate Transition3'
  };

  // External inputs (root inport signals with default storage)
  struct ExtU {
    float MicIn[480];                  // '<Root>/MicIn'
    float FE[480];                     // '<Root>/FE'
  };

  // External outputs (root outports fed by signals with default storage)
  struct ExtY {
    float toFE[480];                   // '<Root>/toFE'
  };

  // Real-time Model Data Structure
  struct RT_MODEL {
    //
    //  Timing:
    //  The following substructure contains information regarding
    //  the timing information for the model.

    struct {
      struct {
        uint8_t TID[2];
      } TaskCounters;

      struct {
        uint8_t TID0_1;
      } RateInteraction;
    } Timing;
  };

  // Copy Constructor
  SmartMicDrvTsk_Ccode(SmartMicDrvTsk_Ccode const&) = delete;

  // Assignment Operator
  SmartMicDrvTsk_Ccode& operator= (SmartMicDrvTsk_Ccode const&) & = delete;

  // Move Constructor
  SmartMicDrvTsk_Ccode(SmartMicDrvTsk_Ccode &&) = delete;

  // Move Assignment Operator
  SmartMicDrvTsk_Ccode& operator= (SmartMicDrvTsk_Ccode &&) = delete;

  // Real-Time Model get method
  SmartMicDrvTsk_Ccode::RT_MODEL * getRTM();

  // Task Real-Time Model get method
  SmartMicDrvTsk_Ccode::RT_MODEL * getTaskRTM();

  // Root inports set method
  void setExternalInputs(const ExtU *pExtU)
  {
    rtU = *pExtU;
  }

  // Root outports get method
  const ExtY &getExternalOutputs() const
  {
    return rtY;
  }

  // model initialize function
  void initialize();

  // model step function
  void Discrete1_step();

  // model step function
  void Periodic_TSK_Main_step();

  // model step function
  void Periodic_TSK_2_step();

  // model step function
  void Periodic_TSK_SpkDelay_step();

  // Constructor
  SmartMicDrvTsk_Ccode();

  // Destructor
  ~SmartMicDrvTsk_Ccode();

  // private data and function members
 private:
  // External inputs
  ExtU rtU;

  // External outputs
  ExtY rtY;

  // Block states
  DW rtDW;

  // Real-Time Model for Tasks
  RT_MODEL task_M[4];

  // private member function(s) for subsystem '<S1>/MATLAB System'
  static void MATLABSystem_Init(DW_MATLABSystem *localDW);
  static void MATLABSystem(const float rtu_0[60], DW_MATLABSystem *localDW);

  // private member function(s) for subsystem '<S1>/Sample-Rate Converter'
  static void SampleRateConverter_Init(DW_SampleRateConverter *localDW);
  static void SampleRateConverter(const float rtu_0[480], DW_SampleRateConverter
    *localDW);

  // private member function(s) for subsystem '<S7>/FFTSystem'
  void FFTSystem_Init(DW_FFTSystem *localDW);
  void FFTSystem(const float rtu_0[480], DW_FFTSystem *localDW);
  void emxInit_int32_t(emxArray_int32_t **pEmxArray, int32_t numDimensions);
  void emxEnsureCapacity_int32_t(emxArray_int32_t *emxArray, int32_t oldNumel);
  void emxFree_int32_t(emxArray_int32_t **pEmxArray);
  int32_t AsyncBuffercgHelper_write(h_dsp_internal_AsyncBuffercgHel *obj, const
    float in[480]);
  void FFTSystem_setupImpl(FFTSystem_p *obj, DW_FFTSystem *localDW);
  void emxInit_float(emxArray_float **pEmxArray, int32_t numDimensions);
  void emxEnsureCapacity_float(emxArray_float *emxArray, int32_t oldNumel);
  void AsyncBuffercgHelper_ReadSamples(const h_dsp_internal_AsyncBuffercgHel
    *obj, emxArray_float *out, int32_t *underrun, int32_t *overlapUnderrun,
    int32_t *c);
  void emxFree_float(emxArray_float **pEmxArray);
  void FFTImplementationCallback_doH_j(const float x[960], creal32_T y[960],
    const creal32_T wwc[959], const float costabinv[1025], const float
    sintabinv[1025], DW_FFTSystem *localDW);

  // private member function(s) for subsystem '<Root>'
  void emxInit_creal32_T(emxArray_creal32_T **pEmxArray, int32_t numDimensions);
  void emxEnsureCapacity_creal32_T(emxArray_creal32_T *emxArray, int32_t
    oldNumel);
  void emxInit_float_j(emxArray_float **pEmxArray, int32_t numDimensions);
  void emxEnsureCapacity_float_j(emxArray_float *emxArray, int32_t oldNumel);
  void emxFree_creal32_T(emxArray_creal32_T **pEmxArray);
  void binary_expand_op_j(LinearAECSystem *in1, int32_t in2);
  void binary_expand_op(emxArray_creal32_T *in1, int32_t in2, const
                        LinearAECSystem *in3);
  void binary_expand_op_j3x(emxArray_float *in1, float in2, const
    LinearAECSystem *in3, int32_t in4, const emxArray_float *in5);
  void binary_expand_op_j3(LinearAECSystem *in1, int32_t in2, const
    emxArray_creal32_T *in3, const emxArray_creal32_T *in4);
  void emxFree_float_j(emxArray_float **pEmxArray);
  void binary_expand_op_j3xz2(creal32_T in1[161], const LinearAECSystem *in2,
    int32_t in3);
  void binary_expand_op_j3xz(LinearAECSystem *in1, int32_t in2, const creal32_T
    in3[161]);
  void emxInit_int32_t_j(emxArray_int32_t **pEmxArray, int32_t numDimensions);
  void emxEnsureCapacity_int32_t_j(emxArray_int32_t *emxArray, int32_t oldNumel);
  void emxFree_int32_t_j(emxArray_int32_t **pEmxArray);
  void AsyncBuffercgHelper_ReadSampl_j(const h_dsp_internal_AsyncBuffercgHel
    *obj, emxArray_float *out, int32_t *underrun, int32_t *c);
  int32_t AsyncBuffercgHelper_write_j(h_dsp_internal_AsyncBuffercgHel *obj,
    const float in[480]);
  void iFFTSystem_stepImpl(iFFTSystem *obj, const creal32_T X_0[480], float u
    [480]);
  void binary_expand_op_j3xz2e4k(creal32_T in1[80], const LinearAECSystem *in2,
    int32_t in3);
  void binary_expand_op_j3xz2e4(LinearAECSystem *in1, int32_t in2, const
    creal32_T in3[80]);
  void FFTImplementationCallback_r2br_(const creal32_T x[8192], const float
    costab[4096], const float sintab[4096], creal32_T y[8192]);
  void FFTImplementationCallback_d_j3x(const float x[6000], int32_t xoffInit,
    creal32_T y[6000], const creal32_T wwc[5999], const float costab[8193],
    const float sintab[8193], const float costabinv[8193], const float
    sintabinv[8193]);
  void fft(const float x[6000], creal32_T y[6000]);
  void FFTImplementationCallback_doblu(const creal32_T x[6000], const float
    costab[8193], const float sintab[8193], const float sintabinv[8193],
    creal32_T y[6000]);
  void emxFreeStruct_c_GAL2(c_GAL2 *pStruct);
  void emxFreeStruct_LinearAECSystem(LinearAECSystem *pStruct);
  void emxInitStruct_c_GAL2(c_GAL2 *pStruct);
  void emxInitStruct_LinearAECSystem(LinearAECSystem *pStruct);
  void iFFTSystem_setupImpl(iFFTSystem *obj);

  // Real-Time Model
  RT_MODEL rtM;
};

//-
//  These blocks were eliminated from the model due to optimizations:
//
//  Block '<S6>/RT1' : Unused code path elimination


//-
//  The generated code includes comments that allow you to trace directly
//  back to the appropriate location in the model.  The basic format
//  is <system>/block_name, where system is the system number (uniquely
//  assigned by Simulink) and block_name is the name of the block.
//
//  Use the MATLAB hilite_system command to trace the generated code back
//  to the model.  For example,
//
//  hilite_system('<S3>')    - opens system 3
//  hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
//
//  Here is the system hierarchy for this model
//
//  '<Root>' : 'SmartMicDrvTsk_Ccode'
//  '<S1>'   : 'SmartMicDrvTsk_Ccode/DownSampler'
//  '<S2>'   : 'SmartMicDrvTsk_Ccode/InputSubsystem'
//  '<S3>'   : 'SmartMicDrvTsk_Ccode/LinearBandH'
//  '<S4>'   : 'SmartMicDrvTsk_Ccode/LinearBandL'
//  '<S5>'   : 'SmartMicDrvTsk_Ccode/OutputSubsystem'
//  '<S6>'   : 'SmartMicDrvTsk_Ccode/SpkDelayTask'
//  '<S7>'   : 'SmartMicDrvTsk_Ccode/TransformSubsystem'


//-
//  Requirements for '<Root>': SmartMicDrvTsk_Ccode


#endif                                 // RTW_HEADER_SmartMicDrvTsk_Ccode_h_

//
// File trailer for generated code.
//
// [EOF]
//
