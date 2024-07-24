#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kthread.h>
#include <linux/init.h>
#include <linux/delay.h>

static int softlockup_thread(void *data) {
    printk(KERN_INFO "Soft lockup simulation thread started\n");

    // 无限循环，模拟软锁
    while (1) {
        // 这里不做任何调度器友好的操作，比如 cond_resched()
        // 这将导致这个线程长时间占用CPU
    }

    return 0;
}

static int __init softlockup_init(void) {
    printk(KERN_INFO "Soft lockup module installing\n");

    // 创建一个内核线程来模拟软锁
    kthread_run(softlockup_thread, NULL, "softlockup_thread");

    return 0;
}

static void __exit softlockup_exit(void) {
    printk(KERN_INFO "Soft lockup module exiting\n");
}

module_init(softlockup_init);
module_exit(softlockup_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("chatglm");
MODULE_DESCRIPTION("A simple Linux kernel module simulating a soft lockup.");
