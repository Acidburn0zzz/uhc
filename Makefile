#!/usr/bin/make -f

.PHONY: ehcs dist www www-sync install lib src build ruler1

###########################################################################################
# Location from which make is invoked
###########################################################################################

TOP_PREFIX				:= 

###########################################################################################
# First (default) target just explains what can be done
###########################################################################################

default: explanation

###########################################################################################
# Definitions, dependencies, rules, etc: spread over subdirectories for subproducts
###########################################################################################

# do not change the order of these includes
-include latex/files.mk
-include lhs2TeX/files.mk

include mk/config.mk

### BEGIN of Ruler1
# This definitely should not remain here....!!!!
# Ruler1, will be obsolete until all type rules are specified with Ruler2 (currently not in Explicit/implicit story)
RULER1				:= bin/ruler1$(EXEC_SUFFIX)
RULER1_DIR			:= ruler1
RULER1_MAIN			:= Ruler
RULER1_AG			:= $(RULER1_MAIN).ag
RULER1_HS			:= $(RULER1_AG:.ag=.hs)
RULER1_DERIV		:= $(RULER1_DIR)/$(RULER1_HS)

RULER1_SRC			:= $(RULER1_DIR)/$(RULER1_AG)

ruler1: $(RULER1)

$(RULER1): $(RULER1_DIR)/$(RULER1_AG) $(LIB_EH_UTIL_INS_FLAG)
	cd $(RULER1_DIR) && \
	$(AGC) -csdfr --module=Main `basename $<` && \
	$(GHC) --make $(GHC_OPTS) -package $(LIB_EH_UTIL_PKG_NAME) $(RULER1_HS) -o ../$@ && \
	$(STRIP) ../$@
### END of Ruler1

include src/files.mk
include $(SRC_PREFIX)ehc/shared.mk
include $(MK_PREFIX)shared.mk

include $(SRC_PREFIX)libutil/files.mk
include $(SRC_PREFIX)top/files.mk
include $(SRC_PREFIX)helium/files.mk
include $(SRC_PREFIX)lvm/files.mk
include $(SRC_PREFIX)text2text/files.mk
include $(SRC_PREFIX)shuffle/files.mk
include $(SRC_PREFIX)ruler2/files.mk
include $(SRC_PREFIX)ehc/variant.mk
include $(SRC_PREFIX)gen/files.mk
include $(SRC_PREFIX)ehc/files1.mk
include $(SRC_PREFIX)grini/files.mk

-include $(SRC_PREFIX)experiments/files.mk
-include $(SRC_EXPERIMENTS_PREFIX)subst/files.mk

include extlibs/bgc/files.mk
include extlibs/gmp/files.mk
include $(SRC_PREFIX)rts/files.mk
ifeq ($(ENABLE_JAVA),yes)
-include $(SRC_PREFIX)jazy/files.mk
endif
include $(SRC_PREFIX)ehc/files2.mk
include $(SRC_PREFIX)agprimer/files.mk
-include $(SRC_PREFIX)infer2pass/variant.mk
-include $(SRC_PREFIX)infer2pass/files.mk
-include figs/files.mk
-include text/files1.mk
-include text/files-variants.mk
-include $(wildcard text/files1-*.mk)
-include text/files2.mk
-include text/files-targets.mk
-include $(wildcard text/files2-*.mk)
-include www/files.mk
include ehclib/files.mk
include test/files.mk

-include $(MK_PREFIX)dist.mk

###########################################################################################
# all versions (as used by testing)
###########################################################################################

VERSIONS			:= $(EHC_PUB_VARIANTS)

# distributed/published stuff for WWW
#WWW_SRC_TGZ					:= www/current-ehc-src.tgz
#WWW_DOC_PDF					:= www/current-ehc-doc.pdf

###########################################################################################
# Target: explain what can be done
###########################################################################################

