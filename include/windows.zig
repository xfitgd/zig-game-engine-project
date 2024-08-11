pub const BOOL = c_int;
pub const CHAR = u8;
pub const SHORT = c_short;
pub const INT = c_int;
pub const LONG = c_long;
pub const UCHAR = u8;
pub const USHORT = c_ushort;
pub const UINT = c_uint;
pub const ULONG = c_ulong;
pub const BYTE = u8;
pub const WORD = c_ushort;
pub const FLOAT = f32;
pub const DWORD = c_ulong;
pub const wchar_t = c_ushort;
pub const WCHAR = wchar_t;
pub const PWCHAR = [*c]wchar_t;
pub const ATOM = WORD;
pub const ULONG32 = c_uint;
pub const DWORD64 = u64;
pub const ULONG64 = u64;
pub const INT32 = c_int;
pub const INT64 = c_longlong;
pub const DWORDLONG = u64;
pub const PCHAR = [*c]CHAR;
pub const PULONG = [*c]ULONG;
pub const PULONG64 = [*c]ULONG64;
pub const PDWORD64 = [*c]DWORD64;
pub const LONGLONG = i64;
pub const ULONGLONG = u64;
pub const VOID = anyopaque;
pub const PVOID = ?*anyopaque;
pub const LPVOID = ?*anyopaque;
pub const PBOOL = [*c]BOOL;
pub const LPBOOL = [*c]BOOL;
pub const PWORD = [*c]WORD;
pub const PLONG = [*c]LONG;
pub const LPLONG = [*c]LONG;
pub const PDWORD = [*c]DWORD;
pub const HANDLE = LPVOID;
pub const HINSTANCE = HANDLE;
pub const HWND = HANDLE;
pub const HMODULE = HINSTANCE;
pub const HDC = HANDLE;
pub const HGLRC = HANDLE;
pub const HMENU = HANDLE;
pub const PHANDLE = [*c]HANDLE;
pub const LPHANDLE = [*c]HANDLE;
pub const PWSTR = [*c]WCHAR;
pub const LPBYTE = [*c]BYTE;
pub const LPDWORD = [*c]DWORD;
pub const LPCVOID = ?*const anyopaque;
pub const INT_PTR = i64;
pub const LONG_PTR = i64;
pub const UINT_PTR = u64;
pub const ULONG_PTR = u64;
pub const DWORD_PTR = ULONG_PTR;
pub const PDWORD_PTR = [*c]DWORD_PTR;
pub const SIZE_T = ULONG_PTR;
pub const SSIZE_T = LONG_PTR;
pub const LPSTR = [*c]CHAR;
pub const LPWSTR = [*c]WCHAR;
pub const LPCSTR = [*c]const CHAR;
pub const LPCWSTR = [*c]const WCHAR;
pub const TCHAR = u8;
pub const TBYTE = u8;
pub const LPCTSTR = LPCSTR;
pub const LPTSTR = LPSTR;
pub const FARPROC = ?*const fn () callconv(.C) INT_PTR;
pub const NEARPROC = ?*const fn () callconv(.C) INT_PTR;
pub const PROC = ?*const fn () callconv(.C) INT_PTR;
pub const ACCESS_MASK = DWORD;
pub const PACCESS_MASK = [*c]ACCESS_MASK;
pub const HICON = HANDLE;
pub const HBRUSH = HANDLE;
pub const HCURSOR = HICON;
pub const HRESULT = LONG;
pub const LRESULT = LONG_PTR;
pub const LPARAM = LONG_PTR;
pub const WPARAM = UINT_PTR;
pub const HGDIOBJ = ?*anyopaque;
pub const HKEY = HANDLE;
pub const PHKEY = [*c]HKEY;
pub const REGSAM = ACCESS_MASK;
pub const struct__SECURITY_ATTRIBUTES = extern struct {
    nLength: DWORD = @import("std").mem.zeroes(DWORD),
    lpSecurityDescriptor: LPVOID = @import("std").mem.zeroes(LPVOID),
    bInheritHandle: BOOL = @import("std").mem.zeroes(BOOL),
};
pub const SECURITY_ATTRIBUTES = struct__SECURITY_ATTRIBUTES;
pub const PSECURITY_ATTRIBUTES = [*c]struct__SECURITY_ATTRIBUTES;
pub const LPSECURITY_ATTRIBUTES = [*c]struct__SECURITY_ATTRIBUTES;
const struct_unnamed_1 = extern struct {
    LowPart: DWORD = @import("std").mem.zeroes(DWORD),
    HighPart: LONG = @import("std").mem.zeroes(LONG),
};
const struct_unnamed_2 = extern struct {
    LowPart: DWORD = @import("std").mem.zeroes(DWORD),
    HighPart: LONG = @import("std").mem.zeroes(LONG),
};
pub const union__LARGE_INTEGER = extern union {
    unnamed_0: struct_unnamed_1,
    u: struct_unnamed_2,
    QuadPart: LONGLONG,
};
pub const LARGE_INTEGER = union__LARGE_INTEGER;
pub const PLARGE_INTEGER = [*c]union__LARGE_INTEGER;
const struct_unnamed_3 = extern struct {
    LowPart: DWORD = @import("std").mem.zeroes(DWORD),
    HighPart: DWORD = @import("std").mem.zeroes(DWORD),
};
const struct_unnamed_4 = extern struct {
    LowPart: DWORD = @import("std").mem.zeroes(DWORD),
    HighPart: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const union__ULARGE_INTEGER = extern union {
    unnamed_0: struct_unnamed_3,
    u: struct_unnamed_4,
    QuadPart: ULONGLONG,
};
pub const ULARGE_INTEGER = union__ULARGE_INTEGER;
pub const PULARGE_INTEGER = [*c]union__ULARGE_INTEGER;
pub const struct__FILETIME = extern struct {
    dwLowDateTime: DWORD = @import("std").mem.zeroes(DWORD),
    dwHighDateTime: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const FILETIME = struct__FILETIME;
pub const PFILETIME = [*c]struct__FILETIME;
pub const LPFILETIME = [*c]struct__FILETIME;
pub extern fn _mm_pause() void;
pub extern fn _ReadWriteBarrier() void;
pub extern fn _InterlockedExchange8(Target: [*c]volatile u8, Value: u8) u8;
pub extern fn _InterlockedExchangeAdd8(Addend: [*c]volatile u8, Value: u8) u8;
pub extern fn _InterlockedExchangeAnd8(Destination: [*c]volatile u8, Value: u8) u8;
pub extern fn _InterlockedExchangeOr8(Destination: [*c]volatile u8, Value: u8) u8;
pub extern fn _InterlockedExchangeXor8(Destination: [*c]volatile u8, Value: u8) u8;
pub extern fn _InterlockedDecrement8(Addend: [*c]volatile u8) u8;
pub extern fn _InterlockedIncrement8(Addend: [*c]volatile u8) u8;
pub extern fn _InterlockedCompareExchange8(Destination: [*c]volatile u8, Exchange: u8, Comparand: u8) u8;
pub extern fn _InterlockedCompareExchange8_HLEAcquire(Destination: [*c]volatile u8, Exchange: u8, Comparand: u8) u8;
pub extern fn _InterlockedCompareExchange8_HLERelease(Destination: [*c]volatile u8, Exchange: u8, Comparand: u8) u8;
pub extern fn _InterlockedExchange16(Target: [*c]volatile c_short, Value: c_short) c_short;
pub extern fn _InterlockedExchangeAdd16(Addend: [*c]volatile c_short, Value: c_short) c_short;
pub extern fn _InterlockedExchangeAnd16(Destination: [*c]volatile c_short, Value: c_short) c_short;
pub extern fn _InterlockedExchangeOr16(Destination: [*c]volatile c_short, Value: c_short) c_short;
pub extern fn _InterlockedExchangeXor16(Destination: [*c]volatile c_short, Value: c_short) c_short;
pub extern fn _InterlockedDecrement16(Addend: [*c]volatile c_short) c_short;
pub extern fn _InterlockedIncrement16(Addend: [*c]volatile c_short) c_short;
pub extern fn _InterlockedCompareExchange16(Destination: [*c]volatile c_short, Exchange: c_short, Comparand: c_short) c_short;
pub extern fn _InterlockedCompareExchange16_HLEAcquire(Destination: [*c]volatile c_short, Exchange: c_short, Comparand: c_short) c_short;
pub extern fn _InterlockedCompareExchange16_HLERelease(Destination: [*c]volatile c_short, Exchange: c_short, Comparand: c_short) c_short;
pub extern fn _InterlockedExchange(Target: [*c]volatile c_long, Value: c_long) c_long;
pub extern fn _InterlockedExchangeAdd(Addend: [*c]volatile c_long, Value: c_long) c_long;
pub extern fn _InterlockedExchangeAnd(Destination: [*c]volatile c_long, Value: c_long) c_long;
pub extern fn _InterlockedExchangeOr(Destination: [*c]volatile c_long, Value: c_long) c_long;
pub extern fn _InterlockedExchangeXor(Destination: [*c]volatile c_long, Value: c_long) c_long;
pub extern fn _InterlockedDecrement(Addend: [*c]volatile c_long) c_long;
pub extern fn _InterlockedIncrement(Addend: [*c]volatile c_long) c_long;
pub extern fn _InterlockedCompareExchange(Destination: [*c]volatile c_long, Exchange: c_long, Comparand: c_long) c_long;
pub extern fn _InterlockedCompareExchange_HLEAcquire(Destination: [*c]volatile c_long, Exchange: c_long, Comparand: c_long) c_long;
pub extern fn _InterlockedCompareExchange_HLERelease(Destination: [*c]volatile c_long, Exchange: c_long, Comparand: c_long) c_long;
pub const SymTagNull: c_int = 0;
pub const SymTagExe: c_int = 1;
pub const SymTagCompiland: c_int = 2;
pub const SymTagCompilandDetails: c_int = 3;
pub const SymTagCompilandEnv: c_int = 4;
pub const SymTagFunction: c_int = 5;
pub const SymTagBlock: c_int = 6;
pub const SymTagData: c_int = 7;
pub const SymTagAnnotation: c_int = 8;
pub const SymTagLabel: c_int = 9;
pub const SymTagPublicSymbol: c_int = 10;
pub const SymTagUDT: c_int = 11;
pub const SymTagEnum: c_int = 12;
pub const SymTagFunctionType: c_int = 13;
pub const SymTagPointerType: c_int = 14;
pub const SymTagArrayType: c_int = 15;
pub const SymTagBaseType: c_int = 16;
pub const SymTagTypedef: c_int = 17;
pub const SymTagBaseClass: c_int = 18;
pub const SymTagFriend: c_int = 19;
pub const SymTagFunctionArgType: c_int = 20;
pub const SymTagFuncDebugStart: c_int = 21;
pub const SymTagFuncDebugEnd: c_int = 22;
pub const SymTagUsingNamespace: c_int = 23;
pub const SymTagVTableShape: c_int = 24;
pub const SymTagVTable: c_int = 25;
pub const SymTagCustom: c_int = 26;
pub const SymTagThunk: c_int = 27;
pub const SymTagCustomType: c_int = 28;
pub const SymTagManagedType: c_int = 29;
pub const SymTagDimension: c_int = 30;
pub const SymTagCallSite: c_int = 31;
pub const SymTagInlineSite: c_int = 32;
pub const SymTagBaseInterface: c_int = 33;
pub const SymTagVectorType: c_int = 34;
pub const SymTagMatrixType: c_int = 35;
pub const SymTagHLSLType: c_int = 36;
pub const enum_SymTagEnum = c_uint;
const union_unnamed_5 = extern union {
    FiberData: ?*anyopaque,
    Version: DWORD,
};
pub const struct__NT_TIB = extern struct {
    ExceptionList: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    StackBase: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    StackLimit: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    SubSystemTib: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    unnamed_0: union_unnamed_5 = @import("std").mem.zeroes(union_unnamed_5),
    ArbitraryUserPointer: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    Self: [*c]struct__NT_TIB = @import("std").mem.zeroes([*c]struct__NT_TIB),
};
pub const NT_TIB = struct__NT_TIB;
pub const LPNT_TIB = [*c]struct__NT_TIB;
pub const PNT_TIB = [*c]struct__NT_TIB;
pub const struct__M128A = extern struct {
    Low: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    High: LONGLONG = @import("std").mem.zeroes(LONGLONG),
};
pub const M128A = struct__M128A;
pub const PM128A = [*c]struct__M128A;
pub const struct__XSAVE_FORMAT = extern struct {
    ControlWord: WORD = @import("std").mem.zeroes(WORD),
    StatusWord: WORD = @import("std").mem.zeroes(WORD),
    TagWord: BYTE = @import("std").mem.zeroes(BYTE),
    Reserved1: BYTE = @import("std").mem.zeroes(BYTE),
    ErrorOpcode: WORD = @import("std").mem.zeroes(WORD),
    ErrorOffset: DWORD = @import("std").mem.zeroes(DWORD),
    ErrorSelector: WORD = @import("std").mem.zeroes(WORD),
    Reserved2: WORD = @import("std").mem.zeroes(WORD),
    DataOffset: DWORD = @import("std").mem.zeroes(DWORD),
    DataSelector: WORD = @import("std").mem.zeroes(WORD),
    Reserved3: WORD = @import("std").mem.zeroes(WORD),
    MxCsr: DWORD = @import("std").mem.zeroes(DWORD),
    MxCsr_Mask: DWORD = @import("std").mem.zeroes(DWORD),
    FloatRegisters: [8]M128A = @import("std").mem.zeroes([8]M128A),
    XmmRegisters: [16]M128A = @import("std").mem.zeroes([16]M128A),
    Reserved4: [96]BYTE = @import("std").mem.zeroes([96]BYTE),
};
pub const XSAVE_FORMAT = struct__XSAVE_FORMAT;
pub const PXSAVE_FORMAT = [*c]struct__XSAVE_FORMAT;
pub const XMM_SAVE_AREA32 = XSAVE_FORMAT;
pub const PXMM_SAVE_AREA32 = [*c]XSAVE_FORMAT;
const struct_unnamed_7 = extern struct {
    Header: [2]M128A = @import("std").mem.zeroes([2]M128A),
    Legacy: [8]M128A = @import("std").mem.zeroes([8]M128A),
    Xmm0: M128A = @import("std").mem.zeroes(M128A),
    Xmm1: M128A = @import("std").mem.zeroes(M128A),
    Xmm2: M128A = @import("std").mem.zeroes(M128A),
    Xmm3: M128A = @import("std").mem.zeroes(M128A),
    Xmm4: M128A = @import("std").mem.zeroes(M128A),
    Xmm5: M128A = @import("std").mem.zeroes(M128A),
    Xmm6: M128A = @import("std").mem.zeroes(M128A),
    Xmm7: M128A = @import("std").mem.zeroes(M128A),
    Xmm8: M128A = @import("std").mem.zeroes(M128A),
    Xmm9: M128A = @import("std").mem.zeroes(M128A),
    Xmm10: M128A = @import("std").mem.zeroes(M128A),
    Xmm11: M128A = @import("std").mem.zeroes(M128A),
    Xmm12: M128A = @import("std").mem.zeroes(M128A),
    Xmm13: M128A = @import("std").mem.zeroes(M128A),
    Xmm14: M128A = @import("std").mem.zeroes(M128A),
    Xmm15: M128A = @import("std").mem.zeroes(M128A),
};
const union_unnamed_6 = extern union {
    FltSave: XMM_SAVE_AREA32,
    DUMMYSTRUCTNAME: struct_unnamed_7,
};
pub const struct__CONTEXT = extern struct {
    P1Home: DWORD64 = @import("std").mem.zeroes(DWORD64),
    P2Home: DWORD64 = @import("std").mem.zeroes(DWORD64),
    P3Home: DWORD64 = @import("std").mem.zeroes(DWORD64),
    P4Home: DWORD64 = @import("std").mem.zeroes(DWORD64),
    P5Home: DWORD64 = @import("std").mem.zeroes(DWORD64),
    P6Home: DWORD64 = @import("std").mem.zeroes(DWORD64),
    ContextFlags: DWORD = @import("std").mem.zeroes(DWORD),
    MxCsr: DWORD = @import("std").mem.zeroes(DWORD),
    SegCs: WORD = @import("std").mem.zeroes(WORD),
    SegDs: WORD = @import("std").mem.zeroes(WORD),
    SegEs: WORD = @import("std").mem.zeroes(WORD),
    SegFs: WORD = @import("std").mem.zeroes(WORD),
    SegGs: WORD = @import("std").mem.zeroes(WORD),
    SegSs: WORD = @import("std").mem.zeroes(WORD),
    EFlags: DWORD = @import("std").mem.zeroes(DWORD),
    Dr0: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Dr1: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Dr2: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Dr3: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Dr6: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Dr7: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rax: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rcx: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rdx: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rbx: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rsp: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rbp: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rsi: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rdi: DWORD64 = @import("std").mem.zeroes(DWORD64),
    R8: DWORD64 = @import("std").mem.zeroes(DWORD64),
    R9: DWORD64 = @import("std").mem.zeroes(DWORD64),
    R10: DWORD64 = @import("std").mem.zeroes(DWORD64),
    R11: DWORD64 = @import("std").mem.zeroes(DWORD64),
    R12: DWORD64 = @import("std").mem.zeroes(DWORD64),
    R13: DWORD64 = @import("std").mem.zeroes(DWORD64),
    R14: DWORD64 = @import("std").mem.zeroes(DWORD64),
    R15: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Rip: DWORD64 = @import("std").mem.zeroes(DWORD64),
    DUMMYUNIONNAME: union_unnamed_6 = @import("std").mem.zeroes(union_unnamed_6),
    VectorRegister: [26]M128A = @import("std").mem.zeroes([26]M128A),
    VectorControl: DWORD64 = @import("std").mem.zeroes(DWORD64),
    DebugControl: DWORD64 = @import("std").mem.zeroes(DWORD64),
    LastBranchToRip: DWORD64 = @import("std").mem.zeroes(DWORD64),
    LastBranchFromRip: DWORD64 = @import("std").mem.zeroes(DWORD64),
    LastExceptionToRip: DWORD64 = @import("std").mem.zeroes(DWORD64),
    LastExceptionFromRip: DWORD64 = @import("std").mem.zeroes(DWORD64),
};
pub const CONTEXT = struct__CONTEXT;
pub const PCONTEXT = [*c]struct__CONTEXT;
pub const LPCONTEXT = PCONTEXT;
pub const struct__EXCEPTION_RECORD = extern struct {
    ExceptionCode: DWORD = @import("std").mem.zeroes(DWORD),
    ExceptionFlags: DWORD = @import("std").mem.zeroes(DWORD),
    ExceptionRecord: [*c]struct__EXCEPTION_RECORD = @import("std").mem.zeroes([*c]struct__EXCEPTION_RECORD),
    ExceptionAddress: PVOID = @import("std").mem.zeroes(PVOID),
    NumberParameters: DWORD = @import("std").mem.zeroes(DWORD),
    ExceptionInformation: [15]ULONG_PTR = @import("std").mem.zeroes([15]ULONG_PTR),
};
pub const EXCEPTION_RECORD = struct__EXCEPTION_RECORD;
pub const PEXCEPTION_RECORD = [*c]struct__EXCEPTION_RECORD;
pub const struct__EXCEPTION_POINTERS = extern struct {
    ExceptionRecord: PEXCEPTION_RECORD = @import("std").mem.zeroes(PEXCEPTION_RECORD),
    ContextRecord: PCONTEXT = @import("std").mem.zeroes(PCONTEXT),
};
pub const EXCEPTION_POINTERS = struct__EXCEPTION_POINTERS;
pub const PEXCEPTION_POINTERS = [*c]struct__EXCEPTION_POINTERS;
pub const LPEXCEPTION_POINTERS = PEXCEPTION_POINTERS;
pub const PTOP_LEVEL_EXCEPTION_FILTER = ?*const fn ([*c]struct__EXCEPTION_POINTERS) callconv(.C) LONG;
pub const LPTOP_LEVEL_EXCEPTION_FILTER = PTOP_LEVEL_EXCEPTION_FILTER;
pub const PVECTORED_EXCEPTION_HANDLER = ?*const fn ([*c]struct__EXCEPTION_POINTERS) callconv(.C) LONG;
pub const struct__SYMBOL_INFO = extern struct {
    SizeOfStruct: ULONG = @import("std").mem.zeroes(ULONG),
    TypeIndex: ULONG = @import("std").mem.zeroes(ULONG),
    Reserved: [2]ULONG64 = @import("std").mem.zeroes([2]ULONG64),
    Index: ULONG = @import("std").mem.zeroes(ULONG),
    Size: ULONG = @import("std").mem.zeroes(ULONG),
    ModBase: ULONG64 = @import("std").mem.zeroes(ULONG64),
    Flags: ULONG = @import("std").mem.zeroes(ULONG),
    Value: ULONG64 = @import("std").mem.zeroes(ULONG64),
    Address: ULONG64 = @import("std").mem.zeroes(ULONG64),
    Register: ULONG = @import("std").mem.zeroes(ULONG),
    Scope: ULONG = @import("std").mem.zeroes(ULONG),
    Tag: ULONG = @import("std").mem.zeroes(ULONG),
    NameLen: ULONG = @import("std").mem.zeroes(ULONG),
    MaxNameLen: ULONG = @import("std").mem.zeroes(ULONG),
    Name: [1]CHAR = @import("std").mem.zeroes([1]CHAR),
};
pub const SYMBOL_INFO = struct__SYMBOL_INFO;
pub const PSYMBOL_INFO = [*c]struct__SYMBOL_INFO;
pub const struct__SYMBOL_INFOW = extern struct {
    SizeOfStruct: ULONG = @import("std").mem.zeroes(ULONG),
    TypeIndex: ULONG = @import("std").mem.zeroes(ULONG),
    Reserved: [2]ULONG64 = @import("std").mem.zeroes([2]ULONG64),
    Index: ULONG = @import("std").mem.zeroes(ULONG),
    Size: ULONG = @import("std").mem.zeroes(ULONG),
    ModBase: ULONG64 = @import("std").mem.zeroes(ULONG64),
    Flags: ULONG = @import("std").mem.zeroes(ULONG),
    Value: ULONG64 = @import("std").mem.zeroes(ULONG64),
    Address: ULONG64 = @import("std").mem.zeroes(ULONG64),
    Register: ULONG = @import("std").mem.zeroes(ULONG),
    Scope: ULONG = @import("std").mem.zeroes(ULONG),
    Tag: ULONG = @import("std").mem.zeroes(ULONG),
    NameLen: ULONG = @import("std").mem.zeroes(ULONG),
    MaxNameLen: ULONG = @import("std").mem.zeroes(ULONG),
    Name: [1]WCHAR = @import("std").mem.zeroes([1]WCHAR),
};
pub const SYMBOL_INFOW = struct__SYMBOL_INFOW;
pub const PSYMBOL_INFOW = [*c]struct__SYMBOL_INFOW;
pub const struct__IMAGEHLP_LINE64 = extern struct {
    SizeOfStruct: DWORD = @import("std").mem.zeroes(DWORD),
    Key: PVOID = @import("std").mem.zeroes(PVOID),
    LineNumber: DWORD = @import("std").mem.zeroes(DWORD),
    FileName: PCHAR = @import("std").mem.zeroes(PCHAR),
    Address: DWORD64 = @import("std").mem.zeroes(DWORD64),
};
pub const IMAGEHLP_LINE64 = struct__IMAGEHLP_LINE64;
pub const PIMAGEHLP_LINE64 = [*c]struct__IMAGEHLP_LINE64;
pub const struct__IMAGEHLP_LINEW64 = extern struct {
    SizeOfStruct: DWORD = @import("std").mem.zeroes(DWORD),
    Key: PVOID = @import("std").mem.zeroes(PVOID),
    LineNumber: DWORD = @import("std").mem.zeroes(DWORD),
    FileName: PWSTR = @import("std").mem.zeroes(PWSTR),
    Address: DWORD64 = @import("std").mem.zeroes(DWORD64),
};
pub const IMAGEHLP_LINEW64 = struct__IMAGEHLP_LINEW64;
pub const PIMAGEHLP_LINEW64 = [*c]struct__IMAGEHLP_LINEW64;
pub const struct_tagTHREADENTRY32 = extern struct {
    dwSize: DWORD = @import("std").mem.zeroes(DWORD),
    cntUsage: DWORD = @import("std").mem.zeroes(DWORD),
    th32ThreadID: DWORD = @import("std").mem.zeroes(DWORD),
    th32OwnerProcessID: DWORD = @import("std").mem.zeroes(DWORD),
    tpBasePri: LONG = @import("std").mem.zeroes(LONG),
    tpDeltaPri: LONG = @import("std").mem.zeroes(LONG),
    dwFlags: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const THREADENTRY32 = struct_tagTHREADENTRY32;
pub const PTHREADENTRY32 = [*c]struct_tagTHREADENTRY32;
pub const LPTHREADENTRY32 = PTHREADENTRY32;
pub const AddrMode1616: c_int = 0;
pub const AddrMode1632: c_int = 1;
pub const AddrModeReal: c_int = 2;
pub const AddrModeFlat: c_int = 3;
pub const ADDRESS_MODE = c_uint;
pub const struct__tagADDRESS64 = extern struct {
    Offset: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Segment: WORD = @import("std").mem.zeroes(WORD),
    Mode: ADDRESS_MODE = @import("std").mem.zeroes(ADDRESS_MODE),
};
pub const ADDRESS64 = struct__tagADDRESS64;
pub const LPADDRESS64 = [*c]struct__tagADDRESS64;
pub const struct__KDHELP64 = extern struct {
    Thread: DWORD64 = @import("std").mem.zeroes(DWORD64),
    ThCallbackStack: DWORD = @import("std").mem.zeroes(DWORD),
    ThCallbackBStore: DWORD = @import("std").mem.zeroes(DWORD),
    NextCallback: DWORD = @import("std").mem.zeroes(DWORD),
    FramePointer: DWORD = @import("std").mem.zeroes(DWORD),
    KiCallUserMode: DWORD64 = @import("std").mem.zeroes(DWORD64),
    KeUserCallbackDispatcher: DWORD64 = @import("std").mem.zeroes(DWORD64),
    SystemRangeStart: DWORD64 = @import("std").mem.zeroes(DWORD64),
    KiUserExceptionDispatcher: DWORD64 = @import("std").mem.zeroes(DWORD64),
    StackBase: DWORD64 = @import("std").mem.zeroes(DWORD64),
    StackLimit: DWORD64 = @import("std").mem.zeroes(DWORD64),
    Reserved: [5]DWORD64 = @import("std").mem.zeroes([5]DWORD64),
};
pub const KDHELP64 = struct__KDHELP64;
pub const PKDHELP64 = [*c]struct__KDHELP64;
pub const struct__tagSTACKFRAME64 = extern struct {
    AddrPC: ADDRESS64 = @import("std").mem.zeroes(ADDRESS64),
    AddrReturn: ADDRESS64 = @import("std").mem.zeroes(ADDRESS64),
    AddrFrame: ADDRESS64 = @import("std").mem.zeroes(ADDRESS64),
    AddrStack: ADDRESS64 = @import("std").mem.zeroes(ADDRESS64),
    AddrBStore: ADDRESS64 = @import("std").mem.zeroes(ADDRESS64),
    FuncTableEntry: PVOID = @import("std").mem.zeroes(PVOID),
    Params: [4]DWORD64 = @import("std").mem.zeroes([4]DWORD64),
    Far: BOOL = @import("std").mem.zeroes(BOOL),
    Virtual: BOOL = @import("std").mem.zeroes(BOOL),
    Reserved: [3]DWORD64 = @import("std").mem.zeroes([3]DWORD64),
    KdHelp: KDHELP64 = @import("std").mem.zeroes(KDHELP64),
};
pub const STACKFRAME64 = struct__tagSTACKFRAME64;
pub const LPSTACKFRAME64 = [*c]struct__tagSTACKFRAME64;
pub const struct__LUID = extern struct {
    LowPart: DWORD = @import("std").mem.zeroes(DWORD),
    HighPart: LONG = @import("std").mem.zeroes(LONG),
};
pub const LUID = struct__LUID;
pub const PLUID = [*c]struct__LUID;
pub const struct__LUID_AND_ATTRIBUTES = extern struct {
    Luid: LUID = @import("std").mem.zeroes(LUID),
    Attributes: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const LUID_AND_ATTRIBUTES = struct__LUID_AND_ATTRIBUTES;
pub const PLUID_AND_ATTRIBUTES = [*c]struct__LUID_AND_ATTRIBUTES;
pub const struct__TOKEN_PRIVILEGES = extern struct {
    PrivilegeCount: DWORD = @import("std").mem.zeroes(DWORD),
    Privileges: [1]LUID_AND_ATTRIBUTES = @import("std").mem.zeroes([1]LUID_AND_ATTRIBUTES),
};
pub const TOKEN_PRIVILEGES = struct__TOKEN_PRIVILEGES;
pub const PTOKEN_PRIVILEGES = [*c]struct__TOKEN_PRIVILEGES;
pub extern fn DebugBreak() void;
pub extern fn IsDebuggerPresent() BOOL;
pub extern fn CheckRemoteDebuggerPresent(hProcess: HANDLE, hbDebuggerPresent: PBOOL) BOOL;
pub extern fn OutputDebugStringA(lpOutputString: LPCSTR) void;
pub extern fn OutputDebugStringW(lpOutputString: LPCWSTR) void;
pub extern fn GetThreadContext(hThread: HANDLE, lpContext: LPCONTEXT) BOOL;
pub extern fn RegisterTouchWindow(hwnd: HWND, ulFlags: ULONG) BOOL;
pub extern fn DebugActiveProcess(dwProcessId: DWORD) BOOL;
pub extern fn DebugActiveProcessStop(dwProcessId: DWORD) BOOL;
pub extern fn SymSetOptions(SymOptions: DWORD) DWORD;
pub extern fn SymInitialize(hProcess: HANDLE, UserSearchPath: LPCSTR, fInvadeProcess: BOOL) BOOL;
pub extern fn SymInitializeW(hProcess: HANDLE, UserSearchPath: LPCWSTR, fInvadeProcess: BOOL) BOOL;
pub extern fn SymFromAddr(hProcess: HANDLE, Address: DWORD64, Displacement: PDWORD64, Symbol: PSYMBOL_INFO) BOOL;
pub extern fn SymFromAddrW(hProcess: HANDLE, Address: DWORD64, Displacement: PDWORD64, Symbol: PSYMBOL_INFOW) BOOL;
pub extern fn SymFunctionTableAccess64(hProcess: HANDLE, AddrBase: DWORD64) PVOID;
pub extern fn SymGetModuleBase64(hProcess: HANDLE, dwAddr: DWORD64) DWORD64;
pub const PSYM_ENUMERATESYMBOLS_CALLBACK = ?*const fn (PSYMBOL_INFO, ULONG, PVOID) callconv(.C) BOOL;
pub const PSYM_ENUMERATESYMBOLS_CALLBACKW = ?*const fn (PSYMBOL_INFOW, ULONG, PVOID) callconv(.C) BOOL;
pub extern fn SymSearch(hProcess: HANDLE, BaseOfDll: ULONG64, Index: DWORD, SymTag: DWORD, Mask: LPCSTR, Address: DWORD64, EnumSymbolsCallback: PSYM_ENUMERATESYMBOLS_CALLBACK, UserContext: PVOID, Options: DWORD) BOOL;
pub extern fn SymSearchW(hProcess: HANDLE, BaseOfDll: ULONG64, Index: DWORD, SymTag: DWORD, Mask: LPCWSTR, Address: DWORD64, EnumSymbolsCallback: PSYM_ENUMERATESYMBOLS_CALLBACKW, UserContext: PVOID, Options: DWORD) BOOL;
pub extern fn SymRefreshModuleList(hProcess: HANDLE) BOOL;
pub const PSYM_ENUMMODULES_CALLBACK64 = ?*const fn (LPCSTR, DWORD64, PVOID) callconv(.C) BOOL;
pub const PSYM_ENUMMODULES_CALLBACKW64 = ?*const fn (LPCWSTR, DWORD64, PVOID) callconv(.C) BOOL;
pub extern fn SymEnumerateModules64(hProcess: HANDLE, EnumModulesCallback: PSYM_ENUMMODULES_CALLBACK64, UserContext: PVOID) BOOL;
pub extern fn SymEnumerateModulesW64(hProcess: HANDLE, EnumModulesCallback: PSYM_ENUMMODULES_CALLBACKW64, UserContext: PVOID) BOOL;
pub extern fn SymSetSearchPath(hProcess: HANDLE, SearchPath: LPCSTR) BOOL;
pub extern fn SymSetSearchPathW(hProcess: HANDLE, SearchPath: LPCWSTR) BOOL;
pub extern fn SymGetSearchPath(hProcess: HANDLE, SearchPath: LPSTR, SearchPathLength: DWORD) BOOL;
pub extern fn SymGetSearchPathW(hProcess: HANDLE, SearchPath: LPWSTR, SearchPathLength: DWORD) BOOL;
pub extern fn SymCleanup(hProcess: HANDLE) BOOL;
pub extern fn SymGetLineFromAddr64(hProcess: HANDLE, dwAddr: DWORD64, pdwDisplacement: PDWORD, Line: PIMAGEHLP_LINE64) BOOL;
pub extern fn SymGetLineFromAddrW64(hProcess: HANDLE, dwAddr: DWORD64, pdwDisplacement: PDWORD, Line: PIMAGEHLP_LINEW64) BOOL;
pub extern fn SetUnhandledExceptionFilter(lpTopLevelExceptionFilter: LPTOP_LEVEL_EXCEPTION_FILTER) LPTOP_LEVEL_EXCEPTION_FILTER;
pub extern fn UnhandledExceptionFilter(ExceptionInfo: [*c]struct__EXCEPTION_POINTERS) LONG;
pub extern fn AddVectoredExceptionHandler(FirstHandler: ULONG, VectoredHandler: PVECTORED_EXCEPTION_HANDLER) PVOID;
pub extern fn RemoveVectoredExceptionHandler(Handler: PVOID) ULONG;
pub extern fn RtlCaptureStackBackTrace(FramesToSkip: ULONG, FramesToCapture: ULONG, BackTrace: [*c]PVOID, BackTraceHash: PULONG) USHORT;
pub extern fn RtlCaptureContext(ContextRecord: PCONTEXT) void;
pub extern fn RaiseException(dwExceptionCode: DWORD, dwExceptionFlags: DWORD, nNumberOfArguments: DWORD, lpArguments: [*c]const ULONG_PTR) void;
pub extern fn CreateToolhelp32Snapshot(dwFlags: DWORD, th32ProcessID: DWORD) HANDLE;
pub extern fn Thread32First(hSnapshot: HANDLE, lpte: LPTHREADENTRY32) BOOL;
pub extern fn Thread32Next(hSnapshot: HANDLE, lpte: LPTHREADENTRY32) BOOL;
pub const PREAD_PROCESS_MEMORY_ROUTINE64 = ?*const fn (HANDLE, DWORD64, PVOID, DWORD, LPDWORD) callconv(.C) BOOL;
pub const PFUNCTION_TABLE_ACCESS_ROUTINE64 = ?*const fn (HANDLE, DWORD64) callconv(.C) PVOID;
pub const PGET_MODULE_BASE_ROUTINE64 = ?*const fn (HANDLE, DWORD64) callconv(.C) DWORD64;
pub const PTRANSLATE_ADDRESS_ROUTINE64 = ?*const fn (HANDLE, HANDLE, LPADDRESS64) callconv(.C) DWORD64;
pub extern fn StackWalk64(MachineType: DWORD, hProcess: HANDLE, hThread: HANDLE, StackFrame: LPSTACKFRAME64, ContextRecord: PVOID, ReadMemoryRoutine: PREAD_PROCESS_MEMORY_ROUTINE64, FunctionTableAccessRoutine: PFUNCTION_TABLE_ACCESS_ROUTINE64, GetModuleBaseRoutine: PGET_MODULE_BASE_ROUTINE64, TranslateAddress: PTRANSLATE_ADDRESS_ROUTINE64) BOOL;
pub const struct_tagVS_FIXEDFILEINFO = extern struct {
    dwSignature: DWORD = @import("std").mem.zeroes(DWORD),
    dwStrucVersion: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileVersionMS: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileVersionLS: DWORD = @import("std").mem.zeroes(DWORD),
    dwProductVersionMS: DWORD = @import("std").mem.zeroes(DWORD),
    dwProductVersionLS: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileFlagsMask: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileFlags: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileOS: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileType: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileSubtype: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileDateMS: DWORD = @import("std").mem.zeroes(DWORD),
    dwFileDateLS: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const VS_FIXEDFILEINFO = struct_tagVS_FIXEDFILEINFO;
pub const MiniDumpNormal: c_int = 0;
pub const MiniDumpWithDataSegs: c_int = 1;
pub const MiniDumpWithFullMemory: c_int = 2;
pub const MiniDumpWithHandleData: c_int = 4;
pub const MiniDumpFilterMemory: c_int = 8;
pub const MiniDumpScanMemory: c_int = 16;
pub const MiniDumpWithUnloadedModules: c_int = 32;
pub const MiniDumpWithIndirectlyReferencedMemory: c_int = 64;
pub const MiniDumpFilterModulePaths: c_int = 128;
pub const MiniDumpWithProcessThreadData: c_int = 256;
pub const MiniDumpWithPrivateReadWriteMemory: c_int = 512;
pub const MiniDumpWithoutOptionalData: c_int = 1024;
pub const MiniDumpWithFullMemoryInfo: c_int = 2048;
pub const MiniDumpWithThreadInfo: c_int = 4096;
pub const MiniDumpWithCodeSegs: c_int = 8192;
pub const MiniDumpWithoutAuxiliaryState: c_int = 16384;
pub const MiniDumpWithFullAuxiliaryState: c_int = 32768;
pub const MiniDumpWithPrivateWriteCopyMemory: c_int = 65536;
pub const MiniDumpIgnoreInaccessibleMemory: c_int = 131072;
pub const MiniDumpWithTokenInformation: c_int = 262144;
pub const MiniDumpValidTypeFlags: c_int = 524287;
pub const enum__MINIDUMP_TYPE = c_uint;
pub const MINIDUMP_TYPE = enum__MINIDUMP_TYPE;
pub const struct__MINIDUMP_EXCEPTION_INFORMATION = extern struct {
    ThreadId: DWORD = @import("std").mem.zeroes(DWORD),
    ExceptionPointers: PEXCEPTION_POINTERS = @import("std").mem.zeroes(PEXCEPTION_POINTERS),
    ClientPointers: BOOL = @import("std").mem.zeroes(BOOL),
};
pub const MINIDUMP_EXCEPTION_INFORMATION = struct__MINIDUMP_EXCEPTION_INFORMATION;
pub const PMINIDUMP_EXCEPTION_INFORMATION = [*c]struct__MINIDUMP_EXCEPTION_INFORMATION;
pub const struct__MINIDUMP_EXCEPTION_INFORMATION64 = extern struct {
    ThreadId: DWORD = @import("std").mem.zeroes(DWORD),
    ExceptionRecord: ULONG64 = @import("std").mem.zeroes(ULONG64),
    ContextRecord: ULONG64 = @import("std").mem.zeroes(ULONG64),
    ClientPointers: BOOL = @import("std").mem.zeroes(BOOL),
};
pub const MINIDUMP_EXCEPTION_INFORMATION64 = struct__MINIDUMP_EXCEPTION_INFORMATION64;
pub const PMINIDUMP_EXCEPTION_INFORMATION64 = [*c]struct__MINIDUMP_EXCEPTION_INFORMATION64;
pub const struct__MINIDUMP_THREAD_CALLBACK = extern struct {
    ThreadId: ULONG = @import("std").mem.zeroes(ULONG),
    ThreadHandle: HANDLE = @import("std").mem.zeroes(HANDLE),
    Context: CONTEXT = @import("std").mem.zeroes(CONTEXT),
    SizeOfContext: ULONG = @import("std").mem.zeroes(ULONG),
    StackBase: ULONG64 = @import("std").mem.zeroes(ULONG64),
    StackEnd: ULONG64 = @import("std").mem.zeroes(ULONG64),
};
pub const MINIDUMP_THREAD_CALLBACK = struct__MINIDUMP_THREAD_CALLBACK;
pub const PMINIDUMP_THREAD_CALLBACK = [*c]struct__MINIDUMP_THREAD_CALLBACK;
pub const struct__MINIDUMP_THREAD_EX_CALLBACK = extern struct {
    ThreadId: ULONG = @import("std").mem.zeroes(ULONG),
    ThreadHandle: HANDLE = @import("std").mem.zeroes(HANDLE),
    Context: CONTEXT = @import("std").mem.zeroes(CONTEXT),
    SizeOfContext: ULONG = @import("std").mem.zeroes(ULONG),
    StackBase: ULONG64 = @import("std").mem.zeroes(ULONG64),
    StackEnd: ULONG64 = @import("std").mem.zeroes(ULONG64),
    BackingStoreBase: ULONG64 = @import("std").mem.zeroes(ULONG64),
    BackingStoreEnd: ULONG64 = @import("std").mem.zeroes(ULONG64),
};
pub const MINIDUMP_THREAD_EX_CALLBACK = struct__MINIDUMP_THREAD_EX_CALLBACK;
pub const PMINIDUMP_THREAD_EX_CALLBACK = [*c]struct__MINIDUMP_THREAD_EX_CALLBACK;
pub const struct__MINIDUMP_MODULE_CALLBACK = extern struct {
    FullPath: PWCHAR = @import("std").mem.zeroes(PWCHAR),
    BaseOfImage: ULONG64 = @import("std").mem.zeroes(ULONG64),
    SizeOfImage: ULONG = @import("std").mem.zeroes(ULONG),
    CheckSum: ULONG = @import("std").mem.zeroes(ULONG),
    TimeDateStamp: ULONG = @import("std").mem.zeroes(ULONG),
    VersionInfo: VS_FIXEDFILEINFO = @import("std").mem.zeroes(VS_FIXEDFILEINFO),
    CvRecord: PVOID = @import("std").mem.zeroes(PVOID),
    SizeOfCvRecord: ULONG = @import("std").mem.zeroes(ULONG),
    MiscRecord: PVOID = @import("std").mem.zeroes(PVOID),
    SizeOfMiscRecord: ULONG = @import("std").mem.zeroes(ULONG),
};
pub const MINIDUMP_MODULE_CALLBACK = struct__MINIDUMP_MODULE_CALLBACK;
pub const PMINIDUMP_MODULE_CALLBACK = [*c]struct__MINIDUMP_MODULE_CALLBACK;
pub const struct__MINIDUMP_INCLUDE_THREAD_CALLBACK = extern struct {
    ThreadId: ULONG = @import("std").mem.zeroes(ULONG),
};
pub const MINIDUMP_INCLUDE_THREAD_CALLBACK = struct__MINIDUMP_INCLUDE_THREAD_CALLBACK;
pub const PMINIDUMP_INCLUDE_THREAD_CALLBACK = [*c]struct__MINIDUMP_INCLUDE_THREAD_CALLBACK;
pub const struct__MINIDUMP_INCLUDE_MODULE_CALLBACK = extern struct {
    BaseOfImage: ULONG64 = @import("std").mem.zeroes(ULONG64),
};
pub const MINIDUMP_INCLUDE_MODULE_CALLBACK = struct__MINIDUMP_INCLUDE_MODULE_CALLBACK;
pub const PMINIDUMP_INCLUDE_MODULE_CALLBACK = [*c]struct__MINIDUMP_INCLUDE_MODULE_CALLBACK;
pub const struct__MINIDUMP_IO_CALLBACK = extern struct {
    Handle: HANDLE = @import("std").mem.zeroes(HANDLE),
    Offset: ULONG64 = @import("std").mem.zeroes(ULONG64),
    Buffer: PVOID = @import("std").mem.zeroes(PVOID),
    BufferBytes: ULONG = @import("std").mem.zeroes(ULONG),
};
pub const MINIDUMP_IO_CALLBACK = struct__MINIDUMP_IO_CALLBACK;
pub const PMINIDUMP_IO_CALLBACK = [*c]struct__MINIDUMP_IO_CALLBACK;
pub const struct__MINIDUMP_READ_MEMORY_FAILURE_CALLBACK = extern struct {
    Offset: ULONG64 = @import("std").mem.zeroes(ULONG64),
    Bytes: ULONG = @import("std").mem.zeroes(ULONG),
    FailureStatus: HRESULT = @import("std").mem.zeroes(HRESULT),
};
pub const MINIDUMP_READ_MEMORY_FAILURE_CALLBACK = struct__MINIDUMP_READ_MEMORY_FAILURE_CALLBACK;
pub const PMINIDUMP_READ_MEMORY_FAILURE_CALLBACK = [*c]struct__MINIDUMP_READ_MEMORY_FAILURE_CALLBACK;
const union_unnamed_8 = extern union {
    Status: HRESULT,
    Thread: MINIDUMP_THREAD_CALLBACK,
    ThreadEx: MINIDUMP_THREAD_EX_CALLBACK,
    Module: MINIDUMP_MODULE_CALLBACK,
    IncludeThread: MINIDUMP_INCLUDE_THREAD_CALLBACK,
    IncludeModule: MINIDUMP_INCLUDE_MODULE_CALLBACK,
    Io: MINIDUMP_IO_CALLBACK,
    ReadMemoryFailure: MINIDUMP_READ_MEMORY_FAILURE_CALLBACK,
    SecondaryFlags: ULONG,
};
pub const struct__MINIDUMP_CALLBACK_INPUT = extern struct {
    ProcessId: ULONG = @import("std").mem.zeroes(ULONG),
    ProcessHandle: HANDLE = @import("std").mem.zeroes(HANDLE),
    CallbackType: ULONG = @import("std").mem.zeroes(ULONG),
    unnamed_0: union_unnamed_8 = @import("std").mem.zeroes(union_unnamed_8),
};
pub const MINIDUMP_CALLBACK_INPUT = struct__MINIDUMP_CALLBACK_INPUT;
pub const PMINIDUMP_CALLBACK_INPUT = [*c]struct__MINIDUMP_CALLBACK_INPUT;
pub const struct__MINIDUMP_MEMORY_INFO = extern struct {
    BaseAddress: ULONG64 = @import("std").mem.zeroes(ULONG64),
    AllocationBase: ULONG64 = @import("std").mem.zeroes(ULONG64),
    AllocationProtect: ULONG32 = @import("std").mem.zeroes(ULONG32),
    __alignment1: ULONG32 = @import("std").mem.zeroes(ULONG32),
    RegionSize: ULONG64 = @import("std").mem.zeroes(ULONG64),
    State: ULONG32 = @import("std").mem.zeroes(ULONG32),
    Protect: ULONG32 = @import("std").mem.zeroes(ULONG32),
    Type: ULONG32 = @import("std").mem.zeroes(ULONG32),
    __alignment2: ULONG32 = @import("std").mem.zeroes(ULONG32),
};
pub const MINIDUMP_MEMORY_INFO = struct__MINIDUMP_MEMORY_INFO;
pub const PMINIDUMP_MEMORY_INFO = [*c]struct__MINIDUMP_MEMORY_INFO;
const struct_unnamed_10 = extern struct {
    MemoryBase: ULONG64 = @import("std").mem.zeroes(ULONG64),
    MemorySize: ULONG = @import("std").mem.zeroes(ULONG),
};
const struct_unnamed_11 = extern struct {
    CheckCancel: BOOL = @import("std").mem.zeroes(BOOL),
    Cancel: BOOL = @import("std").mem.zeroes(BOOL),
};
const struct_unnamed_12 = extern struct {
    VmRegion: MINIDUMP_MEMORY_INFO = @import("std").mem.zeroes(MINIDUMP_MEMORY_INFO),
    Continue: BOOL = @import("std").mem.zeroes(BOOL),
};
const union_unnamed_9 = extern union {
    ModuleWriteFlags: ULONG,
    ThreadWriteFlags: ULONG,
    SecondaryFlags: ULONG,
    unnamed_0: struct_unnamed_10,
    unnamed_1: struct_unnamed_11,
    Handle: HANDLE,
    unnamed_2: struct_unnamed_12,
    Status: HRESULT,
};
pub const struct__MINIDUMP_CALLBACK_OUTPUT = extern struct {
    unnamed_0: union_unnamed_9 = @import("std").mem.zeroes(union_unnamed_9),
};
pub const MINIDUMP_CALLBACK_OUTPUT = struct__MINIDUMP_CALLBACK_OUTPUT;
pub const PMINIDUMP_CALLBACK_OUTPUT = [*c]struct__MINIDUMP_CALLBACK_OUTPUT;
pub const MINIDUMP_CALLBACK_ROUTINE = ?*const fn (PVOID, PMINIDUMP_CALLBACK_INPUT, PMINIDUMP_CALLBACK_OUTPUT) callconv(.C) BOOL;
pub const struct__MINIDUMP_CALLBACK_INFORMATION = extern struct {
    CallbackRoutine: MINIDUMP_CALLBACK_ROUTINE = @import("std").mem.zeroes(MINIDUMP_CALLBACK_ROUTINE),
    CallbackParam: PVOID = @import("std").mem.zeroes(PVOID),
};
pub const MINIDUMP_CALLBACK_INFORMATION = struct__MINIDUMP_CALLBACK_INFORMATION;
pub const PMINIDUMP_CALLBACK_INFORMATION = [*c]struct__MINIDUMP_CALLBACK_INFORMATION;
pub const struct__MINIDUMP_USER_STREAM = extern struct {
    Type: ULONG32 = @import("std").mem.zeroes(ULONG32),
    BufferSize: ULONG = @import("std").mem.zeroes(ULONG),
    Buffer: PVOID = @import("std").mem.zeroes(PVOID),
};
pub const MINIDUMP_USER_STREAM = struct__MINIDUMP_USER_STREAM;
pub const PMINIDUMP_USER_STREAM = [*c]struct__MINIDUMP_USER_STREAM;
pub const struct__MINIDUMP_USER_STREAM_INFORMATION = extern struct {
    UserStreamCount: ULONG = @import("std").mem.zeroes(ULONG),
    UserStreamArray: PMINIDUMP_USER_STREAM = @import("std").mem.zeroes(PMINIDUMP_USER_STREAM),
};
pub const MINIDUMP_USER_STREAM_INFORMATION = struct__MINIDUMP_USER_STREAM_INFORMATION;
pub const PMINIDUMP_USER_STREAM_INFORMATION = [*c]struct__MINIDUMP_USER_STREAM_INFORMATION;
pub extern fn MiniDumpWriteDump(hProcess: HANDLE, ProcessId: DWORD, hFile: HANDLE, DumpType: MINIDUMP_TYPE, ExceptionParam: PMINIDUMP_EXCEPTION_INFORMATION, UserStreamParam: PMINIDUMP_USER_STREAM_INFORMATION, CallbackParam: PMINIDUMP_CALLBACK_INFORMATION) BOOL;
pub extern fn OpenProcessToken(ProcessHandle: HANDLE, DesiredAccess: DWORD, TokenHandle: PHANDLE) BOOL;
pub extern fn LookupPrivilegeValueA(lpSystemName: LPCSTR, lpName: LPCSTR, lpLuid: PLUID) BOOL;
pub extern fn LookupPrivilegeValueW(lpSystemName: LPCWSTR, lpName: LPCWSTR, lpLuid: PLUID) BOOL;
pub extern fn AdjustTokenPrivileges(TokenHandle: HANDLE, DisableAllPrivileges: BOOL, NewState: PTOKEN_PRIVILEGES, BufferLength: DWORD, PreviousState: PTOKEN_PRIVILEGES, ReturnLength: PDWORD) BOOL;
pub const DXGI_FORMAT_UNKNOWN: c_int = 0;
pub const DXGI_FORMAT_R32G32B32A32_TYPELESS: c_int = 1;
pub const DXGI_FORMAT_R32G32B32A32_FLOAT: c_int = 2;
pub const DXGI_FORMAT_R32G32B32A32_UINT: c_int = 3;
pub const DXGI_FORMAT_R32G32B32A32_SINT: c_int = 4;
pub const DXGI_FORMAT_R32G32B32_TYPELESS: c_int = 5;
pub const DXGI_FORMAT_R32G32B32_FLOAT: c_int = 6;
pub const DXGI_FORMAT_R32G32B32_UINT: c_int = 7;
pub const DXGI_FORMAT_R32G32B32_SINT: c_int = 8;
pub const DXGI_FORMAT_R16G16B16A16_TYPELESS: c_int = 9;
pub const DXGI_FORMAT_R16G16B16A16_FLOAT: c_int = 10;
pub const DXGI_FORMAT_R16G16B16A16_UNORM: c_int = 11;
pub const DXGI_FORMAT_R16G16B16A16_UINT: c_int = 12;
pub const DXGI_FORMAT_R16G16B16A16_SNORM: c_int = 13;
pub const DXGI_FORMAT_R16G16B16A16_SINT: c_int = 14;
pub const DXGI_FORMAT_R32G32_TYPELESS: c_int = 15;
pub const DXGI_FORMAT_R32G32_FLOAT: c_int = 16;
pub const DXGI_FORMAT_R32G32_UINT: c_int = 17;
pub const DXGI_FORMAT_R32G32_SINT: c_int = 18;
pub const DXGI_FORMAT_R32G8X24_TYPELESS: c_int = 19;
pub const DXGI_FORMAT_D32_FLOAT_S8X24_UINT: c_int = 20;
pub const DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS: c_int = 21;
pub const DXGI_FORMAT_X32_TYPELESS_G8X24_UINT: c_int = 22;
pub const DXGI_FORMAT_R10G10B10A2_TYPELESS: c_int = 23;
pub const DXGI_FORMAT_R10G10B10A2_UNORM: c_int = 24;
pub const DXGI_FORMAT_R10G10B10A2_UINT: c_int = 25;
pub const DXGI_FORMAT_R11G11B10_FLOAT: c_int = 26;
pub const DXGI_FORMAT_R8G8B8A8_TYPELESS: c_int = 27;
pub const DXGI_FORMAT_R8G8B8A8_UNORM: c_int = 28;
pub const DXGI_FORMAT_R8G8B8A8_UNORM_SRGB: c_int = 29;
pub const DXGI_FORMAT_R8G8B8A8_UINT: c_int = 30;
pub const DXGI_FORMAT_R8G8B8A8_SNORM: c_int = 31;
pub const DXGI_FORMAT_R8G8B8A8_SINT: c_int = 32;
pub const DXGI_FORMAT_R16G16_TYPELESS: c_int = 33;
pub const DXGI_FORMAT_R16G16_FLOAT: c_int = 34;
pub const DXGI_FORMAT_R16G16_UNORM: c_int = 35;
pub const DXGI_FORMAT_R16G16_UINT: c_int = 36;
pub const DXGI_FORMAT_R16G16_SNORM: c_int = 37;
pub const DXGI_FORMAT_R16G16_SINT: c_int = 38;
pub const DXGI_FORMAT_R32_TYPELESS: c_int = 39;
pub const DXGI_FORMAT_D32_FLOAT: c_int = 40;
pub const DXGI_FORMAT_R32_FLOAT: c_int = 41;
pub const DXGI_FORMAT_R32_UINT: c_int = 42;
pub const DXGI_FORMAT_R32_SINT: c_int = 43;
pub const DXGI_FORMAT_R24G8_TYPELESS: c_int = 44;
pub const DXGI_FORMAT_D24_UNORM_S8_UINT: c_int = 45;
pub const DXGI_FORMAT_R24_UNORM_X8_TYPELESS: c_int = 46;
pub const DXGI_FORMAT_X24_TYPELESS_G8_UINT: c_int = 47;
pub const DXGI_FORMAT_R8G8_TYPELESS: c_int = 48;
pub const DXGI_FORMAT_R8G8_UNORM: c_int = 49;
pub const DXGI_FORMAT_R8G8_UINT: c_int = 50;
pub const DXGI_FORMAT_R8G8_SNORM: c_int = 51;
pub const DXGI_FORMAT_R8G8_SINT: c_int = 52;
pub const DXGI_FORMAT_R16_TYPELESS: c_int = 53;
pub const DXGI_FORMAT_R16_FLOAT: c_int = 54;
pub const DXGI_FORMAT_D16_UNORM: c_int = 55;
pub const DXGI_FORMAT_R16_UNORM: c_int = 56;
pub const DXGI_FORMAT_R16_UINT: c_int = 57;
pub const DXGI_FORMAT_R16_SNORM: c_int = 58;
pub const DXGI_FORMAT_R16_SINT: c_int = 59;
pub const DXGI_FORMAT_R8_TYPELESS: c_int = 60;
pub const DXGI_FORMAT_R8_UNORM: c_int = 61;
pub const DXGI_FORMAT_R8_UINT: c_int = 62;
pub const DXGI_FORMAT_R8_SNORM: c_int = 63;
pub const DXGI_FORMAT_R8_SINT: c_int = 64;
pub const DXGI_FORMAT_A8_UNORM: c_int = 65;
pub const DXGI_FORMAT_R1_UNORM: c_int = 66;
pub const DXGI_FORMAT_R9G9B9E5_SHAREDEXP: c_int = 67;
pub const DXGI_FORMAT_R8G8_B8G8_UNORM: c_int = 68;
pub const DXGI_FORMAT_G8R8_G8B8_UNORM: c_int = 69;
pub const DXGI_FORMAT_BC1_TYPELESS: c_int = 70;
pub const DXGI_FORMAT_BC1_UNORM: c_int = 71;
pub const DXGI_FORMAT_BC1_UNORM_SRGB: c_int = 72;
pub const DXGI_FORMAT_BC2_TYPELESS: c_int = 73;
pub const DXGI_FORMAT_BC2_UNORM: c_int = 74;
pub const DXGI_FORMAT_BC2_UNORM_SRGB: c_int = 75;
pub const DXGI_FORMAT_BC3_TYPELESS: c_int = 76;
pub const DXGI_FORMAT_BC3_UNORM: c_int = 77;
pub const DXGI_FORMAT_BC3_UNORM_SRGB: c_int = 78;
pub const DXGI_FORMAT_BC4_TYPELESS: c_int = 79;
pub const DXGI_FORMAT_BC4_UNORM: c_int = 80;
pub const DXGI_FORMAT_BC4_SNORM: c_int = 81;
pub const DXGI_FORMAT_BC5_TYPELESS: c_int = 82;
pub const DXGI_FORMAT_BC5_UNORM: c_int = 83;
pub const DXGI_FORMAT_BC5_SNORM: c_int = 84;
pub const DXGI_FORMAT_B5G6R5_UNORM: c_int = 85;
pub const DXGI_FORMAT_B5G5R5A1_UNORM: c_int = 86;
pub const DXGI_FORMAT_B8G8R8A8_UNORM: c_int = 87;
pub const DXGI_FORMAT_B8G8R8X8_UNORM: c_int = 88;
pub const DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM: c_int = 89;
pub const DXGI_FORMAT_B8G8R8A8_TYPELESS: c_int = 90;
pub const DXGI_FORMAT_B8G8R8A8_UNORM_SRGB: c_int = 91;
pub const DXGI_FORMAT_B8G8R8X8_TYPELESS: c_int = 92;
pub const DXGI_FORMAT_B8G8R8X8_UNORM_SRGB: c_int = 93;
pub const DXGI_FORMAT_BC6H_TYPELESS: c_int = 94;
pub const DXGI_FORMAT_BC6H_UF16: c_int = 95;
pub const DXGI_FORMAT_BC6H_SF16: c_int = 96;
pub const DXGI_FORMAT_BC7_TYPELESS: c_int = 97;
pub const DXGI_FORMAT_BC7_UNORM: c_int = 98;
pub const DXGI_FORMAT_BC7_UNORM_SRGB: c_int = 99;
pub const DXGI_FORMAT_FORCE_UINT: c_uint = 4294967295;
pub const enum_DXGI_FORMAT = c_uint;
pub const DXGI_FORMAT = enum_DXGI_FORMAT;
pub const DDS_PIXELFORMAT = extern struct {
    dwSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwFlags: DWORD = @import("std").mem.zeroes(DWORD),
    dwFourCC: DWORD = @import("std").mem.zeroes(DWORD),
    dwRGBBitCount: DWORD = @import("std").mem.zeroes(DWORD),
    dwRBitMask: DWORD = @import("std").mem.zeroes(DWORD),
    dwGBitMask: DWORD = @import("std").mem.zeroes(DWORD),
    dwBBitMask: DWORD = @import("std").mem.zeroes(DWORD),
    dwABitMask: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const DDS_HEADER = extern struct {
    dwSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwHeaderFlags: DWORD = @import("std").mem.zeroes(DWORD),
    dwHeight: DWORD = @import("std").mem.zeroes(DWORD),
    dwWidth: DWORD = @import("std").mem.zeroes(DWORD),
    dwPitchOrLinearSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwDepth: DWORD = @import("std").mem.zeroes(DWORD),
    dwMipMapCount: DWORD = @import("std").mem.zeroes(DWORD),
    dwReserved1: [11]DWORD = @import("std").mem.zeroes([11]DWORD),
    ddspf: DDS_PIXELFORMAT = @import("std").mem.zeroes(DDS_PIXELFORMAT),
    dwSurfaceFlags: DWORD = @import("std").mem.zeroes(DWORD),
    dwCubemapFlags: DWORD = @import("std").mem.zeroes(DWORD),
    dwReserved2: [3]DWORD = @import("std").mem.zeroes([3]DWORD),
};
pub const DDS_HEADER_DXT10 = extern struct {
    dxgiFormat: DXGI_FORMAT = @import("std").mem.zeroes(DXGI_FORMAT),
    resourceDimension: UINT = @import("std").mem.zeroes(UINT),
    miscFlag: UINT = @import("std").mem.zeroes(UINT),
    arraySize: UINT = @import("std").mem.zeroes(UINT),
    reserved: UINT = @import("std").mem.zeroes(UINT),
};
pub const SECURITY_INFORMATION = DWORD;
pub const PSECURITY_INFORMATION = [*c]DWORD;
pub const PSECURITY_DESCRIPTOR = HANDLE;
const struct_unnamed_14 = extern struct {
    Offset: DWORD = @import("std").mem.zeroes(DWORD),
    OffsetHigh: DWORD = @import("std").mem.zeroes(DWORD),
};
const union_unnamed_13 = extern union {
    unnamed_0: struct_unnamed_14,
    Pointer: PVOID,
};
pub const struct__OVERLAPPED = extern struct {
    Internal: ULONG_PTR = @import("std").mem.zeroes(ULONG_PTR),
    InternalHigh: ULONG_PTR = @import("std").mem.zeroes(ULONG_PTR),
    unnamed_0: union_unnamed_13 = @import("std").mem.zeroes(union_unnamed_13),
    hEvent: HANDLE = @import("std").mem.zeroes(HANDLE),
};
pub const OVERLAPPED = struct__OVERLAPPED;
pub const LPOVERLAPPED = [*c]struct__OVERLAPPED;
pub const struct__WIN32_FIND_DATAA = extern struct {
    dwFileAttributes: DWORD = @import("std").mem.zeroes(DWORD),
    ftCreationTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    ftLastAccessTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    ftLastWriteTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    nFileSizeHigh: DWORD = @import("std").mem.zeroes(DWORD),
    nFileSizeLow: DWORD = @import("std").mem.zeroes(DWORD),
    dwReserved0: DWORD = @import("std").mem.zeroes(DWORD),
    dwReserved1: DWORD = @import("std").mem.zeroes(DWORD),
    cFileName: [260]CHAR = @import("std").mem.zeroes([260]CHAR),
    cAlternateFileName: [14]CHAR = @import("std").mem.zeroes([14]CHAR),
};
pub const WIN32_FIND_DATAA = struct__WIN32_FIND_DATAA;
pub const PWIN32_FIND_DATAA = [*c]struct__WIN32_FIND_DATAA;
pub const LPWIN32_FIND_DATAA = [*c]struct__WIN32_FIND_DATAA;
pub const struct__WIN32_FIND_DATAW = extern struct {
    dwFileAttributes: DWORD = @import("std").mem.zeroes(DWORD),
    ftCreationTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    ftLastAccessTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    ftLastWriteTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    nFileSizeHigh: DWORD = @import("std").mem.zeroes(DWORD),
    nFileSizeLow: DWORD = @import("std").mem.zeroes(DWORD),
    dwReserved0: DWORD = @import("std").mem.zeroes(DWORD),
    dwReserved1: DWORD = @import("std").mem.zeroes(DWORD),
    cFileName: [260]WCHAR = @import("std").mem.zeroes([260]WCHAR),
    cAlternateFileName: [14]WCHAR = @import("std").mem.zeroes([14]WCHAR),
};
pub const WIN32_FIND_DATAW = struct__WIN32_FIND_DATAW;
pub const PWIN32_FIND_DATAW = [*c]struct__WIN32_FIND_DATAW;
pub const LPWIN32_FIND_DATAW = [*c]struct__WIN32_FIND_DATAW;
pub extern fn CreateFileA(lpFileName: LPCSTR, dwDesiredAccess: DWORD, dwShareMode: DWORD, lpSecurityAttributes: LPSECURITY_ATTRIBUTES, dwCreationDisposition: DWORD, dwFlagsAndAttributes: DWORD, hTemplateFile: HANDLE) HANDLE;
pub extern fn CreateFileW(lpFileName: LPCWSTR, dwDesiredAccess: DWORD, dwShareMode: DWORD, lpSecurityAttributes: LPSECURITY_ATTRIBUTES, dwCreationDisposition: DWORD, dwFlagsAndAttributes: DWORD, hTemplateFile: HANDLE) HANDLE;
pub extern fn WriteFile(hFile: HANDLE, lpBuffer: LPCVOID, nNumberOfBytesToWrite: DWORD, lpNumberOfBytesWritten: LPDWORD, lpOverlapped: LPOVERLAPPED) BOOL;
pub extern fn ReadFile(hFile: HANDLE, lpBuffer: LPVOID, nNumberOfBytesToRead: DWORD, lpNumberOfBytesRead: LPDWORD, lpOverlapped: LPOVERLAPPED) BOOL;
pub extern fn SetFilePointer(hFile: HANDLE, lDistanceToMove: LONG, lpDistanceToMoveHigh: PLONG, dwMoveMethod: DWORD) DWORD;
pub extern fn SetFilePointerEx(hFile: HANDLE, liDistanceToMove: LARGE_INTEGER, lpNewFilePointer: PLARGE_INTEGER, dwMoveMethod: DWORD) BOOL;
pub extern fn FlushFileBuffers(hFile: HANDLE) BOOL;
pub extern fn GetModuleFileNameA(hModule: HMODULE, lpFileName: LPSTR, nSize: DWORD) DWORD;
pub extern fn GetModuleFileNameW(hModule: HMODULE, lpFileName: LPWSTR, nSize: DWORD) DWORD;
pub extern fn GetModuleFileNameExA(hProcess: HANDLE, hModule: HMODULE, lpFileName: LPSTR, nSize: DWORD) DWORD;
pub extern fn GetModuleFileNameExW(hProcess: HANDLE, hModule: HMODULE, lpFileName: LPWSTR, nSize: DWORD) DWORD;
pub extern fn OpenFileMappingA(dwDesiredAccess: DWORD, bInheritHandle: BOOL, lpName: LPCSTR) HANDLE;
pub extern fn OpenFileMappingW(dwDesiredAccess: DWORD, bInheritHandle: BOOL, lpName: LPCWSTR) HANDLE;
pub extern fn MapViewOfFile(hFileMappingObject: HANDLE, dwDesiredAccess: DWORD, dwFileOffsetHigh: DWORD, dwFileOffsetLow: DWORD, dwNumberOfBytesToMap: SIZE_T) LPVOID;
pub extern fn MapViewOfFileEx(hFileMappingObject: HANDLE, dwDesiredAccess: DWORD, dwFileOffsetHigh: DWORD, dwFileOffsetLow: DWORD, dwNumberOfBytesToMap: SIZE_T, lpBaseAddress: LPVOID) LPVOID;
pub extern fn CreateFileMappingA(hFile: HANDLE, lpAttributes: LPSECURITY_ATTRIBUTES, flProtect: DWORD, dwMaximumSizeHigh: DWORD, dwMaximumSizeLow: DWORD, lpName: LPCSTR) HANDLE;
pub extern fn CreateFileMappingW(hFile: HANDLE, lpAttributes: LPSECURITY_ATTRIBUTES, flProtect: DWORD, dwMaximumSizeHigh: DWORD, dwMaximumSizeLow: DWORD, lpName: LPCWSTR) HANDLE;
pub extern fn UnmapViewOfFile(lpBaseAddress: LPCVOID) BOOL;
pub extern fn GetFileAttributesA(lpFileName: LPCSTR) DWORD;
pub extern fn GetFileAttributesW(lpFileName: LPCWSTR) DWORD;
pub const GetFileExInfoStandard: c_int = 0;
pub const GetFileExMaxInfoLevel: c_int = 1;
pub const enum__GET_FILEEX_INFO_LEVELS = c_uint;
pub const GET_FILEEX_INFO_LEVELS = enum__GET_FILEEX_INFO_LEVELS;
pub const struct__WIN32_FILE_ATTRIBUTE_DATA = extern struct {
    dwFileAttributes: DWORD = @import("std").mem.zeroes(DWORD),
    ftCreationTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    ftLastAccessTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    ftLastWriteTime: FILETIME = @import("std").mem.zeroes(FILETIME),
    nFileSizeHigh: DWORD = @import("std").mem.zeroes(DWORD),
    nFileSizeLow: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const WIN32_FILE_ATTRIBUTE_DATA = struct__WIN32_FILE_ATTRIBUTE_DATA;
pub const LPWIN32_FILE_ATTRIBUTE_DATA = [*c]struct__WIN32_FILE_ATTRIBUTE_DATA;
pub extern fn GetFileAttributesExA(lpFileName: LPCSTR, fInfoLevelId: GET_FILEEX_INFO_LEVELS, lpFileInformation: LPVOID) BOOL;
pub extern fn GetFileAttributesExW(lpFileName: LPCWSTR, fInfoLevelId: GET_FILEEX_INFO_LEVELS, lpFileInformation: LPVOID) BOOL;
pub extern fn GetFileTime(hFile: HANDLE, lpCreationTime: LPFILETIME, lpLastAccessTime: LPFILETIME, lpLastWriteTime: LPFILETIME) BOOL;
pub extern fn SetEndOfFile(hFile: HANDLE) BOOL;
pub extern fn CreateDirectoryA(lpPathName: LPCSTR, lpSecurityAttributes: LPSECURITY_ATTRIBUTES) BOOL;
pub extern fn CreateDirectoryW(lpPathName: LPCWSTR, lpSecurityAttributes: LPSECURITY_ATTRIBUTES) BOOL;
pub extern fn CopyFileA(lpExistingFileName: LPCSTR, lpNewFileName: LPCSTR, bFailIfExists: BOOL) BOOL;
pub extern fn CopyFileW(lpExistingFileName: LPCWSTR, lpNewFileName: LPCWSTR, bFailIfExists: BOOL) BOOL;
pub extern fn DeleteFileA(lpFileName: LPCSTR) BOOL;
pub extern fn DeleteFileW(lpFileName: LPCWSTR) BOOL;
pub extern fn MoveFileA(lpExistingFileName: LPCSTR, lpNewFileName: LPCSTR) BOOL;
pub extern fn MoveFileW(lpExistingFileName: LPCWSTR, lpNewFileName: LPCWSTR) BOOL;
pub extern fn MoveFileExA(lpExistingFileName: LPCSTR, lpNewFileName: LPCSTR, dwFlags: DWORD) BOOL;
pub extern fn MoveFileExW(lpExistingFileName: LPCWSTR, lpNewFileName: LPCWSTR, dwFlags: DWORD) BOOL;
pub extern fn RemoveDirectoryA(lpPathName: LPCSTR) BOOL;
pub extern fn RemoveDirectoryW(lpPathName: LPCWSTR) BOOL;
pub extern fn GetFileSizeEx(hFile: HANDLE, lpFileSize: PLARGE_INTEGER) BOOL;
pub extern fn FlushViewOfFile(lpBaseAddress: LPCVOID, dwNumberOfBytesToFlush: SIZE_T) BOOL;
pub extern fn FindFirstFileA(lpFileName: LPCSTR, lpFindFileData: LPWIN32_FIND_DATAA) HANDLE;
pub extern fn FindFirstFileW(lpFileName: LPCWSTR, lpFindFileData: LPWIN32_FIND_DATAW) HANDLE;
pub extern fn FindNextFileA(hFindFile: HANDLE, lpFindFileData: LPWIN32_FIND_DATAA) BOOL;
pub extern fn FindNextFileW(hFindFile: HANDLE, lpFindFileData: LPWIN32_FIND_DATAW) BOOL;
pub extern fn FindClose(hFindFile: HANDLE) BOOL;
pub extern fn FindFirstChangeNotificationA(lpPathName: LPCSTR, bWatchSubtree: BOOL, dwNotifyFilter: DWORD) HANDLE;
pub extern fn FindFirstChangeNotificationW(lpPathName: LPCWSTR, bWatchSubtree: BOOL, dwNotifyFilter: DWORD) HANDLE;
pub extern fn FindNextChangeNotification(hChangeHandle: HANDLE) BOOL;
pub extern fn FindCloseChangeNotification(hChangeHandle: HANDLE) BOOL;
pub extern fn GetFileType(hFile: HANDLE) DWORD;
pub extern fn GetTempFileNameW(lpPathName: LPCWSTR, lpPrefixString: LPCWSTR, uUnique: UINT, lpTempFileName: LPWSTR) UINT;
pub extern fn GetTempPathW(nBufferLength: DWORD, lpBuffer: LPWSTR) DWORD;
pub extern fn GetFileSecurityA(lpFileName: LPCSTR, RequestedInformation: SECURITY_INFORMATION, pSecurityDescriptor: PSECURITY_DESCRIPTOR, nLength: DWORD, lpnLengthNeeded: LPDWORD) BOOL;
pub extern fn GetFileSecurityW(lpFileName: LPCWSTR, RequestedInformation: SECURITY_INFORMATION, pSecurityDescriptor: PSECURITY_DESCRIPTOR, nLength: DWORD, lpnLengthNeeded: LPDWORD) BOOL;
pub extern fn LoadCursorA(hInstance: HINSTANCE, lpCursorName: LPCSTR) HCURSOR;
pub extern fn LoadCursorW(hInstance: HINSTANCE, lpCursorName: LPCWSTR) HCURSOR;
pub extern fn LoadIconA(hInstance: HINSTANCE, lpIconName: LPCSTR) HICON;
pub extern fn LoadIconW(hInstance: HINSTANCE, lpIconName: LPCWSTR) HICON;
pub extern fn GetStockObject(fnObject: c_int) HGDIOBJ;
pub extern fn SetCursor(hCursor: HCURSOR) HCURSOR;
pub const HeapCompatibilityInformation: c_int = 0;
pub const HeapEneableTerminationOnCorruption: c_int = 1;
pub const HeapOptimizeResources: c_int = 3;
pub const enum__HEAP_INFORMATION_CLASS = c_uint;
pub const HEAP_INFORMATION_CLASS = enum__HEAP_INFORMATION_CLASS;
pub const struct__COORD = extern struct {
    X: SHORT = @import("std").mem.zeroes(SHORT),
    Y: SHORT = @import("std").mem.zeroes(SHORT),
};
pub const COORD = struct__COORD;
pub const PCOORD = [*c]struct__COORD;
pub const struct__SMALL_RECT = extern struct {
    Left: SHORT = @import("std").mem.zeroes(SHORT),
    Top: SHORT = @import("std").mem.zeroes(SHORT),
    Right: SHORT = @import("std").mem.zeroes(SHORT),
    Bottom: SHORT = @import("std").mem.zeroes(SHORT),
};
pub const SMALL_RECT = struct__SMALL_RECT;
pub const struct__CONSOLE_SCREEN_BUFFER_INFO = extern struct {
    dwSize: COORD = @import("std").mem.zeroes(COORD),
    dwCursorPosition: COORD = @import("std").mem.zeroes(COORD),
    wAttributes: WORD = @import("std").mem.zeroes(WORD),
    srWindow: SMALL_RECT = @import("std").mem.zeroes(SMALL_RECT),
    dwMaximumWindowSize: COORD = @import("std").mem.zeroes(COORD),
};
pub const CONSOLE_SCREEN_BUFFER_INFO = struct__CONSOLE_SCREEN_BUFFER_INFO;
pub const PCONSOLE_SCREEN_BUFFER_INFO = [*c]struct__CONSOLE_SCREEN_BUFFER_INFO;
pub const PHANDLER_ROUTINE = ?*const fn (DWORD) callconv(.C) BOOL;
pub const struct__MEMORY_BASIC_INFORMATION32 = extern struct {
    BaseAddress: DWORD = @import("std").mem.zeroes(DWORD),
    AllocationBase: DWORD = @import("std").mem.zeroes(DWORD),
    AllocationProtect: DWORD = @import("std").mem.zeroes(DWORD),
    RegionSize: DWORD = @import("std").mem.zeroes(DWORD),
    State: DWORD = @import("std").mem.zeroes(DWORD),
    Protect: DWORD = @import("std").mem.zeroes(DWORD),
    Type: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const MEMORY_BASIC_INFORMATION32 = struct__MEMORY_BASIC_INFORMATION32;
pub const PMEMORY_BASIC_INFORMATION32 = [*c]struct__MEMORY_BASIC_INFORMATION32;
pub const struct__MEMORY_BASIC_INFORMATION64 = extern struct {
    BaseAddress: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    AllocationBase: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    AllocationProtect: DWORD = @import("std").mem.zeroes(DWORD),
    __alignment1: DWORD = @import("std").mem.zeroes(DWORD),
    RegionSize: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    State: DWORD = @import("std").mem.zeroes(DWORD),
    Protect: DWORD = @import("std").mem.zeroes(DWORD),
    Type: DWORD = @import("std").mem.zeroes(DWORD),
    __alignment2: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const MEMORY_BASIC_INFORMATION64 = struct__MEMORY_BASIC_INFORMATION64;
pub const PMEMORY_BASIC_INFORMATION64 = [*c]struct__MEMORY_BASIC_INFORMATION64;
pub const MEMORY_BASIC_INFORMATION = MEMORY_BASIC_INFORMATION64;
pub const PMEMORY_BASIC_INFORMATION = PMEMORY_BASIC_INFORMATION64;
pub extern fn GetStdHandle(nStdHandle: DWORD) HANDLE;
pub extern fn GetConsoleScreenBufferInfo(hConsoleOutput: HANDLE, lpConsoleScreenBufferInfo: PCONSOLE_SCREEN_BUFFER_INFO) BOOL;
pub extern fn SetConsoleTextAttribute(hConsoleOutput: HANDLE, wAttributes: WORD) BOOL;
pub extern fn CloseHandle(hObject: HANDLE) BOOL;
pub extern fn SetHandleInformation(hObject: HANDLE, dwMask: DWORD, dwFlags: DWORD) BOOL;
pub extern fn DuplicateHandle(hSourceProcessHandle: HANDLE, hSourceHandle: HANDLE, hTargetProcessHandle: HANDLE, lpTargetHandle: LPHANDLE, dwDesiredAccess: DWORD, bInheritHandle: BOOL, dwOptions: DWORD) BOOL;
pub extern fn GetCommandLineA() LPSTR;
pub extern fn GetCommandLineW() LPWSTR;
pub extern fn AllocConsole() BOOL;
pub extern fn FreeConsole() BOOL;
pub extern fn AttachConsole(dwProcessId: DWORD) BOOL;
pub extern fn WriteConsoleA(hConsoleOutput: HANDLE, lpBuffer: ?*const anyopaque, nNumberOfCharsToWrite: DWORD, lpNumberOfCHarsWritten: LPDWORD, lpReserved: LPVOID) BOOL;
pub extern fn WriteConsoleW(hConsoleOutput: HANDLE, lpBuffer: ?*const anyopaque, nNumberOfCharsToWrite: DWORD, lpNumberOfCHarsWritten: LPDWORD, lpReserved: LPVOID) BOOL;
pub extern fn SetConsoleCtrlHandler(HandlerRoutine: PHANDLER_ROUTINE, Add: BOOL) BOOL;
pub extern fn GetConsoleWindow() HWND;
pub extern fn SetConsoleOutputCP(wCodePageID: UINT) BOOL;
pub extern fn GetConsoleOutputCP() UINT;
pub extern fn GetProcessHeap() HANDLE;
pub extern fn HeapAlloc(hHeap: HANDLE, dwFlags: DWORD, dwBytes: SIZE_T) LPVOID;
pub extern fn HeapReAlloc(hHeap: HANDLE, dwFlags: DWORD, lpMem: LPVOID, dwBytes: SIZE_T) LPVOID;
pub extern fn HeapFree(hHeap: HANDLE, dwFlags: DWORD, lpMem: LPVOID) BOOL;
pub extern fn HeapsetInformation(HeapHandle: HANDLE, HeapInformationClass: HEAP_INFORMATION_CLASS, HeapInformation: PVOID, HeapInformationLength: SIZE_T) BOOL;
pub extern fn VirtualAlloc(lpAddress: LPVOID, dwSize: SIZE_T, flAllocationType: DWORD, flProtect: DWORD) LPVOID;
pub extern fn VirtualQuery(lpAddress: LPCVOID, lpBuffer: PMEMORY_BASIC_INFORMATION, dwLength: SIZE_T) SIZE_T;
pub extern fn VirtualFree(lpAddress: LPVOID, dwSize: SIZE_T, dwFreeType: DWORD) BOOL;
pub extern fn VirtualProtect(lpAddress: LPVOID, dwSize: SIZE_T, flNewProtect: DWORD, lpflOldProtect: PDWORD) BOOL;
pub extern fn FlushInstructionCache(hProcess: HANDLE, lpBaseAddress: LPCVOID, dwSize: SIZE_T) BOOL;
pub extern fn CreatePipe(hReadPipe: PHANDLE, hWritePipe: PHANDLE, lpPipeAttributes: LPSECURITY_ATTRIBUTES, nSize: DWORD) BOOL;
pub extern fn PeekNamedPipe(hNamedPipe: HANDLE, lpBuffer: LPVOID, nBufferSize: DWORD, lpBytesRead: LPDWORD, lpTotalBytesAvail: LPDWORD, lpBytesLeftThisMessage: LPDWORD) BOOL;
pub extern fn GetFullPathNameA(lpFileName: LPCSTR, nBufferLength: DWORD, lpBuffer: LPSTR, lpFilePart: [*c]LPSTR) DWORD;
pub extern fn GetFullPathNameW(lpFileName: LPCWSTR, nBufferLength: DWORD, lpBuffer: LPWSTR, lpFilePart: [*c]LPWSTR) DWORD;
pub extern fn SetCurrentDirectoryA(lpPathName: LPCSTR) BOOL;
pub extern fn SetCurrentDirectoryW(lpPathName: LPCWSTR) BOOL;
pub extern fn GetCurrentDirectoryA(nBufferLength: DWORD, lpBuffer: LPSTR) DWORD;
pub extern fn GetCurrentDirectoryW(nBufferLength: DWORD, lpBuffer: LPWSTR) DWORD;
pub const __builtin_va_list = [*c]u8;
pub const __gnuc_va_list = __builtin_va_list;
pub const va_list = __builtin_va_list;
pub const MMRESULT = UINT;
pub const struct__SYSTEMTIME = extern struct {
    wYear: WORD = @import("std").mem.zeroes(WORD),
    wMonth: WORD = @import("std").mem.zeroes(WORD),
    wDayOfWeek: WORD = @import("std").mem.zeroes(WORD),
    wDay: WORD = @import("std").mem.zeroes(WORD),
    wHour: WORD = @import("std").mem.zeroes(WORD),
    wMinute: WORD = @import("std").mem.zeroes(WORD),
    wSecond: WORD = @import("std").mem.zeroes(WORD),
    wMilliseconds: WORD = @import("std").mem.zeroes(WORD),
};
pub const SYSTEMTIME = struct__SYSTEMTIME;
pub const PSYSTEMTIME = [*c]struct__SYSTEMTIME;
pub const LPSYSTEMTIME = PSYSTEMTIME;
pub const struct__TIME_ZONE_INFORMATION = extern struct {
    Bias: LONG = @import("std").mem.zeroes(LONG),
    StandardName: [32]WCHAR = @import("std").mem.zeroes([32]WCHAR),
    StandardDate: SYSTEMTIME = @import("std").mem.zeroes(SYSTEMTIME),
    StandardBias: LONG = @import("std").mem.zeroes(LONG),
    DaylightName: [32]WCHAR = @import("std").mem.zeroes([32]WCHAR),
    DaylightDate: SYSTEMTIME = @import("std").mem.zeroes(SYSTEMTIME),
    DaylightBias: LONG = @import("std").mem.zeroes(LONG),
};
pub const TIME_ZONE_INFORMATION = struct__TIME_ZONE_INFORMATION;
pub const PTIME_ZONE_INFORMATION = [*c]struct__TIME_ZONE_INFORMATION;
pub const LPTIME_ZONE_INFORMATION = PTIME_ZONE_INFORMATION;
pub extern fn _byteswap_ushort(Number: c_ushort) c_ushort;
pub extern fn _byteswap_ulong(Number: c_ulong) c_ulong;
pub extern fn _byteswap_uint64(Number: c_ulonglong) c_ulonglong;
pub extern fn _rotl(value: c_uint, shift: c_int) c_uint;
pub extern fn _rotl64(value: c_ulonglong, shift: c_int) c_ulonglong;
pub extern fn _BitScanForward(Index: [*c]c_ulong, Mask: c_ulong) u8;
pub extern fn _BitScanForward64(Index: [*c]c_ulong, Mask: c_ulonglong) u8;
pub extern fn WideCharToMultiByte(CodePage: UINT, dwFlags: DWORD, lpWideCharStr: LPCWSTR, cchWideChar: c_int, lpMultiByteStr: LPSTR, cbMultiByte: c_int, lpDefaultChar: LPCSTR, lpUsedDefaultChar: LPBOOL) c_int;
pub extern fn MultiByteToWideChar(CodePage: UINT, dwFlags: DWORD, lpMultiByteStr: LPCSTR, cbMultiByte: c_int, lpWideCharStr: LPWSTR, cchWideChar: c_int) c_int;
pub extern fn lstrlenA(lpString: LPCSTR) c_int;
pub extern fn lstrlenW(lpString: LPCWSTR) c_int;
pub extern fn lstrcpyA(lpString1: LPCSTR, lpString2: LPCSTR) LPCSTR;
pub extern fn lstrcpyW(lpString1: LPCWSTR, lpString2: LPCWSTR) LPCWSTR;
pub extern fn GetSystemTime(lpSystemTime: LPSYSTEMTIME) void;
pub extern fn GetLocalTime(lpSystemTime: LPSYSTEMTIME) void;
pub extern fn QueryProcessCycleTime(hProcess: HANDLE, CycleTime: PULONG64) BOOL;
pub extern fn SystemTimeToFileTime(lpSystemTime: [*c]const SYSTEMTIME, lpFileTime: LPFILETIME) BOOL;
pub extern fn FileTimeToSystemTime(lpFileTime: [*c]const FILETIME, lpSystemTime: LPSYSTEMTIME) BOOL;
pub extern fn CompareFileTime(lpFileTime1: [*c]const FILETIME, lpFileTime2: [*c]const FILETIME) LONG;
pub extern fn GetSystemTimeAsFileTime(lpSystemTimeAsFileTime: LPFILETIME) void;
pub extern fn SystemTimeToTzSpecificLocalTime(lpTimeZone: LPTIME_ZONE_INFORMATION, lpUniversalTime: LPSYSTEMTIME, lpLocalTime: LPSYSTEMTIME) BOOL;
pub extern fn timeGetTime() DWORD;
pub extern fn SetEnvironmentVariableA(lpName: LPCSTR, lpValue: LPCSTR) BOOL;
pub extern fn SetEnvironmentVariableW(lpName: LPCWSTR, lpValue: LPCWSTR) BOOL;
pub extern fn GetEnvironmentVariableA(lpName: LPCSTR, lpBuffer: LPCSTR, nSize: DWORD) DWORD;
pub extern fn GetEnvironmentVariableW(lpName: LPCWSTR, lpBuffer: LPCWSTR, nSize: DWORD) DWORD;
pub extern fn DisableThreadLibraryCalls(hModule: HMODULE) BOOL;
pub extern fn GetLastError() DWORD;
pub extern fn Sleep(dwMilliseconds: DWORD) void;
pub extern fn SleepEx(dwMilliseconds: DWORD, bAlertable: BOOL) DWORD;
pub extern fn GetModuleHandleA(lpModuleName: LPCSTR) HMODULE;
pub extern fn GetModuleHandleW(lpModuleName: LPCWSTR) HMODULE;
pub extern fn FormatMessageA(dwFlags: DWORD, lpSource: LPCVOID, dwMessageId: DWORD, dwLanguageId: DWORD, lpBuffer: LPSTR, nSize: DWORD, Arguments: [*c]va_list) DWORD;
pub extern fn FormatMessageW(dwFlags: DWORD, lpSource: LPCVOID, dwMessageId: DWORD, dwLanguageId: DWORD, lpBuffer: LPWSTR, nSize: DWORD, Arguments: [*c]va_list) DWORD;
pub extern fn GetTickCount() DWORD;
pub extern fn GetTickCount64() ULONGLONG;
pub extern fn QueryPerformanceFrequency(lpFrequency: [*c]LARGE_INTEGER) BOOL;
pub extern fn QueryPerformanceCounter(lpPerformanceCount: [*c]LARGE_INTEGER) BOOL;
pub const struct_timecaps_tag = extern struct {
    wPeriodMin: UINT = @import("std").mem.zeroes(UINT),
    wPeriodMax: UINT = @import("std").mem.zeroes(UINT),
};
pub const TIMECAPS = struct_timecaps_tag;
pub const PTIMECAPS = [*c]struct_timecaps_tag;
pub const NPTIMECAPS = [*c]struct_timecaps_tag;
pub const LPTIMECAPS = [*c]struct_timecaps_tag;
pub extern fn timeGetDevCaps(ptc: LPTIMECAPS, cbtc: UINT) MMRESULT;
pub extern fn timeBeginPeriod(uPeriod: UINT) MMRESULT;
pub extern fn timeEndPeriod(uPeriod: UINT) MMRESULT;
pub extern fn LoadLibraryA(lpFileName: LPCSTR) HMODULE;
pub extern fn LoadLibraryW(lpFileName: LPCWSTR) HMODULE;
pub extern fn LoadLibraryExA(lpLibFileName: LPCSTR, hFile: HANDLE, dwFlags: DWORD) HMODULE;
pub extern fn LoadLibraryExW(lpLibFileName: LPCWSTR, hFile: HANDLE, dwFlags: DWORD) HMODULE;
pub extern fn GetProcAddress(hModule: HMODULE, lProcName: LPCSTR) FARPROC;
pub extern fn wglGetProcAddress(lpszProc: LPCSTR) PROC;
pub extern fn FreeLibrary(hModule: HMODULE) BOOL;
pub extern fn SecureZeroMemory(ptr: PVOID, cnt: SIZE_T) PVOID;
pub const JobObjectBasicAccountingInformation: c_int = 1;
pub const JobObjectBasicLimitInformation: c_int = 2;
pub const JobObjectBasicProcessIdList: c_int = 3;
pub const JobObjectBasicUIRestrictions: c_int = 4;
pub const JobObjectSecurityLimitInformation: c_int = 5;
pub const JobObjectEndOfJobTimeInformation: c_int = 6;
pub const JobObjectAssociateCompletionPortInformation: c_int = 7;
pub const JobObjectBasicAndIoAccountingInformation: c_int = 8;
pub const JobObjectExtendedLimitInformation: c_int = 9;
pub const JobObjectJobSetInformation: c_int = 10;
pub const JobObjectGroupInformation: c_int = 11;
pub const JobObjectNotificationLimitInformation: c_int = 12;
pub const JobObjectLimitViolationInformation: c_int = 13;
pub const JobObjectGroupInformationEx: c_int = 14;
pub const JobObjectCpuRateControlInformation: c_int = 15;
pub const JobObjectCompletionFilter: c_int = 16;
pub const JobObjectCompletionCounter: c_int = 17;
pub const JobObjectReserved1Information: c_int = 18;
pub const JobObjectReserved2Information: c_int = 19;
pub const JobObjectReserved3Information: c_int = 20;
pub const JobObjectReserved4Information: c_int = 21;
pub const JobObjectReserved5Information: c_int = 22;
pub const JobObjectReserved6Information: c_int = 23;
pub const JobObjectReserved7Information: c_int = 24;
pub const JobObjectReserved8Information: c_int = 25;
pub const JobObjectReserved9Information: c_int = 26;
pub const MaxJobObjectInfoClass: c_int = 27;
pub const enum__JOBOBJECTINFOCLASS = c_uint;
pub const JOBOBJECTINFOCLASS = enum__JOBOBJECTINFOCLASS;
pub const struct__STARTUPINFOA = extern struct {
    cb: DWORD = @import("std").mem.zeroes(DWORD),
    lpReserved: LPSTR = @import("std").mem.zeroes(LPSTR),
    lpDesktop: LPSTR = @import("std").mem.zeroes(LPSTR),
    lpTitle: LPSTR = @import("std").mem.zeroes(LPSTR),
    dwX: DWORD = @import("std").mem.zeroes(DWORD),
    dwY: DWORD = @import("std").mem.zeroes(DWORD),
    dwXSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwYSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwXCountChars: DWORD = @import("std").mem.zeroes(DWORD),
    dwYCountChars: DWORD = @import("std").mem.zeroes(DWORD),
    dwFillAttribute: DWORD = @import("std").mem.zeroes(DWORD),
    dwFlags: DWORD = @import("std").mem.zeroes(DWORD),
    wShowWindow: WORD = @import("std").mem.zeroes(WORD),
    cbReserved2: WORD = @import("std").mem.zeroes(WORD),
    lpReserved2: LPBYTE = @import("std").mem.zeroes(LPBYTE),
    hStdInput: HANDLE = @import("std").mem.zeroes(HANDLE),
    hStdOutput: HANDLE = @import("std").mem.zeroes(HANDLE),
    hStdError: HANDLE = @import("std").mem.zeroes(HANDLE),
};
pub const STARTUPINFOA = struct__STARTUPINFOA;
pub const LPSTARTUPINFOA = [*c]struct__STARTUPINFOA;
pub const struct__STARTUPINFOW = extern struct {
    cb: DWORD = @import("std").mem.zeroes(DWORD),
    lpReserved: LPWSTR = @import("std").mem.zeroes(LPWSTR),
    lpDesktop: LPWSTR = @import("std").mem.zeroes(LPWSTR),
    lpTitle: LPWSTR = @import("std").mem.zeroes(LPWSTR),
    dwX: DWORD = @import("std").mem.zeroes(DWORD),
    dwY: DWORD = @import("std").mem.zeroes(DWORD),
    dwXSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwYSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwXCountChars: DWORD = @import("std").mem.zeroes(DWORD),
    dwYCountChars: DWORD = @import("std").mem.zeroes(DWORD),
    dwFillAttribute: DWORD = @import("std").mem.zeroes(DWORD),
    dwFlags: DWORD = @import("std").mem.zeroes(DWORD),
    wShowWindow: WORD = @import("std").mem.zeroes(WORD),
    cbReserved2: WORD = @import("std").mem.zeroes(WORD),
    lpReserved2: LPBYTE = @import("std").mem.zeroes(LPBYTE),
    hStdInput: HANDLE = @import("std").mem.zeroes(HANDLE),
    hStdOutput: HANDLE = @import("std").mem.zeroes(HANDLE),
    hStdError: HANDLE = @import("std").mem.zeroes(HANDLE),
};
pub const STARTUPINFOW = struct__STARTUPINFOW;
pub const LPSTARTUPINFOW = [*c]struct__STARTUPINFOW;
pub const struct__PROC_THREAD_ATTRIBUTE_LIST = opaque {};
pub const PPROC_THREAD_ATTRIBUTE_LIST = ?*struct__PROC_THREAD_ATTRIBUTE_LIST;
pub const LPPROC_THREAD_ATTRIBUTE_LIST = ?*struct__PROC_THREAD_ATTRIBUTE_LIST;
pub const struct__STARTUPINFOEXA = extern struct {
    StartupInfo: STARTUPINFOA = @import("std").mem.zeroes(STARTUPINFOA),
    lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST = @import("std").mem.zeroes(PPROC_THREAD_ATTRIBUTE_LIST),
};
pub const STARTUPINFOEXA = struct__STARTUPINFOEXA;
pub const LPSTARTUPINFOEXA = [*c]struct__STARTUPINFOEXA;
pub const struct__STARTUPINFOEXW = extern struct {
    StartupInfo: STARTUPINFOW = @import("std").mem.zeroes(STARTUPINFOW),
    lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST = @import("std").mem.zeroes(PPROC_THREAD_ATTRIBUTE_LIST),
};
pub const STARTUPINFOEXW = struct__STARTUPINFOEXW;
pub const LPSTARTUPINFOEXW = [*c]struct__STARTUPINFOEXW;
pub const struct__PROCESS_INFORMATION = extern struct {
    hProcess: HANDLE = @import("std").mem.zeroes(HANDLE),
    hThread: HANDLE = @import("std").mem.zeroes(HANDLE),
    dwProcessId: DWORD = @import("std").mem.zeroes(DWORD),
    dwThreadId: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const PROCESS_INFORMATION = struct__PROCESS_INFORMATION;
pub const LPPROCESS_INFORMATION = [*c]struct__PROCESS_INFORMATION;
pub const struct__JOBOBJECT_BASIC_LIMIT_INFORMATION = extern struct {
    PerProcessUserTimeLimit: LARGE_INTEGER = @import("std").mem.zeroes(LARGE_INTEGER),
    PerJobUserTimeLimit: LARGE_INTEGER = @import("std").mem.zeroes(LARGE_INTEGER),
    LimitFlags: DWORD = @import("std").mem.zeroes(DWORD),
    MinimumWorkingSetSize: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    MaximumWorkingSetSize: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    ActiveProcessLimit: DWORD = @import("std").mem.zeroes(DWORD),
    Affinity: ULONG_PTR = @import("std").mem.zeroes(ULONG_PTR),
    PriorityClass: DWORD = @import("std").mem.zeroes(DWORD),
    SchedulingClass: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const JOBOBJECT_BASIC_LIMIT_INFORMATION = struct__JOBOBJECT_BASIC_LIMIT_INFORMATION;
pub const PJOBOBJECT_BASIC_LIMIT_INFORMATION = [*c]struct__JOBOBJECT_BASIC_LIMIT_INFORMATION;
pub const struct__IO_COUNTERS = extern struct {
    ReadOperationCount: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    WriteOperationCount: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    OtherOperationCount: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    ReadTransferCount: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    WriteTransferCount: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    OtherTransferCount: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
};
pub const IO_COUNTERS = struct__IO_COUNTERS;
pub const PIO_COUNTERS = [*c]struct__IO_COUNTERS;
pub const struct__JOBOBJECT_EXTENDED_LIMIT_INFORMATION = extern struct {
    BasicLimitInformation: JOBOBJECT_BASIC_LIMIT_INFORMATION = @import("std").mem.zeroes(JOBOBJECT_BASIC_LIMIT_INFORMATION),
    IoInfo: IO_COUNTERS = @import("std").mem.zeroes(IO_COUNTERS),
    ProcessMemoryLimit: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    JobMemoryLimit: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    PeakProcessMemoryUsed: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    PeakJobMemoryUsed: SIZE_T = @import("std").mem.zeroes(SIZE_T),
};
pub const JOBOBJECT_EXTENDED_LIMIT_INFORMATION = struct__JOBOBJECT_EXTENDED_LIMIT_INFORMATION;
pub const PJOBOBJECT_EXTENDED_LIMIT_INFORMATION = [*c]struct__JOBOBJECT_EXTENDED_LIMIT_INFORMATION;
pub extern fn GetCurrentProcess() HANDLE;
pub extern fn GetCurrentProcessId() DWORD;
pub extern fn ExitProcess(uExitCode: UINT) void;
pub extern fn OpenProcess(dwDesiredAccess: DWORD, bInheritHandle: BOOL, dwProcessId: DWORD) HANDLE;
pub extern fn CreateProcessA(lpApplicationName: LPCSTR, lpCommandLine: LPSTR, lpProcessAttributes: LPSECURITY_ATTRIBUTES, lpThreadAttributes: LPSECURITY_ATTRIBUTES, bInheritHandles: BOOL, dwCreationFlags: DWORD, lpEnvironment: LPVOID, lpCurrentDirectory: LPCSTR, lpStartupInfo: LPSTARTUPINFOA, lpProcessInformation: LPPROCESS_INFORMATION) BOOL;
pub extern fn CreateProcessW(lpApplicationName: LPCWSTR, lpCommandLine: LPWSTR, lpProcessAttributes: LPSECURITY_ATTRIBUTES, lpThreadAttributes: LPSECURITY_ATTRIBUTES, bInheritHandles: BOOL, dwCreationFlags: DWORD, lpEnvironment: LPVOID, lpCurrentDirectory: LPCWSTR, lpStartupInfo: LPSTARTUPINFOW, lpProcessInformation: LPPROCESS_INFORMATION) BOOL;
pub extern fn TerminateProcess(hProcess: HANDLE, uExitCode: UINT) BOOL;
pub extern fn EnumProcessModules(hProcess: HANDLE, lphModule: [*c]HMODULE, cb: DWORD, lpcbNeeded: LPDWORD) BOOL;
pub extern fn WaitForInputIdle(hProcess: HANDLE, dwMilliseconds: DWORD) DWORD;
pub extern fn GetExitCodeProcess(hProcess: HANDLE, lpExitCode: LPDWORD) BOOL;
pub extern fn CreateJobObjectA(lpJobAttributes: LPSECURITY_ATTRIBUTES, lpName: LPCSTR) HANDLE;
pub extern fn CreateJobObjectW(lpJobAttributes: LPSECURITY_ATTRIBUTES, lpName: LPCWSTR) HANDLE;
pub extern fn SetInformationJobObject(hJob: HANDLE, JobObjectInfoClass: JOBOBJECTINFOCLASS, lpJobObjectInfo: LPVOID, cbJobObjectInfoLength: DWORD) BOOL;
pub extern fn AssignProcessToJobObject(hJob: HANDLE, hProcess: HANDLE) BOOL;
const struct_unnamed_16 = extern struct {
    wProcessorArchitecture: WORD = @import("std").mem.zeroes(WORD),
    wReserved: WORD = @import("std").mem.zeroes(WORD),
};
const union_unnamed_15 = extern union {
    dwOemId: DWORD,
    unnamed_0: struct_unnamed_16,
};
pub const struct__SYSTEM_INFO = extern struct {
    unnamed_0: union_unnamed_15 = @import("std").mem.zeroes(union_unnamed_15),
    dwPageSize: DWORD = @import("std").mem.zeroes(DWORD),
    lpMinimumApplicationAddress: LPVOID = @import("std").mem.zeroes(LPVOID),
    lpMaximumApplicationAddress: LPVOID = @import("std").mem.zeroes(LPVOID),
    dwActiveProcessorMask: DWORD_PTR = @import("std").mem.zeroes(DWORD_PTR),
    dwNumberOfProcessors: DWORD = @import("std").mem.zeroes(DWORD),
    dwProcessorType: DWORD = @import("std").mem.zeroes(DWORD),
    dwAllocationGranularity: DWORD = @import("std").mem.zeroes(DWORD),
    wProcessorLevel: WORD = @import("std").mem.zeroes(WORD),
    wProcessorRevision: WORD = @import("std").mem.zeroes(WORD),
};
pub const SYSTEM_INFO = struct__SYSTEM_INFO;
pub const LPSYSTEM_INFO = [*c]struct__SYSTEM_INFO;
pub const struct__DISPLAY_DEVICEA = extern struct {
    cb: DWORD = @import("std").mem.zeroes(DWORD),
    DeviceName: [32]CHAR = @import("std").mem.zeroes([32]CHAR),
    DeviceString: [128]CHAR = @import("std").mem.zeroes([128]CHAR),
    StateFlags: DWORD = @import("std").mem.zeroes(DWORD),
    DeviceID: [128]CHAR = @import("std").mem.zeroes([128]CHAR),
    DeviceKey: [128]CHAR = @import("std").mem.zeroes([128]CHAR),
};
pub const DISPLAY_DEVICEA = struct__DISPLAY_DEVICEA;
pub const PDISPLAY_DEVICEA = [*c]struct__DISPLAY_DEVICEA;
pub const struct__DISPLAY_DEVICEW = extern struct {
    cb: DWORD = @import("std").mem.zeroes(DWORD),
    DeviceName: [32]WCHAR = @import("std").mem.zeroes([32]WCHAR),
    DeviceString: [128]WCHAR = @import("std").mem.zeroes([128]WCHAR),
    StateFlags: DWORD = @import("std").mem.zeroes(DWORD),
    DeviceID: [128]WCHAR = @import("std").mem.zeroes([128]WCHAR),
    DeviceKey: [128]WCHAR = @import("std").mem.zeroes([128]WCHAR),
};
pub const DISPLAY_DEVICEW = struct__DISPLAY_DEVICEW;
pub const PDISPLAY_DEVICEW = [*c]struct__DISPLAY_DEVICEW;
pub const struct__OSVERSIONINFOEXA = extern struct {
    dwOSVersionInfoSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwMajorVersion: DWORD = @import("std").mem.zeroes(DWORD),
    dwMinorVersion: DWORD = @import("std").mem.zeroes(DWORD),
    dwBuildNumber: DWORD = @import("std").mem.zeroes(DWORD),
    dwPlatformId: DWORD = @import("std").mem.zeroes(DWORD),
    szCSDVersion: [128]CHAR = @import("std").mem.zeroes([128]CHAR),
    wServicePackMajor: WORD = @import("std").mem.zeroes(WORD),
    wServicePackMinor: WORD = @import("std").mem.zeroes(WORD),
    wSuiteMask: WORD = @import("std").mem.zeroes(WORD),
    wProductType: BYTE = @import("std").mem.zeroes(BYTE),
    wReserved: BYTE = @import("std").mem.zeroes(BYTE),
};
pub const OSVERSIONINFOEXA = struct__OSVERSIONINFOEXA;
pub const POSVERSIONINFOEXA = [*c]struct__OSVERSIONINFOEXA;
pub const LPOSVERSIONINFOEXA = [*c]struct__OSVERSIONINFOEXA;
pub const struct__OSVERSIONINFOEXW = extern struct {
    dwOSVersionInfoSize: DWORD = @import("std").mem.zeroes(DWORD),
    dwMajorVersion: DWORD = @import("std").mem.zeroes(DWORD),
    dwMinorVersion: DWORD = @import("std").mem.zeroes(DWORD),
    dwBuildNumber: DWORD = @import("std").mem.zeroes(DWORD),
    dwPlatformId: DWORD = @import("std").mem.zeroes(DWORD),
    szCSDVersion: [128]WCHAR = @import("std").mem.zeroes([128]WCHAR),
    wServicePackMajor: WORD = @import("std").mem.zeroes(WORD),
    wServicePackMinor: WORD = @import("std").mem.zeroes(WORD),
    wSuiteMask: WORD = @import("std").mem.zeroes(WORD),
    wProductType: BYTE = @import("std").mem.zeroes(BYTE),
    wReserved: BYTE = @import("std").mem.zeroes(BYTE),
};
pub const OSVERSIONINFOEXW = struct__OSVERSIONINFOEXW;
pub const POSVERSIONINFOEXW = [*c]struct__OSVERSIONINFOEXW;
pub const LPOSVERSIONINFOEXW = [*c]struct__OSVERSIONINFOEXW;
pub const RelationProcessorCore: c_int = 0;
pub const RelationNumaNode: c_int = 1;
pub const RelationCache: c_int = 2;
pub const RelationProcessorPackage: c_int = 3;
pub const RelationGroup: c_int = 4;
pub const RelationAll: c_int = 65535;
pub const enum__LOGICAL_PROCESSOR_RELATIONSHIP = c_uint;
pub const LOGICAL_PROCESSOR_RELATIONSHIP = enum__LOGICAL_PROCESSOR_RELATIONSHIP;
pub const CacheUnified: c_int = 0;
pub const CacheInstruction: c_int = 1;
pub const CacheData: c_int = 2;
pub const CacheTrace: c_int = 3;
pub const enum__PROCESSOR_CACHE_TYPE = c_uint;
pub const PROCESSOR_CACHE_TYPE = enum__PROCESSOR_CACHE_TYPE;
pub const struct__CACHE_DESCRIPTOR = extern struct {
    Level: BYTE = @import("std").mem.zeroes(BYTE),
    Associativity: BYTE = @import("std").mem.zeroes(BYTE),
    LineSize: WORD = @import("std").mem.zeroes(WORD),
    Size: DWORD = @import("std").mem.zeroes(DWORD),
    Type: PROCESSOR_CACHE_TYPE = @import("std").mem.zeroes(PROCESSOR_CACHE_TYPE),
};
pub const CACHE_DESCRIPTOR = struct__CACHE_DESCRIPTOR;
pub const PCACHE_DESCRIPTOR = [*c]struct__CACHE_DESCRIPTOR;
const struct_unnamed_18 = extern struct {
    Flags: BYTE = @import("std").mem.zeroes(BYTE),
};
const struct_unnamed_19 = extern struct {
    NodeNumber: DWORD = @import("std").mem.zeroes(DWORD),
};
const union_unnamed_17 = extern union {
    ProcessorCore: struct_unnamed_18,
    NumaNode: struct_unnamed_19,
    Cache: CACHE_DESCRIPTOR,
    Reserved: [2]ULONGLONG,
};
pub const struct__SYSTEM_LOGICAL_PROCESSOR_INFORMATION = extern struct {
    ProcessorMask: ULONG_PTR = @import("std").mem.zeroes(ULONG_PTR),
    Relationship: LOGICAL_PROCESSOR_RELATIONSHIP = @import("std").mem.zeroes(LOGICAL_PROCESSOR_RELATIONSHIP),
    unnamed_0: union_unnamed_17 = @import("std").mem.zeroes(union_unnamed_17),
};
pub const SYSTEM_LOGICAL_PROCESSOR_INFORMATION = struct__SYSTEM_LOGICAL_PROCESSOR_INFORMATION;
pub const PSYSTEM_LOGICAL_PROCESSOR_INFORMATION = [*c]struct__SYSTEM_LOGICAL_PROCESSOR_INFORMATION;
pub const KAFFINITY = ULONG_PTR;
pub const struct__GROUP_AFFINITY = extern struct {
    Mask: KAFFINITY = @import("std").mem.zeroes(KAFFINITY),
    Group: WORD = @import("std").mem.zeroes(WORD),
    Reserved: [3]WORD = @import("std").mem.zeroes([3]WORD),
};
pub const GROUP_AFFINITY = struct__GROUP_AFFINITY;
pub const PGROUP_AFFINITY = [*c]struct__GROUP_AFFINITY;
pub const struct__NUMA_NODE_RELATIONSHIP = extern struct {
    NodeNumber: DWORD = @import("std").mem.zeroes(DWORD),
    Reserved: [20]BYTE = @import("std").mem.zeroes([20]BYTE),
    GroupMask: GROUP_AFFINITY = @import("std").mem.zeroes(GROUP_AFFINITY),
};
pub const NUMA_NODE_RELATIONSHIP = struct__NUMA_NODE_RELATIONSHIP;
pub const PNUMA_NODE_RELATIONSHIP = [*c]struct__NUMA_NODE_RELATIONSHIP;
pub const struct__PROCESSOR_GROUP_INFO = extern struct {
    MaximumProcessorCount: BYTE = @import("std").mem.zeroes(BYTE),
    ActiveProcessorCount: BYTE = @import("std").mem.zeroes(BYTE),
    Reserved: [38]BYTE = @import("std").mem.zeroes([38]BYTE),
    ActiveProcessorMask: KAFFINITY = @import("std").mem.zeroes(KAFFINITY),
};
pub const PROCESSOR_GROUP_INFO = struct__PROCESSOR_GROUP_INFO;
pub const PPROCESSOR_GROUP_INFO = [*c]struct__PROCESSOR_GROUP_INFO;
pub const struct__GROUP_RELATIONSHIP = extern struct {
    MaximumGroupCount: WORD = @import("std").mem.zeroes(WORD),
    ActiveGroupCount: WORD = @import("std").mem.zeroes(WORD),
    Reserved: [20]BYTE = @import("std").mem.zeroes([20]BYTE),
    GroupInfo: [1]PROCESSOR_GROUP_INFO = @import("std").mem.zeroes([1]PROCESSOR_GROUP_INFO),
};
pub const GROUP_RELATIONSHIP = struct__GROUP_RELATIONSHIP;
pub const PGROUP_RELATIONSHIP = [*c]struct__GROUP_RELATIONSHIP;
pub const struct__CACHE_RELATIONSHIP = extern struct {
    Level: BYTE = @import("std").mem.zeroes(BYTE),
    Associativity: BYTE = @import("std").mem.zeroes(BYTE),
    LineSize: WORD = @import("std").mem.zeroes(WORD),
    CacheSize: DWORD = @import("std").mem.zeroes(DWORD),
    Type: PROCESSOR_CACHE_TYPE = @import("std").mem.zeroes(PROCESSOR_CACHE_TYPE),
    Reserved: [20]BYTE = @import("std").mem.zeroes([20]BYTE),
    GroupMask: GROUP_AFFINITY = @import("std").mem.zeroes(GROUP_AFFINITY),
};
pub const CACHE_RELATIONSHIP = struct__CACHE_RELATIONSHIP;
pub const PCACHE_RELATIONSHIP = [*c]struct__CACHE_RELATIONSHIP;
pub const struct__PROCESSOR_RELATIONSHIP = extern struct {
    Flags: BYTE = @import("std").mem.zeroes(BYTE),
    EfficiencyClass: BYTE = @import("std").mem.zeroes(BYTE),
    Reserved: [21]BYTE = @import("std").mem.zeroes([21]BYTE),
    GroupCount: WORD = @import("std").mem.zeroes(WORD),
    GroupMask: [1]GROUP_AFFINITY = @import("std").mem.zeroes([1]GROUP_AFFINITY),
};
pub const PROCESSOR_RELATIONSHIP = struct__PROCESSOR_RELATIONSHIP;
pub const PPROCESSOR_RELATIONSHIP = [*c]struct__PROCESSOR_RELATIONSHIP;
const union_unnamed_20 = extern union {
    Processor: PROCESSOR_RELATIONSHIP,
    NumaNode: NUMA_NODE_RELATIONSHIP,
    Cache: CACHE_RELATIONSHIP,
    Group: GROUP_RELATIONSHIP,
};
pub const struct__SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX = extern struct {
    Relationship: LOGICAL_PROCESSOR_RELATIONSHIP = @import("std").mem.zeroes(LOGICAL_PROCESSOR_RELATIONSHIP),
    Size: DWORD = @import("std").mem.zeroes(DWORD),
    unnamed_0: union_unnamed_20 = @import("std").mem.zeroes(union_unnamed_20),
};
pub const SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX = struct__SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX;
pub const PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX = [*c]struct__SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX;
pub const struct__PROCESS_MEMORY_COUNTERS = extern struct {
    cb: DWORD = @import("std").mem.zeroes(DWORD),
    PageFaultCount: DWORD = @import("std").mem.zeroes(DWORD),
    PeakWorkingSetSize: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    WorkingSetSize: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    QuotaPeakPagedPoolUsage: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    QuotaPagedPoolUsage: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    QuotaPeakNonPagedPoolUsage: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    QuotaNonPagedPoolUsage: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    PagefileUsage: SIZE_T = @import("std").mem.zeroes(SIZE_T),
    PeakPagefileUsage: SIZE_T = @import("std").mem.zeroes(SIZE_T),
};
pub const PROCESS_MEMORY_COUNTERS = struct__PROCESS_MEMORY_COUNTERS;
pub const PPROCESS_MEMORY_COUNTERS = [*c]struct__PROCESS_MEMORY_COUNTERS;
pub const struct__MEMORYSTATUSEX = extern struct {
    dwLength: DWORD = @import("std").mem.zeroes(DWORD),
    dwMemoryLoad: DWORD = @import("std").mem.zeroes(DWORD),
    ullTotalPhys: DWORDLONG = @import("std").mem.zeroes(DWORDLONG),
    ullAvailPhys: DWORDLONG = @import("std").mem.zeroes(DWORDLONG),
    ullTotalPageFile: DWORDLONG = @import("std").mem.zeroes(DWORDLONG),
    ullAvailPageFile: DWORDLONG = @import("std").mem.zeroes(DWORDLONG),
    ullTotalVirtual: DWORDLONG = @import("std").mem.zeroes(DWORDLONG),
    ullAvailVirtual: DWORDLONG = @import("std").mem.zeroes(DWORDLONG),
    ullAvailExtendedVirtual: DWORDLONG = @import("std").mem.zeroes(DWORDLONG),
};
pub const MEMORYSTATUSEX = struct__MEMORYSTATUSEX;
pub const LPMEMORYSTATUSEX = [*c]struct__MEMORYSTATUSEX;
pub const struct__PROCESSOR_NUMBER = extern struct {
    Group: WORD = @import("std").mem.zeroes(WORD),
    Number: BYTE = @import("std").mem.zeroes(BYTE),
    Reserved: BYTE = @import("std").mem.zeroes(BYTE),
};
pub const PROCESSOR_NUMBER = struct__PROCESSOR_NUMBER;
pub const PPROCESSOR_NUMBER = [*c]struct__PROCESSOR_NUMBER;
pub extern fn GetSystemInfo(lpSystemInfo: LPSYSTEM_INFO) void;
pub extern fn GlobalMemoryStatusEx(lpBuffer: LPMEMORYSTATUSEX) BOOL;
pub extern fn GetLogicalProcessorInformation(Buffer: PSYSTEM_LOGICAL_PROCESSOR_INFORMATION, ReturnedLength: PDWORD) BOOL;
pub extern fn GetLogicalProcessorInformationEx(RelationshipType: LOGICAL_PROCESSOR_RELATIONSHIP, Buffer: PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX, ReturnedLength: PDWORD) BOOL;
pub extern fn GetProcessMemoryInfo(hProcess: HANDLE, ppsmemCounters: PPROCESS_MEMORY_COUNTERS, cb: DWORD) BOOL;
pub extern fn GetProcessTimes(hProcess: HANDLE, lpCreationTime: LPFILETIME, lpExitTime: LPFILETIME, lpKernelTime: LPFILETIME, lpUserTime: LPFILETIME) BOOL;
pub extern fn GetCurrentProcessorNumber() DWORD;
pub extern fn GetCurrentProcessorNumberEx(ProcNumber: PPROCESSOR_NUMBER) void;
pub extern fn GetActiveProcessorCount(GroupNumber: WORD) DWORD;
pub extern fn GetComputerNameA(lpBuffer: LPSTR, lpnSize: LPDWORD) BOOL;
pub extern fn GetComputerNameW(lpBuffer: LPWSTR, lpnSize: LPDWORD) BOOL;
pub extern fn VerifyVersionInfoA(lpVersionInfo: LPOSVERSIONINFOEXA, dwTypeMask: DWORD, dwlConditionMask: DWORDLONG) BOOL;
pub extern fn VerifyVersionInfoW(lpVersionInfo: LPOSVERSIONINFOEXW, dwTypeMask: DWORD, dwlConditionMask: DWORDLONG) BOOL;
pub extern fn VerSetConditionMask(ConditionMask: ULONGLONG, TypeMask: DWORD, Condition: BYTE) ULONGLONG;
pub fn IsWindowsVersionOrGreater(arg_major: WORD, arg_minor: WORD, arg_servpack: WORD) callconv(.C) BOOL {
    var major = arg_major;
    _ = &major;
    var minor = arg_minor;
    _ = &minor;
    var servpack = arg_servpack;
    _ = &servpack;
    var vi: OSVERSIONINFOEXW = OSVERSIONINFOEXW{
        .dwOSVersionInfoSize = @as(DWORD, @bitCast(@as(c_ulong, @truncate(@sizeOf(OSVERSIONINFOEXW))))),
        .dwMajorVersion = @as(DWORD, @bitCast(@as(c_ulong, major))),
        .dwMinorVersion = @as(DWORD, @bitCast(@as(c_ulong, minor))),
        .dwBuildNumber = @as(DWORD, @bitCast(@as(c_long, @as(c_int, 0)))),
        .dwPlatformId = @as(DWORD, @bitCast(@as(c_long, @as(c_int, 0)))),
        .szCSDVersion = [1]WCHAR{
            0,
        } ++ [1]WCHAR{@import("std").mem.zeroes(WCHAR)} ** 127,
        .wServicePackMajor = servpack,
        .wServicePackMinor = @import("std").mem.zeroes(WORD),
        .wSuiteMask = @import("std").mem.zeroes(WORD),
        .wProductType = @import("std").mem.zeroes(BYTE),
        .wReserved = @import("std").mem.zeroes(BYTE),
    };
    _ = &vi;
    return VerifyVersionInfoW(&vi, @as(DWORD, @bitCast(@as(c_long, (@as(c_int, 2) | @as(c_int, 1)) | @as(c_int, 32)))), VerSetConditionMask(VerSetConditionMask(VerSetConditionMask(@as(ULONGLONG, @bitCast(@as(c_longlong, @as(c_int, 0)))), @as(DWORD, @bitCast(@as(c_long, @as(c_int, 2)))), @as(BYTE, @bitCast(@as(i8, @truncate(@as(c_int, 3)))))), @as(DWORD, @bitCast(@as(c_long, @as(c_int, 1)))), @as(BYTE, @bitCast(@as(i8, @truncate(@as(c_int, 3)))))), @as(DWORD, @bitCast(@as(c_long, @as(c_int, 32)))), @as(BYTE, @bitCast(@as(i8, @truncate(@as(c_int, 3)))))));
}
pub fn IsWindowsVersionOrLess(arg_major: WORD, arg_minor: WORD, arg_servpack: WORD) callconv(.C) BOOL {
    var major = arg_major;
    _ = &major;
    var minor = arg_minor;
    _ = &minor;
    var servpack = arg_servpack;
    _ = &servpack;
    var vi: OSVERSIONINFOEXW = OSVERSIONINFOEXW{
        .dwOSVersionInfoSize = @as(DWORD, @bitCast(@as(c_ulong, @truncate(@sizeOf(OSVERSIONINFOEXW))))),
        .dwMajorVersion = @as(DWORD, @bitCast(@as(c_ulong, major))),
        .dwMinorVersion = @as(DWORD, @bitCast(@as(c_ulong, minor))),
        .dwBuildNumber = @as(DWORD, @bitCast(@as(c_long, @as(c_int, 0)))),
        .dwPlatformId = @as(DWORD, @bitCast(@as(c_long, @as(c_int, 0)))),
        .szCSDVersion = [1]WCHAR{
            0,
        } ++ [1]WCHAR{@import("std").mem.zeroes(WCHAR)} ** 127,
        .wServicePackMajor = servpack,
        .wServicePackMinor = @import("std").mem.zeroes(WORD),
        .wSuiteMask = @import("std").mem.zeroes(WORD),
        .wProductType = @import("std").mem.zeroes(BYTE),
        .wReserved = @import("std").mem.zeroes(BYTE),
    };
    _ = &vi;
    return VerifyVersionInfoW(&vi, @as(DWORD, @bitCast(@as(c_long, (@as(c_int, 2) | @as(c_int, 1)) | @as(c_int, 32)))), VerSetConditionMask(VerSetConditionMask(VerSetConditionMask(@as(ULONGLONG, @bitCast(@as(c_longlong, @as(c_int, 0)))), @as(DWORD, @bitCast(@as(c_long, @as(c_int, 2)))), @as(BYTE, @bitCast(@as(i8, @truncate(@as(c_int, 5)))))), @as(DWORD, @bitCast(@as(c_long, @as(c_int, 1)))), @as(BYTE, @bitCast(@as(i8, @truncate(@as(c_int, 5)))))), @as(DWORD, @bitCast(@as(c_long, @as(c_int, 32)))), @as(BYTE, @bitCast(@as(i8, @truncate(@as(c_int, 5)))))));
}
pub fn GetWindowsVersionCUSTOM(arg_major: PWORD, arg_minor: PWORD, arg_srvpack: PWORD) callconv(.C) void {
    var major = arg_major;
    _ = &major;
    var minor = arg_minor;
    _ = &minor;
    var srvpack = arg_srvpack;
    _ = &srvpack;
    if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 2560)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 2560)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 0)))))) != 0) {
        major.* = 10;
        minor.* = 0;
        srvpack.* = 0;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1539)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1539)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 0)))))) != 0) {
        major.* = 6;
        minor.* = 3;
        srvpack.* = 0;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1538)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1538)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 0)))))) != 0) {
        major.* = 6;
        minor.* = 2;
        srvpack.* = 0;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1537)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1537)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 1)))))) != 0) {
        major.* = 6;
        minor.* = 1;
        srvpack.* = 1;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1537)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1537)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 0)))))) != 0) {
        major.* = 6;
        minor.* = 1;
        srvpack.* = 0;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1536)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1536)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 2)))))) != 0) {
        major.* = 6;
        minor.* = 0;
        srvpack.* = 2;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1536)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1536)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 1)))))) != 0) {
        major.* = 6;
        minor.* = 0;
        srvpack.* = 1;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1536)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1536)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 0)))))) != 0) {
        major.* = 6;
        minor.* = 0;
        srvpack.* = 0;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1281)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1281)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 3)))))) != 0) {
        major.* = 5;
        minor.* = 1;
        srvpack.* = 2;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1281)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1281)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 1)))))) != 0) {
        major.* = 5;
        minor.* = 1;
        srvpack.* = 1;
    } else if (IsWindowsVersionOrGreater(@as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate((@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1281)))) >> @intCast(8)) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_ushort, @as(BYTE, @bitCast(@as(u8, @truncate(@as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 1281)))) & @as(DWORD_PTR, @bitCast(@as(c_longlong, @as(c_int, 255))))))))))), @as(WORD, @bitCast(@as(c_short, @truncate(@as(c_int, 0)))))) != 0) {
        major.* = 5;
        minor.* = 1;
        srvpack.* = 0;
    } else {
        major.* = 0;
        minor.* = 0;
        srvpack.* = 0;
    }
}
pub extern fn __cpuid(cpuInfo: [*c]c_int, function_id: c_int) void;
pub extern fn __cpuidex(cpuInfo: [*c]c_int, function_id: c_int, subfunction_id: c_int) void;
pub extern fn EnumDisplayDevicesA(lpDevice: LPCSTR, iDevNum: DWORD, lpDisplayDevice: PDISPLAY_DEVICEA, dwFlags: DWORD) BOOL;
pub extern fn EnumDisplayDevicesW(lpDevice: LPCWSTR, iDevNum: DWORD, lpDisplayDevice: PDISPLAY_DEVICEW, dwFlags: DWORD) BOOL;
pub extern fn RegOpenKeyExA(hKey: HKEY, lpSubKey: LPCSTR, ulOptions: DWORD, samDesired: REGSAM, phkResult: PHKEY) LONG;
pub extern fn RegOpenKeyExW(hKey: HKEY, lpSubKey: LPCWSTR, ulOptions: DWORD, samDesired: REGSAM, phkResult: PHKEY) LONG;
pub extern fn RegQueryValueExA(hKey: HKEY, lpValueName: LPCSTR, lpReserved: LPDWORD, lpType: LPDWORD, lpData: LPBYTE, lpcbData: LPDWORD) LONG;
pub extern fn RegQueryValueExW(hKey: HKEY, lpValueName: LPCWSTR, lpReserved: LPDWORD, lpType: LPDWORD, lpData: LPBYTE, lpcbData: LPDWORD) LONG;
pub extern fn RegCreateKeyExA(hKey: HKEY, lpSubKey: LPCSTR, Reserved: DWORD, lpClass: LPSTR, dwOptions: DWORD, samDesired: REGSAM, lpSecurityAttributes: LPSECURITY_ATTRIBUTES, phkResult: PHKEY, lpdwDisposition: LPDWORD) LONG;
pub extern fn RegCreateKeyExW(hKey: HKEY, lpSubKey: LPCWSTR, Reserved: DWORD, lpClass: LPWSTR, dwOptions: DWORD, samDesired: REGSAM, lpSecurityAttributes: LPSECURITY_ATTRIBUTES, phkResult: PHKEY, lpdwDisposition: LPDWORD) LONG;
pub extern fn RegEnumValueA(hKey: HKEY, dwIndex: DWORD, lpValueName: LPSTR, lpcchValueName: LPDWORD, lpReserved: LPDWORD, lpType: LPDWORD, lpData: LPBYTE, lpcbData: LPDWORD) LONG;
pub extern fn RegEnumValueW(hKey: HKEY, dwIndex: DWORD, lpValueName: LPWSTR, lpcchValueName: LPDWORD, lpReserved: LPDWORD, lpType: LPDWORD, lpData: LPBYTE, lpcbData: LPDWORD) LONG;
pub extern fn RegQueryInfoKeyA(hKey: HKEY, lpClass: LPSTR, lpcClass: LPDWORD, lpReserved: LPDWORD, lpcSubKeys: LPDWORD, lpcMaxSubKeyLen: LPDWORD, lpcMaxClassLen: LPDWORD, lpcValues: LPDWORD, lpcMaxValueNameLen: LPDWORD, lpcMaxValueLen: LPDWORD, lpcbSecurityDescriptor: LPDWORD, lpftLastWriteTime: PFILETIME) LONG;
pub extern fn RegQueryInfoKeyW(hKey: HKEY, lpClass: LPWSTR, lpcClass: LPDWORD, lpReserved: LPDWORD, lpcSubKeys: LPDWORD, lpcMaxSubKeyLen: LPDWORD, lpcMaxClassLen: LPDWORD, lpcValues: LPDWORD, lpcMaxValueNameLen: LPDWORD, lpcMaxValueLen: LPDWORD, lpcbSecurityDescriptor: LPDWORD, lpftLastWriteTime: PFILETIME) LONG;
pub extern fn RegEnumKeyExA(hKey: HKEY, dwIndex: DWORD, lpName: LPSTR, lpcName: LPDWORD, lpReserved: LPDWORD, lpClass: LPSTR, lpcClass: LPDWORD, lpftLastWriteTime: PFILETIME) LONG;
pub extern fn RegEnumKeyExW(hKey: HKEY, dwIndex: DWORD, lpName: LPWSTR, lpcName: LPDWORD, lpReserved: LPDWORD, lpClass: LPWSTR, lpcClass: LPDWORD, lpftLastWriteTime: PFILETIME) LONG;
pub extern fn RegCloseKey(hKey: HKEY) LONG;
pub extern fn RegFlushKey(hKey: HKEY) LONG;
pub const PIMAGE_TLS_CALLBACK = ?*const fn (PVOID, DWORD, PVOID) callconv(.C) void;
pub const struct__IMAGE_TLS_DIRECTORY32 = extern struct {
    StartAddressOfRawData: DWORD = @import("std").mem.zeroes(DWORD),
    EndAddressOfRawData: DWORD = @import("std").mem.zeroes(DWORD),
    AddressOfIndex: DWORD = @import("std").mem.zeroes(DWORD),
    AddressOfCallbacks: DWORD = @import("std").mem.zeroes(DWORD),
    SizeOfZeroFill: DWORD = @import("std").mem.zeroes(DWORD),
    Characteristics: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const IMAGE_TLS_DIRECTORY32 = struct__IMAGE_TLS_DIRECTORY32;
pub const PIMAGE_TLS_DIRECTORY32 = [*c]struct__IMAGE_TLS_DIRECTORY32;
pub const struct__IMAGE_TLS_DIRECTORY64 = extern struct {
    StartAddressOfRawData: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    EndAddressOfRawData: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    AddressOfIndex: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    AddressOfCallbacks: ULONGLONG = @import("std").mem.zeroes(ULONGLONG),
    SizeOfZeroFill: DWORD = @import("std").mem.zeroes(DWORD),
    Characteristics: DWORD = @import("std").mem.zeroes(DWORD),
};
pub const IMAGE_TLS_DIRECTORY64 = struct__IMAGE_TLS_DIRECTORY64;
pub const PIMAGE_TLS_DIRECTORY64 = [*c]struct__IMAGE_TLS_DIRECTORY64;
pub const IMAGE_TLS_DIRECTORY = IMAGE_TLS_DIRECTORY64;
pub const PIMAGE_TLS_DIRECTORY = PIMAGE_TLS_DIRECTORY64;
pub const struct__LIST_ENTRY = extern struct {
    Flink: [*c]struct__LIST_ENTRY = @import("std").mem.zeroes([*c]struct__LIST_ENTRY),
    Blink: [*c]struct__LIST_ENTRY = @import("std").mem.zeroes([*c]struct__LIST_ENTRY),
};
pub const LIST_ENTRY = struct__LIST_ENTRY;
pub const PLIST_ENTRY = [*c]struct__LIST_ENTRY;
pub const PRTL_CRITICAL_SECTION_DEBUG = [*c]struct__RTL_CRITICAL_SECTION_DEBUG;
pub const struct__RTL_CRITICAL_SECTION = extern struct {
    DebugInfo: PRTL_CRITICAL_SECTION_DEBUG = @import("std").mem.zeroes(PRTL_CRITICAL_SECTION_DEBUG),
    LockCount: LONG = @import("std").mem.zeroes(LONG),
    RecursionCount: LONG = @import("std").mem.zeroes(LONG),
    OwningThread: HANDLE = @import("std").mem.zeroes(HANDLE),
    LockSemaphore: HANDLE = @import("std").mem.zeroes(HANDLE),
    SpinCount: ULONG_PTR = @import("std").mem.zeroes(ULONG_PTR),
};
pub const struct__RTL_CRITICAL_SECTION_DEBUG = extern struct {
    Type: WORD = @import("std").mem.zeroes(WORD),
    CreatorBackTraceIndex: WORD = @import("std").mem.zeroes(WORD),
    CriticalSection: [*c]struct__RTL_CRITICAL_SECTION = @import("std").mem.zeroes([*c]struct__RTL_CRITICAL_SECTION),
    ProcessLocksList: LIST_ENTRY = @import("std").mem.zeroes(LIST_ENTRY),
    EntryCount: DWORD = @import("std").mem.zeroes(DWORD),
    ContentionCount: DWORD = @import("std").mem.zeroes(DWORD),
    Flags: DWORD = @import("std").mem.zeroes(DWORD),
    CreatorBackTraceIndexHigh: WORD = @import("std").mem.zeroes(WORD),
    SpareWORD: WORD = @import("std").mem.zeroes(WORD),
};
pub const RTL_CRITICAL_SECTION_DEBUG = struct__RTL_CRITICAL_SECTION_DEBUG;
pub const RTL_CRITICAL_SECTION = struct__RTL_CRITICAL_SECTION;
pub const PRTL_CRITICAL_SECTION = [*c]struct__RTL_CRITICAL_SECTION;
pub const CRITICAL_SECTION = RTL_CRITICAL_SECTION;
pub const PCRITICAL_SECTION = PRTL_CRITICAL_SECTION;
pub const LPCRITICAL_SECTION = PRTL_CRITICAL_SECTION;
pub const struct__RTL_CONDITION_VARIABLE = extern struct {
    Ptr: PVOID = @import("std").mem.zeroes(PVOID),
};
pub const RTL_CONDITION_VARIABLE = struct__RTL_CONDITION_VARIABLE;
pub const PRTL_CONDITION_VARIABLE = [*c]struct__RTL_CONDITION_VARIABLE;
pub const CONDITION_VARIABLE = RTL_CONDITION_VARIABLE;
pub const PCONDITION_VARIABLE = PRTL_CONDITION_VARIABLE;
pub const struct__RTL_SRWLOCK = extern struct {
    Ptr: PVOID = @import("std").mem.zeroes(PVOID),
};
pub const RTL_SRWLOCK = struct__RTL_SRWLOCK;
pub const PRTL_SRWLOCK = [*c]struct__RTL_SRWLOCK;
pub const SRWLOCK = RTL_SRWLOCK;
pub const PSRWLOCK = [*c]RTL_SRWLOCK;
pub extern fn WaitForSingleObject(hHandle: HANDLE, dwMilliseconds: DWORD) DWORD;
pub extern fn WaitForMultipleObjects(nCount: DWORD, lpHandles: [*c]const HANDLE, bWaitAll: BOOL, dwMilliseconds: DWORD) DWORD;
pub extern fn WaitForSingleObjectEx(hHandle: HANDLE, dwMilliseconds: DWORD, bAlertable: BOOL) DWORD;
pub extern fn WaitForMultipleObjectsEx(nCount: DWORD, lpHandles: [*c]const HANDLE, bWaitAll: BOOL, dwMilliseconds: DWORD, bAlertable: BOOL) DWORD;
pub const PTHREAD_START_ROUTINE = ?*const fn (LPVOID) callconv(.C) DWORD;
pub const LPTHREAD_START_ROUTINE = PTHREAD_START_ROUTINE;
pub extern fn CreateThread(lpThreadAttributes: LPSECURITY_ATTRIBUTES, dwStackSize: SIZE_T, lpStartAddress: LPTHREAD_START_ROUTINE, lpParameter: LPVOID, dwCreationFlags: DWORD, lpThreadId: LPDWORD) HANDLE;
pub extern fn GetCurrentThread() HANDLE;
pub extern fn GetCurrentThreadId() DWORD;
pub extern fn SetThreadAffinityMask(hThread: HANDLE, dwThreadAffinityMask: DWORD_PTR) DWORD_PTR;
pub extern fn OpenThread(dwDesiredAccess: DWORD, bInheritHandle: BOOL, dwThreadId: DWORD) HANDLE;
pub extern fn SuspendThread(hThread: HANDLE) DWORD;
pub extern fn ResumeThread(hThread: HANDLE) DWORD;
pub extern fn ExitThread(dwExitCode: DWORD) void;
pub extern fn GetProcessAffinityMask(hProcess: HANDLE, lpProcessAffinityMask: PDWORD_PTR, lpSystemAffinityMask: PDWORD_PTR) BOOL;
pub extern fn SetProcessAffinityMask(hProcess: HANDLE, dwProcessAffinityMask: DWORD_PTR) BOOL;
pub extern fn SwitchToThread() BOOL;
pub extern fn InitializeCriticalSection(lpCriticalSection: LPCRITICAL_SECTION) void;
pub extern fn InitializeCriticalSectionAndSpinCount(lpCriticalSection: LPCRITICAL_SECTION, dwSpinCount: DWORD) BOOL;
pub extern fn SetCriticalSectionSpinCount(lpCriticalSection: LPCRITICAL_SECTION, dwSpinCount: DWORD) DWORD;
pub extern fn EnterCriticalSection(lpCriticalSection: LPCRITICAL_SECTION) void;
pub extern fn TryEnterCriticalSection(lpCriticalSection: LPCRITICAL_SECTION) BOOL;
pub extern fn LeaveCriticalSection(lpCriticalSection: LPCRITICAL_SECTION) void;
pub extern fn DeleteCriticalSection(lpCriticalSection: LPCRITICAL_SECTION) void;
pub extern fn InitializeConditionVariable(ConditionVariable: PCONDITION_VARIABLE) void;
pub extern fn SleepConditionVariableCS(ConditionVariable: PCONDITION_VARIABLE, CriticalSection: PCRITICAL_SECTION, dwMilliseconds: DWORD) BOOL;
pub extern fn WakeAllConditionVariable(ConditionVariable: PCONDITION_VARIABLE) void;
pub extern fn WakeConditionVariable(ConditionVariable: PCONDITION_VARIABLE) void;
pub extern fn CreateMutexA(lpMutexAttributes: LPSECURITY_ATTRIBUTES, bInitialOwner: BOOL, lpName: LPCSTR) HANDLE;
pub extern fn CreateMutexW(lpMutexAttributes: LPSECURITY_ATTRIBUTES, bInitialOwner: BOOL, lpName: LPCWSTR) HANDLE;
pub extern fn ReleaseMutex(hMutex: HANDLE) BOOL;
pub extern fn CreateSemaphoreA(lpSemaphoreAttributes: LPSECURITY_ATTRIBUTES, lInitialCount: LONG, lMaximumCount: LONG, lpName: LPCSTR) HANDLE;
pub extern fn CreateSemaphoreW(lpSemaphoreAttributes: LPSECURITY_ATTRIBUTES, lInitialCount: LONG, lMaximumCount: LONG, lpName: LPCWSTR) HANDLE;
pub extern fn ReleaseSemaphore(hSemaphore: HANDLE, lReleaseCount: LONG, lpPreviousCount: LPLONG) BOOL;
pub extern fn OpenSemaphoreA(dwDesiredAccess: DWORD, bInheritHandle: BOOL, lpName: LPCSTR) HANDLE;
pub extern fn OpenSemaphoreW(dwDesiredAccess: DWORD, bInheritHandle: BOOL, lpName: LPCWSTR) HANDLE;
pub extern fn TlsAlloc() DWORD;
pub extern fn TlsSetValue(dwTlsIndex: DWORD, lpTlsValue: LPVOID) BOOL;
pub extern fn TlsGetValue(dwTlsIndex: DWORD) LPVOID;
pub extern fn TlsFree(dwTlsIndex: DWORD) DWORD;
pub const PFLS_CALLBACK_FUNCTION = ?*const fn (PVOID) callconv(.C) void;
pub extern fn FlsAlloc(lpCallback: PFLS_CALLBACK_FUNCTION) DWORD;
pub extern fn FlsFree(dwFlsIndex: DWORD) BOOL;
pub extern fn FlsSetValue(dwFlsIndex: DWORD, lpFlsData: PVOID) BOOL;
pub extern fn FlsGetValue(dwFlsIndex: DWORD) PVOID;
pub extern fn InitializeSRWLock(SRWLock: PSRWLOCK) void;
pub extern fn AcquireSRWLockExclusive(SRWLock: PSRWLOCK) void;
pub extern fn AcquireSRWLockShared(SRWLock: PSRWLOCK) void;
pub extern fn ReleaseSRWLockExclusive(SRWLock: PSRWLOCK) void;
pub extern fn ReleaseSRWLockShared(SRWLock: PSRWLOCK) void;
pub extern fn TryAcquireSRWLockExclusive(SRWLock: PSRWLOCK) BOOL;
pub extern fn TryAcquireSRWLockShared(SRWLock: PSRWLOCK) BOOL;
pub extern fn SleepConditionVariableSRW(ConditionVariable: PCONDITION_VARIABLE, SRWLock: PSRWLOCK, dwMilliseconds: DWORD, Flags: ULONG) BOOL;
pub extern fn WaitOnAddress(Address: ?*volatile anyopaque, CompareAddress: PVOID, AddressSize: SIZE_T, dwMilliseconds: DWORD) BOOL;
pub extern fn WakeByAddressSingle(Address: PVOID) void;
pub extern fn WakeByAddressAll(Address: PVOID) void;
pub extern fn CreateEvent(lpEventAttributes: LPSECURITY_ATTRIBUTES, bManualReset: BOOL, bInitialState: BOOL, lpName: LPCTSTR) HANDLE;
pub extern fn OpenEvent(dwDesiredAccess: DWORD, bInheritHandle: BOOL, lpName: LPCTSTR) HANDLE;
pub extern fn SetEvent(hEvent: HANDLE) BOOL;
pub extern fn ResetEvent(hEvent: HANDLE) BOOL;
pub const struct__RECT = extern struct {
    left: LONG = @import("std").mem.zeroes(LONG),
    top: LONG = @import("std").mem.zeroes(LONG),
    right: LONG = @import("std").mem.zeroes(LONG),
    bottom: LONG = @import("std").mem.zeroes(LONG),
};
pub const RECT = struct__RECT;
pub const PRECT = [*c]struct__RECT;
pub const LPRECT = [*c]struct__RECT;
pub const WNDPROC = ?*const fn (HWND, UINT, WPARAM, LPARAM) callconv(.C) LRESULT;
pub const struct_tagWNDCLASS = extern struct {
    style: UINT = @import("std").mem.zeroes(UINT),
    lpfnWndProc: WNDPROC = @import("std").mem.zeroes(WNDPROC),
    cbClsExtra: c_int = @import("std").mem.zeroes(c_int),
    cbWndExtra: c_int = @import("std").mem.zeroes(c_int),
    hInstance: HINSTANCE = @import("std").mem.zeroes(HINSTANCE),
    hIcon: HICON = @import("std").mem.zeroes(HICON),
    hCursor: HCURSOR = @import("std").mem.zeroes(HCURSOR),
    hbrBackground: HBRUSH = @import("std").mem.zeroes(HBRUSH),
    lpszMenuName: LPCTSTR = @import("std").mem.zeroes(LPCTSTR),
    lpszClassName: LPCTSTR = @import("std").mem.zeroes(LPCTSTR),
};
pub const WNDCLASS = struct_tagWNDCLASS;
pub const WNDCLASSA = WNDCLASS;
pub const PWNDCLASS = [*c]struct_tagWNDCLASS;
pub const PWNDCLASSA = [*c]struct_tagWNDCLASS;
pub const struct_tagPOINT = extern struct {
    x: LONG = @import("std").mem.zeroes(LONG),
    y: LONG = @import("std").mem.zeroes(LONG),
};
pub const POINT = struct_tagPOINT;
pub const PPOINT = [*c]struct_tagPOINT;
pub const struct_tagMSG = extern struct {
    hwnd: HWND = @import("std").mem.zeroes(HWND),
    message: UINT = @import("std").mem.zeroes(UINT),
    wParam: WPARAM = @import("std").mem.zeroes(WPARAM),
    lParam: LPARAM = @import("std").mem.zeroes(LPARAM),
    time: DWORD = @import("std").mem.zeroes(DWORD),
    pt: POINT = @import("std").mem.zeroes(POINT),
};
pub const MSG = struct_tagMSG;
pub const PMSG = [*c]struct_tagMSG;
pub const LPMSG = [*c]struct_tagMSG;
pub extern fn MessageBoxA(hWND: HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT) c_int;
pub extern fn MessageBoxW(hWND: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT) c_int;
pub extern fn RegisterClassA(lpWndClass: ?*WNDCLASS) ATOM;
pub extern fn RegisterClassW(lpWndClass: ?*WNDCLASS) ATOM;
pub extern fn UnregisterClassA(lpClassName: LPCSTR, hInstance: HINSTANCE) BOOL;
pub extern fn UnregisterClassW(lpClassName: LPCWSTR, hInstance: HINSTANCE) BOOL;
pub extern fn CreateWindowExA(dwExStyle: DWORD, lpClassName: LPCSTR, lpWindowName: LPCSTR, dwStyle: DWORD, x: c_int, y: c_int, nWidth: c_int, nHeight: c_int, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID) HWND;
pub extern fn CreateWindowExW(dwExStyle: DWORD, lpClassName: LPCWSTR, lpWindowName: LPCWSTR, dwStyle: DWORD, x: c_int, y: c_int, nWidth: c_int, nHeight: c_int, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID) HWND;
pub extern fn ShowWindow(hWnd: HWND, nCmdShow: c_int) BOOL;
pub extern fn UpdateWindow(hWnd: HWND) BOOL;
pub extern fn DefWindowProcA(hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) LRESULT;
pub extern fn DefWindowProcW(hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) LRESULT;
pub extern fn DestroyWindow(hWnd: HWND) BOOL;
pub extern fn AdjustWindowRectEx(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) BOOL;
pub extern fn GetClientRect(hWnd: HWND, lpRect: LPRECT) BOOL;
pub extern fn GetSystemMetrics(nIndex: c_int) c_int;
pub extern fn PeekMessageA(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) BOOL;
pub extern fn PeekMessageW(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) BOOL;
pub extern fn TranslateMessage(lpMsg: [*c]const MSG) BOOL;
pub extern fn DispatchMessageA(lpMsg: [*c]const MSG) LRESULT;
pub extern fn DispatchMessageW(lpMsg: [*c]const MSG) LRESULT;
pub extern fn PostQuitMessage(nExitCode: c_int) void;
pub extern fn CreateEventA(lpEventAttributes: LPSECURITY_ATTRIBUTES, bManualReset: BOOL, bInitialState: BOOL, lpName: LPCSTR) HANDLE;
pub extern fn CreateEventW(lpEventAttributes: LPSECURITY_ATTRIBUTES, bManualReset: BOOL, bInitialState: BOOL, lpName: LPCWSTR) HANDLE;
pub extern fn OpenEventA(dwDesiredAccess: DWORD, bInheritHandle: BOOL, lpName: LPCSTR) HANDLE;
pub extern fn OpenEventW(dwDesiredAccess: DWORD, bInheritHandle: BOOL, lpName: LPCWSTR) HANDLE;
pub extern fn GetKeyState(nVirtKey: c_int) SHORT;
pub const PFIBER_START_ROUTINE = ?*const fn (LPVOID) callconv(.C) void;
pub const LPFIBER_START_ROUTINE = PFIBER_START_ROUTINE;
pub extern fn IsThreadAFiber() BOOL;
pub extern fn SwitchToFiber(lpFiber: LPVOID) void;
pub extern fn DeleteFiber(lpFiber: LPVOID) void;
pub extern fn ConvertFiberToThread() BOOL;
pub extern fn CreateFiber(dwStackSize: SIZE_T, lpStartAddress: LPFIBER_START_ROUTINE, lpParameter: LPVOID) LPVOID;
pub extern fn CreateFiberEx(dwStackCommitSize: SIZE_T, dwStackReserveSize: SIZE_T, dwFlags: DWORD, lpStartAddress: LPFIBER_START_ROUTINE, lpParameter: LPVOID) LPVOID;
pub extern fn ConvertThreadToFiber(lpParameter: LPVOID) LPVOID;
pub extern fn ConvertThreadToFiberEx(lpParameter: LPVOID, dwFlags: DWORD) LPVOID;
pub const _INC_WINDOWS = "";
pub const WINDOWS_H = "";
pub const __int64 = c_longlong;
pub const WINDOWS_BASE_H = "";
pub const _WIN32_WINNT = @as(c_int, 0x0600);
pub const TRUE = @as(c_int, 1);
pub const FALSE = @as(c_int, 0);
pub inline fn TEXT(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub const PATH_MAX = @as(c_int, 260);
pub const MAX_PATH = @as(c_int, 260);
pub inline fn MAKEWORD(a: anytype, b: anytype) WORD {
    return @as(WORD, @intCast((a & 0xff) | ((b & 0xff) << 8)));
}
pub inline fn MAKELONG(a: anytype, b: anytype) LONG {
    return @as(LONG, @intCast((a & 0xffff) | ((b & 0xffff) << 16)));
}
pub inline fn HIWORD(l: anytype) WORD {
    return @as(WORD, @intCast((l >> 16) & 0xffff));
}
pub inline fn LOWORD(l: anytype) WORD {
    return @as(WORD, @intCast(l & 0xffff));
}
pub inline fn HIBYTE(l: anytype) BYTE {
    return @as(BYTE, @intCast((l >> 8) & 0xff));
}
pub inline fn LOBYTE(l: anytype) BYTE {
    return @as(BYTE, @intCast(l & 0xff));
}

pub inline fn GET_WHEEL_DELTA_WPARAM(l: anytype) SHORT {
    return @intCast(HIWORD(l));
}
pub inline fn GET_X_LPARAM(l: anytype) INT {
    return @intCast(LOWORD(l));
}
pub inline fn GET_Y_LPARAM(l: anytype) INT {
    return @intCast(HIWORD(l));
}

pub inline fn HRESULT_IS_WIN32(x: anytype) @TypeOf(((x >> @as(c_int, 16)) & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex)) == @as(c_int, 0x8)) {
    _ = &x;
    return ((x >> @as(c_int, 16)) & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex)) == @as(c_int, 0x8);
}
pub inline fn HRESULT_IS_FAILURE(x: anytype) @TypeOf(((x >> @as(c_int, 31)) & @as(c_int, 0x1)) == @as(c_int, 0x1)) {
    _ = &x;
    return ((x >> @as(c_int, 31)) & @as(c_int, 0x1)) == @as(c_int, 0x1);
}
pub inline fn HRESULT_FACILITY(x: anytype) @TypeOf((x >> @as(c_int, 16)) & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex)) {
    _ = &x;
    return (x >> @as(c_int, 16)) & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex);
}
pub inline fn HRESULT_CODE(x: anytype) @TypeOf(x & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex)) {
    _ = &x;
    return x & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex);
}
pub inline fn HRESULT_FROM_WIN32(x: anytype) @TypeOf(@import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80070000, .hex) | x) {
    _ = &x;
    return @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80070000, .hex) | x;
}

