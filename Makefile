VERSION = 5
PATCHLEVEL = 4
SUBLEVEL = 289
#~ EXTRAVERSION =
#~ NAME = Kleptomaniac Octopus

export KERNEL_SUPPORTS_NESTED_COMPOSITES := y

PHONY := _all
_all:

ifneq ($(sub_make_done),1)

MAKEFLAGS += -rR

unexport LC_ALL
LC_COLLATE=C
LC_NUMERIC=C
export LC_COLLATE LC_NUMERIC

unexport GREP_OPTIONS

ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif

ifeq ($(filter 3.%,$(MAKE_VERSION)),)
silence:=$(findstring s,$(firstword -$(MAKEFLAGS)))
else
silence:=$(findstring s,$(filter-out --%,$(MAKEFLAGS)))
endif

ifeq ($(silence),s)
quiet=silent_
endif

export quiet Q KBUILD_VERBOSE

ifeq ("$(origin O)", "command line")
  KBUILD_OUTPUT := $(O)
endif

ifneq ($(KBUILD_OUTPUT),)
abs_objtree := $(shell mkdir -p $(KBUILD_OUTPUT) && cd $(KBUILD_OUTPUT) && pwd)
$(if $(abs_objtree),, \
     $(error failed to create output directory "$(KBUILD_OUTPUT)"))

abs_objtree := $(realpath $(abs_objtree))
else
abs_objtree := $(CURDIR)
endif # ifneq ($(KBUILD_OUTPUT),)

ifeq ($(abs_objtree),$(CURDIR))
MAKEFLAGS += --no-print-directory
else
need-sub-make := 1
endif

abs_srctree := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

ifneq ($(words $(subst :, ,$(abs_srctree))), 1)
$(error source directory cannot contain spaces or colons)
endif

ifneq ($(abs_srctree),$(abs_objtree))
MAKEFLAGS += --include-dir=$(abs_srctree)
need-sub-make := 1
endif

ifneq ($(filter 3.%,$(MAKE_VERSION)),)

need-sub-make := 1
$(lastword $(MAKEFILE_LIST)): ;
endif

export abs_srctree abs_objtree
export sub_make_done := 1

ifeq ($(need-sub-make),1)

PHONY += $(MAKECMDGOALS) sub-make

$(filter-out _all sub-make $(lastword $(MAKEFILE_LIST)), $(MAKECMDGOALS)) _all: sub-make
	@:

sub-make:
	$(Q)$(MAKE) -C $(abs_objtree) -f $(abs_srctree)/Makefile $(MAKECMDGOALS)

endif # need-sub-make
endif # sub_make_done

ifeq ($(need-sub-make),)

MAKEFLAGS += --no-print-directory

ifeq ("$(origin C)", "command line")
  KBUILD_CHECKSRC = $(C)
endif
ifndef KBUILD_CHECKSRC
  KBUILD_CHECKSRC = 0
endif

ifeq ("$(origin M)", "command line")
  KBUILD_EXTMOD := $(M)
endif

export KBUILD_CHECKSRC KBUILD_EXTMOD

extmod-prefix = $(if $(KBUILD_EXTMOD),$(KBUILD_EXTMOD)/)

ifeq ($(abs_srctree),$(abs_objtree))
        srctree := .
	building_out_of_srctree :=
else
        ifeq ($(abs_srctree)/,$(dir $(abs_objtree)))
                srctree := ..
        else
                srctree := $(abs_srctree)
        endif
	building_out_of_srctree := 1
endif

ifneq ($(KBUILD_ABS_SRCTREE),)
srctree := $(abs_srctree)
endif

objtree		:= .
VPATH		:= $(srctree)

export building_out_of_srctree srctree objtree VPATH

version_h := include/generated/uapi/linux/version.h
old_version_h := include/linux/version.h

clean-targets := %clean mrproper cleandocs
no-dot-config-targets := $(clean-targets) \
			 cscope gtags TAGS tags help% %docs check% coccicheck \
			 $(version_h) headers headers_% archheaders archscripts \
			 %asm-generic kernelversion %src-pkg
no-sync-config-targets := $(no-dot-config-targets) install %install \
			   kernelrelease
single-targets := %.a %.i %.ko %.lds %.ll %.lst %.mod %.o %.s %.symtypes %/

config-build	:=
mixed-build	:=
need-config	:= 1
may-sync-config	:= 1
single-build	:=

ifneq ($(filter $(no-dot-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-dot-config-targets), $(MAKECMDGOALS)),)
		need-config :=
	endif
endif

ifneq ($(filter $(no-sync-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-sync-config-targets), $(MAKECMDGOALS)),)
		may-sync-config :=
	endif
endif

ifneq ($(KBUILD_EXTMOD),)
	may-sync-config :=
endif

ifeq ($(KBUILD_EXTMOD),)
        ifneq ($(filter config %config,$(MAKECMDGOALS)),)
		config-build := 1
                ifneq ($(words $(MAKECMDGOALS)),1)
			mixed-build := 1
                endif
        endif
endif

ifneq ($(filter $(single-targets), $(MAKECMDGOALS)),)
	single-build := 1
	ifneq ($(filter-out $(single-targets), $(MAKECMDGOALS)),)
		mixed-build := 1
	endif
endif

ifneq ($(filter $(clean-targets),$(MAKECMDGOALS)),)
        ifneq ($(filter-out $(clean-targets),$(MAKECMDGOALS)),)
		mixed-build := 1
        endif
endif

ifneq ($(filter install,$(MAKECMDGOALS)),)
        ifneq ($(filter modules_install,$(MAKECMDGOALS)),)
		mixed-build := 1
        endif
endif

ifdef mixed-build
PHONY += $(MAKECMDGOALS) __build_one_by_one

$(filter-out __build_one_by_one, $(MAKECMDGOALS)): __build_one_by_one
	@:

__build_one_by_one:
	$(Q)set -e; \
	for i in $(MAKECMDGOALS); do \
		$(MAKE) -f $(srctree)/Makefile $$i; \
	done

else

include scripts/Kbuild.include

KERNELRELEASE = $(shell cat include/config/kernel.release 2> /dev/null)
KERNELVERSION = $(VERSION)$(if $(PATCHLEVEL),.$(PATCHLEVEL)$(if $(SUBLEVEL),.$(SUBLEVEL)))$(EXTRAVERSION)
export VERSION PATCHLEVEL SUBLEVEL KERNELRELEASE KERNELVERSION

include scripts/subarch.include

ARCH		?= arm64
UTS_MACHINE 	:= arm64
SRCARCH 	:= arm64

KCONFIG_CONFIG	?= .config
export KCONFIG_CONFIG

CONFIG_SHELL := sh

HOST_LFS_CFLAGS := $(shell getconf LFS_CFLAGS 2>/dev/null)
HOST_LFS_LDFLAGS := $(shell getconf LFS_LDFLAGS 2>/dev/null)
HOST_LFS_LIBS := $(shell getconf LFS_LIBS 2>/dev/null)

ifneq ($(LLVM),)
HOSTCC	= clang
HOSTCXX	= clang++
else
HOSTCC	= gcc
HOSTCXX	= g++
endif

