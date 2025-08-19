// WarningDisable.h
// portable way of disabling warnings for both win/mac
// from: https://www.fluentcpp.com/2019/08/30/how-to-disable-a-warning-in-cpp/
// for usage note that you have to define the specific warning to disable in order to do it for both win/mac
// since win uses number and mac uses name there's no way other than this approach to cleanly handle in code.
// usage:
// DISABLE_WARNING_PUSH
// DISABLE_WARNING_POTENTIAL_DIVIDE_BY_ZERO
// 1/0
// DISABLE_WARNING_POP
#pragma once
#ifndef WARNINGDISABLE_H
#define WARNINGDISABLE_H

#if defined(_MSC_VER)
#define DISABLE_WARNING_PUSH           __pragma(warning( push ))
#define DISABLE_WARNING_POP            __pragma(warning( pop )) 
#define DISABLE_WARNING(warningNumber) __pragma(warning( disable : warningNumber ))

#define DISABLE_WARNING_UNREFERENCED_FORMAL_PARAMETER    DISABLE_WARNING(4100)
#define DISABLE_WARNING_UNREFERENCED_FUNCTION            DISABLE_WARNING(4505)
#define DISABLE_WARNING_DECLARATION_HIDES_GLOBAL         DISABLE_WARNING(4459)
#define DISABLE_WARNING_POTENTIAL_DIVIDE_BY_ZERO         DISABLE_WARNING(4723)
// other warnings you want to deactivate...

#elif defined(__GNUC__) || defined(__clang__)
#define DO_PRAGMA(X) _Pragma(#X)
#define DISABLE_WARNING_PUSH           DO_PRAGMA(GCC diagnostic push)
#define DISABLE_WARNING_POP            DO_PRAGMA(GCC diagnostic pop) 
#define DISABLE_WARNING(warningName)   DO_PRAGMA(GCC diagnostic ignored #warningName)

#define DISABLE_WARNING_UNREFERENCED_FORMAL_PARAMETER    DISABLE_WARNING(-Wunused-parameter)
#define DISABLE_WARNING_UNREFERENCED_FUNCTION            DISABLE_WARNING(-Wunused-function)
#define DISABLE_WARNING_DECLARATION_HIDES_GLOBAL         // DISABLE_WARNING(-W) // TODO:
#define DISABLE_WARNING_POTENTIAL_DIVIDE_BY_ZERO         // DISABLE_WARNING(-W) // TODO:
// other warnings you want to deactivate... 

#else
#define DISABLE_WARNING_PUSH
#define DISABLE_WARNING_POP
#define DISABLE_WARNING_UNREFERENCED_FORMAL_PARAMETER
#define DISABLE_WARNING_UNREFERENCED_FUNCTION
#define DISABLE_WARNING_DECLARATION_HIDES_GLOBAL
#define DISABLE_WARNING_POTENTIAL_DIVIDE_BY_ZERO

// other warnings you want to deactivate... 

#endif

#endif