pub const MINCHAR = @as(c_int, 0x80);
pub const MAXCHAR = @as(c_int, 0x7f);
pub const MINSHORT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000, .hex);
pub const MAXSHORT = @as(c_int, 0x7fff);
pub const MINLONG = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hex);
pub const MAXLONG = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hex);
pub const MAXBYTE = @as(c_int, 0xff);
pub const MAXWORD = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffff, .hex);
pub const MAXDWORD = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffffffff, .hex);
pub const ERROR_SUCCESS = @as(c_long, 0);
pub const ERROR_FILE_NOT_FOUND = @as(c_long, 2);
pub const ERROR_PATH_NOT_FOUND = @as(c_long, 3);
pub const ERROR_TOO_MANY_OPEN_FILES = @as(c_long, 4);
pub const ERROR_ACCESS_DENIED = @as(c_long, 5);
pub const ERROR_NO_MORE_FILES = @as(c_long, 18);
pub const ERROR_SHARING_VIOLATION = @as(c_long, 32);
pub const ERROR_FILE_EXISTS = @as(c_long, 80);
pub const ERROR_INSUFFICIENT_BUFFER = @as(c_long, 122);
pub const ERROR_ALREADY_EXISTS = @as(c_long, 183);
pub const ERROR_MORE_DATA = @as(c_long, 234);
pub const DLL_PROCESS_ATTACH = @as(c_int, 1);
pub const DLL_PROCESS_DETACH = @as(c_int, 0);
pub const DLL_THREAD_ATTACH = @as(c_int, 2);
pub const DLL_THREAD_DETACH = @as(c_int, 3);
pub const WINDOWS_ATOMIC_H = "";
pub const WINDOWS_INTRIN_H = "";
pub const InterlockedExchange8 = _InterlockedExchange8;
pub const InterlockedExchangeAdd8 = _InterlockedExchangeAdd8;
pub const InterlockedExchangeAnd8 = _InterlockedExchangeAnd8;
pub const InterlockedExchangeOr8 = _InterlockedExchangeOr8;
pub const InterlockedExchangeXor8 = _InterlockedExchangeXor8;
pub const InterlockedDecrement8 = _InterlockedDecrement8;
pub const InterlockedIncrement8 = _InterlockedIncrement8;
pub const InterlockedCompareExchange8 = _InterlockedCompareExchange8;
pub const InterlockedExchange16 = _InterlockedExchange16;
pub const InterlockedExchangeAdd16 = _InterlockedExchangeAdd16;
pub const InterlockedExchangeAnd16 = _InterlockedExchangeAnd16;
pub const InterlockedExchangeOr16 = _InterlockedExchangeOr16;
pub const InterlockedExchangeXor16 = _InterlockedExchangeXor16;
pub const InterlockedDecrement16 = _InterlockedDecrement16;
pub const InterlockedIncrement16 = _InterlockedIncrement16;
pub const InterlockedCompareExchange16 = _InterlockedCompareExchange16;
pub const InterlockedExchange = _InterlockedExchange;
pub const InterlockedExchangeAdd = _InterlockedExchangeAdd;
pub const InterlockedExchangeAnd = _InterlockedExchangeAnd;
pub const InterlockedExchangeOr = _InterlockedExchangeOr;
pub const InterlockedExchangeXor = _InterlockedExchangeXor;
pub const InterlockedDecrement = _InterlockedDecrement;
pub const InterlockedIncrement = _InterlockedIncrement;
pub const InterlockedCompareExchange = _InterlockedCompareExchange;
pub const WINDOWS_DBGHELP_H = "";
pub const EXCEPTION_MAXIMUM_PARAMETERS = @as(c_int, 15);
pub const EXCEPTION_EXECUTE_HANDLER = @as(c_int, 0x1);
pub const EXCEPTION_CONTINUE_EXECUTION = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFFFFFF, .hex);
pub const EXCEPTION_CONTINUE_SEARCH = @as(c_int, 0x0);
pub const EXCEPTION_ACCESS_VIOLATION = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000005, .hex));
pub const EXCEPTION_DATATYPE_MISALIGNMENT = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0x80000002, .hex));
pub const EXCEPTION_BREAKPOINT = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0x80000003, .hex));
pub const EXCEPTION_SINGLE_STEP = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0x80000004, .hex));
pub const EXCEPTION_ARRAY_BOUNDS_EXCEEDED = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC000008C, .hex));
pub const EXCEPTION_FLT_DENORMAL_OPERAND = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC000008D, .hex));
pub const EXCEPTION_FLT_DIVIDE_BY_ZERO = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC000008E, .hex));
pub const EXCEPTION_FLT_INEXACT_RESULT = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC000008F, .hex));
pub const EXCEPTION_FLT_INVALID_OPERATION = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000090, .hex));
pub const EXCEPTION_FLT_OVERFLOW = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000091, .hex));
pub const EXCEPTION_FLT_STACK_CHECK = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000092, .hex));
pub const EXCEPTION_FLT_UNDERFLOW = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000093, .hex));
pub const EXCEPTION_INT_DIVIDE_BY_ZERO = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000094, .hex));
pub const EXCEPTION_INT_OVERFLOW = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000095, .hex));
pub const EXCEPTION_PRIV_INSTRUCTION = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000096, .hex));
pub const EXCEPTION_IN_PAGE_ERROR = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000006, .hex));
pub const EXCEPTION_STACK_OVERFLOW = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC00000FD, .hex));
pub const EXCEPTION_ILLEGAL_INSTRUCTION = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC000001D, .hex));
pub const EXCEPTION_NONCONTINUABLE_EXCEPTION = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000025, .hex));
pub const EXCEPTION_INVALID_DISPOSITION = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000026, .hex));
pub const EXCEPTION_GUARD_PAGE = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0x80000001, .hex));
pub const EXCEPTION_INVALID_HANDLE = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000008, .hex));
pub const EXCEPTION_POSSIBLE_DEADLOCK = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC0000194, .hex));
pub const CONTROL_C_EXIT = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xC000013A, .hex));
pub const EXCEPTION_ASSERTION = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_long, 0xEF000001, .hex));
pub const TH32CS_SNAPTHREAD = @as(c_int, 0x00000004);
pub const IMAGE_FILE_MACHINE_I386 = @as(c_int, 0x014c);
pub const IMAGE_FILE_MACHINE_AMD64 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8664, .hex);
pub const CONTEXT_AMD64 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x100000, .hex);
pub const CONTEXT_CONTROL = CONTEXT_AMD64 | @as(c_long, 0x1);
pub const CONTEXT_INTEGER = CONTEXT_AMD64 | @as(c_long, 0x2);
pub const CONTEXT_SEGMENTS = CONTEXT_AMD64 | @as(c_long, 0x4);
pub const CONTEXT_FLOATING_POINT = CONTEXT_AMD64 | @as(c_long, 0x8);
pub const CONTEXT_DEBUG_REGISTERS = CONTEXT_AMD64 | @as(c_long, 0x10);
pub const CONTEXT_FULL = (CONTEXT_CONTROL | CONTEXT_INTEGER) | CONTEXT_FLOATING_POINT;
pub const CONTEXT_ALL = (((CONTEXT_CONTROL | CONTEXT_INTEGER) | CONTEXT_SEGMENTS) | CONTEXT_FLOATING_POINT) | CONTEXT_DEBUG_REGISTERS;
pub const SYMOPT_CASE_INSENSITIVE = @as(c_int, 0x00000001);
pub const SYMOPT_UNDNAME = @as(c_int, 0x00000002);
pub const SYMOPT_DEFERRED_LOADS = @as(c_int, 0x00000004);
pub const SYMOPT_NO_CPP = @as(c_int, 0x00000008);
pub const SYMOPT_LOAD_LINES = @as(c_int, 0x00000010);
pub const SYMOPT_OMAP_FIND_NEAREST = @as(c_int, 0x00000020);
pub const SYMOPT_LOAD_ANYTHING = @as(c_int, 0x00000040);
pub const SYMOPT_IGNORE_CVREC = @as(c_int, 0x00000080);
pub const SYMOPT_NO_UNQUALIFIED_LOADS = @as(c_int, 0x00000100);
pub const SYMOPT_FAIL_CRITICAL_ERRORS = @as(c_int, 0x00000200);
pub const SYMOPT_EXACT_SYMBOLS = @as(c_int, 0x00000400);
pub const SYMOPT_ALLOW_ABSOLUTE_SYMBOLS = @as(c_int, 0x00000800);
pub const SYMOPT_IGNORE_NT_SYMPATH = @as(c_int, 0x00001000);
pub const SYMOPT_INCLUDE_32BIT_MODULES = @as(c_int, 0x00002000);
pub const SYMOPT_PUBLICS_ONLY = @as(c_int, 0x00004000);
pub const SYMOPT_NO_PUBLICS = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00008000, .hex);
pub const SYMOPT_AUTO_PUBLICS = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00010000, .hex);
pub const SYMOPT_NO_IMAGE_SEARCH = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00020000, .hex);
pub const SYMOPT_SECURE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00040000, .hex);
pub const SYMOPT_NO_PROMPTS = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00080000, .hex);
pub const SYMOPT_OVERWRITE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00100000, .hex);
pub const SYMOPT_IGNORE_IMAGEDIR = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00200000, .hex);
pub const SYMOPT_FLAT_DIRECTORY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00400000, .hex);
pub const SYMOPT_FAVOR_COMPRESSED = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00800000, .hex);
pub const SYMOPT_ALLOW_ZERO_ADDRESS = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x01000000, .hex);
pub const SYMOPT_DISABLE_SYMSRV_AUTODETECT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x02000000, .hex);
pub const SYMOPT_DEBUG = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hex);
pub const CaptureStackBackTrace = RtlCaptureStackBackTrace;
pub const WINDOWS_DDS_H = "";
pub const DXGI_FORMAT_DEFINED = @as(c_int, 1);
pub const FOURCC_DDS = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x20534444, .hex);
pub const DDPF_FOURCC = @as(c_int, 0x00000004);
pub const FMT_DX10 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x30315844, .hex);
pub const FMT_DXT1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x31545844, .hex);
pub const FMT_DXT3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x33545844, .hex);
pub const FMT_DXT5 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x35545844, .hex);
pub const DDSD_CAPS = @as(c_int, 0x00000001);
pub const DDSD_HEIGHT = @as(c_int, 0x00000002);
pub const DDSD_WIDTH = @as(c_int, 0x00000004);
pub const DDSD_PITCH = @as(c_int, 0x00000008);
pub const DDSD_PIXELFORMAT = @as(c_int, 0x00001000);
pub const DDSD_MIPMAPCOUNT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00020000, .hex);
pub const DDSD_LINEARSIZE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00080000, .hex);
pub const DDSD_DEPTH = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00800000, .hex);
pub const DDSCAPS_COMPLEX = @as(c_int, 0x00000008);
pub const DDSCAPS_MIPMAP = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x04000000, .hex);
pub const DDSCAPS_TEXTURE = @as(c_int, 0x00001000);
pub const BLOCKSIZE_DXT1 = @as(c_int, 0x8);
pub const BLOCKSIZE_DXT3 = @as(c_int, 0x10);
pub const BLOCKSIZE_DXT5 = @as(c_int, 0x10);
pub const WINDOWS_FILE_H = "";
pub const FILE_SHARE_DELETE = @as(c_int, 0x00000004);
pub const FILE_SHARE_READ = @as(c_int, 0x00000001);
pub const FILE_SHARE_WRITE = @as(c_int, 0x00000002);
pub const GENERIC_READ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 0x80000000, .hex);
pub const GENERIC_WRITE = @as(c_long, 0x40000000);
pub const GENERIC_EXECUTE = @as(c_long, 0x20000000);
pub const GENERIC_ALL = @as(c_long, 0x10000000);
pub const DELETE = @as(c_long, 0x00010000);
pub const READ_CONTROL = @as(c_long, 0x00020000);
pub const WRITE_DAC = @as(c_long, 0x00040000);
pub const WRITE_OWNER = @as(c_long, 0x00080000);
pub const SYNCHRONIZE = @as(c_long, 0x00100000);
pub const STANDARD_RIGHTS_REQUIRED = @as(c_long, 0x000F0000);
pub const STANDARD_RIGHTS_READ = READ_CONTROL;
pub const STANDARD_RIGHTS_WRITE = READ_CONTROL;
pub const STANDARD_RIGHTS_EXECUTE = READ_CONTROL;
pub const STANDARD_RIGHTS_ALL = @as(c_long, 0x001F0000);
pub const SPECIFIC_RIGHTS_ALL = @as(c_long, 0x0000FFFF);
pub const FILE_READ_DATA = @as(c_int, 0x0001);
pub const FILE_LIST_DIRECTORY = @as(c_int, 0x0001);
pub const FILE_WRITE_DATA = @as(c_int, 0x0002);
pub const FILE_ADD_FILE = @as(c_int, 0x0002);
pub const FILE_APPEND_DATA = @as(c_int, 0x0004);
pub const FILE_ADD_SUBDIRECTORY = @as(c_int, 0x0004);
pub const FILE_CREATE_PIPE_INSTANCE = @as(c_int, 0x0004);
pub const FILE_READ_EA = @as(c_int, 0x0008);
pub const FILE_WRITE_EA = @as(c_int, 0x0010);
pub const FILE_EXECUTE = @as(c_int, 0x0020);
pub const FILE_TRAVERSE = @as(c_int, 0x0020);
pub const FILE_DELETE_CHILD = @as(c_int, 0x0040);
pub const FILE_READ_ATTRIBUTES = @as(c_int, 0x0080);
pub const FILE_WRITE_ATTRIBUTES = @as(c_int, 0x0100);
pub const FILE_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE) | @as(c_int, 0x1FF);
pub const FILE_GENERIC_READ = (((STANDARD_RIGHTS_READ | FILE_READ_DATA) | FILE_READ_ATTRIBUTES) | FILE_READ_EA) | SYNCHRONIZE;
pub const FILE_GENERIC_WRITE = ((((STANDARD_RIGHTS_WRITE | FILE_WRITE_DATA) | FILE_WRITE_ATTRIBUTES) | FILE_WRITE_EA) | FILE_APPEND_DATA) | SYNCHRONIZE;
pub const FILE_GENERIC_EXECUTE = ((STANDARD_RIGHTS_EXECUTE | FILE_READ_ATTRIBUTES) | FILE_EXECUTE) | SYNCHRONIZE;
pub const CREATE_ALWAYS = @as(c_int, 2);
pub const CREATE_NEW = @as(c_int, 1);
pub const OPEN_ALWAYS = @as(c_int, 4);
pub const OPEN_EXISTING = @as(c_int, 3);
pub const TRUNCATE_EXISTING = @as(c_int, 5);
pub const INVALID_FILE_ATTRIBUTES = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffffffff, .hex);
pub const FILE_ATTRIBUTE_HIDDEN = @as(c_int, 0x2);
pub const FILE_ATTRIBUTE_NORMAL = @as(c_int, 0x80);
pub const FILE_ATTRIBUTE_DIRECTORY = @as(c_int, 0x10);
pub const FILE_ATTRIBUTE_TEMPORARY = @as(c_int, 0x100);
pub const FILE_ATTRIBUTE_REPARSE_POINT = @as(c_int, 0x400);
pub const FILE_BEGIN = @as(c_int, 0);
pub const FILE_CURRENT = @as(c_int, 1);
pub const FILE_END = @as(c_int, 2);
pub const SECTION_QUERY = @as(c_int, 0x0001);
pub const SECTION_MAP_WRITE = @as(c_int, 0x0002);
pub const SECTION_MAP_READ = @as(c_int, 0x0004);
pub const SECTION_MAP_EXECUTE = @as(c_int, 0x0008);
pub const SECTION_EXTEND_SIZE = @as(c_int, 0x0010);
pub const SECTION_MAP_EXECUTE_EXPLICIT = @as(c_int, 0x0020);
pub const SECTION_ALL_ACCESS = ((((STANDARD_RIGHTS_REQUIRED | SECTION_QUERY) | SECTION_MAP_WRITE) | SECTION_MAP_READ) | SECTION_MAP_EXECUTE) | SECTION_EXTEND_SIZE;
pub const FILE_MAP_COPY = SECTION_QUERY;
pub const FILE_MAP_WRITE = SECTION_MAP_WRITE;
pub const FILE_MAP_READ = SECTION_MAP_READ;
pub const FILE_MAP_ALL_ACCESS = SECTION_ALL_ACCESS;
pub const FILE_MAP_EXECUTE = SECTION_MAP_EXECUTE_EXPLICIT;
pub const PAGE_EXECUTE_READ = @as(c_int, 0x20);
pub const PAGE_EXECUTE_READWRITE = @as(c_int, 0x40);
pub const PAGE_EXECUTE_WRITECOPY = @as(c_int, 0x80);
pub const PAGE_READONLY = @as(c_int, 0x02);
pub const PAGE_READWRITE = @as(c_int, 0x04);
pub const PAGE_WRITECOPY = @as(c_int, 0x08);
pub const FILE_NOTIFY_CHANGE_FILE_NAME = @as(c_int, 0x00000001);
pub const FILE_NOTIFY_CHANGE_DIR_NAME = @as(c_int, 0x00000002);
pub const FILE_NOTIFY_CHANGE_ATTRIBUTES = @as(c_int, 0x00000004);
pub const FILE_NOTIFY_CHANGE_SIZE = @as(c_int, 0x00000008);
pub const FILE_NOTIFY_CHANGE_LAST_WRITE = @as(c_int, 0x00000010);
pub const FILE_NOTIFY_CHANGE_SECURITY = @as(c_int, 0x00000100);
pub const FILE_TYPE_UNKNOWN = @as(c_int, 0x0000);
pub const FILE_TYPE_DISK = @as(c_int, 0x0001);
pub const FILE_TYPE_CHAR = @as(c_int, 0x0002);
pub const FILE_TYPE_PIPE = @as(c_int, 0x0003);
pub const FILE_TYPE_REMOTE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000, .hex);
pub const MOVEFILE_COPY_ALLOWED = @as(c_int, 0x2);
pub const MOVEFILE_REPLACE_EXISTING = @as(c_int, 0x1);
pub const WINDOWS_GDI_H = "";
pub const BLACK_BRUSH = @as(c_int, 4);
pub inline fn MAKEINTRESOURCE(res: anytype) ULONG_PTR {
    _ = &res;
    return @import("std").zig.c_translation.cast(ULONG_PTR, @import("std").zig.c_translation.cast(USHORT, res));
}
pub const IDI_APPLICATION = MAKEINTRESOURCE(@as(c_int, 32512));
pub const IDC_ARROW = MAKEINTRESOURCE(@as(c_int, 32512));
pub const WINDOWS_IO_H = "";
pub const STD_INPUT_HANDLE = @import("std").zig.c_translation.cast(DWORD, -@as(c_int, 10));
pub const STD_OUTPUT_HANDLE = @import("std").zig.c_translation.cast(DWORD, -@as(c_int, 11));
pub const STD_ERROR_HANDLE = @import("std").zig.c_translation.cast(DWORD, -@as(c_int, 12));
pub const INVALID_HANDLE_VALUE = @import("std").zig.c_translation.cast(HANDLE, @import("std").zig.c_translation.cast(LONG_PTR, -@as(c_int, 1)));
pub const ATTACH_PARENT_PROCESS = @import("std").zig.c_translation.cast(DWORD, -@as(c_int, 1));
pub const HANDLE_FLAG_INHERIT = @as(c_int, 0x00000001);
pub const HANDLE_FLAG_PROTECT_FROM_CLOSE = @as(c_int, 0x00000002);
pub const FOREGROUND_BLUE = @as(c_int, 0x0001);
pub const FOREGROUND_GREEN = @as(c_int, 0x0002);
pub const FOREGROUND_RED = @as(c_int, 0x0004);
pub const FOREGROUND_INTENSITY = @as(c_int, 0x0008);
pub const BACKGROUND_BLUE = @as(c_int, 0x0010);
pub const BACKGROUND_GREEN = @as(c_int, 0x0020);
pub const BACKGROUND_RED = @as(c_int, 0x0040);
pub const BACKGROUND_INTENSITY = @as(c_int, 0x0080);
pub const CTRL_C_EVENT = @as(c_int, 0x0);
pub const CTRL_BREAK_EVENT = @as(c_int, 0x1);
pub const CTRL_CLOSE_EVENT = @as(c_int, 0x2);
pub const CTRL_LOGOFF_EVENT = @as(c_int, 0x5);
pub const CTRL_SHUTDOWN_EVENT = @as(c_int, 0x6);
pub const HEAP_NO_SERIALIZE = @as(c_int, 0x00000001);
pub const HEAP_ZERO_MEMORY = @as(c_int, 0x00000008);
pub const HEAP_REALLOC_IN_PLACE_ONLY = @as(c_int, 0x00000010);
pub const MEM_COMMIT = @as(c_int, 0x00001000);
pub const MEM_RESERVE = @as(c_int, 0x00002000);
pub const MEM_RESET = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00080000, .hex);
pub const MEM_RESET_UNDO = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x01000000, .hex);
pub const MEM_LARGE_PAGES = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x20000000, .hex);
pub const MEM_PHYSICAL = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00400000, .hex);
pub const MEM_TOP_DOWN = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00100000, .hex);
pub const MEM_WRITE_WATCH = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00200000, .hex);
pub const PAGE_EXECUTE = @as(c_int, 0x10);
pub const PAGE_NOACCESS = @as(c_int, 0x01);
pub const PAGE_TARGETS_INVALID = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x40000000, .hex);
pub const PAGE_TARGETS_NO_UPDATE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x40000000, .hex);
pub const PAGE_GUARD = @as(c_int, 0x100);
pub const PAGE_NOCACHE = @as(c_int, 0x200);
pub const PAGE_WRITECOMBINE = @as(c_int, 0x400);
pub const MEM_DECOMMIT = @as(c_int, 0x4000);
pub const MEM_RELEASE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000, .hex);
pub const MEM_FREE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x10000, .hex);
pub const MEM_IMAGE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x1000000, .hex);
pub const MEM_MAPPED = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x40000, .hex);
pub const MEM_PRIVATE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x20000, .hex);
pub const GetCommandLine = GetCommandLineA;
pub const TIMERR_BASE = @as(c_int, 96);
pub const TIMERR_NOERROR = @as(c_int, 0);
pub const TIMERR_NOCANDO = TIMERR_BASE + @as(c_int, 1);
pub const TIMERR_STRUCT = TIMERR_BASE + @as(c_int, 33);
pub const CP_INSTALLED = @as(c_int, 0x00000001);
pub const CP_SUPPORTED = @as(c_int, 0x00000002);
pub const CP_ACP = @as(c_int, 0);
pub const CP_OEMCP = @as(c_int, 1);
pub const CP_MACCP = @as(c_int, 2);
pub const CP_THREAD_ACP = @as(c_int, 3);
pub const CP_SYMBOL = @as(c_int, 42);
pub const CP_UTF7 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65000, .decimal);
pub const CP_UTF8 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65001, .decimal);
pub const FORMAT_MESSAGE_ALLOCATE_BUFFER = @as(c_int, 0x00000100);
pub const FORMAT_MESSAGE_ARGUMENT_ARRAY = @as(c_int, 0x00002000);
pub const FORMAT_MESSAGE_FROM_SYSTEM = @as(c_int, 0x00001000);
pub const FORMAT_MESSAGE_IGNORE_INSERTS = @as(c_int, 0x00000200);
pub const FORMAT_MESSAGE_FROM_HMODULE = @as(c_int, 0x00000800);
pub const FORMAT_MESSAGE_FROM_STRING = @as(c_int, 0x00000400);
pub inline fn MAKELANGID(p: anytype, s: anytype) @TypeOf((@import("std").zig.c_translation.cast(WORD, s) << @as(c_int, 10)) | @import("std").zig.c_translation.cast(WORD, p)) {
    _ = &p;
    _ = &s;
    return (@import("std").zig.c_translation.cast(WORD, s) << @as(c_int, 10)) | @import("std").zig.c_translation.cast(WORD, p);
}
pub inline fn PRIMARYLANGID(lgid: anytype) @TypeOf(@import("std").zig.c_translation.cast(WORD, lgid) & @as(c_int, 0x3ff)) {
    _ = &lgid;
    return @import("std").zig.c_translation.cast(WORD, lgid) & @as(c_int, 0x3ff);
}
pub inline fn SUBLANGID(lgid: anytype) @TypeOf(@import("std").zig.c_translation.cast(WORD, lgid) >> @as(c_int, 10)) {
    _ = &lgid;
    return @import("std").zig.c_translation.cast(WORD, lgid) >> @as(c_int, 10);
}
pub const LANG_NEUTRAL = @as(c_int, 0x00);
pub const LANG_INVARIANT = @as(c_int, 0x7f);
pub const LANG_ENGLISH = @as(c_int, 0x09);
pub const LANG_GERMAN = @as(c_int, 0x07);
pub const SUBLANG_NEUTRAL = @as(c_int, 0x00);
pub const SUBLANG_DEFAULT = @as(c_int, 0x01);
pub const SUBLANG_SYS_DEFAULT = @as(c_int, 0x02);
pub const SUBLANG_CUSTOM_DEFAULT = @as(c_int, 0x03);
pub const SUBLANG_CUSTOM_UNSPECIFIED = @as(c_int, 0x04);
pub const SUBLANG_UI_CUSTOM_DEFAULT = @as(c_int, 0x05);
pub const SUBLANG_ENGLISH_US = @as(c_int, 0x01);
pub const SUBLANG_ENGLISH_UK = @as(c_int, 0x02);
pub const SUBLANG_GERMAN = @as(c_int, 0x01);
pub const WINDOWS_PROCESS_H = "";
pub const INFINITE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffffffff, .hex);
pub const PROCESS_DUP_HANDLE = @as(c_int, 0x0040);
pub const PROCESS_QUERY_INFORMATION = @as(c_int, 0x0400);
pub const PROCESS_SUSPEND_RESUME = @as(c_int, 0x0800);
pub const PROCESS_TERMINATE = @as(c_int, 0x0001);
pub const PROCESS_VM_READ = @as(c_int, 0x0010);
pub const PROCESS_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE) | @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex);
pub const TOKEN_ASSIGN_PRIMARY = @as(c_int, 0x0001);
pub const TOKEN_DUPLICATE = @as(c_int, 0x0002);
pub const TOKEN_IMPERSONATE = @as(c_int, 0x0004);
pub const TOKEN_QUERY = @as(c_int, 0x0008);
pub const TOKEN_QUERY_SOURCE = @as(c_int, 0x0010);
pub const TOKEN_ADJUST_PRIVILEGES = @as(c_int, 0x0020);
pub const TOKEN_ADJUST_GROUPS = @as(c_int, 0x0040);
pub const TOKEN_ADJUST_DEFAULT = @as(c_int, 0x0080);
pub const TOKEN_ADJUST_SESSIONID = @as(c_int, 0x0100);
pub const TOKEN_ALL_ACCESS_P = (((((((STANDARD_RIGHTS_REQUIRED | TOKEN_ASSIGN_PRIMARY) | TOKEN_DUPLICATE) | TOKEN_IMPERSONATE) | TOKEN_QUERY) | TOKEN_QUERY_SOURCE) | TOKEN_ADJUST_PRIVILEGES) | TOKEN_ADJUST_GROUPS) | TOKEN_ADJUST_DEFAULT;
pub const SE_PRIVILEGE_ENABLED_BY_DEFAULT = @as(c_long, 0x00000001);
pub const SE_PRIVILEGE_ENABLED = @as(c_long, 0x00000002);
pub const SE_PRIVILEGE_REMOVED = @as(c_long, 0x00000004);
pub const SE_PRIVILEGE_USED_FOR_ACCESS = @import("std").zig.c_translation.promoteIntLiteral(c_long, 0x80000000, .hex);
pub const STATUS_WAIT_0 = @import("std").zig.c_translation.cast(DWORD, @as(c_long, 0x00000000));
pub const STATUS_TIMEOUT = @import("std").zig.c_translation.cast(DWORD, @as(c_long, 0x00000102));
pub const STATUS_PENDING = @import("std").zig.c_translation.cast(DWORD, @as(c_long, 0x00000103));
pub const STILL_ACTIVE = STATUS_PENDING;
pub const STARTF_USESHOWWINDOW = @as(c_int, 0x00000001);
pub const STARTF_USESIZE = @as(c_int, 0x00000002);
pub const STARTF_USEPOSITION = @as(c_int, 0x00000004);
pub const STARTF_USECOUNTCHARS = @as(c_int, 0x00000008);
pub const STARTF_USEFILLATTRIBUTE = @as(c_int, 0x00000010);
pub const STARTF_RUNFULLSCREEN = @as(c_int, 0x00000020);
pub const STARTF_FORCEONFEEDBACK = @as(c_int, 0x00000040);
pub const STARTF_FORCEOFFFEEDBACK = @as(c_int, 0x00000080);
pub const STARTF_USESTDHANDLES = @as(c_int, 0x00000100);
pub const NORMAL_PRIORITY_CLASS = @as(c_int, 0x00000020);
pub const JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = @as(c_int, 0x00002000);
pub const WINDOWS_SYSINFO_H = "";
pub const DISPLAY_DEVICE_ACTIVE = @as(c_int, 0x00000001);
pub const DISPLAY_DEVICE_ATTACHED = @as(c_int, 0x00000002);
pub const DISPLAY_DEVICE_PRIMARY_DEVICE = @as(c_int, 0x00000004);
pub const SM_CXSCREEN = @as(c_int, 0);
pub const SM_CYSCREEN = @as(c_int, 1);
pub const SM_CMONITORS = @as(c_int, 80);
pub const VER_EQUAL = @as(c_int, 1);
pub const VER_GREATER = @as(c_int, 2);
pub const VER_GREATER_EQUAL = @as(c_int, 3);
pub const VER_LESS = @as(c_int, 4);
pub const VER_LESS_EQUAL = @as(c_int, 5);
pub const VER_AND = @as(c_int, 6);
pub const VER_OR = @as(c_int, 7);
pub const _WIN32_WINNT_WINXP = @as(c_int, 0x0501);
pub const _WIN32_WINNT_WS03 = @as(c_int, 0x0502);
pub const _WIN32_WINNT_VISTA = @as(c_int, 0x0600);
pub const _WIN32_WINNT_WS08 = @as(c_int, 0x0600);
pub const _WIN32_WINNT_WIN7 = @as(c_int, 0x0601);
pub const _WIN32_WINNT_WIN8 = @as(c_int, 0x0602);
pub const _WIN32_WINNT_WIN81 = @as(c_int, 0x0603);
pub const _WIN32_WINNT_WIN10 = @as(c_int, 0x0A00);
pub const VER_MINORVERSION = @as(c_int, 0x0000001);
pub const VER_MAJORVERSION = @as(c_int, 0x0000002);
pub const VER_BUILDNUMBER = @as(c_int, 0x0000004);
pub const VER_PLATFORMID = @as(c_int, 0x0000008);
pub const VER_SERVICEPACKMINOR = @as(c_int, 0x0000010);
pub const VER_SERVICEPACKMAJOR = @as(c_int, 0x0000020);
pub const HKEY_CLASSES_ROOT = @import("std").zig.c_translation.cast(HKEY, @import("std").zig.c_translation.cast(ULONG_PTR, @import("std").zig.c_translation.cast(LONG, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hex))));
pub const HKEY_CURRENT_USER = @import("std").zig.c_translation.cast(HKEY, @import("std").zig.c_translation.cast(ULONG_PTR, @import("std").zig.c_translation.cast(LONG, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000001, .hex))));
pub const HKEY_LOCAL_MACHINE = @import("std").zig.c_translation.cast(HKEY, @import("std").zig.c_translation.cast(ULONG_PTR, @import("std").zig.c_translation.cast(LONG, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000002, .hex))));
pub const HKEY_USERS = @import("std").zig.c_translation.cast(HKEY, @import("std").zig.c_translation.cast(ULONG_PTR, @import("std").zig.c_translation.cast(LONG, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000003, .hex))));
pub const REG_NONE = @as(c_int, 0);
pub const REG_SZ = @as(c_int, 1);
pub const REG_EXPAND_SZ = @as(c_int, 2);
pub const REG_BINARY = @as(c_int, 3);
pub const REG_DWORD = @as(c_int, 4);
pub const REG_DWORD_LITTLE_ENDIAN = @as(c_int, 4);
pub const REG_DWORD_BIG_ENDIAN = @as(c_int, 5);
pub const REG_LINK = @as(c_int, 6);
pub const REG_MULTI_SZ = @as(c_int, 7);
pub const REG_RESOURCE_LIST = @as(c_int, 8);
pub const REG_FULL_RESOURCE_DESCRIPTOR = @as(c_int, 9);
pub const REG_RESOURCE_REQUIREMENTS_LIST = @as(c_int, 10);
pub const REG_QWORD = @as(c_int, 11);
pub const REG_QWORD_LITTLE_ENDIAN = @as(c_int, 11);
pub const KEY_QUERY_VALUE = @as(c_int, 0x0001);
pub const KEY_SET_VALUE = @as(c_int, 0x0002);
pub const KEY_CREATE_SUB_KEY = @as(c_int, 0x0004);
pub const KEY_ENUMERATE_SUB_KEYS = @as(c_int, 0x0008);
pub const KEY_NOTIFY = @as(c_int, 0x0010);
pub const KEY_CREATE_LINK = @as(c_int, 0x0020);
pub const KEY_WOW64_32KEY = @as(c_int, 0x0200);
pub const KEY_WOW64_64KEY = @as(c_int, 0x0100);
pub const KEY_WOW64_RES = @as(c_int, 0x0300);
pub const KEY_READ = (((STANDARD_RIGHTS_READ | KEY_QUERY_VALUE) | KEY_ENUMERATE_SUB_KEYS) | KEY_NOTIFY) & ~SYNCHRONIZE;
pub const KEY_WRITE = ((STANDARD_RIGHTS_WRITE | KEY_SET_VALUE) | KEY_CREATE_SUB_KEY) & ~SYNCHRONIZE;
pub const KEY_EXECUTE = KEY_READ & ~SYNCHRONIZE;
pub const KEY_ALL_ACCESS = ((((((STANDARD_RIGHTS_ALL | KEY_QUERY_VALUE) | KEY_SET_VALUE) | KEY_CREATE_SUB_KEY) | KEY_ENUMERATE_SUB_KEYS) | KEY_NOTIFY) | KEY_CREATE_LINK) & ~SYNCHRONIZE;
pub const ALL_PROCESSOR_GROUPS = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffff, .hex);
pub const MAX_COMPUTERNAME_LENGTH = @as(c_int, 31);
pub const GREATER = IsWindowsVersionOrGreater;
pub const WINDOWS_THREADS_H = "";
pub const STATUS_ABANDONED_WAIT_0 = @import("std").zig.c_translation.cast(DWORD, @as(c_long, 0x00000080));
pub const WAIT_FAILED = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffffffff, .hex));
pub const WAIT_OBJECT_0 = STATUS_WAIT_0 + @as(c_int, 0);
pub const WAIT_ABANDONED = STATUS_ABANDONED_WAIT_0 + @as(c_int, 0);
pub const WAIT_TIMEOUT = @as(c_long, 258);
pub const TLS_OUT_OF_INDEXES = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFFFFFF, .hex));
pub const FLS_OUT_OF_INDEXES = @import("std").zig.c_translation.cast(DWORD, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFFFFFF, .hex));
pub const CREATE_NEW_CONSOLE = @as(c_int, 0x00000010);
pub const CREATE_NO_WINDOW = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x08000000, .hex);
pub const CREATE_SUSPENDED = @as(c_int, 0x00000004);
pub const DETACHED_PROCESS = @as(c_int, 0x00000008);
pub const THREAD_GET_CONTEXT = @as(c_int, 0x0008);
pub const THREAD_QUERY_INFORMATION = @as(c_int, 0x0040);
pub const THREAD_SUSPEND_RESUME = @as(c_int, 0x0002);
pub const THREAD_TERMINATE = @as(c_int, 0x0001);
pub const THREAD_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE) | @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex);
pub const SEMAPHORE_ALL_ACCESS = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x1F0003, .hex);
pub const SEMAPHORE_MODIFY_STATE = @as(c_int, 0x0002);
pub const EVENT_ALL_ACCESS = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x1F0003, .hex);
pub const EVENT_MODIFY_STATE = @as(c_int, 0x0002);
pub const RTL_CONDITION_VARIABLE_LOCKMODE_SHARED = @as(c_int, 0x1);
pub const WINDOWS_WINDOW_H = "";
pub const MB_ABORTRETRYIGNORE = @as(c_long, 0x00000002);
pub const MB_CANCELTRYCONTINUE = @as(c_long, 0x00000006);
pub const MB_HELP = @as(c_long, 0x00004000);
pub const MB_OK = @as(c_long, 0x00000000);
pub const MB_OKCANCEL = @as(c_long, 0x00000001);
pub const MB_RETRYCANCEL = @as(c_long, 0x00000005);
pub const MB_YESNO = @as(c_long, 0x00000004);
pub const MB_YESNOCANCEL = @as(c_long, 0x00000003);
pub const MB_ICONEXCLAMATION = @as(c_long, 0x00000030);
pub const MB_ICONWARNING = @as(c_long, 0x00000030);
pub const MB_ICONINFORMATION = @as(c_long, 0x00000040);
pub const MB_ICONASTERISK = @as(c_long, 0x00000040);
pub const MB_ICONQUESTION = @as(c_long, 0x00000020);
pub const MB_ICONSTOP = @as(c_long, 0x00000010);
pub const MB_ICONERROR = @as(c_long, 0x00000010);
pub const MB_ICONHAND = @as(c_long, 0x00000010);
pub const MB_DEFBUTTON1 = @as(c_long, 0x00000000);
pub const MB_DEFBUTTON2 = @as(c_long, 0x00000100);
pub const MB_DEFBUTTON3 = @as(c_long, 0x00000200);
pub const MB_DEFBUTTON4 = @as(c_long, 0x00000300);
pub const MB_APPLMODAL = @as(c_long, 0x00000000);
pub const MB_SYSTEMMODAL = @as(c_long, 0x00001000);
pub const MB_TASKMODAL = @as(c_long, 0x00002000);
pub const MB_DEFAULT_DESKTOP_ONLY = @as(c_long, 0x00020000);
pub const MB_RIGHT = @as(c_long, 0x00080000);
pub const MB_RTLREADING = @as(c_long, 0x00100000);
pub const MB_SETFOREGROUND = @as(c_long, 0x00010000);
pub const MB_TOPMOST = @as(c_long, 0x00040000);
pub const MB_SERVICE_NOTIFICATION = @as(c_long, 0x00200000);
pub const IDABORT = @as(c_int, 3);
pub const IDCANCEL = @as(c_int, 2);
pub const IDCONTINUE = @as(c_int, 11);
pub const IDIGNORE = @as(c_int, 5);
pub const IDNO = @as(c_int, 7);
pub const IDOK = @as(c_int, 1);
pub const IDRETRY = @as(c_int, 4);
pub const IDTRYAGAIN = @as(c_int, 10);
pub const IDYES = @as(c_int, 6);
pub const WS_OVERLAPPED = @as(DWORD, 0x00000000);
pub const WS_POPUP = @import("std").zig.c_translation.promoteIntLiteral(DWORD, 0x80000000, .hex);
pub const WS_CHILD = @as(DWORD, 0x40000000);
pub const WS_MINIMIZE = @as(DWORD, 0x20000000);
pub const WS_VISIBLE = @as(DWORD, 0x10000000);
pub const WS_DISABLED = @as(DWORD, 0x08000000);
pub const WS_CLIPSIBLINGS = @as(DWORD, 0x04000000);
pub const WS_CLIPCHILDREN = @as(DWORD, 0x02000000);
pub const WS_MAXIMIZE = @as(DWORD, 0x01000000);
pub const WS_CAPTION = @as(DWORD, 0x00C00000);
pub const WS_BORDER = @as(DWORD, 0x00800000);
pub const WS_DLGFRAME = @as(DWORD, 0x00400000);
pub const WS_VSCROLL = @as(DWORD, 0x00200000);
pub const WS_HSCROLL = @as(DWORD, 0x00100000);
pub const WS_SYSMENU = @as(DWORD, 0x00080000);
pub const WS_THICKFRAME = @as(DWORD, 0x00040000);
pub const WS_GROUP = @as(DWORD, 0x00020000);
pub const WS_TABSTOP = @as(DWORD, 0x00010000);
pub const WS_MINIMIZEBOX = @as(DWORD, 0x00020000);
pub const WS_MAXIMIZEBOX = @as(DWORD, 0x00010000);
pub const WS_TILED = WS_OVERLAPPED;
pub const WS_ICONIC = WS_MINIMIZE;
pub const WS_SIZEBOX = WS_THICKFRAME;
pub const WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW;
pub const WS_OVERLAPPEDWINDOW = ((((WS_OVERLAPPED | WS_CAPTION) | WS_SYSMENU) | WS_THICKFRAME) | WS_MINIMIZEBOX) | WS_MAXIMIZEBOX;
pub const WS_POPUPWINDOW = (WS_POPUP | WS_BORDER) | WS_SYSMENU;
pub const WS_CHILDWINDOW = WS_CHILD;
pub const CW_USEDEFAULT = @import("std").zig.c_translation.cast(c_int, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hex));
pub const CS_OWNDC = @as(c_int, 0x0020);
pub const CS_VREDRAW = @as(c_int, 0x0001);
pub const CS_HREDRAW = @as(c_int, 0x0002);
pub const PM_NOREMOVE = @as(c_int, 0x0000);
pub const PM_REMOVE = @as(c_int, 0x0001);
pub const PM_NOYIELD = @as(c_int, 0x0002);
pub const WM_NULL = @as(c_int, 0x0000);
pub const WM_CREATE = @as(c_int, 0x0001);
pub const WM_DESTROY = @as(c_int, 0x0002);
pub const WM_MOVE = @as(c_int, 0x0003);
pub const WM_SIZE = @as(c_int, 0x0005);
pub const WM_SETFOCUS = @as(c_int, 0x0007);
pub const WM_KILLFOCUS = @as(c_int, 0x0008);
pub const WM_ENABLE = @as(c_int, 0x000A);
pub const WM_SETREDRAW = @as(c_int, 0x000B);
pub const WM_SETTEXT = @as(c_int, 0x000C);
pub const WM_GETTEXT = @as(c_int, 0x000D);
pub const WM_GETTEXTLENGTH = @as(c_int, 0x000E);
pub const WM_PAINT = @as(c_int, 0x000F);
pub const WM_CLOSE = @as(c_int, 0x0010);
pub const WM_QUIT = @as(c_int, 0x0012);
pub const WM_ERASEBKGND = @as(c_int, 0x0014);
pub const WM_SYSCOLORCHANGE = @as(c_int, 0x0015);
pub const WM_SHOWWINDOW = @as(c_int, 0x0018);
pub const WM_WININICHANGE = @as(c_int, 0x001A);
pub const WM_NCDESTROY = @as(c_int, 0x0082);
pub const WM_KEYDOWN = @as(c_int, 0x0100);
pub const WM_KEYUP = @as(c_int, 0x0101);
pub const WM_SYSKEYDOWN = @as(c_int, 0x0104);
pub const WM_SYSKEYUP = @as(c_int, 0x0105);
pub const WM_SYSCOMMAND = @as(c_int, 0x0112);
pub const WM_ENTERSIZEMOVE = @as(c_int, 0x0231);
pub const WM_EXITSIZEMOVE = @as(c_int, 0x0232);
pub const WM_ACTIVATE = @as(c_int, 0x0006);
pub const WA_INACTIVE = @as(c_int, 0);
pub const WA_ACTIVE = @as(c_int, 1);
pub const WA_CLICKACTIVE = @as(c_int, 2);
pub const SC_KEYMENU = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xF100, .hex);
pub const WINDOWS_FIBER_H = "";
pub const _WINDOWS_ = "";
pub const _SECURITY_ATTRIBUTES = struct__SECURITY_ATTRIBUTES;
pub const _LARGE_INTEGER = union__LARGE_INTEGER;
pub const _ULARGE_INTEGER = union__ULARGE_INTEGER;
pub const _FILETIME = struct__FILETIME;
pub const _NT_TIB = struct__NT_TIB;
pub const _M128A = struct__M128A;
pub const _XSAVE_FORMAT = struct__XSAVE_FORMAT;
pub const _CONTEXT = struct__CONTEXT;
pub const _EXCEPTION_RECORD = struct__EXCEPTION_RECORD;
pub const _EXCEPTION_POINTERS = struct__EXCEPTION_POINTERS;
pub const _SYMBOL_INFO = struct__SYMBOL_INFO;
pub const _SYMBOL_INFOW = struct__SYMBOL_INFOW;
pub const _IMAGEHLP_LINE64 = struct__IMAGEHLP_LINE64;
pub const _IMAGEHLP_LINEW64 = struct__IMAGEHLP_LINEW64;
pub const tagTHREADENTRY32 = struct_tagTHREADENTRY32;
pub const _tagADDRESS64 = struct__tagADDRESS64;
pub const _KDHELP64 = struct__KDHELP64;
pub const _tagSTACKFRAME64 = struct__tagSTACKFRAME64;
pub const _LUID = struct__LUID;
pub const _LUID_AND_ATTRIBUTES = struct__LUID_AND_ATTRIBUTES;
pub const _TOKEN_PRIVILEGES = struct__TOKEN_PRIVILEGES;
pub const tagVS_FIXEDFILEINFO = struct_tagVS_FIXEDFILEINFO;
pub const _MINIDUMP_TYPE = enum__MINIDUMP_TYPE;
pub const _MINIDUMP_EXCEPTION_INFORMATION = struct__MINIDUMP_EXCEPTION_INFORMATION;
pub const _MINIDUMP_EXCEPTION_INFORMATION64 = struct__MINIDUMP_EXCEPTION_INFORMATION64;
pub const _MINIDUMP_THREAD_CALLBACK = struct__MINIDUMP_THREAD_CALLBACK;
pub const _MINIDUMP_THREAD_EX_CALLBACK = struct__MINIDUMP_THREAD_EX_CALLBACK;
pub const _MINIDUMP_MODULE_CALLBACK = struct__MINIDUMP_MODULE_CALLBACK;
pub const _MINIDUMP_INCLUDE_THREAD_CALLBACK = struct__MINIDUMP_INCLUDE_THREAD_CALLBACK;
pub const _MINIDUMP_INCLUDE_MODULE_CALLBACK = struct__MINIDUMP_INCLUDE_MODULE_CALLBACK;
pub const _MINIDUMP_IO_CALLBACK = struct__MINIDUMP_IO_CALLBACK;
pub const _MINIDUMP_READ_MEMORY_FAILURE_CALLBACK = struct__MINIDUMP_READ_MEMORY_FAILURE_CALLBACK;
pub const _MINIDUMP_CALLBACK_INPUT = struct__MINIDUMP_CALLBACK_INPUT;
pub const _MINIDUMP_MEMORY_INFO = struct__MINIDUMP_MEMORY_INFO;
pub const _MINIDUMP_CALLBACK_OUTPUT = struct__MINIDUMP_CALLBACK_OUTPUT;
pub const _MINIDUMP_CALLBACK_INFORMATION = struct__MINIDUMP_CALLBACK_INFORMATION;
pub const _MINIDUMP_USER_STREAM = struct__MINIDUMP_USER_STREAM;
pub const _MINIDUMP_USER_STREAM_INFORMATION = struct__MINIDUMP_USER_STREAM_INFORMATION;
pub const _OVERLAPPED = struct__OVERLAPPED;
pub const _WIN32_FIND_DATAA = struct__WIN32_FIND_DATAA;
pub const _WIN32_FIND_DATAW = struct__WIN32_FIND_DATAW;
pub const _GET_FILEEX_INFO_LEVELS = enum__GET_FILEEX_INFO_LEVELS;
pub const _WIN32_FILE_ATTRIBUTE_DATA = struct__WIN32_FILE_ATTRIBUTE_DATA;
pub const _HEAP_INFORMATION_CLASS = enum__HEAP_INFORMATION_CLASS;
pub const _COORD = struct__COORD;
pub const _SMALL_RECT = struct__SMALL_RECT;
pub const _CONSOLE_SCREEN_BUFFER_INFO = struct__CONSOLE_SCREEN_BUFFER_INFO;
pub const _MEMORY_BASIC_INFORMATION32 = struct__MEMORY_BASIC_INFORMATION32;
pub const _MEMORY_BASIC_INFORMATION64 = struct__MEMORY_BASIC_INFORMATION64;
pub const _SYSTEMTIME = struct__SYSTEMTIME;
pub const _TIME_ZONE_INFORMATION = struct__TIME_ZONE_INFORMATION;
pub const timecaps_tag = struct_timecaps_tag;
pub const _JOBOBJECTINFOCLASS = enum__JOBOBJECTINFOCLASS;
pub const _STARTUPINFOA = struct__STARTUPINFOA;
pub const _STARTUPINFOW = struct__STARTUPINFOW;
pub const _PROC_THREAD_ATTRIBUTE_LIST = struct__PROC_THREAD_ATTRIBUTE_LIST;
pub const _STARTUPINFOEXA = struct__STARTUPINFOEXA;
pub const _STARTUPINFOEXW = struct__STARTUPINFOEXW;
pub const _PROCESS_INFORMATION = struct__PROCESS_INFORMATION;
pub const _JOBOBJECT_BASIC_LIMIT_INFORMATION = struct__JOBOBJECT_BASIC_LIMIT_INFORMATION;
pub const _IO_COUNTERS = struct__IO_COUNTERS;
pub const _JOBOBJECT_EXTENDED_LIMIT_INFORMATION = struct__JOBOBJECT_EXTENDED_LIMIT_INFORMATION;
pub const _SYSTEM_INFO = struct__SYSTEM_INFO;
pub const _DISPLAY_DEVICEA = struct__DISPLAY_DEVICEA;
pub const _DISPLAY_DEVICEW = struct__DISPLAY_DEVICEW;
pub const _OSVERSIONINFOEXA = struct__OSVERSIONINFOEXA;
pub const _OSVERSIONINFOEXW = struct__OSVERSIONINFOEXW;
pub const _LOGICAL_PROCESSOR_RELATIONSHIP = enum__LOGICAL_PROCESSOR_RELATIONSHIP;
pub const _PROCESSOR_CACHE_TYPE = enum__PROCESSOR_CACHE_TYPE;
pub const _CACHE_DESCRIPTOR = struct__CACHE_DESCRIPTOR;
pub const _SYSTEM_LOGICAL_PROCESSOR_INFORMATION = struct__SYSTEM_LOGICAL_PROCESSOR_INFORMATION;
pub const _GROUP_AFFINITY = struct__GROUP_AFFINITY;
pub const _NUMA_NODE_RELATIONSHIP = struct__NUMA_NODE_RELATIONSHIP;
pub const _PROCESSOR_GROUP_INFO = struct__PROCESSOR_GROUP_INFO;
pub const _GROUP_RELATIONSHIP = struct__GROUP_RELATIONSHIP;
pub const _CACHE_RELATIONSHIP = struct__CACHE_RELATIONSHIP;
pub const _PROCESSOR_RELATIONSHIP = struct__PROCESSOR_RELATIONSHIP;
pub const _SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX = struct__SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX;
pub const _PROCESS_MEMORY_COUNTERS = struct__PROCESS_MEMORY_COUNTERS;
pub const _MEMORYSTATUSEX = struct__MEMORYSTATUSEX;
pub const _PROCESSOR_NUMBER = struct__PROCESSOR_NUMBER;
pub const _IMAGE_TLS_DIRECTORY32 = struct__IMAGE_TLS_DIRECTORY32;
pub const _IMAGE_TLS_DIRECTORY64 = struct__IMAGE_TLS_DIRECTORY64;
pub const _LIST_ENTRY = struct__LIST_ENTRY;
pub const _RTL_CRITICAL_SECTION = struct__RTL_CRITICAL_SECTION;
pub const _RTL_CRITICAL_SECTION_DEBUG = struct__RTL_CRITICAL_SECTION_DEBUG;
pub const _RTL_CONDITION_VARIABLE = struct__RTL_CONDITION_VARIABLE;
pub const _RTL_SRWLOCK = struct__RTL_SRWLOCK;
pub const _RECT = struct__RECT;
pub const tagWNDCLASS = struct_tagWNDCLASS;
pub const tagPOINT = struct_tagPOINT;
pub const tagMSG = struct_tagMSG;

