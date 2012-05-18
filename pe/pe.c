/* pe.c
 * Read DOS and PE headers from an executable
 */

#include <stdio.h>
#include <stdlib.h>

#include "pe.h"

#define READ_BYTE(v)  v = read_byte(fh);  btotal += 1;
#define READ_WORD(v)  v = read_word(fh);  btotal += 2;
#define READ_DWORD(v) v = read_dword(fh); btotal += 4;

/* Return a byte as an unsigned char (8 bits) */
BYTE read_byte(FILE *fh) {
	return (BYTE) fgetc(fh);
}

/* Return 2 bytes as an unsigned short (16 bits) */
WORD read_word(FILE *fh) {
	int a, b;

	a = fgetc(fh);
	b = fgetc(fh);

	b <<= 8;

	return (WORD) (a | b);
}

/* Return 4 bytes as an unsigned long (32 bits) */
DWORD read_dword(FILE *fh) {
	int a, b, c, d;

	a = fgetc(fh);
	b = fgetc(fh);
	c = fgetc(fh);
	d = fgetc(fh);

	d <<= 24;
	c <<= 16;
	b <<= 8;
	a <<= 0;

	return (DWORD) (a | b | c | d);
}

void slurp_dos_header(dos_header *header, FILE *fh, int *bytes_read) {
	int j;
	int btotal = 0;

	header->e_magic    = read_word(fh); btotal += 2;
	header->e_cblp     = read_word(fh); btotal += 2;
	header->e_cp       = read_word(fh); btotal += 2;
	header->e_crlc     = read_word(fh); btotal += 2;
	header->e_cparhdr  = read_word(fh); btotal += 2;
	header->e_minalloc = read_word(fh); btotal += 2;
	header->e_maxalloc = read_word(fh); btotal += 2;
	header->e_ss       = read_word(fh); btotal += 2;
	header->e_sp       = read_word(fh); btotal += 2;
	header->e_csum     = read_word(fh); btotal += 2;
	header->e_ip       = read_word(fh); btotal += 2;
	header->e_cs       = read_word(fh); btotal += 2;
	header->e_lfarlc   = read_word(fh); btotal += 2;
	header->e_ovno     = read_word(fh); btotal += 2;

	for (j = 0; j < 4; ++j) {
		header->e_res[j] = read_word(fh); btotal += 2;
	}

	header->e_oemid   = read_word(fh); btotal += 2;
	header->e_oeminfo = read_word(fh); btotal += 2;

	for (j = 0; j < 10; ++j) {
		header->e_res2[j] = read_word(fh); btotal += 2;
	}

	header->e_lfanew = read_dword(fh); btotal += 4;

	*bytes_read = btotal;
}

