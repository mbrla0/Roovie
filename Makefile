PROJECTS=bl kernel

all:
	for i in $(PROJECTS); \
	do \
		make -C $$i all || exit 1; \
	done

clean:
	for i in $(PROJECTS); \
	do \
		make -C $$i clean || exit 1; \
	done