explanation:
	@$(EXIT_IF_ABSENT_LIB_OR_TOOL)
	@echo "UHC" ; \
	echo  "===" ; \
	echo  "make uhc                 : make uhc and library (ehc variant 101)" ; \
	echo  "make install             : make uhc and install globally, possibly needing admin permission" ; \
	echo  "make test                : regress test uhc" ; \
	echo  "" ; \
    echo  "EHC & tools" ; \
	echo  "===========" ; \
	echo  "make <n>/ehc             : make compiler variant <n> (in bin/, where <n> in {$(EHC_PUB_VARIANTS)})" ; \
	echo  "make <n>/ehclib          : make ehc library (i.e. used to compile with ehc) variant <n> (in bin/, where <n> in {$(EHC_PREL_VARIANTS)})" ; \
	echo  "make <n>/ehclibs         : make ehc libraries for all codegen targets" ; \
	echo  "make <n>/rts             : make only the rts part of a library" ; \
	echo  "make <n>/grini           : make grin interpreter variant <n> (in bin/, where <n> in {$(GRIN_PUB_VARIANTS)}) (obsolete)" ; \
	echo  "make <n>/hdoc            : make Haddock documentation for variant <n> (in hdoc/)" ; \
	echo  "make <n>/bare            : make bare source dir for variant <n> (in bare/)," ; \
	echo  "                           then 'cd' to there and 'make'" ; \
	echo  "make $(RULER2_NAME)               : make ruler tool" ; \
	echo  "make $(SHUFFLE_NAME)             : make shuffle tool" ; \
	echo  "" ; \
    echo  "Documentation" ; \
	echo  "=============" ; \
	echo  "make www                 : make www documentation: $(TEXT_WWW_DOC_PDFS)" ; \
	echo  "make www-sync            : install www documentation in the EHC web (http://www.cs.uu.nl/wiki/Ehc/WebHome)" ; \
	echo  "" ; \
	echo  "make doc/<d>.pdf         : make (public) documentation <d> (where <d> in {$(TEXT_PUB_VARIANTS)})," ; \
	echo  "                           or (non-public): <d> in {$(TEXT_PRIV_VARIANTS)}" ; \
	echo  "                           or (doc): <d> in {$(TEXT_DOCLTX_VARIANTS)}" ; \
	echo  "                           only if text src available, otherwise already generated" ; \
	echo  "" ; \
    echo  "Testing" ; \
	echo  "===========" ; \
	echo  "make test-regress        : run regression test," ; \
	echo  "                           restrict to versions <v> by specifying 'TEST_VARIANTS=<v>' (default '${TEST_VARIANTS}')," ; \
	echo  "                           requires corresponding $(EHC_EXEC_NAME)/$(GRINI_EXEC_NAME)/$(EHCLIB_EHCLIB) already built" ; \
	echo  "make test-expect         : make expected output (for later comparison with test-regress), see test-regress for remarks" ; \
	echo  "" ; \
    echo  "Cleaning up" ; \
	echo  "===========" ; \
	echo  "make <n>/clean           : cleanup for variant <n>" ; \
	echo  "make clean               : cleanup all variants + internal libraries and tools" ; \
	echo  "make clean-extlibs       : cleanup external libraries" ; \
	echo  "" ; \
    echo  "Other" ; \
	echo  "=====" ; \
	echo  "make ehcs                : make all compiler ($(EHC_EXEC_NAME)) versions" ; \
	echo  "make top                 : make Typing Our Programs library" ; \
	echo  "make lvm                 : make Lazy Virtual Machine library" ; \
	echo  "make helium              : make Helium library" ; \
	echo  "make heliumdoc           : make Haddock documentation for Helium, Top and Lvm (in hdoc/)" ; \
	echo  "" ; \
    echo  "Obsolecence candidates" ; \
	echo  "======================" ; \
	echo  "make <n>/infer2pass      : make infer2pass demo version <n> (in bin/, where <n> in {$(INF2PS_VARIANTS)})" ; \
	echo  "make grinis              : make all grin interpreter ($(GRINI_EXEC_NAME)) versions" ; \
	echo  "" ; \

###########################################################################################
# Target: make every variant of something
###########################################################################################

