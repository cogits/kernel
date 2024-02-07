/*
 * hello-3.c - Illustrating the __init, __initdata and __exit macros.
 */
#include <linux/init.h>	  /* Needed for the macros */
#include <linux/module.h> /* Needed by all modules */
#include <linux/printk.h> /* Needed for pr_info() */

static int hello3_data __initdata = 3;

// The __init macro causes the init function to be discarded and its memory freed
// once the init function finishes for built-in drivers, but not loadable modules.
static int __init hello_3_init(void)
{
	pr_info("Hello, world %d\n", hello3_data);
	return 0;
}

// The __exit macro causes the omission of the function when the module is built
// into the kernel, and like __init , has no effect for loadable modules.
static void __exit hello_3_exit(void)
{
	pr_info("Goodbye, world 3\n");
}

module_init(hello_3_init);
module_exit(hello_3_exit);

MODULE_LICENSE("GPL");

// These macros serve to free up kernel memory. When you boot your kernel and see
// something like Freeing unused kernel memory: 236k freed, this is precisely what
// the kernel is freeing.
