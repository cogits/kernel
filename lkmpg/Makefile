DIRS := \
		hello

all:
	@for dir in $(DIRS); do \
		echo "build $$dir"; \
		make -C $$dir; \
	done

clean:
	@for dir in $(DIRS); do \
		echo "clean $$dir"; \
		make -C $$dir clean; \
	done
