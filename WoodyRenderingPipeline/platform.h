#ifndef __PLATFORM_H__
#define __PLATFORM_H__

//#include "tgaimage.h"

typedef struct window window_t;
typedef enum { KEY_A, KEY_D, KEY_S, KEY_W, KEY_SPACE, KEY_NUM } keycode_t;
typedef enum { BUTTON_L, BUTTON_R, BUTTON_NUM } button_t;


/* platform initialization */
void platform_initialize(void);
void platform_terminate(void);

#endif //__PLATFORM_H__