KBUILD_HOSTCFLAGS   := -Wall -Wmissing-prototypes -Wstrict-prototypes -Wno-deprecated-declarations -O2 \
		-fomit-frame-pointer -std=gnu89 $(HOST_LFS_CFLAGS) \
		$(HOSTCFLAGS)
KBUILD_HOSTCXXFLAGS := -O2 $(HOST_LFS_CFLAGS) $(HOSTCXXFLAGS)
KBUILD_HOSTLDFLAGS  := $(HOST_LFS_LDFLAGS) $(HOSTLDFLAGS)
KBUILD_HOSTLDLIBS   := $(HOST_LFS_LIBS) $(HOSTLDLIBS)

CPP		= $(CC) -E

ifneq ($(LLVM),)
CC	= clang
LD		= ld.lld
AR		= llvm-ar
NM		= llvm-nm
OBJCOPY		= llvm-objcopy
OBJDUMP		= llvm-objdump
READELF		= llvm-readelf
OBJSIZE		= llvm-size
STRIP		= llvm-strip
else
CC		= $(CROSS_COMPILE)gcc
LD		= $(CROSS_COMPILE)ld
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
OBJCOPY		= $(CROSS_COMPILE)objcopy
OBJDUMP		= $(CROSS_COMPILE)objdump
READELF		= $(CROSS_COMPILE)readelf
OBJSIZE		= $(CROSS_COMPILE)size
STRIP		= $(CROSS_COMPILE)strip
endif

PAHOLE		= pahole
LEX		= flex
YACC		= bison
AWK		= awk
INSTALLKERNEL  := installkernel
DEPMOD		= depmod
PERL		= perl
PYTHON		= python
PYTHON3		= python3
CHECK		= sparse
BASH		= bash
KGZIP		= gzip
KBZIP2		= bzip2
KLZOP		= lzop
LZMA		= lzma
LZ4		= lz4c
XZ		= xz

CHECKFLAGS     := -D__linux__ -Dlinux -D__STDC__ -Dunix -D__unix__ \
		  -Wbitwise -Wno-return-void -Wno-unknown-attribute $(CF)
NOSTDINC_FLAGS :=
CFLAGS_MODULE   =
AFLAGS_MODULE   =
LDFLAGS_MODULE  =
CFLAGS_KERNEL	=
AFLAGS_KERNEL	=
LDFLAGS_vmlinux =

USERINCLUDE    := \
		-I$(srctree)/arch/arm64/include/uapi \
		-I$(objtree)/arch/arm64/include/generated/uapi \
		-I$(srctree)/include/uapi \
		-I$(objtree)/include/generated/uapi \
                -include $(srctree)/include/linux/kconfig.h

LINUXINCLUDE    := \
		-I$(srctree)/arch/arm64/include \
		-I$(objtree)/arch/arm64/include/generated \
		$(if $(building_out_of_srctree),-I$(srctree)/include) \
		-I$(objtree)/include \
		$(USERINCLUDE)

KBUILD_AFLAGS   := -D__ASSEMBLY__ -fno-PIE
KBUILD_CFLAGS   := -Wall -Wundef -Wno-trigraphs \
		   -fno-strict-aliasing -fno-common -fshort-wchar -fno-PIE \
#~ 		   -Werror=implicit-function-declaration -Werror=implicit-int \
#~ 		   -Werror=return-type -Wno-format-security \
		   -std=gnu89
KBUILD_CPPFLAGS := -D__KERNEL__
KBUILD_AFLAGS_KERNEL :=
KBUILD_CFLAGS_KERNEL :=
KBUILD_AFLAGS_MODULE  := -DMODULE
KBUILD_CFLAGS_MODULE  := -DMODULE
KBUILD_LDFLAGS_MODULE :=
export KBUILD_LDS_MODULE := $(srctree)/scripts/module-common.lds
KBUILD_LDFLAGS :=
GCC_PLUGINS_CFLAGS :=
CLANG_FLAGS :=

CC := scripts/basic/cc-wrapper $(CC)

export ARCH SRCARCH CONFIG_SHELL BASH HOSTCC KBUILD_HOSTCFLAGS CROSS_COMPILE LD CC
export CPP AR NM STRIP OBJCOPY OBJDUMP OBJSIZE READELF PAHOLE LEX YACC AWK INSTALLKERNEL
export PERL PYTHON PYTHON3 CHECK CHECKFLAGS MAKE UTS_MACHINE HOSTCXX
export KGZIP KBZIP2 KLZOP LZMA LZ4 XZ
export KBUILD_HOSTCXXFLAGS KBUILD_HOSTLDFLAGS KBUILD_HOSTLDLIBS LDFLAGS_MODULE

export KBUILD_CPPFLAGS NOSTDINC_FLAGS LINUXINCLUDE OBJCOPYFLAGS KBUILD_LDFLAGS
export KBUILD_CFLAGS CFLAGS_KERNEL CFLAGS_MODULE
export CFLAGS_KASAN CFLAGS_KASAN_NOSANITIZE CFLAGS_UBSAN
export KBUILD_AFLAGS AFLAGS_KERNEL AFLAGS_MODULE
export KBUILD_AFLAGS_MODULE KBUILD_CFLAGS_MODULE KBUILD_LDFLAGS_MODULE
export KBUILD_AFLAGS_KERNEL KBUILD_CFLAGS_KERNEL

export RCS_FIND_IGNORE := \( -name SCCS -o -name BitKeeper -o -name .svn -o    \
			  -name CVS -o -name .pc -o -name .hg -o -name .git \) \
			  -prune -o
export RCS_TAR_IGNORE := --exclude SCCS --exclude BitKeeper --exclude .svn \
			 --exclude CVS --exclude .pc --exclude .hg --exclude .git

KBUILD_CFLAGS	+= $(call cc-option,-Wno-misleading-indentation)

PHONY += scripts_basic
scripts_basic:
	$(Q)$(MAKE) $(build)=scripts/basic
	$(Q)rm -f .tmp_quiet_recordmcount

PHONY += outputmakefile

outputmakefile:
ifdef building_out_of_srctree
	$(Q)if [ -f $(srctree)/.config -o \
		 -d $(srctree)/include/config -o \
		 -d $(srctree)/arch/arm64/include/generated ]; then \
		echo >&2 "***"; \
		echo >&2 "*** The source tree is not clean, please run 'make$(if $(findstring command line, $(origin ARCH)), ARCH=$(ARCH)) mrproper'"; \
		echo >&2 "*** in $(abs_srctree)";\
		echo >&2 "***"; \
		false; \
	fi
	$(Q)ln -fsn $(srctree) source
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/mkmakefile $(srctree)
	$(Q)test -e .gitignore || \
	{ echo "# this is build directory, ignore it"; echo "*"; } > .gitignore
endif