pub const SW_HIDE = 0;
pub const SW_SHOWNORMAL = 1;
pub const SW_NORMAL = 1;
pub const SW_SHOWMINIMIZED = 2;
pub const SW_SHOWMAXIMIZED = 3;
pub const SW_MAXIMIZE = 3;
pub const SW_SHOWNOACTIVATE = 4;
pub const SW_SHOW = 5;
pub const SW_MINIMIZE = 6;
pub const SW_SHOWMINNOACTIVE = 7;
pub const SW_SHOWNA = 8;
pub const SW_RESTORE = 9;
pub const SW_SHOWDEFAULT = 10;
pub const SW_FORCEMINIMIZE = 11;

pub const VER_NT_WORKSTATION = 0x1;
pub const VER_NT_SERVER = 0x3;
pub const VER_NT_DOMAIN_CONTROLLER = 0x2;

pub const LPCRECT = [*c]const RECT;
pub const POINTL = POINT;
pub const HMONITOR = HANDLE;
pub const LPMONITORINFO = [*c]MONITORINFO;
pub const MONITORENUMPROC = ?*const fn (HMONITOR, HDC, LPRECT, LPARAM) callconv(.C) BOOL;

pub extern fn GetMessageA(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) BOOL;
pub extern fn GetMessageW(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) BOOL;

