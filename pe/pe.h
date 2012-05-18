/* pe.h
 * DOS and PE header structures
 * http://www.skynet.ie/~caolan/pub/winresdump/winresdump/doc/pefile.html
 */

#ifndef __PE_H__
#define __PE_H__

typedef unsigned char  BYTE;
typedef unsigned short WORD;
typedef unsigned long  DWORD;

typedef struct {
	WORD  e_magic;    /* Magic number */
	WORD  e_cblp;     /* Bytes on last page of file */
	WORD  e_cp;       /* Pages in file */
	WORD  e_crlc;     /* Relocations */
	WORD  e_cparhdr;  /* Size of header in paragraphs */
	WORD  e_minalloc; /* Minimum extra paragraphs needed */
	WORD  e_maxalloc; /* Maximum extra paragraphs needed */
	WORD  e_ss;       /* Initial (relative) SS value */
	WORD  e_sp;       /* Initial SP value */
	WORD  e_csum;     /* Checksum */
	WORD  e_ip;       /* Initial IP value */
	WORD  e_cs;       /* Initial (relative) CS value */
	WORD  e_lfarlc;   /* File address of relocation table */
	WORD  e_ovno;     /* Overlay number */
	WORD  e_res[4];   /* Reserved words */
	WORD  e_oemid;    /* OEM identifier (for e_oeminfo) */
	WORD  e_oeminfo;  /* OEM information; e_oemid specific */
	WORD  e_res2[10]; /* Reserved words */
	DWORD e_lfanew;   /* Address of PE header */
} dos_header;

typedef struct {
	DWORD VirtualAddress;
	DWORD Size;
} pe_data_directory;

typedef struct {
	DWORD Signature;

	/* File Header */
	WORD  Machine;
	WORD  NumberOfSections;
	DWORD TimeDateStamp;
	DWORD PointerToSymbolTable;
	DWORD NumberOfSymbols;
	WORD  SizeOfOptionalHeader;
	WORD  Characteristics;

	/* Optional Header */

	/* Standard fields */
	WORD  Magic;
	BYTE  MajorLinkerVersion;
	BYTE  MinorLinkerVersion;
	DWORD SizeOfCode;
	DWORD SizeOfInitializedData;
	DWORD SizeOfUninitializedData;
	DWORD AddressOfEntryPoint;
	DWORD BaseOfCode;
	DWORD BaseOfData;

	/* Additional fields */
	DWORD ImageBase;
	DWORD SectionAlignment;
	DWORD FileAlignment;
	WORD  MajorOperatingSystemVersion;
	WORD  MinorOperatingSystemVersion;
	WORD  MajorImageVersion;
	WORD  MinorImageVersion;
	WORD  MajorSubsystemVersion;
	WORD  MinorSubsystemVersion;
	DWORD Win32VersionValue;
	DWORD SizeOfImage;
	DWORD SizeOfHeaders;
	DWORD CheckSum;
	WORD  Subsystem;
	WORD  DllCharacteristics;
	DWORD SizeOfStackReserve;
	DWORD SizeOfStackCommit;
	DWORD SizeOfHeapReserve;
	DWORD SizeOfHeapCommit;
	DWORD LoaderFlags;
	DWORD NumberOfRvaAndSizes;
	pe_data_directory *DataDirectories; /* length == NumberOfRvaAndSizes */
} pe_header;

BYTE  read_byte(FILE *);
WORD  read_word(FILE *);
DWORD read_dword(FILE *);

void slurp_dos_header(dos_header *, FILE *, int *);
void slurp_pe_header(pe_header *, FILE *, int *);

#endif