ifneq ($(shell $(CC) --version 2>&1 | grep clang),)
ifneq ($(CROSS_COMPILE),)
CLANG_TRIPLE	?= $(CROSS_COMPILE)
CLANG_FLAGS	+= --target=$(notdir $(CLANG_TRIPLE:%-=%))
ifeq ($(shell $(srctree)/scripts/clang-android.sh $(CC) $(CLANG_FLAGS)), y)
$(error "Clang with Android --target detected. Did you specify CLANG_TRIPLE?")
endif
GCC_TOOLCHAIN_DIR := $(dir $(shell which $(CROSS_COMPILE)elfedit))
CLANG_FLAGS	+= --prefix=$(GCC_TOOLCHAIN_DIR)$(notdir $(CROSS_COMPILE))
GCC_TOOLCHAIN	:= $(realpath $(GCC_TOOLCHAIN_DIR)/..)
endif
ifneq ($(GCC_TOOLCHAIN),)
CLANG_FLAGS	+= --gcc-toolchain=$(GCC_TOOLCHAIN)
endif
ifneq ($(LLVM_IAS),1)
CLANG_FLAGS	+= -no-integrated-as
endif
#~ CLANG_FLAGS	+= -Werror=unknown-warning-option
KBUILD_CFLAGS	+= $(CLANG_FLAGS)
KBUILD_AFLAGS	+= $(CLANG_FLAGS)
export CLANG_FLAGS
endif

CC_VERSION_TEXT = $(shell $(CC) --version 2>/dev/null | head -n 1)

ifdef config-build
include arch/arm64/Makefile
export KBUILD_DEFCONFIG KBUILD_KCONFIG CC_VERSION_TEXT

config: outputmakefile scripts_basic FORCE
	$(Q)$(MAKE) $(build)=scripts/kconfig $@

%config: outputmakefile scripts_basic FORCE
	$(Q)$(MAKE) $(build)=scripts/kconfig $@

else
PHONY += all
ifeq ($(KBUILD_EXTMOD),)
_all: all
else
_all: modules
endif

KBUILD_MODULES :=
KBUILD_BUILTIN := 1

ifeq ($(MAKECMDGOALS),modules)
  KBUILD_BUILTIN :=
endif

ifneq ($(filter all _all modules nsdeps,$(MAKECMDGOALS)),)
  KBUILD_MODULES := 1
endif

ifeq ($(MAKECMDGOALS),)
  KBUILD_MODULES := 1
endif

export KBUILD_MODULES KBUILD_BUILTIN

ifdef need-config
include include/config/auto.conf
endif

ifeq ($(KBUILD_EXTMOD),)
init-y		:= init/
drivers-y	:= drivers/ sound/ techpack/
drivers-$(CONFIG_SAMPLES) += samples/
net-y		:= net/
libs-y		:= lib/
core-y		:= usr/
virt-y		:= virt/
endif # KBUILD_EXTMOD

all: vmlinux

CFLAGS_GCOV	:= -fprofile-arcs -ftest-coverage \
	$(call cc-option,-fno-tree-loop-im) \
	$(call cc-disable-warning,maybe-uninitialized,)
export CFLAGS_GCOV

ifdef CONFIG_FUNCTION_TRACER
  CC_FLAGS_FTRACE := -pg
endif

RETPOLINE_CFLAGS_GCC := -mindirect-branch=thunk-extern -mindirect-branch-register
RETPOLINE_VDSO_CFLAGS_GCC := -mindirect-branch=thunk-inline -mindirect-branch-register
RETPOLINE_CFLAGS_CLANG := -mretpoline-external-thunk
RETPOLINE_VDSO_CFLAGS_CLANG := -mretpoline
RETPOLINE_CFLAGS := $(call cc-option,$(RETPOLINE_CFLAGS_GCC),$(call cc-option,$(RETPOLINE_CFLAGS_CLANG)))
RETPOLINE_VDSO_CFLAGS := $(call cc-option,$(RETPOLINE_VDSO_CFLAGS_GCC),$(call cc-option,$(RETPOLINE_VDSO_CFLAGS_CLANG)))
export RETPOLINE_CFLAGS
export RETPOLINE_VDSO_CFLAGS

ifdef CONFIG_LTO_CLANG
AR		:= llvm-ar
LLVM_NM		:= llvm-nm
export LLVM_NM
LDFLAGS		+= --plugin-opt=O3
endif

include arch/arm64/Makefile

ifdef need-config
ifdef may-sync-config
include include/config/auto.conf.cmd

#~ $(KCONFIG_CONFIG):
#~ 	@echo >&2 '***'
#~ 	@echo >&2 '*** Configuration file "$@" not found!'
#~ 	@echo >&2 '***'
#~ 	@echo >&2 '*** Please run some configurator (e.g. "make oldconfig" or'
#~ 	@echo >&2 '*** "make menuconfig" or "make xconfig").'
#~ 	@echo >&2 '***'
#~ 	@/bin/false

%/auto.conf %/auto.conf.cmd %/tristate.conf: $(KCONFIG_CONFIG)
	$(Q)$(MAKE) -f $(srctree)/Makefile syncconfig
else
PHONY += include/config/auto.conf

include/config/auto.conf:
	$(Q)test -e include/generated/autoconf.h -a -e $@ || (		\
	echo >&2;							\
	echo >&2 "  ERROR: Kernel configuration is invalid.";		\
	echo >&2 "         include/generated/autoconf.h or $@ are missing.";\
	echo >&2 "         Run 'make oldconfig && make prepare' on kernel src to fix it.";	\
	echo >&2 ;							\
	/bin/false)

endif
endif

KBUILD_CFLAGS	+= $(call cc-option,-fno-delete-null-pointer-checks,)
KBUILD_CFLAGS	+= $(call cc-disable-warning,frame-address,)
KBUILD_CFLAGS	+= $(call cc-disable-warning, format-truncation)
KBUILD_CFLAGS	+= $(call cc-disable-warning, format-overflow)
KBUILD_CFLAGS	+= $(call cc-disable-warning, address-of-packed-member)

ifdef CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE
KBUILD_CFLAGS += -O2
else ifdef CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3
KBUILD_CFLAGS += -O3
else ifdef CONFIG_CC_OPTIMIZE_FOR_SIZE
KBUILD_CFLAGS += -Os
endif

KBUILD_CFLAGS	+= $(call cc-option,--param=allow-store-data-races=0)
KBUILD_CFLAGS	+= $(call cc-option,-fno-allow-store-data-races)

include scripts/Makefile.kcov
include scripts/Makefile.gcc-plugins

ifdef CONFIG_READABLE_ASM
KBUILD_CFLAGS += $(call cc-option,-fno-reorder-blocks,) \
                 $(call cc-option,-fno-ipa-cp-clone,) \
                 $(call cc-option,-fno-partial-inlining)
endif

ifneq ($(CONFIG_FRAME_WARN),0)
KBUILD_CFLAGS += $(call cc-option,-Wframe-larger-than=${CONFIG_FRAME_WARN})
endif

stackp-flags-$(CONFIG_CC_HAS_STACKPROTECTOR_NONE) := -fno-stack-protector
stackp-flags-$(CONFIG_STACKPROTECTOR)             := -fstack-protector
stackp-flags-$(CONFIG_STACKPROTECTOR_STRONG)      := -fstack-protector-strong

KBUILD_CFLAGS += $(stackp-flags-y)