pub extern fn EnumDisplayMonitors(lpMsg: HDC, hWnd: LPCRECT, wMsgFilterMin: MONITORENUMPROC, wMsgFilterMax: UINT) BOOL;

pub const MONITORINFO = extern struct {
    cbSize: DWORD,
    rcMonitor: RECT,
    rcWork: RECT,
    dwFlags: DWORD,
};

pub const CCHDEVICENAME = 32;
pub const MONITORINFOEXA = extern struct {
    monitorInfo: MONITORINFO,
    szDevice: [CCHDEVICENAME]CHAR,
};

pub extern fn GetMonitorInfoA(hMonitor: HMONITOR, lpmi: LPMONITORINFO) BOOL;
pub extern fn CreateWaitableTimerA(lpTimerAttributes: LPSECURITY_ATTRIBUTES, bManualReset: BOOL, lpTimerName: LPCWSTR) HANDLE;

pub const WS_EX_APPWINDOW = @as(DWORD, 0x00040000);
pub const WS_EX_TOPMOST = @as(DWORD, 0x00000008);
pub const MONITORINFOF_PRIMARY = @as(DWORD, 0x1);

pub const DEVMODEA = extern struct {
    dmDeviceName: [32]u8,
    dmSpecVersion: u16,
    dmDriverVersion: u16,
    dmSize: u16,
    dmDriverExtra: u16,
    dmFields: u32,
    Anonymous1: extern union {
        Anonymous1: extern struct {
            dmOrientation: i16,
            dmPaperSize: i16,
            dmPaperLength: i16,
            dmPaperWidth: i16,
            dmScale: i16,
            dmCopies: i16,
            dmDefaultSource: i16,
            dmPrintQuality: i16,
        },
        Anonymous2: extern struct {
            dmPosition: POINTL,
            dmDisplayOrientation: u32,
            dmDisplayFixedOutput: u32,
        },
    },
    dmColor: i16,
    dmDuplex: i16,
    dmYResolution: i16,
    dmTTOption: i16,
    dmCollate: i16,
    dmFormName: [32]u8,
    dmLogPixels: u16,
    dmBitsPerPel: u32,
    dmPelsWidth: u32,
    dmPelsHeight: u32,
    Anonymous2: extern union {
        dmDisplayFlags: u32,
        dmNup: u32,
    },
    dmDisplayFrequency: u32,
    dmICMMethod: u32,
    dmICMIntent: u32,
    dmMediaType: u32,
    dmDitherType: u32,
    dmReserved1: u32,
    dmReserved2: u32,
    dmPanningWidth: u32,
    dmPanningHeight: u32,
};