void slurp_pe_header(pe_header *header, FILE *fh, int *bytes_read) {
	int btotal = 0;

	header->Signature            = read_dword(fh); btotal += 4;
	header->Machine              = read_word(fh);  btotal += 2;
	header->NumberOfSections     = read_word(fh);  btotal += 2;
	header->TimeDateStamp        = read_dword(fh); btotal += 4;
	header->PointerToSymbolTable = read_dword(fh); btotal += 4;
	header->NumberOfSymbols      = read_dword(fh); btotal += 4;
	header->SizeOfOptionalHeader = read_word(fh);  btotal += 2;
	header->Characteristics      = read_word(fh);  btotal += 2;

	if (header->SizeOfOptionalHeader > 0) {
		int j;

		header->Magic                       = read_word(fh);  btotal += 2;
		header->MajorLinkerVersion          = read_byte(fh);  btotal += 1;
		header->MinorLinkerVersion          = read_byte(fh);  btotal += 1;
		header->SizeOfCode                  = read_dword(fh); btotal += 4;
		header->SizeOfInitializedData       = read_dword(fh); btotal += 4;
		header->SizeOfUninitializedData     = read_dword(fh); btotal += 4;
		header->AddressOfEntryPoint         = read_dword(fh); btotal += 4;
		header->BaseOfCode                  = read_dword(fh); btotal += 4;
		header->BaseOfData                  = read_dword(fh); btotal += 4;
		header->ImageBase                   = read_dword(fh); btotal += 4;
		header->SectionAlignment            = read_dword(fh); btotal += 4;
		header->FileAlignment               = read_dword(fh); btotal += 4;
		header->MajorOperatingSystemVersion = read_word(fh);  btotal += 2;
		header->MinorOperatingSystemVersion = read_word(fh);  btotal += 2;
		header->MajorImageVersion           = read_word(fh);  btotal += 2;
		header->MinorImageVersion           = read_word(fh);  btotal += 2;
		header->MajorSubsystemVersion       = read_word(fh);  btotal += 2;
		header->MinorSubsystemVersion       = read_word(fh);  btotal += 2;
		header->Win32VersionValue           = read_dword(fh); btotal += 4;
		header->SizeOfImage                 = read_dword(fh); btotal += 4;
		header->SizeOfHeaders               = read_dword(fh); btotal += 4;
		header->CheckSum                    = read_dword(fh); btotal += 4;
		header->Subsystem                   = read_word(fh);  btotal += 2;
		header->DllCharacteristics          = read_word(fh);  btotal += 2;
		header->SizeOfStackReserve          = read_dword(fh); btotal += 4;
		header->SizeOfStackCommit           = read_dword(fh); btotal += 4;
		header->SizeOfHeapReserve           = read_dword(fh); btotal += 4;
		header->SizeOfHeapCommit            = read_dword(fh); btotal += 4;
		header->LoaderFlags                 = read_dword(fh); btotal += 4;
		header->NumberOfRvaAndSizes         = read_dword(fh); btotal += 4;

		header->DataDirectories = (pe_data_directory *)
			malloc(sizeof(pe_data_directory) * header->NumberOfRvaAndSizes);
		for (j = 0; j < header->NumberOfRvaAndSizes; ++j) {
			header->DataDirectories[j]->VirtualAddress = read_dword(fh); btotal += 4;
			header->DataDirectories[j]->Size           = read_dword(fh); btotal += 4;
		}
	}

	*bytes_read = btotal;
}

int main(int argc, char **argv) {
	FILE *fh;
	dos_header *dos;
	pe_header *pe;

	if (argc < 2) {
		fprintf(stderr, "Not enough arguments.\n");
		return 1;
	}

	if ((fh = fopen(argv[1], "rb")) != NULL) {
		int dos_header_bytes, pe_header_bytes;
		int j;

		dos = (dos_header *) malloc(sizeof(dos_header));
		slurp_dos_header(dos, fh, &dos_header_bytes);

		printf("Size of MZ header: %d\n", dos_header_bytes);
		printf("Magic number: 0x%04hx\n", dos->e_magic);
		printf("PE header offset: 0x%08lx\n", dos->e_lfanew);

		/* jump to PE header */
		for (j = dos_header_bytes; j < dos->e_lfanew; ++j) {
			fgetc(fh);
		}

		pe = (pe_header *) malloc(sizeof(pe_header));
		slurp_pe_header(pe, fh, &pe_header_bytes);

		printf("\n");
		printf("Size of PE header: %d\n", pe_header_bytes);
		printf("Signature: 0x%08lx\n", pe->Signature);
		printf("Machine: 0x%04hx\n", pe->Machine);
		printf("Number of Sections: 0x%04hx\n", pe->NumberOfSections);
		printf("Size of Optional Header: 0x%04hx\n", pe->SizeOfOptionalHeader);
		printf("Characteristics: 0x%04hx\n", pe->Characteristics);
		printf("Magic: 0x%04hx\n", pe->Magic);
		printf("Address of Entry Point: 0x%08lx\n", pe->AddressOfEntryPoint);
		printf("Image Base: 0x%08lx\n", pe->ImageBase);
		printf("Section Alignment: 0x%08lx\n", pe->SectionAlignment);
		printf("File Alignment: 0x%08lx\n", pe->FileAlignment);
		printf("Major Subsystem Version: 0x%04hx\n", pe->MajorSubsystemVersion);
		printf("Size of Image: 0x%08lx\n", pe->SizeOfImage);
		printf("Size of Headers: 0x%08lx\n", pe->SizeOfHeaders);
		printf("Subsystem: 0x%04hx\n", pe->Subsystem);
		printf("Number of Rva and Sizes: 0x%08lx\n", pe->NumberOfRvaAndSizes);
	}
	else {
		perror(argv[1]);
		return 1;
	}


	return 0;
}