ifdef CONFIG_CC_IS_CLANG
KBUILD_CPPFLAGS += -Qunused-arguments
KBUILD_CFLAGS += -Wno-format-invalid-specifier
KBUILD_CFLAGS += -Wno-gnu
KBUILD_CFLAGS += -Wno-tautological-compare
KBUILD_CFLAGS += -mno-global-merge
KBUILD_CFLAGS += $(call cc-disable-warning, undefined-optimized)
KBUILD_CFLAGS += -fno-builtin
KBUILD_CFLAGS += $(call cc-disable-warning, void-ptr-dereference)
else
KBUILD_CFLAGS += $(call cc-option,-Wimplicit-fallthrough,)
endif

KBUILD_CFLAGS += $(call cc-disable-warning, unused-but-set-variable)
KBUILD_CFLAGS += $(call cc-disable-warning, unused-const-variable)
KBUILD_CFLAGS += $(call cc-disable-warning, dangling-pointer)

ifdef CONFIG_FRAME_POINTER
KBUILD_CFLAGS	+= -fno-omit-frame-pointer -fno-optimize-sibling-calls
else

ifndef CONFIG_FUNCTION_TRACER
KBUILD_CFLAGS	+= -fomit-frame-pointer
endif
endif

ifdef CONFIG_INIT_STACK_ALL_PATTERN
KBUILD_CFLAGS	+= -ftrivial-auto-var-init=pattern
endif

ifdef CONFIG_INIT_STACK_ALL_ZERO
KBUILD_CFLAGS	+= -ftrivial-auto-var-init=zero
ifdef CONFIG_CC_HAS_AUTO_VAR_INIT_ZERO_ENABLER
KBUILD_CFLAGS	+= -enable-trivial-auto-var-init-zero-knowing-it-will-be-removed-from-clang
endif
endif

DEBUG_CFLAGS	:= $(call cc-option, -fno-var-tracking-assignments)

ifdef CONFIG_DEBUG_INFO
ifdef CONFIG_DEBUG_INFO_SPLIT
DEBUG_CFLAGS	+= -gsplit-dwarf
else
DEBUG_CFLAGS	+= -g
endif
ifeq ($(LLVM_IAS),1)
KBUILD_AFLAGS	+= -g
else
KBUILD_AFLAGS	+= -Wa,-gdwarf-2
endif
endif

ifdef CONFIG_DEBUG_INFO_DWARF4
DEBUG_CFLAGS	+= -gdwarf-4
endif

ifdef CONFIG_DEBUG_INFO_REDUCED
DEBUG_CFLAGS	+= $(call cc-option, -femit-struct-debug-baseonly) \
		   $(call cc-option,-fno-var-tracking)
endif

KBUILD_CFLAGS += $(DEBUG_CFLAGS)
export DEBUG_CFLAGS

ifdef CONFIG_FUNCTION_TRACER
ifdef CONFIG_FTRACE_MCOUNT_RECORD
  ifeq ($(call cc-option-yn,-mrecord-mcount),y)
    CC_FLAGS_FTRACE	+= -mrecord-mcount
    export CC_USING_RECORD_MCOUNT := 1
  endif
  ifdef CONFIG_HAVE_NOP_MCOUNT
    ifeq ($(call cc-option-yn, -mnop-mcount),y)
      CC_FLAGS_FTRACE	+= -mnop-mcount
      CC_FLAGS_USING	+= -DCC_USING_NOP_MCOUNT
    endif
  endif
endif
ifdef CONFIG_HAVE_FENTRY
  ifeq ($(call cc-option-yn, -mfentry),y)
    CC_FLAGS_FTRACE	+= -mfentry
    CC_FLAGS_USING	+= -DCC_USING_FENTRY
  endif
endif
export CC_FLAGS_FTRACE
KBUILD_CFLAGS	+= $(CC_FLAGS_FTRACE) $(CC_FLAGS_USING)
KBUILD_AFLAGS	+= $(CC_FLAGS_USING)
ifdef CONFIG_DYNAMIC_FTRACE
	ifdef CONFIG_HAVE_C_RECORDMCOUNT
		BUILD_C_RECORDMCOUNT := y
		export BUILD_C_RECORDMCOUNT
	endif
endif
endif

ifdef CONFIG_DEBUG_SECTION_MISMATCH
KBUILD_CFLAGS += $(call cc-option, -fno-inline-functions-called-once)
endif

ifdef CONFIG_LD_DEAD_CODE_DATA_ELIMINATION
KBUILD_CFLAGS_KERNEL += -ffunction-sections -fdata-sections
LDFLAGS_vmlinux += --gc-sections
endif

ifdef CONFIG_LIVEPATCH
KBUILD_CFLAGS += $(call cc-option, -flive-patching=inline-clone)
endif

ifdef CONFIG_SHADOW_CALL_STACK
CC_FLAGS_SCS	:= -fsanitize=shadow-call-stack
KBUILD_CFLAGS	+= $(CC_FLAGS_SCS)
export CC_FLAGS_SCS
endif

ifdef CONFIG_LTO_CLANG
ifdef CONFIG_THINLTO
CC_FLAGS_LTO_CLANG := -flto=thin $(call cc-option, -fsplit-lto-unit)
KBUILD_LDFLAGS	+= --thinlto-cache-dir=.thinlto-cache
else
CC_FLAGS_LTO_CLANG := -flto
endif
ifdef CONFIG_LD_IS_LLD
KBUILD_LDFLAGS += --lto-O3
endif
CC_FLAGS_LTO_CLANG += -fvisibility=default

LD_FLAGS_LTO_CLANG := -mllvm -import-instr-limit=5

KBUILD_LDFLAGS += $(LD_FLAGS_LTO_CLANG)
KBUILD_LDFLAGS_MODULE += $(LD_FLAGS_LTO_CLANG)

KBUILD_LDS_MODULE += $(srctree)/scripts/module-lto.lds
endif

ifdef CONFIG_LTO
CC_FLAGS_LTO	:= $(CC_FLAGS_LTO_CLANG)
KBUILD_CFLAGS	+= $(CC_FLAGS_LTO)
export CC_FLAGS_LTO
endif

ifdef CONFIG_CFI_CLANG
CC_FLAGS_CFI	:= -fsanitize=cfi \
		   -fno-sanitize-cfi-canonical-jump-tables \
		   -fno-sanitize-blacklist

ifdef CONFIG_MODULES
CC_FLAGS_CFI	+= -fsanitize-cfi-cross-dso
endif

ifdef CONFIG_CFI_PERMISSIVE
CC_FLAGS_CFI	+= -fsanitize-recover=cfi \
		   -fno-sanitize-trap=cfi
endif

CC_FLAGS_LTO	+= $(CC_FLAGS_CFI)
KBUILD_CFLAGS	+= $(CC_FLAGS_CFI)
export CC_FLAGS_CFI
endif

NOSTDINC_FLAGS += -nostdinc -isystem $(shell $(CC) -print-file-name=include)

KBUILD_CFLAGS += -Wdeclaration-after-statement
KBUILD_CFLAGS += -Wvla
KBUILD_CFLAGS += -Wno-pointer-sign
KBUILD_CFLAGS += $(call cc-disable-warning, stringop-truncation)