pub const DEVMODEW = extern struct {
    dmDeviceName: [32]u16,
    dmSpecVersion: u16,
    dmDriverVersion: u16,
    dmSize: u16,
    dmDriverExtra: u16,
    dmFields: u32,
    Anonymous1: extern union {
        Anonymous1: extern struct {
            dmOrientation: i16,
            dmPaperSize: i16,
            dmPaperLength: i16,
            dmPaperWidth: i16,
            dmScale: i16,
            dmCopies: i16,
            dmDefaultSource: i16,
            dmPrintQuality: i16,
        },
        Anonymous2: extern struct {
            dmPosition: POINTL,
            dmDisplayOrientation: u32,
            dmDisplayFixedOutput: u32,
        },
    },
    dmColor: i16,
    dmDuplex: i16,
    dmYResolution: i16,
    dmTTOption: i16,
    dmCollate: i16,
    dmFormName: [32]u16,
    dmLogPixels: u16,
    dmBitsPerPel: u32,
    dmPelsWidth: u32,
    dmPelsHeight: u32,
    Anonymous2: extern union {
        dmDisplayFlags: u32,
        dmNup: u32,
    },
    dmDisplayFrequency: u32,
    dmICMMethod: u32,
    dmICMIntent: u32,
    dmMediaType: u32,
    dmDitherType: u32,
    dmReserved1: u32,
    dmReserved2: u32,
    dmPanningWidth: u32,
    dmPanningHeight: u32,
};

