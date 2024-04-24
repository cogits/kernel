/*
 * sched.c
 */
#include <linux/init.h>
#include <linux/module.h>
#include <linux/workqueue.h>

static struct workqueue_struct *queue = NULL;
static struct delayed_work work;

static void work_handler(struct work_struct *data)
{
	pr_info("work handler function: tick %lu\n", jiffies);
	queue_delayed_work(queue, &work, 500);
}

static int __init sched_init(void)
{
	queue = alloc_workqueue("HELLOWORLD", WQ_UNBOUND, 1);
	INIT_DELAYED_WORK(&work, work_handler);
	queue_delayed_work(queue, &work, 1);
	return 0;
}

static void __exit sched_exit(void)
{
	pr_info("destroy workqueue\n");
	cancel_delayed_work(&work);
	destroy_workqueue(queue);
}

module_init(sched_init);
module_exit(sched_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Workqueue example");
