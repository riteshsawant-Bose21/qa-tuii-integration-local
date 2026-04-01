/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// OCALiteController.cpp : Defines the entry point for the OCA Controller application.
//

#ifndef _CONTROLPAL_OCA_UTILS_H
#define _CONTROLPAL_OCA_UTILS_H

::OcaLiteRoot* FindObject(::OcaONo blockOno, OcaLiteClassID classId);

::OcaONo FindParentZoneBlock(::OcaONo objONo);

#endif