pub const DM_SPECVERSION = @as(u32, 1025);
pub const DM_ORIENTATION = @as(i32, 1);
pub const DM_PAPERSIZE = @as(i32, 2);
pub const DM_PAPERLENGTH = @as(i32, 4);
pub const DM_PAPERWIDTH = @as(i32, 8);
pub const DM_SCALE = @as(i32, 16);
pub const DM_POSITION = @as(i32, 32);
pub const DM_NUP = @as(i32, 64);
pub const DM_DISPLAYORIENTATION = @as(i32, 128);
pub const DM_COPIES = @as(i32, 256);
pub const DM_DEFAULTSOURCE = @as(i32, 512);
pub const DM_PRINTQUALITY = @as(i32, 1024);
pub const DM_COLOR = @as(i32, 2048);
pub const DM_DUPLEX = @as(i32, 4096);
pub const DM_YRESOLUTION = @as(i32, 8192);
pub const DM_TTOPTION = @as(i32, 16384);
pub const DM_COLLATE = @as(i32, 32768);
pub const DM_FORMNAME = @as(i32, 65536);
pub const DM_LOGPIXELS = @as(i32, 131072);
pub const DM_BITSPERPEL = @as(i32, 262144);
pub const DM_PELSWIDTH = @as(i32, 524288);
pub const DM_PELSHEIGHT = @as(i32, 1048576);
pub const DM_DISPLAYFLAGS = @as(i32, 2097152);
pub const DM_DISPLAYFREQUENCY = @as(i32, 4194304);
pub const DM_ICMMETHOD = @as(i32, 8388608);
pub const DM_ICMINTENT = @as(i32, 16777216);
pub const DM_MEDIATYPE = @as(i32, 33554432);
pub const DM_DITHERTYPE = @as(i32, 67108864);
pub const DM_PANNINGWIDTH = @as(i32, 134217728);
pub const DM_PANNINGHEIGHT = @as(i32, 268435456);
pub const DM_DISPLAYFIXEDOUTPUT = @as(i32, 536870912);

