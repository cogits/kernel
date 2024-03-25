/*
 * stop.c - Illustration of multi filed modules
 */

#include <linux/kernel.h> /* We are doing kernel work */
#include <linux/module.h> /* Specifically, a module */

void bye(void);

void cleanup_module(void)
{
	bye();
}

MODULE_IMPORT_NS(SYMBOL_NS_EXAMPLE);
MODULE_LICENSE("GPL");
