#include <linux/init.h>
#include <linux/delay.h>
#include <linux/module.h>
#include <linux/workqueue.h>

typedef struct {
	uint x;
	struct delayed_work dw;
} work_t;

static struct workqueue_struct *queue = NULL;
static work_t work[12];

static void work_handler(struct work_struct *data)
{
	work_t *w = container_of(container_of(data, struct delayed_work, work), work_t, dw);
	pr_info("[%u] work handler function: tick %lu\n", w->x, jiffies);
	msleep(20);
}

static int __init sched_init(void)
{
	queue = alloc_workqueue("HELLOWORLD", WQ_UNBOUND, 3);
	for (uint i = 0; i < 12; i++) {
		work[i].x = i;
		INIT_DELAYED_WORK(&work[i].dw, work_handler);
		queue_delayed_work(queue, &work[i].dw, 1 * HZ);
	}
    return 0;
}

static void __exit sched_exit(void)
{
	destroy_workqueue(queue);
}

module_init(sched_init);
module_exit(sched_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Workqueue example");