pub const DISP_CHANGE_SUCCESSFUL = 0;
pub const DISP_CHANGE_RESTART = 1;
pub const DISP_CHANGE_FAILED = -1;
pub const DISP_CHANGE_BADMODE = -2;
pub const DISP_CHANGE_NOTUPDATED = -3;
pub const DISP_CHANGE_BADFLAGS = -4;
pub const DISP_CHANGE_BADPARAM = -5;
pub const DISP_CHANGE_BADDUALVIEW = -6;

pub const CDS_FULLSCREEN = 0x00000004;
pub const CDS_GLOBAL = 0x00000008;
pub const CDS_NORESET = 0x10000000;
pub const CDS_RESET = 0x40000000;
pub const CDS_SET_PRIMARY = 0x00000010;
pub const CDS_TEST = 0x00000002;
pub const CDS_UPDATEREGISTRY = 0x00000001;
pub const CDS_VIDEOPARAMETERS = 0x00000020;
pub const CDS_ENABLE_UNSAFE_MODES = 0x00000100;
pub const CDS_DISABLE_UNSAFE_MODES = 0x00000200;

pub extern fn ChangeDisplaySettingsExA(lpszDeviceName: ?[*:0]const u8, lpDevMode: ?*DEVMODEA, hwnd: HWND, dwflags: DWORD, lParam: ?*anyopaque) LONG;
pub extern fn ChangeDisplaySettingsExW(lpszDeviceName: ?[*:0]const u16, lpDevMode: ?*DEVMODEW, hwnd: HWND, dwflags: DWORD, lParam: ?*anyopaque) LONG;

pub const ENUM_DISPLAY_SETTINGS_MODE = UINT;
pub const ENUM_CURRENT_SETTINGS = 4294967295;
pub const ENUM_REGISTRY_SETTINGS = 4294967294;
pub extern fn EnumDisplaySettingsA(lpszDeviceName: ?[*:0]const u8, iModeNum: ENUM_DISPLAY_SETTINGS_MODE, lpDevMode: ?*DEVMODEA) BOOL;
pub extern fn EnumDisplaySettingsW(lpszDeviceName: ?[*:0]const u16, iModeNum: ENUM_DISPLAY_SETTINGS_MODE, lpDevMode: ?*DEVMODEW) BOOL;

