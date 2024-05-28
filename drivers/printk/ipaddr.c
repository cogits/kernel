/*
 * ipaddr.c - print IP addresses.
 */

#include <linux/module.h> /* Needed by all modules */
#include <linux/printk.h> /* Needed for pr_info() */
#include <linux/in.h>     /* Needed for struct sockaddr_in */

int init_module(void)
{
	uint32_t localhost = cpu_to_be32(0x7f000001);
	pr_info("localhost: %pI4\n", &localhost);

	struct sockaddr_in sa;
	sa.sin_family = AF_INET;
	sa.sin_port = cpu_to_be16(12345);
	sa.sin_addr.s_addr = localhost;

	pr_info("sin_addr: %pIS\n", &sa);

	/* A non 0 return means init_module failed; module will not be loaded. */
	return -1;
}

void cleanup_module(void) { }

MODULE_LICENSE("GPL");
