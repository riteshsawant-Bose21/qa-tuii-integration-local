ifeq ($(ARCH),arm64)
	LIBS = \
       	-lstdc++ -lrt -lpthread \
       	-L ${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/lib \
       	-lboost_program_options -lspdlog -lfmt -std=c++17
	
	CXX_CFLAGS = -Wall -I ${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/include\
		     -I ./include \
		     -I ./include/bosepro \
		     -DSPDLOG_FMT_EXTERNAL -DSPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_TRACE
else
	CC=g++
	
	LIBS =\
	      -lstdc++ -lrt -lpthread -lboost_program_options \
              -lspdlog -lfmt -std=c++17
	
	CXX_CFLAGS = -Wall \
		     -I ./include \
		     -I ./include/bosepro \
		     -DSPDLOG_FMT_EXTERNAL -DSPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_TRACE
endif

.PHONY: clean  all

SRCDIR = src
OBJDIR = obj

TELM_CORE_EXEC = telemetry_core

SOURCES = $(wildcard $(SRCDIR)/*.cc)
TELM_CORE_OBJ = $(patsubst $(SRCDIR)/%.cc, $(OBJDIR)/%.o, $(SOURCES))

all: $(TELM_CORE_EXEC)

telemetry_core: $(TELM_CORE_OBJ)
	$(CC) -o $@ $(TELM_CORE_OBJ) $(LIBS) 

$(OBJDIR)/%.o: $(SRCDIR)/%.cc
	mkdir -p $(OBJDIR)
	$(CC) $(CXX_CFLAGS) -c $< -o $@

clean:
	@rm -f $(TELM_CORE_EXEC) $(TELM_CORE_OBJ)

