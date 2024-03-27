/*
 * start.c - Illustration of multi filed modules
 */

#include <linux/kernel.h> /* We are doing kernel work */
#include <linux/module.h> /* Specifically, a module */
void hello(void);

void bye(void)
{
	pr_info("Short is the life of a kernel module\n");
}

int init_module(void)
{
	hello();
	return 0;
}

MODULE_LICENSE("GPL");