KBUILD_CFLAGS += $(call cc-disable-warning, zero-length-bounds)
KBUILD_CFLAGS += $(call cc-disable-warning, array-bounds)
KBUILD_CFLAGS += $(call cc-disable-warning, stringop-overflow)

KBUILD_CFLAGS += $(call cc-disable-warning, restrict)
KBUILD_CFLAGS += $(call cc-disable-warning, maybe-uninitialized)
KBUILD_CFLAGS	+= $(call cc-option,-fno-strict-overflow)
KBUILD_CFLAGS	+= $(call cc-option,-fno-merge-all-constants)
KBUILD_CFLAGS	+= $(call cc-option,-fmerge-constants)
KBUILD_CFLAGS  += $(call cc-option,-fno-stack-check,)
KBUILD_CFLAGS   += $(call cc-option,-fconserve-stack)
KBUILD_CFLAGS	+= $(call cc-option,-fmacro-prefix-map=$(srctree)/=)

include scripts/Makefile.kasan
include scripts/Makefile.extrawarn
include scripts/Makefile.ubsan

KBUILD_CPPFLAGS += $(KCPPFLAGS)
KBUILD_AFLAGS   += $(KAFLAGS)
KBUILD_CFLAGS   += $(KCFLAGS)

KBUILD_LDFLAGS_MODULE += --build-id
LDFLAGS_vmlinux += --build-id

KBUILD_LDFLAGS	+= -z noexecstack
KBUILD_LDFLAGS	+= $(call ld-option,--no-warn-rwx-segments)

ifeq ($(CONFIG_STRIP_ASM_SYMS),y)
LDFLAGS_vmlinux	+= $(call ld-option, -X,)
endif

ifeq ($(CONFIG_RELR),y)
LDFLAGS_vmlinux	+= --pack-dyn-relocs=relr --use-android-relr-tags
endif

CHECKFLAGS += --arch=arm64

CHECKFLAGS += $(if $(CONFIG_CPU_BIG_ENDIAN),-mbig-endian,-mlittle-endian)

CHECKFLAGS += $(if $(CONFIG_64BIT),-m64,-m32)

export KBUILD_IMAGE ?= vmlinux
#~ export	INSTALL_PATH ?= /boot
#~ export INSTALL_DTBS_PATH ?= $(INSTALL_PATH)/dtbs/$(KERNELRELEASE)

MODLIB	= $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)
export MODLIB

ifdef INSTALL_MOD_STRIP
ifeq ($(INSTALL_MOD_STRIP),1)
mod_strip_cmd = $(STRIP) --strip-debug
else
mod_strip_cmd = $(STRIP) $(INSTALL_MOD_STRIP)
endif # INSTALL_MOD_STRIP=1
else
mod_strip_cmd = true
endif # INSTALL_MOD_STRIP
export mod_strip_cmd

mod_compress_cmd = true
ifdef CONFIG_MODULE_COMPRESS
  ifdef CONFIG_MODULE_COMPRESS_GZIP
    mod_compress_cmd = $(KGZIP) -n -f
  endif # CONFIG_MODULE_COMPRESS_GZIP
  ifdef CONFIG_MODULE_COMPRESS_XZ
    mod_compress_cmd = $(XZ) -f
  endif # CONFIG_MODULE_COMPRESS_XZ
endif # CONFIG_MODULE_COMPRESS
export mod_compress_cmd

ifdef CONFIG_MODULE_SIG_ALL
$(eval $(call config_filename,MODULE_SIG_KEY))

mod_sign_cmd = scripts/sign-file $(CONFIG_MODULE_SIG_HASH) $(MODULE_SIG_KEY_SRCPREFIX)$(CONFIG_MODULE_SIG_KEY) certs/signing_key.x509
else
mod_sign_cmd = true
endif
export mod_sign_cmd

HOST_LIBELF_LIBS = $(shell pkg-config libelf --libs 2>/dev/null || echo -lelf)

ifdef CONFIG_STACK_VALIDATION
  has_libelf := $(call try-run,\
		echo "int main() {}" | $(HOSTCC) $(KBUILD_HOSTLDFLAGS) -xc -o /dev/null $(HOST_LIBELF_LIBS) -,1,0)
  ifeq ($(has_libelf),1)
    objtool_target := tools/objtool FORCE
  else
    SKIP_STACK_VALIDATION := 1
    export SKIP_STACK_VALIDATION
  endif
endif

PHONY += prepare0

export MODORDER := $(extmod-prefix)modules.order

ifeq ($(KBUILD_EXTMOD),)
core-y		+= kernel/ certs/ mm/ fs/ ipc/ security/ crypto/ block/

vmlinux-dirs	:= $(patsubst %/,%,$(filter %/, $(init-y) $(init-m) \
		     $(core-y) $(core-m) $(drivers-y) $(drivers-m) \
		     $(net-y) $(net-m) $(libs-y) $(libs-m) $(virt-y)))

vmlinux-alldirs	:= $(sort $(vmlinux-dirs) \
		     $(patsubst %/,%,$(filter %/, $(init-) $(core-) \
			$(drivers-) $(net-) $(libs-) $(virt-))))

build-dirs	:= $(vmlinux-dirs)
clean-dirs	:= $(vmlinux-alldirs)

init-y		:= $(patsubst %/, %/built-in.a, $(init-y))
core-y		:= $(patsubst %/, %/built-in.a, $(core-y))
drivers-y	:= $(patsubst %/, %/built-in.a, $(drivers-y))
net-y		:= $(patsubst %/, %/built-in.a, $(net-y))
libs-y1		:= $(patsubst %/, %/lib.a, $(libs-y))
libs-y2		:= $(patsubst %/, %/built-in.a, $(filter-out %.a, $(libs-y)))
virt-y		:= $(patsubst %/, %/built-in.a, $(virt-y))

export KBUILD_VMLINUX_OBJS := $(head-y) $(init-y) $(core-y) $(libs-y2) \
			      $(drivers-y) $(net-y) $(virt-y)
export KBUILD_VMLINUX_LIBS := $(libs-y1)
export KBUILD_LDS          := arch/arm64/kernel/vmlinux.lds
export LDFLAGS_vmlinux
export KBUILD_ALLDIRS := $(sort $(filter-out arch/%,$(vmlinux-alldirs)) LICENSES arch include scripts tools)

vmlinux-deps := $(KBUILD_LDS) $(KBUILD_VMLINUX_OBJS) $(KBUILD_VMLINUX_LIBS)

PHONY += autoksyms_recursive
ifdef CONFIG_TRIM_UNUSED_KSYMS
autoksyms_recursive: descend modules.order
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/adjust_autoksyms.sh \
	  "$(MAKE) -f $(srctree)/Makefile autoksyms_recursive"
endif

ifdef CONFIG_TRIM_UNUSED_KSYMS
  KBUILD_MODULES := 1
endif

autoksyms_h := $(if $(CONFIG_TRIM_UNUSED_KSYMS), include/generated/autoksyms.h)

quiet_cmd_autoksyms_h = GEN     $@
      cmd_autoksyms_h = mkdir -p $(dir $@); \
			$(CONFIG_SHELL) $(srctree)/scripts/gen_autoksyms.sh $@

