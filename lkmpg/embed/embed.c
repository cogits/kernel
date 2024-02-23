/*
 * embed.c - Implementing #embed for kernel module.
 */

#include <linux/init.h>	  /* Needed for the macros */
#include <linux/module.h> /* Needed by all modules */
#include <linux/printk.h> /* Needed for pr_info() */

extern const char _binary_art_txt_start[];
extern const char _binary_art_txt_end[];

static int __init embed_init(void)
{
	size_t length = _binary_art_txt_end - _binary_art_txt_start;
	pr_info("start: %p, end: %p\n", _binary_art_txt_start, _binary_art_txt_end);
	pr_info("The binary is %zu(%zu) bytes and the first character is %c.\n",
	 length, strlen(_binary_art_txt_start), _binary_art_txt_start[0]);

	pr_info("%s", _binary_art_txt_start);

	return 0;
}

static void __exit embed_exit(void)
{
	pr_info("Goodbye\n");
}

module_init(embed_init);
module_exit(embed_exit);

MODULE_LICENSE("GPL");
