# another way of building external kernel module directory
# note the last `/`, it's necessary.
obj-y += hello/

DIRS := \
	chardev \
	proc \
	sysfs \
	embed \
	threads

all:
	@for dir in $(DIRS); do \
		echo "build $$dir"; \
		make -C $$dir; \
	done

clean:
	# unfortunately, these's no way of cleaning the directory automatically
	git clean -fdx hello

	@for dir in $(DIRS); do \
		echo "clean $$dir"; \
		make -C $$dir clean; \
	done
