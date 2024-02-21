/*
 * stop.c - Illustration of multi filed modules
 */

#include <linux/kernel.h> /* We are doing kernel work */
#include <linux/module.h> /* Specifically, a module */
void bye(void);

void hello(void)
{
	pr_info("Hello, world - this is the kernel speaking\n");
}

void cleanup_module(void)
{
	bye();
}

MODULE_LICENSE("GPL");
