/*
 * Copyright (c) 2023, Erich Styger
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include "platform.h"
#include "McuRTOS.h"
#include <stdio.h>
#if PL_CONFIG_USE_GCOV
  #include "gcov_support.h"
#endif

int main(void) {
  PL_Init();
  vTaskStartScheduler();
#if PL_CONFIG_USE_GCOV
   gcov_write_files(); /* write coverage data files */
#endif
  for(;;) {
    /* do not return from main() */
  }
  return 0;
}
