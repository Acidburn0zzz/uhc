# location of lib src
EHCLIB_EHCLIB							:= ehclib
EHCLIB_EHCLIB_PREFIX					:= $(EHCLIB_EHCLIB)/
EHCLIB_EHCBASE							:= ehcbase
EHCLIB_EHCBASE_PREFIX					:= $(EHCLIB_EHCBASE)/
EHCLIB_EHCLIB_EHCBASE					:= $(EHCLIB_EHCLIB_PREFIX)$(EHCLIB_EHCBASE)
EHCLIB_EHCLIB_EHCBASE_PREFIX			:= $(EHCLIB_EHCLIB_PREFIX)$(EHCLIB_EHCBASE_PREFIX)
EHCLIB_SRC_PREFIX						:= $(TOP_PREFIX)$(EHCLIB_EHCLIB_PREFIX)
EHCLIB_BASE_SRC_PREFIX					:= $(TOP_PREFIX)$(EHCLIB_EHCLIB_EHCBASE_PREFIX)

# build locations
EHCLIB_BLD_VARIANT_PREFIX				:= $(EHC_BLD_VARIANT_PREFIX)$(EHCLIB_EHCLIB_PREFIX)
EHCLIB_BASE_BLD_VARIANT_PREFIX			:= $(EHC_BLD_VARIANT_PREFIX)$(EHCLIB_EHCLIB_EHCBASE_PREFIX)

# this file
EHCLIB_MKF								:= $(EHCLIB_SRC_PREFIX)files.mk

# end products
# NOTE: library is just a bunch of compiled .hs files, triggered by compile of a Main
EHCLIB_MAIN								:= CompileAll
EHCLIB_ALL_LIBS							:= $(patsubst %,$(BLD_PREFIX)%/$(EHCLIB_EHCLIB_EHCBASE_PREFIX)$(EHCLIB_MAIN)$(EXEC_SUFFIX),$(EHC_PREL_VARIANTS))

# main + sources + dpds
# sources
EHCLIB_HS_MAIN_DRV_HS					:= $(EHCLIB_BASE_BLD_VARIANT_PREFIX)$(EHCLIB_MAIN).hs
EHCLIB_TRIGGER_EXEC						:= $(EHCLIB_BASE_BLD_VARIANT_PREFIX)$(EHCLIB_MAIN)$(EXEC_SUFFIX)

EHCLIB_HS_ALL_SRC_HS					:= $(wildcard $(EHCLIB_BASE_SRC_PREFIX)*.hs $(EHCLIB_BASE_SRC_PREFIX)EHC/*.hs)
EHCLIB_HS_ALL_DRV_HS					:= $(patsubst $(EHCLIB_SRC_PREFIX)%.hs,$(EHCLIB_BLD_VARIANT_PREFIX)%.hs,$(EHCLIB_HS_ALL_SRC_HS))

EHCLIB_ALL_SRC							:= $(EHCLIB_HS_ALL_SRC_HS)

# distribution
EHCLIB_DIST_FILES						:= $(EHCLIB_ALL_SRC) $(EHCLIB_MKF)

# targets
ehclib-variant-dflt: $(EHCLIB_HS_ALL_DRV_HS)
	$(EHC_BLD_EXEC) $(EHCLIB_HS_MAIN_DRV_HS)

# dispatch rules
$(patsubst $(BLD_PREFIX)%/$(EHCLIB_EHCBASE_PREFIX)$(EHCLIB_MAIN)$(EXEC_SUFFIX),%,$(EHCLIB_ALL_LIBS)): %: $(BLD_PREFIX)%/$(EHCLIB_EHCBASE_PREFIX)$(EHCLIB_MAIN)$(EXEC_SUFFIX)

$(EHCLIB_ALL_LIBS): %: $(EHCLIB_ALL_SRC) $(EHCLIB_MKF)
	$(MAKE) EHC_VARIANT=`echo $(*D) | sed -n -e 's+$(BLD_PREFIX)\([0-9]*\)/$(EHCLIB_EHCLIB_EHCBASE)+\1+p'` ehclib-variant-dflt

# rules
$(EHCLIB_HS_ALL_DRV_HS): $(EHCLIB_BLD_VARIANT_PREFIX)%.hs: $(EHCLIB_SRC_PREFIX)%.hs
	mkdir -p $(@D)
	cp $< $@
	touch $@
