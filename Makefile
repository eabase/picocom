
VERSION = 2024-07
ifneq (,$(findstring dev,$(VERSION)))
VERSION := $(if $(shell command -v git),$(shell git describe --tags --dirty --always),$(VERSION))
endif

#CC ?= gcc

# EXTRA_CPPFLAGS is added for build-systems who prefer to not touch
# CPPFLAGS directly.
CPPFLAGS += -DVERSION_STR=\"$(VERSION)\" $(EXTRA_CPPFLAGS)
CFLAGS += -Wall -g

LD = $(CC)
LDFLAGS ?= -g
LDLIBS ?=

all: picocom
OBJS =

## This is the maximum size (in bytes) the output (e.g. copy-paste)
## queue is allowed to grow to. Zero means unlimitted.
TTY_Q_SZ = 0
CPPFLAGS += -DTTY_Q_SZ=$(TTY_Q_SZ)

## Comment this out to disable high-baudrate support
CPPFLAGS += -DHIGH_BAUD

## Normally you should NOT enable both: UUCP-style and flock(2)
## locking.

## Comment this out to disable locking with flock
CPPFLAGS += -DUSE_FLOCK

## Comment these out to disable UUCP-style lockdirs
#UUCP_LOCK_DIR=/var/lock
#CPPFLAGS += -DUUCP_LOCK_DIR=\"$(UUCP_LOCK_DIR)\"

## Comment these out to disable "linenoise"-library support
HISTFILE = .picocom_history
CPPFLAGS += -DHISTFILE=\"$(HISTFILE)\" \
	    -DLINENOISE
OBJS += linenoise-1.0/linenoise.o
linenoise-1.0/linenoise.o : linenoise-1.0/linenoise.c linenoise-1.0/linenoise.h

## Comment this in to enable (force) custom baudrate support
## even on systems not enabled by default.
#CPPFLAGS += -DUSE_CUSTOM_BAUD

## Comment this in to disable custom baudrate support
## on ALL systems (even on these enabled by default).
#CPPFLAGS += -DNO_CUSTOM_BAUD

## Comment this IN to remove help strings (saves ~ 4-6 Kb).
#CPPFLAGS += -DNO_HELP

## Comment this IN to disable fork() for MMU-less systems.
## That means no sending/receiving of files. Saves ~ 6-8Kb.
#CPPFLAGS += -DNO_FORK


OBJS += picocom.o term.o fdio.o split.o custbaud.o termios2.o custbaud_bsd.o
picocom : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

picocom.o : picocom.c term.h fdio.h split.h custbaud.h
term.o : term.c term.h termios2.h custbaud_bsd.h custbaud.h
split.o : split.c split.h
fdio.o : fdio.c fdio.h
termios2.o : termios2.c termios2.h termbits2.h custbaud.h
custbaud_bsd.o : custbaud_bsd.c custbaud_bsd.h custbaud.h
custbaud.o : custbaud.c custbaud.h

.c.o :
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

doc : picocom.1

picocom.1 : picocom.1.md
	(echo '% PICOCOM 1 "v$(VERSION)"'; cat $<) | go-md2man >$@

clean:
	rm -f picocom.o term.o fdio.o split.o
	rm -f linenoise-1.0/linenoise.o
	rm -f custbaud.o termios2.o custbaud_bsd.o
	rm -f *~

distclean: clean
	rm -f picocom
	rm -f picocom.1
