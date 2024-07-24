#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/timer.h>
#include <linux/jiffies.h>

struct timer_list my_timer;

// 定时器回调函数
void my_timer_callback(struct timer_list *t) {
    printk(KERN_INFO "Timer callback executed\n");

    // 重新设置定时器，使任务循环执行
    mod_timer(t, jiffies + msecs_to_jiffies(2000)); // 2000毫秒后再次执行
}

static int __init my_timer_init(void) {
    printk(KERN_INFO "Timer module installing\n");

    // 初始化定时器
    timer_setup(&my_timer, my_timer_callback, 0);

    // 启动定时器，2000毫秒后第一次执行
    my_timer.expires = jiffies + msecs_to_jiffies(2000);
    add_timer(&my_timer);

    return 0;
}

static void __exit my_timer_exit(void) {
    printk(KERN_INFO "Timer module exiting\n");

    // 删除定时器
    del_timer(&my_timer);
}

module_init(my_timer_init);
module_exit(my_timer_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("chatglm");
MODULE_DESCRIPTION("A simple Linux kernel module using a timer to execute a task periodically.");

