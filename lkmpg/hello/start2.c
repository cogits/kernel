/*
 * start.c - Illustration of multi filed modules
 */

#include <linux/kernel.h> /* We are doing kernel work */
#include <linux/module.h> /* Specifically, a module */

void hello(void)
{
	pr_info("Hello, world - this is the kernel speaking\n");
}

void bye(void)
{
	pr_info("Short is the life of a kernel module\n");
}

int init_module(void)
{
	hello();
	return 0;
}

EXPORT_SYMBOL_NS_GPL(bye, SYMBOL_NS_EXAMPLE);
MODULE_LICENSE("GPL");
