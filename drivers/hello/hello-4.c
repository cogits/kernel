/*
 * hello-4.c - Demonstrates module documentation.
 */
#include <linux/init.h>	  /* Needed for the macros */
#include <linux/module.h> /* Needed by all modules */
#include <linux/printk.h> /* Needed for pr_info() */

// Some examples are "GPL", "GPL v2", "GPL and additional rights", "Dual BSD/GPL",
// "Dual MIT/GPL", "Dual MPL/GPL" and "Proprietary".
MODULE_LICENSE("Proprietary");
MODULE_AUTHOR("LKMPG");
MODULE_DESCRIPTION("A sample driver");

static int __init init_hello_4(void)
{
	pr_info("Hello, world 4\n");
	return 0;
}

static void __exit cleanup_hello_4(void)
{
	pr_info("Goodbye, world 4\n");
}

module_init(init_hello_4);
module_exit(cleanup_hello_4);
