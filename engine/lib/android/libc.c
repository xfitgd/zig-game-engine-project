#include <stdio.h>
#include <errno.h>

int __vfprintf_chk(FILE* stream, int flag, const char* format, va_list ap)
{
    return vfprintf(stream, format, ap);
}

int* __errno_location() {
  return __errno();
}