CC              = gcc

GITREV        = $(shell git show --pretty=format:"%h" --no-patch)
GITDIRTY        = $(shell git diff --quiet || echo '-dirty')
UNAME           = $(shell uname)
CFLAGS          = -Wall -g -O -Ihidapi/hidapi -DGITREV='"$(GITREV)$(GITDIRTY)"'
LDFLAGS         = -g
CCARCH          =
LIBUSB_LIBS     = $(shell pkg-config libusb-1.0 --libs)

# Linux
ifeq ($(UNAME),Linux)
ifeq (,$(LIBUSB_LIBS))
    LIBS        += -Wl,-Bstatic -lusb-1.0 -Wl,-Bdynamic
else
    LIBS        += $(LIBUSB_LIBS)
endif
    LIBS        += -lpthread -ludev
    HIDLIB      = hidapi/libusb/.libs/libhidapi-libusb.a
endif

# FreeBSD
ifeq ($(UNAME),FreeBSD)
    LIBS        += -liconv -lusb -lpthread
    HIDLIB      = hidapi/libusb/.libs/libhidapi.a
endif

# DragonFly BSD
ifeq ($(UNAME),DragonFly)
    LIBS        += -Wl,-Bstatic -lusb -Wl,-Bdynamic -lpthread
    HIDLIB      = hidapi/libusb/.libs/libhidapi.a
endif

# Mac OS X
ifeq ($(UNAME),Darwin)
    LIBS        += -framework IOKit -framework CoreFoundation
    HIDLIB      = hidapi/mac/.libs/libhidapi.a
    UNIV_ARCHS  = $(shell grep '^universal_archs' /opt/local/etc/macports/macports.conf)
    ifneq ($(findstring i386,$(UNIV_ARCHS)),)
        CCARCH  += -arch i386
    endif
    ifneq ($(findstring x86_64,$(UNIV_ARCHS)),)
        CCARCH  += -arch x86_64
    endif
    CC          += $(CCARCH)
endif

PROG_OBJS       = progyon.o target.o executive.o serial.o \
                  adapter-pickit2.o adapter-hidboot.o adapter-an1388.o \
                  adapter-bitbang.o adapter-stk500v2.o adapter-uhb.o \
                  adapter-an1388-uart.o configure.o \
                  family-mx1.o family-mx3.o family-mz.o family-mm.o family-mk.o $(HIDLIB)

# JTAG adapters based on FT2232 chip
CFLAGS          += -DUSE_MPSSE
PROG_OBJS       += adapter-mpsse.o
ifeq ($(UNAME),Darwin)
    # Use 'sudo port install libusb'
    CFLAGS      += -I/opt/local/include
    LIBS        += /opt/local/lib/libusb-1.0.a -lobjc
endif

all:            progyon

progyon:      $(PROG_OBJS)
		$(CC) $(LDFLAGS) -o $@ $(PROG_OBJS) $(LIBS)

load:           demo1986ve91.srec
		progyon $<

adapter-mpsse:	adapter-mpsse.c
		$(CC) $(LDFLAGS) $(CFLAGS) -DSTANDALONE -o $@ adapter-mpsse.c $(LIBS)

progyon.po:	*.c
		xgettext --from-code=utf-8 --keyword=_ progyon.c target.c adapter-lpt.c -o $@

progyon-ru.mo: progyon-ru.po
		msgfmt -c -o $@ $<

progyon-ru-cp866.mo ru/LC_MESSAGES/progyon.mo: progyon-ru.po
		iconv -f utf-8 -t cp866 $< | sed 's/UTF-8/CP866/' | msgfmt -c -o $@ -
		cp progyon-ru-cp866.mo ru/LC_MESSAGES/progyon.mo

clean:
		rm -f *~ *.o core progyon adapter-mpsse progyon.po hidapi/ar-lib hidapi/compile
		if [ -f hidapi/Makefile ]; then make -C hidapi clean; fi

install:	progyon #progyon-ru.mo
		install -c -s progyon /usr/local/bin/progyon
#		install -c -m 444 progyon-ru.mo /usr/local/share/locale/ru/LC_MESSAGES/progyon.mo

hidapi/hidapi/hidapi.h:
		git submodule update --init

$(HIDLIB):      hidapi/hidapi/hidapi.h
		if [ ! -f hidapi/configure ]; then cd hidapi && ./bootstrap; fi
		cd hidapi && ./configure --enable-shared=no CFLAGS='$(CCARCH)'
		make -C hidapi

###
adapter-an1388-uart.o: adapter-an1388-uart.c adapter.h pic32.h serial.h
adapter-an1388.o: adapter-an1388.c adapter.h hidapi/hidapi/hidapi.h pic32.h
adapter-bitbang.o: adapter-bitbang.c adapter.h pic32.h serial.h \
  bitbang/ICSP_v1E.inc
adapter-hidboot.o: adapter-hidboot.c adapter.h hidapi/hidapi/hidapi.h pic32.h
adapter-mpsse.o: adapter-mpsse.c adapter.h pic32.h
adapter-pickit2.o: adapter-pickit2.c adapter.h hidapi/hidapi/hidapi.h pickit2.h \
  pic32.h
adapter-stk500v2.o: adapter-stk500v2.c adapter.h pic32.h serial.h
adapter-uhb.o: adapter-uhb.c adapter.h hidapi/hidapi/hidapi.h pic32.h
configure.o: configure.c target.h adapter.h
executive.o: executive.c pic32.h
family-mx1.o: family-mx1.c pic32.h
family-mx3.o: family-mx3.c pic32.h
family-mz.o: family-mz.c pic32.h
family-mm.o: family-mm.c pic32.h
family-mk.o: family-mk.c pic32.h
progyon.o: progyon.c target.h adapter.h serial.h localize.h
serial.o: serial.c adapter.h
target.o: target.c target.h adapter.h localize.h pic32.h
