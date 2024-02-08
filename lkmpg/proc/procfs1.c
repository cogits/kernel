/*
 * procfs1.c
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/uaccess.h>
#include <linux/version.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 6, 0)
#define HAVE_PROC_OPS
#endif

#define PROCFS_NAME "helloworld"

static struct proc_dir_entry *our_proc_file;

// Be careful with this function, if it never returns zero, the read function is called endlessly.
static ssize_t procfile_read(struct file *file_pointer, char __user *buffer, size_t buffer_length, loff_t *offset)
{
	char s[13] = "HelloWorld!\n";
	int len = sizeof(s);
	ssize_t ret = len;

	if (*offset >= len) {
		pr_info("EOF\n");
		ret = 0;
	} else if (copy_to_user(buffer, s, len)) {
		pr_info("copy_to_user failed\n");
		ret = -EFAULT;
	} else {
		pr_info("procfile read %s\n", file_pointer->f_path.dentry->d_name.name);
		*offset += len;
	}

	return ret;
}

#ifdef HAVE_PROC_OPS
// the file which never disappears in /proc can set the proc_flag as PROC_ENTRY_PERMANENT
// to save 2 atomic ops, 1 allocation, 1 free in per open/read/close sequence.
static const struct proc_ops proc_file_fops = {
    .proc_read = procfile_read,
};
#else
static const struct file_operations proc_file_fops = {
    .read = procfile_read,
};
#endif

static int __init procfs1_init(void)
{
	our_proc_file = proc_create(PROCFS_NAME, 0644, NULL, &proc_file_fops);
	if (NULL == our_proc_file) {
		proc_remove(our_proc_file);
		pr_alert("Error:Could not initialize /proc/%s\n", PROCFS_NAME);
		return -ENOMEM;
	}

	pr_info("/proc/%s created\n", PROCFS_NAME);
	return 0;
}

static void __exit procfs1_exit(void)
{
	proc_remove(our_proc_file);
	pr_info("/proc/%s removed\n", PROCFS_NAME);
}

module_init(procfs1_init);
module_exit(procfs1_exit);

MODULE_LICENSE("GPL");