pub const WM_QUERYENDSESSION = @as(u32, 17);
pub const WM_QUERYOPEN = @as(u32, 19);
pub const WM_ENDSESSION = @as(u32, 22);
pub const WM_SETTINGCHANGE = @as(u32, 26);
pub const WM_DEVMODECHANGE = @as(u32, 27);
pub const WM_ACTIVATEAPP = @as(u32, 28);
pub const WM_FONTCHANGE = @as(u32, 29);
pub const WM_TIMECHANGE = @as(u32, 30);
pub const WM_CANCELMODE = @as(u32, 31);
pub const WM_SETCURSOR = @as(u32, 32);
pub const WM_MOUSEACTIVATE = @as(u32, 33);
pub const WM_CHILDACTIVATE = @as(u32, 34);
pub const WM_QUEUESYNC = @as(u32, 35);
pub const WM_GETMINMAXINFO = @as(u32, 36);
pub const WM_PAINTICON = @as(u32, 38);
pub const WM_ICONERASEBKGND = @as(u32, 39);
pub const WM_NEXTDLGCTL = @as(u32, 40);
pub const WM_SPOOLERSTATUS = @as(u32, 42);
pub const WM_DRAWITEM = @as(u32, 43);
pub const WM_MEASUREITEM = @as(u32, 44);
pub const WM_DELETEITEM = @as(u32, 45);
pub const WM_VKEYTOITEM = @as(u32, 46);
pub const WM_CHARTOITEM = @as(u32, 47);
pub const WM_SETFONT = @as(u32, 48);
pub const WM_GETFONT = @as(u32, 49);
pub const WM_SETHOTKEY = @as(u32, 50);
pub const WM_GETHOTKEY = @as(u32, 51);
pub const WM_QUERYDRAGICON = @as(u32, 55);
pub const WM_COMPAREITEM = @as(u32, 57);
pub const WM_GETOBJECT = @as(u32, 61);
pub const WM_COMPACTING = @as(u32, 65);
pub const WM_COMMNOTIFY = @as(u32, 68);
pub const WM_WINDOWPOSCHANGING = @as(u32, 70);
pub const WM_WINDOWPOSCHANGED = @as(u32, 71);
pub const WM_POWER = @as(u32, 72);
pub const PWR_OK = @as(u32, 1);
pub const PWR_FAIL = @as(i32, -1);
pub const PWR_SUSPENDREQUEST = @as(u32, 1);
pub const PWR_SUSPENDRESUME = @as(u32, 2);
pub const PWR_CRITICALRESUME = @as(u32, 3);
pub const WM_COPYDATA = @as(u32, 74);
pub const WM_CANCELJOURNAL = @as(u32, 75);
pub const WM_INPUTLANGCHANGEREQUEST = @as(u32, 80);
pub const WM_INPUTLANGCHANGE = @as(u32, 81);
pub const WM_TCARD = @as(u32, 82);
pub const WM_HELP = @as(u32, 83);
pub const WM_USERCHANGED = @as(u32, 84);
pub const WM_NOTIFYFORMAT = @as(u32, 85);
pub const NFR_ANSI = @as(u32, 1);
pub const NFR_UNICODE = @as(u32, 2);
pub const NF_QUERY = @as(u32, 3);
pub const NF_REQUERY = @as(u32, 4);
pub const WM_STYLECHANGING = @as(u32, 124);
pub const WM_STYLECHANGED = @as(u32, 125);
pub const WM_DISPLAYCHANGE = @as(u32, 126);
pub const WM_GETICON = @as(u32, 127);
pub const WM_SETICON = @as(u32, 128);
pub const WM_NCCREATE = @as(u32, 129);
pub const WM_NCCALCSIZE = @as(u32, 131);
pub const WM_NCHITTEST = @as(u32, 132);
pub const WM_NCPAINT = @as(u32, 133);
pub const WM_NCACTIVATE = @as(u32, 134);
pub const WM_GETDLGCODE = @as(u32, 135);
pub const WM_SYNCPAINT = @as(u32, 136);
pub const WM_NCMOUSEMOVE = @as(u32, 160);
pub const WM_NCLBUTTONDOWN = @as(u32, 161);
pub const WM_NCLBUTTONUP = @as(u32, 162);
pub const WM_NCLBUTTONDBLCLK = @as(u32, 163);
pub const WM_NCRBUTTONDOWN = @as(u32, 164);
pub const WM_NCRBUTTONUP = @as(u32, 165);
pub const WM_NCRBUTTONDBLCLK = @as(u32, 166);
pub const WM_NCMBUTTONDOWN = @as(u32, 167);
pub const WM_NCMBUTTONUP = @as(u32, 168);
pub const WM_NCMBUTTONDBLCLK = @as(u32, 169);
pub const WM_NCXBUTTONDOWN = @as(u32, 171);
pub const WM_NCXBUTTONUP = @as(u32, 172);
pub const WM_NCXBUTTONDBLCLK = @as(u32, 173);
pub const WM_INPUT_DEVICE_CHANGE = @as(u32, 254);
pub const WM_INPUT = @as(u32, 255);
pub const WM_KEYFIRST = @as(u32, 256);
pub const WM_CHAR = @as(u32, 258);
pub const WM_DEADCHAR = @as(u32, 259);
pub const WM_SYSCHAR = @as(u32, 262);
pub const WM_SYSDEADCHAR = @as(u32, 263);
pub const WM_KEYLAST = @as(u32, 265);
pub const UNICODE_NOCHAR = @as(u32, 65535);
pub const WM_IME_STARTCOMPOSITION = @as(u32, 269);
pub const WM_IME_ENDCOMPOSITION = @as(u32, 270);
pub const WM_IME_COMPOSITION = @as(u32, 271);
pub const WM_IME_KEYLAST = @as(u32, 271);
pub const WM_INITDIALOG = @as(u32, 272);
pub const WM_COMMAND = @as(u32, 273);
pub const WM_TIMER = @as(u32, 275);
pub const WM_HSCROLL = @as(u32, 276);
pub const WM_VSCROLL = @as(u32, 277);
pub const WM_INITMENU = @as(u32, 278);
pub const WM_INITMENUPOPUP = @as(u32, 279);
pub const WM_GESTURE = @as(u32, 281);
pub const WM_GESTURENOTIFY = @as(u32, 282);
pub const WM_MENUSELECT = @as(u32, 287);
pub const WM_MENUCHAR = @as(u32, 288);
pub const WM_ENTERIDLE = @as(u32, 289);
pub const WM_MENURBUTTONUP = @as(u32, 290);
pub const WM_MENUDRAG = @as(u32, 291);
pub const WM_MENUGETOBJECT = @as(u32, 292);
pub const WM_UNINITMENUPOPUP = @as(u32, 293);
pub const WM_MENUCOMMAND = @as(u32, 294);
pub const WM_CHANGEUISTATE = @as(u32, 295);
pub const WM_UPDATEUISTATE = @as(u32, 296);
pub const WM_QUERYUISTATE = @as(u32, 297);
pub const UIS_SET = @as(u32, 1);
pub const UIS_CLEAR = @as(u32, 2);
pub const UIS_INITIALIZE = @as(u32, 3);
pub const UISF_HIDEFOCUS = @as(u32, 1);
pub const UISF_HIDEACCEL = @as(u32, 2);
pub const UISF_ACTIVE = @as(u32, 4);
pub const WM_CTLCOLORMSGBOX = @as(u32, 306);
pub const WM_CTLCOLOREDIT = @as(u32, 307);
pub const WM_CTLCOLORLISTBOX = @as(u32, 308);
pub const WM_CTLCOLORBTN = @as(u32, 309);
pub const WM_CTLCOLORDLG = @as(u32, 310);
pub const WM_CTLCOLORSCROLLBAR = @as(u32, 311);
pub const WM_CTLCOLORSTATIC = @as(u32, 312);
pub const MN_GETHMENU = @as(u32, 481);
pub const WM_MOUSEFIRST = @as(u32, 512);
pub const WM_MOUSEMOVE = @as(u32, 512);
pub const WM_LBUTTONDOWN = @as(u32, 513);
pub const WM_LBUTTONUP = @as(u32, 514);
pub const WM_LBUTTONDBLCLK = @as(u32, 515);
pub const WM_RBUTTONDOWN = @as(u32, 516);
pub const WM_RBUTTONUP = @as(u32, 517);
pub const WM_RBUTTONDBLCLK = @as(u32, 518);
pub const WM_MBUTTONDOWN = @as(u32, 519);
pub const WM_MBUTTONUP = @as(u32, 520);
pub const WM_MBUTTONDBLCLK = @as(u32, 521);
pub const WM_MOUSEWHEEL = @as(u32, 522);
pub const WM_XBUTTONDOWN = @as(u32, 523);
pub const WM_XBUTTONUP = @as(u32, 524);
pub const WM_XBUTTONDBLCLK = @as(u32, 525);
pub const WM_MOUSEHWHEEL = @as(u32, 526);
pub const WM_MOUSELAST = @as(u32, 526);
pub const WHEEL_DELTA = @as(u32, 120);
pub const WM_PARENTNOTIFY = @as(u32, 528);
pub const WM_ENTERMENULOOP = @as(u32, 529);
pub const WM_EXITMENULOOP = @as(u32, 530);
pub const WM_NEXTMENU = @as(u32, 531);
pub const WM_SIZING = @as(u32, 532);
pub const WM_CAPTURECHANGED = @as(u32, 533);
pub const WM_MOVING = @as(u32, 534);
pub const WM_POWERBROADCAST = @as(u32, 536);
pub const PBT_APMQUERYSUSPEND = @as(u32, 0);
pub const PBT_APMQUERYSTANDBY = @as(u32, 1);
pub const PBT_APMQUERYSUSPENDFAILED = @as(u32, 2);
pub const PBT_APMQUERYSTANDBYFAILED = @as(u32, 3);
pub const PBT_APMSUSPEND = @as(u32, 4);
pub const PBT_APMSTANDBY = @as(u32, 5);
pub const PBT_APMRESUMECRITICAL = @as(u32, 6);
pub const PBT_APMRESUMESUSPEND = @as(u32, 7);
pub const PBT_APMRESUMESTANDBY = @as(u32, 8);
pub const PBTF_APMRESUMEFROMFAILURE = @as(u32, 1);
pub const PBT_APMBATTERYLOW = @as(u32, 9);
pub const PBT_APMPOWERSTATUSCHANGE = @as(u32, 10);
pub const PBT_APMOEMEVENT = @as(u32, 11);
pub const PBT_APMRESUMEAUTOMATIC = @as(u32, 18);
pub const PBT_POWERSETTINGCHANGE = @as(u32, 32787);
pub const WM_MDICREATE = @as(u32, 544);
pub const WM_MDIDESTROY = @as(u32, 545);
pub const WM_MDIACTIVATE = @as(u32, 546);
pub const WM_MDIRESTORE = @as(u32, 547);
pub const WM_MDINEXT = @as(u32, 548);
pub const WM_MDIMAXIMIZE = @as(u32, 549);
pub const WM_MDITILE = @as(u32, 550);
pub const WM_MDICASCADE = @as(u32, 551);
pub const WM_MDIICONARRANGE = @as(u32, 552);
pub const WM_MDIGETACTIVE = @as(u32, 553);
pub const WM_MDISETMENU = @as(u32, 560);
pub const WM_DROPFILES = @as(u32, 563);
pub const WM_MDIREFRESHMENU = @as(u32, 564);
pub const WM_POINTERDEVICECHANGE = @as(u32, 568);
pub const WM_POINTERDEVICEINRANGE = @as(u32, 569);
pub const WM_POINTERDEVICEOUTOFRANGE = @as(u32, 570);
pub const WM_TOUCH = @as(u32, 576);
pub const WM_NCPOINTERUPDATE = @as(u32, 577);
pub const WM_NCPOINTERDOWN = @as(u32, 578);
pub const WM_NCPOINTERUP = @as(u32, 579);
pub const WM_POINTERUPDATE = @as(u32, 581);
pub const WM_POINTERDOWN = @as(u32, 582);
pub const WM_POINTERUP = @as(u32, 583);
pub const WM_POINTERENTER = @as(u32, 585);
pub const WM_POINTERLEAVE = @as(u32, 586);
pub const WM_POINTERACTIVATE = @as(u32, 587);
pub const WM_POINTERCAPTURECHANGED = @as(u32, 588);
pub const WM_TOUCHHITTESTING = @as(u32, 589);
pub const WM_POINTERWHEEL = @as(u32, 590);
pub const WM_POINTERHWHEEL = @as(u32, 591);
pub const DM_POINTERHITTEST = @as(u32, 592);
pub const WM_POINTERROUTEDTO = @as(u32, 593);
pub const WM_POINTERROUTEDAWAY = @as(u32, 594);
pub const WM_POINTERROUTEDRELEASED = @as(u32, 595);
pub const WM_IME_SETCONTEXT = @as(u32, 641);
pub const WM_IME_NOTIFY = @as(u32, 642);
pub const WM_IME_CONTROL = @as(u32, 643);
pub const WM_IME_COMPOSITIONFULL = @as(u32, 644);
pub const WM_IME_SELECT = @as(u32, 645);
pub const WM_IME_CHAR = @as(u32, 646);
pub const WM_IME_REQUEST = @as(u32, 648);
pub const WM_IME_KEYDOWN = @as(u32, 656);
pub const WM_IME_KEYUP = @as(u32, 657);
pub const WM_NCMOUSEHOVER = @as(u32, 672);
pub const WM_NCMOUSELEAVE = @as(u32, 674);
pub const WM_WTSSESSION_CHANGE = @as(u32, 689);
pub const WM_TABLET_FIRST = @as(u32, 704);
pub const WM_TABLET_LAST = @as(u32, 735);
pub const WM_DPICHANGED = @as(u32, 736);
pub const WM_DPICHANGED_BEFOREPARENT = @as(u32, 738);
pub const WM_DPICHANGED_AFTERPARENT = @as(u32, 739);
pub const WM_GETDPISCALEDSIZE = @as(u32, 740);
pub const WM_CUT = @as(u32, 768);
pub const WM_COPY = @as(u32, 769);
pub const WM_PASTE = @as(u32, 770);
pub const WM_CLEAR = @as(u32, 771);
pub const WM_UNDO = @as(u32, 772);
pub const WM_RENDERFORMAT = @as(u32, 773);
pub const WM_RENDERALLFORMATS = @as(u32, 774);
pub const WM_DESTROYCLIPBOARD = @as(u32, 775);
pub const WM_DRAWCLIPBOARD = @as(u32, 776);
pub const WM_PAINTCLIPBOARD = @as(u32, 777);
pub const WM_VSCROLLCLIPBOARD = @as(u32, 778);
pub const WM_SIZECLIPBOARD = @as(u32, 779);
pub const WM_ASKCBFORMATNAME = @as(u32, 780);
pub const WM_CHANGECBCHAIN = @as(u32, 781);
pub const WM_HSCROLLCLIPBOARD = @as(u32, 782);
pub const WM_QUERYNEWPALETTE = @as(u32, 783);
pub const WM_PALETTEISCHANGING = @as(u32, 784);
pub const WM_PALETTECHANGED = @as(u32, 785);
pub const WM_HOTKEY = @as(u32, 786);
pub const WM_PRINT = @as(u32, 791);
pub const WM_APPCOMMAND = @as(u32, 793);
pub const WM_THEMECHANGED = @as(u32, 794);
pub const WM_CLIPBOARDUPDATE = @as(u32, 797);
pub const WM_DWMCOMPOSITIONCHANGED = @as(u32, 798);
pub const WM_DWMNCRENDERINGCHANGED = @as(u32, 799);
pub const WM_DWMCOLORIZATIONCOLORCHANGED = @as(u32, 800);
pub const WM_DWMWINDOWMAXIMIZEDCHANGE = @as(u32, 801);
pub const WM_DWMSENDICONICTHUMBNAIL = @as(u32, 803);
pub const WM_DWMSENDICONICLIVEPREVIEWBITMAP = @as(u32, 806);
pub const WM_GETTITLEBARINFOEX = @as(u32, 831);
pub const WM_HANDHELDFIRST = @as(u32, 856);
pub const WM_HANDHELDLAST = @as(u32, 863);
pub const WM_AFXFIRST = @as(u32, 864);
pub const WM_AFXLAST = @as(u32, 895);
pub const WM_PENWINFIRST = @as(u32, 896);
pub const WM_PENWINLAST = @as(u32, 911);
pub const WM_APP = @as(u32, 32768);
pub const WM_USER = @as(u32, 1024);
pub const WMSZ_LEFT = @as(u32, 1);
pub const WMSZ_RIGHT = @as(u32, 2);
pub const WMSZ_TOP = @as(u32, 3);
pub const WMSZ_TOPLEFT = @as(u32, 4);
pub const WMSZ_TOPRIGHT = @as(u32, 5);
pub const WMSZ_BOTTOM = @as(u32, 6);
pub const WMSZ_BOTTOMLEFT = @as(u32, 7);
pub const WMSZ_BOTTOMRIGHT = @as(u32, 8);
pub const HTERROR = @as(i32, -2);
pub const HTTRANSPARENT = @as(i32, -1);
pub const HTNOWHERE = @as(u32, 0);
pub const HTCLIENT = @as(u32, 1);
pub const HTCAPTION = @as(u32, 2);
pub const HTSYSMENU = @as(u32, 3);
pub const HTGROWBOX = @as(u32, 4);
pub const HTSIZE = @as(u32, 4);
pub const HTMENU = @as(u32, 5);
pub const HTHSCROLL = @as(u32, 6);
pub const HTVSCROLL = @as(u32, 7);
pub const HTMINBUTTON = @as(u32, 8);
pub const HTMAXBUTTON = @as(u32, 9);
pub const HTLEFT = @as(u32, 10);
pub const HTRIGHT = @as(u32, 11);
pub const HTTOP = @as(u32, 12);
pub const HTTOPLEFT = @as(u32, 13);
pub const HTTOPRIGHT = @as(u32, 14);
pub const HTBOTTOM = @as(u32, 15);
pub const HTBOTTOMLEFT = @as(u32, 16);
pub const HTBOTTOMRIGHT = @as(u32, 17);
pub const HTBORDER = @as(u32, 18);
pub const HTREDUCE = @as(u32, 8);
pub const HTZOOM = @as(u32, 9);
pub const HTSIZEFIRST = @as(u32, 10);
pub const HTSIZELAST = @as(u32, 17);
pub const HTOBJECT = @as(u32, 19);
pub const HTCLOSE = @as(u32, 20);
pub const HTHELP = @as(u32, 21);
pub const MA_ACTIVATE = @as(u32, 1);
pub const MA_ACTIVATEANDEAT = @as(u32, 2);
pub const MA_NOACTIVATE = @as(u32, 3);
pub const MA_NOACTIVATEANDEAT = @as(u32, 4);
pub const ICON_SMALL = @as(u32, 0);
pub const ICON_BIG = @as(u32, 1);
pub const ICON_SMALL2 = @as(u32, 2);
pub const SIZE_RESTORED = @as(u32, 0);
pub const SIZE_MINIMIZED = @as(u32, 1);
pub const SIZE_MAXIMIZED = @as(u32, 2);
pub const SIZE_MAXSHOW = @as(u32, 3);
pub const SIZE_MAXHIDE = @as(u32, 4);
pub const SIZENORMAL = @as(u32, 0);
pub const SIZEICONIC = @as(u32, 1);
pub const SIZEFULLSCREEN = @as(u32, 2);
pub const SIZEZOOMSHOW = @as(u32, 3);
pub const SIZEZOOMHIDE = @as(u32, 4);
pub const MK_LBUTTON = @as(u32, 1);
pub const MK_RBUTTON = @as(u32, 2);
pub const MK_SHIFT = @as(u32, 4);
pub const MK_CONTROL = @as(u32, 8);
pub const MK_MBUTTON = @as(u32, 16);
pub const MK_XBUTTON1 = @as(u32, 32);
pub const MK_XBUTTON2 = @as(u32, 64);
pub const WM_MOUSEHOVER = @as(u32, 673);
pub const WM_MOUSELEAVE = @as(u32, 675);
pub const HOVER_DEFAULT = @as(u32, 4294967295);
pub const VK_LBUTTON = @as(c_int, 0x01);
pub const VK_RBUTTON = @as(c_int, 0x02);
pub const VK_CANCEL = @as(c_int, 0x03);
pub const VK_MBUTTON = @as(c_int, 0x04);
pub const VK_XBUTTON1 = @as(c_int, 0x05);
pub const VK_XBUTTON2 = @as(c_int, 0x06);
pub const VK_BACK = @as(c_int, 0x08);
pub const VK_TAB = @as(c_int, 0x09);
pub const VK_CLEAR = @as(c_int, 0x0C);
pub const VK_RETURN = @as(c_int, 0x0D);
pub const VK_SHIFT = @as(c_int, 0x10);
pub const VK_CONTROL = @as(c_int, 0x11);
pub const VK_MENU = @as(c_int, 0x12);
pub const VK_PAUSE = @as(c_int, 0x13);
pub const VK_CAPITAL = @as(c_int, 0x14);
pub const VK_KANA = @as(c_int, 0x15);
pub const VK_HANGUEL = @as(c_int, 0x15);
pub const VK_HANGUL = @as(c_int, 0x15);
pub const VK_JUNJA = @as(c_int, 0x17);
pub const VK_FINAL = @as(c_int, 0x18);
pub const VK_HANJA = @as(c_int, 0x19);
pub const VK_KANJI = @as(c_int, 0x19);
pub const VK_ESCAPE = @as(c_int, 0x1B);
pub const VK_CONVERT = @as(c_int, 0x1C);
pub const VK_NONCONVERT = @as(c_int, 0x1D);
pub const VK_ACCEPT = @as(c_int, 0x1E);
pub const VK_MODECHANGE = @as(c_int, 0x1F);
pub const VK_SPACE = @as(c_int, 0x20);
pub const VK_PRIOR = @as(c_int, 0x21);
pub const VK_NEXT = @as(c_int, 0x22);
pub const VK_END = @as(c_int, 0x23);
pub const VK_HOME = @as(c_int, 0x24);
pub const VK_LEFT = @as(c_int, 0x25);
pub const VK_UP = @as(c_int, 0x26);
pub const VK_RIGHT = @as(c_int, 0x27);
pub const VK_DOWN = @as(c_int, 0x28);
pub const VK_SELECT = @as(c_int, 0x29);
pub const VK_PRINT = @as(c_int, 0x2A);
pub const VK_EXECUTE = @as(c_int, 0x2B);
pub const VK_SNAPSHOT = @as(c_int, 0x2C);
pub const VK_INSERT = @as(c_int, 0x2D);
pub const VK_DELETE = @as(c_int, 0x2E);
pub const VK_HELP = @as(c_int, 0x2F);
pub const VK_KEY_0 = @as(c_int, 0x30);
pub const VK_KEY_1 = @as(c_int, 0x31);
pub const VK_KEY_2 = @as(c_int, 0x32);
pub const VK_KEY_3 = @as(c_int, 0x33);
pub const VK_KEY_4 = @as(c_int, 0x34);
pub const VK_KEY_5 = @as(c_int, 0x35);
pub const VK_KEY_6 = @as(c_int, 0x36);
pub const VK_KEY_7 = @as(c_int, 0x37);
pub const VK_KEY_8 = @as(c_int, 0x38);
pub const VK_KEY_9 = @as(c_int, 0x39);
pub const VK_KEY_A = @as(c_int, 0x41);
pub const VK_KEY_B = @as(c_int, 0x42);
pub const VK_KEY_C = @as(c_int, 0x43);
pub const VK_KEY_D = @as(c_int, 0x44);
pub const VK_KEY_E = @as(c_int, 0x45);
pub const VK_KEY_F = @as(c_int, 0x46);
pub const VK_KEY_G = @as(c_int, 0x47);
pub const VK_KEY_H = @as(c_int, 0x48);
pub const VK_KEY_I = @as(c_int, 0x49);
pub const VK_KEY_J = @as(c_int, 0x4A);
pub const VK_KEY_K = @as(c_int, 0x4B);
pub const VK_KEY_L = @as(c_int, 0x4C);
pub const VK_KEY_M = @as(c_int, 0x4D);
pub const VK_KEY_N = @as(c_int, 0x4E);
pub const VK_KEY_O = @as(c_int, 0x4F);
pub const VK_KEY_P = @as(c_int, 0x50);
pub const VK_KEY_Q = @as(c_int, 0x51);
pub const VK_KEY_R = @as(c_int, 0x52);
pub const VK_KEY_S = @as(c_int, 0x53);
pub const VK_KEY_T = @as(c_int, 0x54);
pub const VK_KEY_U = @as(c_int, 0x55);
pub const VK_KEY_V = @as(c_int, 0x56);
pub const VK_KEY_W = @as(c_int, 0x57);
pub const VK_KEY_X = @as(c_int, 0x58);
pub const VK_KEY_Y = @as(c_int, 0x59);
pub const VK_KEY_Z = @as(c_int, 0x5A);
pub const VK_LWIN = @as(c_int, 0x5B);
pub const VK_RWIN = @as(c_int, 0x5C);
pub const VK_APPS = @as(c_int, 0x5D);
pub const VK_SLEEP = @as(c_int, 0x5F);
pub const VK_NUMPAD0 = @as(c_int, 0x60);
pub const VK_NUMPAD1 = @as(c_int, 0x61);
pub const VK_NUMPAD2 = @as(c_int, 0x62);
pub const VK_NUMPAD3 = @as(c_int, 0x63);
pub const VK_NUMPAD4 = @as(c_int, 0x64);
pub const VK_NUMPAD5 = @as(c_int, 0x65);
pub const VK_NUMPAD6 = @as(c_int, 0x66);
pub const VK_NUMPAD7 = @as(c_int, 0x67);
pub const VK_NUMPAD8 = @as(c_int, 0x68);
pub const VK_NUMPAD9 = @as(c_int, 0x69);
pub const VK_MULTIPLY = @as(c_int, 0x6A);
pub const VK_ADD = @as(c_int, 0x6B);
pub const VK_SEPARATOR = @as(c_int, 0x6C);
pub const VK_SUBTRACT = @as(c_int, 0x6D);
pub const VK_DECIMAL = @as(c_int, 0x6E);
pub const VK_DIVIDE = @as(c_int, 0x6F);
pub const VK_F1 = @as(c_int, 0x70);
pub const VK_F2 = @as(c_int, 0x71);
pub const VK_F3 = @as(c_int, 0x72);
pub const VK_F4 = @as(c_int, 0x73);
pub const VK_F5 = @as(c_int, 0x74);
pub const VK_F6 = @as(c_int, 0x75);
pub const VK_F7 = @as(c_int, 0x76);
pub const VK_F8 = @as(c_int, 0x77);
pub const VK_F9 = @as(c_int, 0x78);
pub const VK_F10 = @as(c_int, 0x79);
pub const VK_F11 = @as(c_int, 0x7A);
pub const VK_F12 = @as(c_int, 0x7B);
pub const VK_F13 = @as(c_int, 0x7C);
pub const VK_F14 = @as(c_int, 0x7D);
pub const VK_F15 = @as(c_int, 0x7E);
pub const VK_F16 = @as(c_int, 0x7F);
pub const VK_F17 = @as(c_int, 0x80);
pub const VK_F18 = @as(c_int, 0x81);
pub const VK_F19 = @as(c_int, 0x82);
pub const VK_F20 = @as(c_int, 0x83);
pub const VK_F21 = @as(c_int, 0x84);
pub const VK_F22 = @as(c_int, 0x85);
pub const VK_F23 = @as(c_int, 0x86);
pub const VK_F24 = @as(c_int, 0x87);
pub const VK_NUMLOCK = @as(c_int, 0x90);
pub const VK_SCROLL = @as(c_int, 0x91);
pub const VK_LSHIFT = @as(c_int, 0xA0);
pub const VK_RSHIFT = @as(c_int, 0xA1);
pub const VK_LCONTROL = @as(c_int, 0xA2);
pub const VK_RCONTROL = @as(c_int, 0xA3);
pub const VK_LMENU = @as(c_int, 0xA4);
pub const VK_RMENU = @as(c_int, 0xA5);
pub const VK_BROWSER_BACK = @as(c_int, 0xA6);
pub const VK_BROWSER_FORWARD = @as(c_int, 0xA7);
pub const VK_BROWSER_REFRESH = @as(c_int, 0xA8);
pub const VK_BROWSER_STOP = @as(c_int, 0xA9);
pub const VK_BROWSER_SEARCH = @as(c_int, 0xAA);
pub const VK_BROWSER_FAVORITES = @as(c_int, 0xAB);
pub const VK_BROWSER_HOME = @as(c_int, 0xAC);
pub const VK_VOLUME_MUTE = @as(c_int, 0xAD);
pub const VK_VOLUME_DOWN = @as(c_int, 0xAE);
pub const VK_VOLUME_UP = @as(c_int, 0xAF);
pub const VK_MEDIA_NEXT_TRACK = @as(c_int, 0xB0);
pub const VK_MEDIA_PREV_TRACK = @as(c_int, 0xB1);
pub const VK_MEDIA_STOP = @as(c_int, 0xB2);
pub const VK_MEDIA_PLAY_PAUSE = @as(c_int, 0xB3);
pub const VK_LAUNCH_MAIL = @as(c_int, 0xB4);
pub const VK_MEDIA_SELECT = @as(c_int, 0xB5);
pub const VK_LAUNCH_APP1 = @as(c_int, 0xB6);
pub const VK_LAUNCH_APP2 = @as(c_int, 0xB7);
pub const VK_OEM_1 = @as(c_int, 0xBA);
pub const VK_OEM_PLUS = @as(c_int, 0xBB);
pub const VK_OEM_COMMA = @as(c_int, 0xBC);
pub const VK_OEM_MINUS = @as(c_int, 0xBD);
pub const VK_OEM_PERIOD = @as(c_int, 0xBE);
pub const VK_OEM_2 = @as(c_int, 0xBF);
pub const VK_OEM_3 = @as(c_int, 0xC0);
pub const VK_ABNT_C1 = @as(c_int, 0xC1);
pub const VK_ABNT_C2 = @as(c_int, 0xC2);
pub const VK_OEM_4 = @as(c_int, 0xDB);
pub const VK_OEM_5 = @as(c_int, 0xDC);
pub const VK_OEM_6 = @as(c_int, 0xDD);
pub const VK_OEM_7 = @as(c_int, 0xDE);
pub const VK_OEM_8 = @as(c_int, 0xDF);
pub const VK_OEM_102 = @as(c_int, 0xE2);
pub const VK_PROCESSKEY = @as(c_int, 0xE5);
pub const VK_PACKET = @as(c_int, 0xE7);
pub const VK_ATTN = @as(c_int, 0xF6);
pub const VK_CRSEL = @as(c_int, 0xF7);
pub const VK_EXSEL = @as(c_int, 0xF8);
pub const VK_EREOF = @as(c_int, 0xF9);
pub const VK_PLAY = @as(c_int, 0xFA);
pub const VK_ZOOM = @as(c_int, 0xFB);
pub const VK_NONAME = @as(c_int, 0xFC);
pub const VK_PA1 = @as(c_int, 0xFD);
pub const VK_OEM_CLEAR = @as(c_int, 0xFE);

pub const PTIMERAPCROUTINE = ?*const fn (LPVOID, DWORD, DWORD, LPARAM) callconv(.C) void;

pub const POWER_REQUEST_CONTEXT_FLAGS = enum(u32) {
    DETAILED_STRING = 2,
    SIMPLE_STRING = 1,
};

pub const REASON_CONTEXT = extern struct {
    Version: u32,
    Flags: POWER_REQUEST_CONTEXT_FLAGS,
    Reason: extern union {
        Detailed: extern struct {
            LocalizedReasonModule: ?HINSTANCE,
            LocalizedReasonId: u32,
            ReasonStringCount: u32,
            ReasonStrings: ?*?PWSTR,
        },
        SimpleReasonString: ?PWSTR,
    },
};

pub extern fn SetWaitableTimerEx(hTimer: HANDLE, lpDueTime: ?*const LARGE_INTEGER, lPeriod: i32, pfnCompletionRoutine: PTIMERAPCROUTINE, lpArgToCompletionRoutine: ?*anyopaque, WakeContext: ?*REASON_CONTEXT, TolerableDelay: u32) BOOL;

pub extern fn SetWaitableTimer(hTimer: HANDLE, lpDueTime: ?*const LARGE_INTEGER, lPeriod: i32, pfnCompletionRoutine: PTIMERAPCROUTINE, lpArgToCompletionRoutine: ?*anyopaque, fResume: BOOL) BOOL;

pub const HRAWINPUT = HANDLE;

pub const RAWINPUTHEADER = extern struct {
    dwType: u32,
    dwSize: u32,
    hDevice: HANDLE,
    wParam: WPARAM,
};

pub const RAWMOUSE = extern struct {
    usFlags: u16,
    Anonymous: extern union {
        ulButtons: u32,
        Anonymous: extern struct {
            usButtonFlags: u16,
            usButtonData: u16,
        },
    },
    ulRawButtons: u32,
    lLastX: i32,
    lLastY: i32,
    ulExtraInformation: u32,
};

pub const RAWKEYBOARD = extern struct {
    MakeCode: u16,
    Flags: u16,
    Reserved: u16,
    VKey: u16,
    Message: u32,
    ExtraInformation: u32,
};

pub const RAWHID = extern struct {
    dwSizeHid: u32,
    dwCount: u32,
    bRawData: [1]u8,
};

pub const RAWINPUT = extern struct {
    header: RAWINPUTHEADER,
    data: extern union {
        mouse: RAWMOUSE,
        keyboard: RAWKEYBOARD,
        hid: RAWHID,
    },
};

pub const RID_HEADER = 0x10000005;
pub const RID_INPUT = 0x10000003;
pub extern fn GetRawInputData(hRawInput: HRAWINPUT, uiCommand: UINT, pData: ?*anyopaque, pcbSize: ?*UINT, cbSizeHeader: UINT) UINT;
pub const TME_CANCEL = 0x80000000;
pub const TME_HOVER = 0x00000001;
pub const TME_LEAVE = 0x00000002;
pub const TME_NONCLIENT = 0x00000010;
pub const TME_QUERY = 0x40000000;

pub const TRACKMOUSEEVENT = extern struct {
    cbSize: DWORD,
    dwFlags: DWORD,
    hwndTrack: HWND,
    dwHoverTime: DWORD,
};

pub extern fn TrackMouseEvent(lpEventTrack: ?*TRACKMOUSEEVENT) BOOL;