$(autoksyms_h):
	$(call cmd,autoksyms_h)

ARCH_POSTLINK := $(wildcard $(srctree)/arch/arm64/Makefile.postlink)

cmd_link-vmlinux =                                                 \
	$(CONFIG_SHELL) $< $(LD) $(KBUILD_LDFLAGS) $(LDFLAGS_vmlinux) ;    \
	$(if $(ARCH_POSTLINK), $(MAKE) -f $(ARCH_POSTLINK) $@, true)

vmlinux: scripts/link-vmlinux.sh autoksyms_recursive $(vmlinux-deps) FORCE
	+$(call if_changed,link-vmlinux)

targets := vmlinux

$(sort $(vmlinux-deps)): descend ;

filechk_kernel.release = \
	echo "$(KERNELVERSION)$$($(CONFIG_SHELL) $(srctree)/scripts/setlocalversion \
		$(srctree) $(BRANCH) $(KMI_GENERATION))"

include/config/kernel.release: FORCE
	$(call filechk,kernel.release)

PHONY += scripts
scripts: scripts_basic scripts_dtc
	$(Q)$(MAKE) $(build)=$(@)

PHONY += prepare archprepare

archprepare: outputmakefile archheaders archscripts scripts include/config/kernel.release \
	asm-generic $(version_h) $(autoksyms_h) include/generated/utsrelease.h

prepare0: archprepare
	$(Q)$(MAKE) $(build)=scripts/mod
	$(Q)$(MAKE) $(build)=.

prepare: prepare0 prepare-objtool

asm-generic := -f $(srctree)/scripts/Makefile.asm-generic obj

PHONY += asm-generic uapi-asm-generic
asm-generic: uapi-asm-generic
	$(Q)$(MAKE) $(asm-generic)=arch/arm64/include/generated/asm \
	generic=include/asm-generic
uapi-asm-generic:
	$(Q)$(MAKE) $(asm-generic)=arch/arm64/include/generated/uapi/asm \
	generic=include/uapi/asm-generic

PHONY += prepare-objtool
prepare-objtool: $(objtool_target)
ifeq ($(SKIP_STACK_VALIDATION),1)
ifdef CONFIG_UNWINDER_ORC
	@echo "error: Cannot generate ORC metadata for CONFIG_UNWINDER_ORC=y, please install libelf-dev, libelf-devel or elfutils-libelf-devel" >&2
	@false
else
	@echo "warning: Cannot use CONFIG_STACK_VALIDATION=y, please install libelf-dev, libelf-devel or elfutils-libelf-devel" >&2
endif
endif

uts_len := 128
ifneq (,$(BUILD_NUMBER))
	UTS_RELEASE=$(KERNELRELEASE)-ab$(BUILD_NUMBER)
else
	UTS_RELEASE=$(KERNELRELEASE)
endif
define filechk_utsrelease.h
	if [ `echo -n "$(UTS_RELEASE)" | wc -c ` -gt $(uts_len) ]; then \
		echo '"$(UTS_RELEASE)" exceeds $(uts_len) characters' >&2;    \
		exit 1;                                                       \
	fi;                                                             \
	echo \#define UTS_RELEASE \"$(UTS_RELEASE)\"
endef

define filechk_version.h
	if [ $(SUBLEVEL) -gt 255 ]; then                                 \
		echo \#define LINUX_VERSION_CODE $(shell                 \
		expr $(VERSION) \* 65536 + $(PATCHLEVEL) \* 256 + 255); \
	else                                                             \
		echo \#define LINUX_VERSION_CODE $(shell                 \
		expr $(VERSION) \* 65536 + $(PATCHLEVEL) \* 256 + $(SUBLEVEL)); \
	fi;                                                              \
	echo '#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) +  \
	((c) > 255 ? 255 : (c)))'
endef

$(version_h): PATCHLEVEL := $(if $(PATCHLEVEL), $(PATCHLEVEL), 0)
$(version_h): SUBLEVEL := $(if $(SUBLEVEL), $(SUBLEVEL), 0)
$(version_h): FORCE
	$(call filechk,version.h)
	$(Q)rm -f $(old_version_h)

include/generated/utsrelease.h: include/config/kernel.release FORCE
	$(call filechk,utsrelease.h)

PHONY += headerdep
headerdep:
	$(Q)find $(srctree)/include/ -name '*.h' | xargs --max-args 1 \
	$(srctree)/scripts/headerdep.pl -I$(srctree)/include

export INSTALL_HDR_PATH = $(objtree)/usr

quiet_cmd_headers_install = INSTALL $(INSTALL_HDR_PATH)/include
      cmd_headers_install = \
	mkdir -p $(INSTALL_HDR_PATH); \
	rsync -mrl --include='*/' --include='*\.h' --exclude='*' \
	usr/include $(INSTALL_HDR_PATH)

PHONY += headers_install
headers_install: headers
	$(call cmd,headers_install)

PHONY += archheaders archscripts

hdr-inst := -f $(srctree)/scripts/Makefile.headersinst obj

techpack-dirs := $(shell find $(srctree)/techpack -maxdepth 1 -mindepth 1 -type d -not -name ".*")
techpack-dirs := $(subst $(srctree)/,,$(techpack-dirs))

PHONY += headers
headers: $(version_h) scripts_unifdef uapi-asm-generic archheaders archscripts
	$(if $(wildcard $(srctree)/arch/arm64/include/uapi/asm/Kbuild),, \
	  $(error Headers not exportable for the arm64 architecture))
	$(Q)$(MAKE) $(hdr-inst)=include/uapi
	$(Q)$(MAKE) $(hdr-inst)=arch/arm64/include/uapi
	$(Q)for d in $(techpack-dirs); do \
		$(MAKE) $(hdr-inst)=$$d/include/uapi; \
	done

PHONY += headers_check
headers_check:
	@:
	$(Q)for d in $(techpack-dirs); do \
		$(MAKE) $(hdr-inst)=$$d/include/uapi HDRCHECK=1; \
	done

ifdef CONFIG_HEADERS_INSTALL
prepare: headers
endif

PHONY += scripts_unifdef
scripts_unifdef: scripts_basic
	$(Q)$(MAKE) $(build)=scripts scripts/unifdef

PHONY += kselftest
kselftest:
	$(Q)$(MAKE) -C $(srctree)/tools/testing/selftests run_tests

kselftest-%: FORCE
	$(Q)$(MAKE) -C $(srctree)/tools/testing/selftests $*

PHONY += kselftest-merge
kselftest-merge:
	$(if $(wildcard $(objtree)/.config),, $(error No .config exists, config your kernel first!))
	$(Q)find $(srctree)/tools/testing/selftests -name config | \
		xargs $(srctree)/scripts/kconfig/merge_config.sh -m $(objtree)/.config
	$(Q)$(MAKE) -f $(srctree)/Makefile olddefconfig

#~ ifneq ($(wildcard $(srctree)/arch/arm64/boot/dts/),)
#~ dtstree := arch/arm64/boot/dts
#~ endif

#~ ifneq ($(dtstree),)

