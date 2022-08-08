PROJECTS=bl kernel

all:
	for i in $(PROJECTS); \
	do \
		make -C $$i all; \
	done

clean:
	for i in $(PROJECTS); \
	do \
		make -C $$i clean; \
	done
