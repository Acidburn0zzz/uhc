# aspects, EHC_ASPECTS to be configured at top level, for now here
EHC_ASPECTS								:= $(if $(ASPECTS),$(ASPECTS),base hmty codegen grin noHmTyRuler)
EHC_ASPECTS_SUFFIX						:= $(if $(ASPECTS),-$(subst $(space),-,$(ASPECTS)),)
EHC_ASPECTS_SUFFIX2						:= $(subst -,,$(EHC_ASPECTS_SUFFIX))

# config depending on EHC_ASPECTS
EHC_CFG_USE_GRIN						:= $(filter grin,$(EHC_ASPECTS))

# variant, EHC_VARIANT to be configured at top level
EHC_VARIANT								:= X
EHC_VARIANT_PREFIX						:= $(EHC_VARIANT)$(EHC_ASPECTS_SUFFIX)/
EHC_BLD_VARIANT_PREFIX					:= $(BLD_PREFIX)$(EHC_VARIANT_PREFIX)
EHC_BLD_LIBEHC_VARIANT_PREFIX			:= $(EHC_BLD_VARIANT_PREFIX)lib-ehc/
EHC_BLD_LIBGRINC_VARIANT_PREFIX			:= $(EHC_BLD_VARIANT_PREFIX)lib-grinc/
EHC_BLD_BIN_VARIANT_PREFIX				:= $(EHC_BLD_VARIANT_PREFIX)bin/
EHC_BLD_GEN_VARIANT_PREFIX				:= $(EHC_BLD_VARIANT_PREFIX)gen/
EHC_BIN_PREFIX							:= $(BIN_PREFIX)
EHC_LIB_PREFIX							:= $(LIB_PREFIX)
EHC_BIN_VARIANT_PREFIX					:= $(EHC_BIN_PREFIX)$(EHC_VARIANT_PREFIX)
EHC_LIB_VARIANT_PREFIX					:= $(EHC_LIB_PREFIX)$(EHC_VARIANT_PREFIX)
EHC_VARIANT_RULER_SEL					:= ().().()

# lib/cabal/module config
LIB_EHC_BASE							:= EH
LIB_EHC_QUAL							:= $(subst _,x,$(LIB_EHC_BASE)$(EHC_VARIANT))$(EHC_ASPECTS_SUFFIX2)
LIB_EHC_QUAL_PREFIX						:= $(LIB_EHC_QUAL).
LIB_EHC_HS_PREFIX						:= $(subst .,$(PATH_SEP),$(LIB_EHC_QUAL_PREFIX))
LIB_EHC_PKG_NAMEBASE					:= $(GHC_PKG_NAME_PREFIX)$(subst .,-,$(LIB_EHC_QUAL))
LIB_EHC_PKG_NAME						:= $(LIB_EHC_PKG_NAMEBASE)
LIB_EHC_INS_FLAG						:= $(INSABS_FLAG_PREFIX)$(LIB_EHC_PKG_NAME)

EHC_BASE								:= $(LIB_EHC_BASE)C
EHC_INS_FLAG							:= $(INSABS_FLAG_PREFIX)$(EHC_BASE)$(EHC_VARIANT)$(EHC_ASPECTS_SUFFIX)

# installation
INS_EHC_LIB_PREFIX						:= $(INS_PREFIX)lib/$(LIB_EHC_PKG_NAME)-$(EH_VERSION)/
INSABS_EHC_LIB_PREFIX					:= $(INSABS_PREFIX)lib/$(LIB_EHC_PKG_NAME)-$(EH_VERSION)/
INS_EHC_LIB_AG_PREFIX					:= $(INS_EHC_LIB_PREFIX)ag/
INSABS_EHC_LIB_AG_PREFIX				:= $(INSABS_EHC_LIB_PREFIX)ag/

# further derived info
EHC_BLD_LIB_HS_VARIANT_PREFIX			:= $(EHC_BLD_LIBEHC_VARIANT_PREFIX)$(LIB_EHC_HS_PREFIX)
SRC_EHC_LIB_PREFIX						:= $(SRC_EHC_PREFIX)$(LIB_EHC_BASE)

# tool use
LIB_EHC_SHUFFLE_DEFS					:= --def=EH:$(LIB_EHC_QUAL_PREFIX) --def=VARIANT:$(EHC_VARIANT) --def="ASPECTS:$(EHC_ASPECTS)"