#~ %.dtb: include/config/kernel.release scripts_dtc
#~ 	$(Q)$(MAKE) $(build)=$(dtstree) $(dtstree)/$@

#~ PHONY += dtbs dtbs_install dtbs_check
#~ dtbs: include/config/kernel.release scripts_dtc
#~ 	$(Q)$(MAKE) $(build)=$(dtstree)

#~ ifneq ($(filter dtbs_check, $(MAKECMDGOALS)),)
#~ dtbs: dt_binding_check
#~ endif

#~ dtbs_check: export CHECK_DTBS=1
#~ dtbs_check: dtbs

#~ dtbs_install:
#~ 	$(Q)$(MAKE) $(dtbinst)=$(dtstree)

#~ ifdef CONFIG_OF_EARLY_FLATTREE
#~ all: dtbs
#~ endif

#~ endif

PHONY += scripts_dtc
scripts_dtc: scripts_basic
	$(Q)$(MAKE) $(build)=scripts/dtc

#~ PHONY += dt_binding_check
#~ dt_binding_check: scripts_dtc
#~ 	$(Q)$(MAKE) $(build)=Documentation/devicetree/bindings

ifdef CONFIG_MODULES

all: modules

ifdef CONFIG_MODVERSIONS
  KBUILD_BUILTIN := 1
endif

PHONY += modules
modules: $(if $(KBUILD_BUILTIN),vmlinux) modules.order modules.builtin
ifdef CONFIG_TRIM_UNUSED_KSYMS
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/adjust_autoksyms.sh \
	  "$(MAKE) -f $(srctree)/Makefile vmlinux"
endif
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modpost
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/modules-check.sh

modules.order: descend
	$(Q)$(AWK) '!x[$$0]++' $(addsuffix /$@, $(build-dirs)) > $@

modbuiltin-dirs := $(addprefix _modbuiltin_, $(build-dirs))

modules.builtin: $(modbuiltin-dirs)
	$(Q)$(AWK) '!x[$$0]++' $(addsuffix /$@, $(build-dirs)) > $@

PHONY += $(modbuiltin-dirs)
$(modbuiltin-dirs): include/config/tristate.conf
	$(Q)$(MAKE) $(modbuiltin)=$(patsubst _modbuiltin_%,%,$@)

PHONY += modules_prepare
modules_prepare: prepare

PHONY += modules_install
modules_install: _modinst_ _modinst_post

PHONY += _modinst_
_modinst_:
	@rm -rf $(MODLIB)/kernel
	@rm -f $(MODLIB)/source
	@mkdir -p $(MODLIB)/kernel
	@ln -s $(abspath $(srctree)) $(MODLIB)/source
	@if [ ! $(objtree) -ef  $(MODLIB)/build ]; then \
		rm -f $(MODLIB)/build ; \
		ln -s $(CURDIR) $(MODLIB)/build ; \
	fi
	@sed 's:^:kernel/:' modules.order > $(MODLIB)/modules.order
	@sed 's:^:kernel/:' modules.builtin > $(MODLIB)/modules.builtin
	@cp -f $(objtree)/modules.builtin.modinfo $(MODLIB)/
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modinst

PHONY += _modinst_post
_modinst_post: _modinst_
	$(call cmd,depmod)

ifeq ($(CONFIG_MODULE_SIG), y)
PHONY += modules_sign
modules_sign:
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modsign
endif

#~ else

#~ PHONY += modules modules_install
#~ modules modules_install:
#~ 	@echo >&2
#~ 	@echo >&2 "The present kernel configuration has modules disabled."
#~ 	@echo >&2 "Type 'make config' and enable loadable module support."
#~ 	@echo >&2 "Then build a kernel with module support enabled."
#~ 	@echo >&2
#~ 	@exit 1

endif

CLEAN_DIRS  += include/ksym
CLEAN_FILES += modules.builtin.modinfo

MRPROPER_DIRS  += include/config include/generated          \
		  arch/arm64/include/generated .tmp_objdiff \
		  debian/ snap/ tar-install/
MRPROPER_FILES += .config .config.old .version \
		  Module.symvers \
		  signing_key.pem signing_key.priv signing_key.x509	\
		  x509.genkey extra_certificates signing_key.x509.keyid	\
		  signing_key.x509.signer vmlinux-gdb.py \
		  *.spec

DISTCLEAN_DIRS  +=
DISTCLEAN_FILES += tags TAGS cscope* GPATH GTAGS GRTAGS GSYMS

clean: rm-dirs  := $(CLEAN_DIRS)
clean: rm-files := $(CLEAN_FILES)

PHONY += archclean vmlinuxclean

vmlinuxclean:
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/link-vmlinux.sh clean
	$(Q)$(if $(ARCH_POSTLINK), $(MAKE) -f $(ARCH_POSTLINK) clean)

clean: archclean vmlinuxclean

mrproper: rm-dirs  := $(wildcard $(MRPROPER_DIRS))
mrproper: rm-files := $(wildcard $(MRPROPER_FILES))
mrproper-dirs      := $(addprefix _mrproper_,scripts)

PHONY += $(mrproper-dirs) mrproper
$(mrproper-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _mrproper_%,%,$@)

mrproper: clean $(mrproper-dirs)
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)

distclean: rm-dirs  := $(wildcard $(DISTCLEAN_DIRS))
distclean: rm-files := $(wildcard $(DISTCLEAN_FILES))

PHONY += distclean

distclean: mrproper
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)
	@find $(srctree) $(RCS_FIND_IGNORE) \
		\( -name '*.orig' -o -name '*.rej' -o -name '*~' \
		-o -name '*.bak' -o -name '#*#' -o -name '*%' \
		-o -name 'core' \) \
		-type f -print | xargs rm -f

%src-pkg: FORCE
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.package $@
%pkg: include/config/kernel.release FORCE
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.package $@

boards := $(wildcard $(srctree)/arch/arm64/configs/*_defconfig)
boards := $(sort $(notdir $(boards)))
board-dirs := $(dir $(wildcard $(srctree)/arch/arm64/configs/*/*_defconfig))
board-dirs := $(sort $(notdir $(board-dirs:/=)))

