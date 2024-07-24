#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/sched.h>
#include <linux/delay.h>
#include <linux/kthread.h>
#include <linux/semaphore.h>

static struct semaphore sem1, sem2;
static struct task_struct *thread1, *thread2;

// 死锁函数1
static int deadlock_func1(void *data) {
    printk(KERN_INFO "Deadlock function 1 acquired sem1\n");
    down(&sem1); // 获取信号量1

    // 做一些其他操作，比如让出CPU时间片
    msleep(1000);

    printk(KERN_INFO "Deadlock function 1 trying to acquire sem2\n");
    down(&sem2); // 尝试获取信号量2，这将导致死锁

    // 正常情况下这里会释放信号量，但由于死锁，代码不会执行到这里
    up(&sem1);
    up(&sem2);

    return 0;
}

// 死锁函数2
static int deadlock_func2(void *data) {
    printk(KERN_INFO "Deadlock function 2 acquired sem2\n");
    down(&sem2); // 获取信号量2

    // 做一些其他操作，比如让出CPU时间片
    msleep(1000);

    printk(KERN_INFO "Deadlock function 2 trying to acquire sem1\n");
    down(&sem1); // 尝试获取信号量1，这将导致死锁

    // 正常情况下这里会释放信号量，但由于死锁，代码不会执行到这里
    up(&sem2);
    up(&sem1);

    return 0;
}

// 初始化模块
static int __init deadlock_init(void) {
    sema_init(&sem1, 1); // 初始化信号量为1
    sema_init(&sem2, 1); // 初始化信号量为1

    printk(KERN_INFO "Deadlock module installing\n");

    // 创建两个进程分别运行死锁函数
    thread1 = kthread_run(deadlock_func1, NULL, "deadlock_func1");
    if (IS_ERR(thread1)) {
        printk(KERN_ERR "Failed to create deadlock_func1 thread\n");
        return PTR_ERR(thread1);
    }

    thread2 = kthread_run(deadlock_func2, NULL, "deadlock_func2");
    if (IS_ERR(thread2)) {
        printk(KERN_ERR "Failed to create deadlock_func2 thread\n");
        kthread_stop(thread1);
        return PTR_ERR(thread2);
    }

    return 0;
}

// 清理模块
static void __exit deadlock_exit(void) {
    printk(KERN_INFO "Deadlock module exiting\n");
    // 停止线程
    kthread_stop(thread1);
    kthread_stop(thread2);
    // 释放信号量
    down(&sem1);
    down(&sem2);
    up(&sem1);
    up(&sem2);
}

module_init(deadlock_init);
module_exit(deadlock_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("chatglm");
MODULE_DESCRIPTION("A simple Linux kernel module demonstrating a deadlock.");