ehcs: $(EHC_ALL_PUB_EXECS)

grinis: $(GRINI_ALL_PUB_EXECS)

grinllvms: $(GRINLLVM_ALL_PUB_EXECS)

docs: $(TEXT_DIST_DOC_FILES)

cleans: $(patsubst %,%/clean,$(EHC_VARIANTS))

###########################################################################################
# Target: www stuff + sync to www
###########################################################################################

# www: $(WWW_SRC_TGZ) www-ex $(WWW_DOC_FILES)
www: $(WWW_DOC_FILES)

# www/DoneSyncStamp: www-ex
www/DoneSyncStamp: www
	(date "+%G%m%d %H:%M") > www/DoneSyncStamp ; \
	chmod 664 www/* ; \
	rsync --progress -azv -e ssh www/* `whoami`@shell.cs.uu.nl:/users/www/groups/ST/Projects/ehc

www-sync: www/DoneSyncStamp

###########################################################################################
# Target: helium doc
###########################################################################################

heliumdoc: $(LIB_HELIUM_ALL_DRV_HS) $(LIB_TOP_HS_DRV) $(LIB_LVM_HS_DRV)
	mkdir -p hdoc/helium
	haddock --html --odir=hdoc/helium $(LIB_HELIUM_ALL_DRV_HS) $(LIB_TOP_HS_DRV) $(LIB_LVM_HS_DRV)

###########################################################################################
# Target: UHC: uhc + libs
###########################################################################################

uhc: $(EHC_FOR_UHC_BLD_EXEC) $(EHC_UHC_INSTALL_VARIANT)/ehclibs

UHC_INSTALL_VARIANT_PREFIX 	:= $(call FUN_INSTALLABS_VARIANT_PREFIX,$(EHC_UHC_INSTALL_VARIANT))
UHC_INSTALL_VARIANTNAME		:= $(UHC_EXEC_NAME)-$(EH_VERSION_FULL)
UHC_INSTALL_PREFIX			:= $(call FUN_DIR_VARIANT_PREFIX,$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME))

uhc-install: uhc
	mkdir -p $(UHC_INSTALL_PREFIX)
	$(call FUN_COPY_FILES_BY_TAR,$(UHC_INSTALL_VARIANT_PREFIX),$(UHC_INSTALL_PREFIX),*) ; \
	alltargets="`$(EHC_FOR_UHC_BLD_EXEC) --meta-targets`" ; \
	for target in $${alltargets} ; \
	do \
	  $(MAKE) uhc-install-postprocess-$${target} EHC_VARIANT_TARGET=$${target} ; \
	done ; \
	rm -f $(UHC_INSTALL_EXEC) ; \
	mkdir -p $(INSTALL_UHC_BIN_PREFIX) ; \
	ehc="$(UHC_INSTALL_PREFIX)bin/$(EHC_EXEC_NAME)$(EXEC_SUFFIX)" ; \
	$(STRIP) $${ehc} ; \
	ln -s $${ehc} $(UHC_INSTALL_EXEC)
	$(UHC_INSTALL_EXEC) --meta-export-env=$(TOPLEVEL_SYSTEM_ABSPATH_PREFIX)$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME)

uhc-install-postprocess-bc:
	cd $(call FUN_DIR_VARIANT_LIB_TARGET_PREFIX,$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME),$(EHC_VARIANT_TARGET)) ; \
	for pkg in $(EHC_PACKAGES_ASSUMED) ; \
	do \
	  rm -f $${pkg}/$(EHCLIB_MAIN)* ; \
	done

#	  rm -f $${pkg}/*.{hs,hs-cpp,c} $${pkg}/*/*.{hs,hs-cpp,c} $${pkg}/$(EHCLIB_MAIN)* ; \

uhc-install-postprocess-C:
	cd $(call FUN_DIR_VARIANT_LIB_TARGET_PREFIX,$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME),$(EHC_VARIANT_TARGET)) ; \
	for pkg in $(EHC_PACKAGES_ASSUMED) ; \
	do \
	  rm -f $${pkg}/$(EHCLIB_MAIN)* ; \
	done

