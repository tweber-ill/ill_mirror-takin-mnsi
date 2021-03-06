#
# MnSi dynamics module for Takin and helper tools
# @author Tobias Weber <tweber@ill.fr>
# @date 2018-2020
# @license GPLv2 (see 'LICENSE' file)
#

mingw_build = 0
debug_build = 0
strip_bins = 1


# -----------------------------------------------------------------------------
# setup
# -----------------------------------------------------------------------------
ifneq ($(mingw_build), 1)
	ifeq ("$(CXX)", "")
		CXX = g++
	endif

	SYSINCS = -I/usr/local/include \
		-I/usr/include/lapacke -I/usr/local/opt/lapack/include \
		-I/usr/include/qt5 -I/usr/include/x86_64-linux-gnu/qt5/ \
		-I/usr/local/include/Minuit2 \
		#-I/usr/local/Cellar/qt/5.15.0/include \
		#-I/home/tw/build/boost_1_73_0
	LIBDIRS = -L/usr/local/opt/lapack/lib -L/usr/local/lib

	LIBBOOSTSYS = -lboost_system
	LIBBOOSTFILESYS = -lboost_filesystem

	BIN_SUFFIX =
else
	CXX = x86_64-w64-mingw32-g++

	SYSINCS = -I/usr/x86_64-w64-mingw32/sys-root/mingw/include \
		-I/usr/x86_64-w64-mingw32/sys-root/mingw/include/qt5
	LIBDIRS = -L/usr/x86_64-w64-mingw32/sys-root/mingw/bin/

	LIBBOOSTSYS = -lboost_system-x64
	LIBBOOSTFILESYS = -lboost_filesystem-x64

	BIN_SUFFIX = .exe
endif


ifneq ($(debug_build), 1)
	OPT = -O2 #-march=native

	ifeq ($(strip_bins), 1)
		STRIP = strip
	else
		STRIP = echo -e "Not stripping"
	endif
else
	OPT = -g -ggdb
	STRIP = echo -e "Not stripping"
endif


STD = -std=c++17
LIBDEFS = -fPIC
DEFS = -DDEF_SKX_ORDER=7 -DDEF_HELI_ORDER=7 \
	-DNO_MINIMISATION -DNO_REDEFINITIONS \
	-D__HACK_FULL_INST__ #-DPLUGIN_APPLI
INCS = -Isrc -Iext -Iext/takin $(SYSINCS)
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# meta rules
# -----------------------------------------------------------------------------
.PHONY: all clean

all: prepare lib/skxmod.so lib/skxmod_grid.so \
	bin/genskx bin/genheli bin/merge bin/convert bin/dump \
	bin/drawskx bin/dyn bin/weight \
	bin/heliphase bin/skx_gs bin/weight_sum

clean:
	find . -name "*.o" -exec rm -fv {} \;
	rm -rfv bin/
	rm -rfv lib/

prepare:
	mkdir -p bin/
	mkdir -p lib/
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Takin plugin modules
# -----------------------------------------------------------------------------
lib/skxmod.so: src/takin/takin.o src/core/skx.o src/core/fp.o src/core/heli.o src/core/longfluct.o src/core/magsys.o \
	ext/takin/tools/monteconvo/sqwbase.o ext/tlibs2/libs/log.o
	@echo "Linking Takin module $@..."
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) $(LIBDEFS) -shared -o $@ $+ -llapacke
	$(STRIP) $@

lib/skxmod_grid.so: src/takin/takin_grid.o ext/takin/tools/monteconvo/sqwbase.o ext/tlibs2/libs/log.o
	@echo "Linking Takin grid module $@..."
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) $(LIBDEFS) -shared -o $@ $+ $(LIBBOOSTSYS) -lQt5Core
	$(STRIP) $@
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# tools
# -----------------------------------------------------------------------------
bin/genskx: src/takin/genskx.o src/core/skx.o src/core/magsys.o ext/tlibs2/libs/log.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) $(LIBDEFS) -o $@ $+ $(LIBBOOSTFILESYS) -llapacke -lpthread
	$(STRIP) $@$(BIN_SUFFIX)

bin/genheli: src/takin/genheli.o src/core/heli.o src/core/magsys.o ext/tlibs2/libs/log.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) $(LIBDEFS) -o $@ $+ $(LIBBOOSTFILESYS) -llapacke -lpthread
	$(STRIP) $@$(BIN_SUFFIX)

bin/merge: src/takin/merge.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) -o $@ $+ $(LIBBOOSTSYS)
	$(STRIP) $@$(BIN_SUFFIX)

bin/convert: src/takin/convert.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) -o $@ $+
	$(STRIP) $@$(BIN_SUFFIX)

bin/dump: src/takin/dump.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) -o $@ $+
	$(STRIP) $@$(BIN_SUFFIX)

bin/drawskx: src/calc/drawskx.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) -o $@ $+
	$(STRIP) $@$(BIN_SUFFIX)

bin/dyn: src/calc/dyn.o src/core/skx.o src/core/fp.o src/core/heli.o src/core/magsys.o ext/tlibs2/libs/log.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) $(LIBDEFS) -o $@ $+ -llapacke -lpthread
	$(STRIP) $@$(BIN_SUFFIX)

bin/weight: src/calc/weight.o src/core/skx.o src/core/fp.o src/core/heli.o src/core/magsys.o ext/tlibs2/libs/log.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) $(LIBDEFS) -o $@ $+ -llapacke -lpthread
	$(STRIP) $@$(BIN_SUFFIX)

bin/weight_sum: src/calc/weight_sum.o src/core/skx.o src/core/fp.o src/core/heli.o src/core/magsys.o ext/tlibs2/libs/log.o
	$(CXX) $(STD) $(OPT) $(DEFS) $(LIBDIRS) $(LIBDEFS) -o $@ $+ -llapacke -lpthread
	$(STRIP) $@$(BIN_SUFFIX)
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# further tools needing specialised compilation options
# -----------------------------------------------------------------------------
bin/heliphase: src/calc/heliphase.cpp src/core/heli.cpp src/core/magsys.cpp ext/tlibs2/libs/log.cpp
	$(CXX) $(STD) $(OPT) $(INCS) -DDEF_HELI_ORDER=4 -DNO_REDEFINITIONS -D__HACK_FULL_INST__ $(LIBDIRS) -o $@ $+ -lMinuit2 -llapacke
	$(STRIP) $@$(BIN_SUFFIX)

bin/skx_gs: src/calc/skx_gs.cpp src/core/skx.cpp src/core/heli.cpp src/core/magsys.cpp ext/tlibs2/libs/log.cpp
	$(CXX) $(STD) $(OPT) $(INCS) -DDEF_SKX_ORDER=7 -DDEF_HELI_ORDER=7 -DNO_REDEFINITIONS -D__HACK_FULL_INST__ $(LIBDIRS) -o $@ $+ -lMinuit2 -llapacke
	$(STRIP) $@$(BIN_SUFFIX)
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# general rules
# -----------------------------------------------------------------------------
%.o: %.cpp
	@echo "Compiling $< -> $@..."
	$(CXX) $(STD) $(OPT) $(DEFS) $(INCS) $(LIBDEFS) -c $< -o $@
# -----------------------------------------------------------------------------
