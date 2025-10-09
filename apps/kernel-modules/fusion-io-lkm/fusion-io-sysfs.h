/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * Copyright 2024 Bose Professional.
 * Common Sysfs Infrastructure for Fusion IO Drivers
 */

#ifndef _FUSION_IO_SYSFS_H
#define _FUSION_IO_SYSFS_H

#include <linux/device.h>
#include <linux/platform_device.h>

// Class for Fusion IO devices
extern struct class *fusion_io_class;

int fusion_io_create_sysfs_base(struct platform_device *pdev);
void fusion_io_remove_sysfs_base(struct platform_device *pdev);

int fusion_io_create_sysfs_io_card(struct platform_device *pdev, struct io_card *ic);
void fusion_io_remove_sysfs_io_card(struct platform_device *pdev, struct io_card *ic);

#endif /* _FUSION_IO_SYSFS_H */