#	  rm -f $${pkg}/*.{hs,hs-cpp} $${pkg}/*/*.{hs,hs-cpp} $${pkg}/$(EHCLIB_MAIN)* ; \

uhc-install-postprocess-core:
	
uhc-install-postprocess-jazy:
	
# still to do: uhc --meta-export-env=$(INSTALL_UHC_LIB_PREFIX),$(UHC_EXEC_NAME)

###########################################################################################
# Target: UHC: installation
###########################################################################################

install: uhc-install

###########################################################################################
# Target: UHC: regression test
###########################################################################################

uhc-test: thaw-test-expect
	@echo "WARNING: output may slightly differ for the following tests: " IO2.hs IO3.hs SysEnv1.hs
	$(MAKE) test-regress TEST_VARIANTS=uhc

test: uhc-test

###########################################################################################
# Target: clean build stuff
###########################################################################################

clean:
	$(MAKE) cleans
	$(MAKE) ruler-clean
	$(MAKE) shuffle-clean
	$(MAKE) libutil-clean
	@echo "NOTE: all but external libraries (gmp, ...) is cleaned. Use 'make clean-extlibs' for cleaning those."

clean-extlibs:
	$(MAKE) bgc-clean
	$(MAKE) gmp-clean

###########################################################################################
# Version incrementing/bumping
###########################################################################################

bump-major:
	@echo $$(($(EH_VERSION_MAJOR)+1)).0.0 > VERSION ; \
	echo "bumped version to `cat VERSION`"

bump-minor:
	@echo $(EH_VERSION_MAJOR).$$(($(EH_VERSION_MINOR)+1)).0 > VERSION ; \
	echo "bumped version to `cat VERSION`"

bump-minorminor:
	@echo $(EH_VERSION_MAJOR).$(EH_VERSION_MINOR).$$(($(EH_VERSION_MINORMINOR)+1)) > VERSION ; \
	echo "bumped version to `cat VERSION`"

###########################################################################################
# Releasing, currently just svn copying
###########################################################################################

release:
	cd ../.. ; \
	svn cp trunk/EHC releases/$(EH_VERSION_FULL)

release-prepare:
	$(MAKE) uhc
	@echo "WARNING: password may be needed"
	sudo $(MAKE) install
	$(MAKE) test-expect TEST_VARIANTS=uhc
	$(MAKE) freeze-test-expect

###########################################################################################
# Target: try outs and debugging of make variable definitions
###########################################################################################

FUN_PREFIX2DIR			= $(patsubst %/,%,$(1))

tst:
	@echo $(UHC_INSTALL_PREFIX)
	@echo $(INSTALL_UHC_BIN_PREFIX)

tstv:
	$(MAKE) EHC_VARIANT=100 tst

###########################################################################################
# Target: obsolete or to become so
###########################################################################################

#: afp-full ehcs doc grinis
#	$(MAKE) initial-test-expect

rules2.tex: rules2.rul
	$(RULER1) -l --base=rules $< | $(LHS2TEX) $(LHS2TEX_OPTS_POLY) > $@

A_EH_TEST			:= $(word 1,$(wildcard test/*.eh))
A_EH_TEST_EXP		:= $(addsuffix .exp$(VERSION_FIRST),$(A_EH_TEST))

$(A_EH_TEST_EXP): $(A_EH_TEST)
	$(MAKE) test-expect

initial-test-expect: $(A_EH_TEST_EXP)

WWW_EXAMPLES_TMPL			:=	www/ehc-examples-templ.html
WWW_EXAMPLES_HTML			:=	www/ehc-examples.html

www-ex: $(WWW_EXAMPLES_HTML)

$(WWW_EXAMPLES_HTML): $(WWW_EXAMPLES_TMPL)
	$(call PERL_SUBST_EHC,$(WWW_EXAMPLES_TMPL),$(WWW_EXAMPLES_HTML))

$(WWW_SRC_TGZ): $(DIST_TGZ)
	cp $^ $@

