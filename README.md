# asmcat — Line-Numbered File Reader in x86-64 Assembly

A command-line utility that reads one or more files and prints their contents to stdout with continuous line numbering. Written entirely in **x86-64 assembly for Linux**.

## Features

- **Line numbering**: Automatically numbers every line across all input files with continuous counting
- **Multiple file support**: Process multiple files in one command
- **Large file handling**: Supports files larger than 64 KB using a 64 KB read buffer
- **ANSI terminal detection**: Clears screen and homes cursor when output is a TTY
- **Efficient string operations**: Uses x86-64 string instructions (SCASB, STOSB) for performance
- **Clean error handling**: Informative error messages for missing or inaccessible files

## Usage


./numblines [-h] <file1> [file2] ...

*Examples

# Display a single file with line numbers
./numblines myfile.txt

# Display multiple files (line numbering continues across files)
./numblines file1.txt file2.txt file3.txt

# Show help message
./numblines -h

*Requirements

    NASM (Netwide Assembler) — for assembly compilation
    ld (GNU linker) — for linking object files
    Linux x86-64 environment

*Project Structure
asmcat/
├── main.asm          # Main program entry point, argument parsing, file opening
├── proc.asm          # External procedure: file reading and output
├── macros.mac        # Reusable assembly macros (print\_str, sys\_exit, etc.)
├── Makefile          # Build configuration
├── .gitignore        # Git ignore rules
└── README.md         # This file