boards-per-dir = $(sort $(notdir $(wildcard $(srctree)/arch/arm64/configs/$*/*_defconfig)))

$(help-board-dirs): help-%:
	@echo  'Architecture specific targets (arm64 $*):'
	@$(if $(boards-per-dir), \
		$(foreach b, $(boards-per-dir), \
		printf "  %-24s - Build for %s\\n" $*/$(b) $(subst _defconfig,,$(b));) \
		echo '')

PHONY += scripts_gdb
scripts_gdb: prepare0
	$(Q)$(MAKE) $(build)=scripts/gdb
	$(Q)ln -fsn $(abspath $(srctree)/scripts/gdb/vmlinux-gdb.py)

ifdef CONFIG_GDB_SCRIPTS
all: scripts_gdb
endif

else # KBUILD_EXTMOD

KBUILD_MODULES := 1

PHONY += $(objtree)/Module.symvers
$(objtree)/Module.symvers:
	@test -e $(objtree)/Module.symvers || ( \
	echo; \
	echo "  WARNING: Symbol version dump $(objtree)/Module.symvers"; \
	echo "           is missing; modules will have no dependencies and modversions."; \
	echo )

build-dirs := $(KBUILD_EXTMOD)
PHONY += modules
modules: descend $(objtree)/Module.symvers
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modpost

PHONY += modules_install
modules_install: _emodinst_ _emodinst_post

install-dir := $(if $(INSTALL_MOD_DIR),$(INSTALL_MOD_DIR),extra)
PHONY += _emodinst_
_emodinst_:
	$(Q)mkdir -p $(MODLIB)/$(install-dir)
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modinst

PHONY += _emodinst_post
_emodinst_post: _emodinst_
	$(call cmd,depmod)

clean-dirs := $(KBUILD_EXTMOD)
clean: rm-files := $(KBUILD_EXTMOD)/Module.symvers

PHONY += /
/:
	@echo >&2 '"$(MAKE) /" is no longer supported. Please use "$(MAKE) ./" instead.'

#~ PHONY += help
#~ help:
#~ 	@echo  '  Building external modules.'
#~ 	@echo  '  Syntax: make -C path/to/kernel/src M=$$PWD target'
#~ 	@echo  ''
#~ 	@echo  '  modules         - default target, build the module(s)'
#~ 	@echo  '  modules_install - install the module'
#~ 	@echo  '  clean           - remove generated files in module directory only'
#~ 	@echo  ''

PHONY += prepare
endif

ifdef single-build

single-ko := $(sort $(filter %.ko, $(MAKECMDGOALS)))
single-no-ko := $(sort $(patsubst %.ko,%.mod, $(MAKECMDGOALS)))

$(single-ko): single_modpost
	@:
$(single-no-ko): descend
	@:

ifeq ($(KBUILD_EXTMOD),)
MODORDER := .modules.tmp
endif

PHONY += single_modpost
single_modpost: $(single-no-ko)
	$(Q){ $(foreach m, $(single-ko), echo $(extmod-prefix)$m;) } > $(MODORDER)
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modpost

KBUILD_MODULES := 1

export KBUILD_SINGLE_TARGETS := $(addprefix $(extmod-prefix), $(single-no-ko))

build-dirs := $(foreach d, $(build-dirs), \
			$(if $(filter $(d)/%, $(KBUILD_SINGLE_TARGETS)), $(d)))

endif

PHONY += descend $(build-dirs)
descend: $(build-dirs)
$(build-dirs): prepare
	$(Q)$(MAKE) $(build)=$@ \
	single-build=$(if $(filter-out $@/, $(single-no-ko)),1) \
	need-builtin=1 need-modorder=1

clean-dirs := $(addprefix _clean_, $(clean-dirs))
PHONY += $(clean-dirs) clean
$(clean-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

clean: $(clean-dirs)
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)
	@find $(if $(KBUILD_EXTMOD), $(KBUILD_EXTMOD), .) $(RCS_FIND_IGNORE) \
		\( -name '*.[aios]' -o -name '*.ko' -o -name '.*.cmd' \
		-o -name '*.ko.*' \
		-o -name '*.dtb' -o -name '*.dtb.S' -o -name '*.dt.yaml' \
		-o -name '*.dwo' -o -name '*.lst' \
		-o -name '*.su' -o -name '*.mod' -o -name '*.ns_deps' \
		-o -name '.*.d' -o -name '.*.tmp' -o -name '*.mod.c' \
		-o -name '*.lex.c' -o -name '*.tab.[ch]' \
		-o -name '*.asn1.[ch]' \
		-o -name '*.symtypes' -o -name 'modules.order' \
		-o -name modules.builtin -o -name '.tmp_*.o.*' \
		-o -name '*.c.[012]*.*' \
		-o -name '*.ll' \
		-o -name '*.gcno' \
		-o -name '*.*.symversions' \) -type f -print | xargs rm -f

quiet_cmd_tags = GEN     $@
      cmd_tags = $(BASH) $(srctree)/scripts/tags.sh $@

tags TAGS cscope gtags: FORCE
	$(call cmd,tags)

PHONY += nsdeps

nsdeps: modules
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modpost nsdeps
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/$@

PHONY += includecheck versioncheck coccicheck namespacecheck export_report

includecheck:
	find $(srctree)/* $(RCS_FIND_IGNORE) \
		-name '*.[hcS]' -type f -print | sort \
		| xargs $(PERL) -w $(srctree)/scripts/checkincludes.pl

versioncheck:
	find $(srctree)/* $(RCS_FIND_IGNORE) \
		-name '*.[hcS]' -type f -print | sort \
		| xargs $(PERL) -w $(srctree)/scripts/checkversion.pl

coccicheck:
	$(Q)$(BASH) $(srctree)/scripts/$@

namespacecheck:
	$(PERL) $(srctree)/scripts/namespace.pl

export_report:
	$(PERL) $(srctree)/scripts/export_report.pl

PHONY += checkstack kernelrelease kernelversion image_name

CHECKSTACK_ARCH := arm64
checkstack:
	$(OBJDUMP) -d vmlinux $$(find . -name '*.ko') | \
	$(PERL) $(srctree)/scripts/checkstack.pl $(CHECKSTACK_ARCH)

kernelrelease:
	@echo "$(KERNELVERSION)$$($(CONFIG_SHELL) $(srctree)/scripts/setlocalversion \
		$(srctree) $(BRANCH) $(KMI_GENERATION))"

kernelversion:
	@echo $(KERNELVERSION)

image_name:
	@echo $(KBUILD_IMAGE)

ifeq ($(quiet),silent_)
tools_silent=s
endif

tools/: FORCE
	$(Q)mkdir -p $(objtree)/tools
	$(Q)$(MAKE) LDFLAGS= MAKEFLAGS="$(tools_silent) $(filter --j% -j,$(MAKEFLAGS))" O=$(abspath $(objtree)) subdir=tools -C $(srctree)/tools/

tools/%: FORCE
	$(Q)mkdir -p $(objtree)/tools
	$(Q)$(MAKE) LDFLAGS= MAKEFLAGS="$(tools_silent) $(filter --j% -j,$(MAKEFLAGS))" O=$(abspath $(objtree)) subdir=tools -C $(srctree)/tools/ $*

quiet_cmd_rmdirs = $(if $(wildcard $(rm-dirs)),CLEAN   $(wildcard $(rm-dirs)))
      cmd_rmdirs = rm -rf $(rm-dirs)

quiet_cmd_rmfiles = $(if $(wildcard $(rm-files)),CLEAN   $(wildcard $(rm-files)))
      cmd_rmfiles = rm -f $(rm-files)

quiet_cmd_depmod = DEPMOD  $(KERNELRELEASE)
      cmd_depmod = $(CONFIG_SHELL) $(srctree)/scripts/depmod.sh $(DEPMOD) \
                   $(KERNELRELEASE)

existing-targets := $(wildcard $(sort $(targets)))

-include $(foreach f,$(existing-targets),$(dir $(f)).$(notdir $(f)).cmd)

endif
endif
endif

PHONY += FORCE
FORCE:

.PHONY: $(PHONY)