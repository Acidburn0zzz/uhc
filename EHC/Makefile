#!/usr/bin/make -f

.PHONY: ehcs dist www www-sync install lib src build ruler1

###########################################################################################
# Location from which make is invoked
###########################################################################################

UHC_TOP_PREFIX			:= 
TOP_PREFIX				:= $(UHC_TOP_PREFIX)

###########################################################################################
# First (default) target just explains what can be done
###########################################################################################

default: uhc
#default: 99/ehclib
help: explanation

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
	$(GHC) -XFlexibleContexts --make $(GHC_OPTS) $(RULER1_HS) -o ../$@ && \
	$(STRIP) ../$@
### END of Ruler1

include src/files.mk
include $(UHC_SRC_PREFIX)ehc/shared.mk
include $(UHC_MK_PREFIX)functions.mk
include $(UHC_MK_PREFIX)shared.mk

#include $(UHC_SRC_PREFIX)libutil/files.mk
-include $(UHC_SRC_PREFIX)text2text/files.mk
#include $(UHC_SRC_PREFIX)ruler2/files.mk
include $(UHC_SRC_PREFIX)ehc/variant.mk
include $(UHC_SRC_PREFIX)gen/files.mk
include $(UHC_SRC_PREFIX)ehc/files1.mk

include extlibs/files.mk
ifeq ($(EHC_CFG_GMPLIB),gmp)
include $(EXTLIBS_PREFIX)bgc/files.mk
endif
ifeq ($(EHC_CFG_MPLIB),gmp)
include $(EXTLIBS_PREFIX)gmp/files.mk
endif
include $(EXTLIBS_PREFIX)ltm/files.mk
include ehclib/files1.mk
include $(UHC_SRC_PREFIX)rts/files.mk
ifeq ($(ENABLE_JAVA),yes)
-include $(UHC_SRC_PREFIX)jazy/files.mk
endif
ifeq ($(ENABLE_JS),yes)
-include $(UHC_SRC_PREFIX)javascript/files.mk
endif
include $(UHC_SRC_PREFIX)ehc/files2.mk
include ehclib/files2.mk
include test/files.mk
include test/benchmark/files.mk

#-include $(UHC_MK_PREFIX)dist.mk

###########################################################################################
# all versions (as used by testing)
###########################################################################################

VERSIONS			:= $(EHC_PUB_VARIANTS)

# distributed/published stuff for WWW
#WWW_SRC_TGZ					:= www/current-ehc-src.tgz
#WWW_DOC_PDF					:= www/current-ehc-doc.pdf

###########################################################################################
# UHC specific definitions
###########################################################################################

UHC_INSTALL_VARIANT_PREFIX 	:= $(call FUN_INSTALLABS_VARIANT_PREFIX,$(EHC_UHC_INSTALL_VARIANT))
UHC_INSTALL_VARIANTNAME		:= $(UHC_EXEC_NAME)-$(EH_VERSION_FULL)
UHC_INSTALL_PREFIX			:= $(call FUN_DIR_VARIANT_PREFIX,$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME))
UHC_INSTALL_EHCBINARY		:= $(UHC_INSTALL_PREFIX)bin/$(EHC_EXEC_NAME)$(EXEC_SUFFIX)

###########################################################################################
# Target: explain what can be done
###########################################################################################

explanation:
	@$(EXIT_IF_ABSENT_LIB_OR_TOOL)
	@echo "UHC" ; \
	echo  "===" ; \
	echo  "make                     : defaults to 'make uhc'" ; \
	echo  "make uhc                 : make uhc and library (ehc variant 101)" ; \
	echo  "make install             : make uhc and install globally (into $(UHC_INSTALL_PREFIX)), possibly needing admin permission" ; \
	echo  "make uninstall           : uninstall uhc, possibly needing admin permission" ; \
	echo  "make test                : regress test uhc" ; \
	echo  "" ; \
    echo  "EHC & tools" ; \
	echo  "===========" ; \
	echo  "make <n>/ehc             : make compiler variant <n> (in bin/, where <n> in {$(EHC_PUB_VARIANTS)})" ; \
	echo  "make <n>/ehcr            : make runner (of CoreRun) variant <n> (in bin/, where <n> in {$(EHC_CODE_VARIANTS)})" ; \
	echo  "make <n>/ehclib          : make ehc library (i.e. used to compile with ehc) variant <n> (in bin/, where <n> in {$(EHC_PREL_VARIANTS)})" ; \
	echo  "make <n>/ehclibs         : make ehc libraries for all codegen targets" ; \
	echo  "make <n>/rts             : make only the rts part of a library" ; \
	echo  "make <n>/bare            : make bare source dir for variant <n> (in bare/)," ; \
	echo  "                           then 'cd' to there and 'make'" ; \
	echo  "" ; \
    echo  "Documentation" ; \
	echo  "=============" ; \
	echo  "make help                : print this help" ; \
	echo  "" ; \
    echo  "Testing" ; \
	echo  "===========" ; \
	echo  "make test-regress        : run regression test," ; \
	echo  "                           restrict to versions <v> by specifying 'TEST_VARIANTS=<v>' (default '${TEST_VARIANTS}')," ; \
	echo  "                           requires corresponding $(EHC_EXEC_NAME)/$(GRINI_EXEC_NAME)/$(EHCLIB_EHCLIB) already built" ; \
	echo  "make test-expect         : make expected output (for later comparison with test-regress), see test-regress for remarks" ; \
	echo  "make benchmark           : run 16 nofib programs with 3 compilers on 3 inputs each"; \
	echo  "" ; \
    echo  "Distribution" ; \
	echo  "===========" ; \
	echo  "make uhc-light           : make cabal version of a light UHC variant in $(CABALDIST_UHCLIGHT_PREFIX)" ; \
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
# Target: www stuff + sync to www. The full content of www is copied, including releases
###########################################################################################

# www: $(WWW_SRC_TGZ) www-ex $(WWW_DOC_FILES)
www: $(WWW_DOC_FILES)

# www/DoneSyncStamp: www-ex
www/DoneSyncStamp: www
	(date "+%G%m%d %H:%M") > www/DoneSyncStamp ; \
	chmod 664 www/* ; \
	rsync --progress -azv -e ssh www/* dijks106@csstaff.science.uu.nl:/users/www/groups/ST/Projects/ehc

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

# install util functions, also used for building distribution (see target uhc-dist)

# Copy install files to install/dist location
# $1: src install prefix
# $2: dst install prefix
FUN_INSTALLUHC_COPY	= \
	echo "Copying files to $(2) ..." && \
	mkdir -p $(2) && \
	$(call FUN_COPY_FILES_AND_RENAME,$(1),$(2),$(EHC_UHC_INSTALL_VARIANT),$(UHC_INSTALL_VARIANTNAME)) && \
	$(STRIP) $(2)bin/$(EHC_EXEC_NAME)$(EXEC_SUFFIX) && \
	alltargets="`$(EHC_FOR_UHC_BLD_EXEC) --meta-targets`" && \
	echo "Postprocessing installation ..." && \
	for target in $${alltargets} ; \
	do \
	  $(MAKE) uhc-install-postprocess-$${target} EHC_VARIANT_TARGET=$${target} ; \
	done

# install

uhc: $(EHC_FOR_UHC_BLD_EXEC) $(EHC_UHC_INSTALL_VARIANT)/ehclibs

uhc-install: uhc
	@rm -f $(DESTDIR)$(UHC_INSTALL_EXEC)
	@$(call FUN_INSTALLUHC_COPY,$(UHC_INSTALL_VARIANT_PREFIX),$(DESTDIR)$(UHC_INSTALL_PREFIX)) ; \
	rm -f $(DESTDIR)$(UHC_INSTALL_EXEC) ; \
	mkdir -p $(DESTDIR)$(INSTALL_UHC_BIN_PREFIX) ; \
 	$(call FUN_INSTALLUHC_WRAPPER,$(UHC_INSTALL_EHCBINARY),$(DESTDIR)$(UHC_INSTALL_SHELL),$(DESTDIR)$(INSTALL_UHC_BIN_PREFIX),$(TOPLEVEL_SYSTEM_ABSPATH_PREFIX)$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME))
	@echo "Installation done"

#	ln -s $(UHC_INSTALL_EHCBINARY) $(UHC_INSTALL_EXEC)
#	$(UHC_INSTALL_EXEC) --meta-export-env=$(TOPLEVEL_SYSTEM_ABSPATH_PREFIX)$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME)

uhc-uninstall:
	@echo "Removing installation $(DESTDIR)$(UHC_INSTALL_PREFIX) ..."
	rm -fr $(DESTDIR)$(UHC_INSTALL_PREFIX) $(DESTDIR)$(UHC_INSTALL_EXEC)

uhc-install-postprocess-bc:
#	@cd $(call FUN_DIR_VARIANT_LIB_TARGET_PREFIX,$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME),$(EHC_VARIANT_TARGET)) ; \
#	for pkg in $(EHC_PACKAGES_ASSUMED) ; \
#	do \
#	  rm -f $${pkg}/$(EHCLIB_MAIN)* ; \
#	done

#	  rm -f $${pkg}/*.{hs,hs-cpp,c} $${pkg}/*/*.{hs,hs-cpp,c} $${pkg}/$(EHCLIB_MAIN)* ; \

uhc-install-postprocess-C:
#	@cd $(call FUN_DIR_VARIANT_LIB_TARGET_PREFIX,$(INSTALL_UHC_ROOT),$(UHC_INSTALL_VARIANTNAME),$(EHC_VARIANT_TARGET)) ; \
#	for pkg in $(EHC_PACKAGES_ASSUMED) ; \
#	do \
#	  rm -f $${pkg}/$(EHCLIB_MAIN)* ; \
#	done

#	  rm -f $${pkg}/*.{hs,hs-cpp} $${pkg}/*/*.{hs,hs-cpp} $${pkg}/$(EHCLIB_MAIN)* ; \

uhc-install-postprocess-core:
	
uhc-install-postprocess-jazy:
	
uhc-install-postprocess-js:
	
uhc-install-postprocess-cr:
	
uhc-install-postprocess-llvm:
	
# still to do: uhc --meta-export-env=$(INSTALL_UHC_LIB_PREFIX),$(UHC_EXEC_NAME)

###########################################################################################
# Target: UHC light, for installation as lib/cabal/package, Core only based subset
###########################################################################################

uhc-light:
	$(MAKE) ENABLE_JS= EHC_VARIANT=$(EHC_UHCLIGHT_CABAL_VARIANT) uhc-light-dist
	cd $(CABALDIST_UHCLIGHT_PREFIX) && cabal configure && cabal sdist

uhc-light-tst:
	$(MAKE) ENABLE_JS= EHC_VARIANT=$(EHC_UHCLIGHT_CABAL_VARIANT) INCLUDE_DERIVED_MK=yes uhc-light-cabal-dist

uhc-light-dist:
	$(MAKE) $(EHC_UHCLIGHT_CABAL_VARIANT)/ehc
	$(MAKE) $(EHC_UHCLIGHT_CABAL_VARIANT)/ehclib
	$(MAKE) INCLUDE_DERIVED_MK=yes uhc-light-cabal-dist

###########################################################################################
# Target: UHC: binary distribution generation
###########################################################################################

uhc-dist: uhc
	@distnm="$(UHC_INSTALL_VARIANTNAME)-$(subst :,-,$(GIT_REVISION))-$(DATE)-$(HOST_PLATFORM_NRWORDBITS)-$(HOST_PLATFORM_NAME)" && \
	distdir="$(DISTABS_PREFIX)$${distnm}" && \
	mkdir -p $${distdir} && \
	$(call FUN_INSTALLUHC_COPY,$(UHC_INSTALL_VARIANT_PREFIX),$${distdir}/dist/) && \
	echo "Generating install (make, config, ...) files to $${distdir} ..." && \
	mkdir -p $(UHC_INSTALL_VARIANT_PREFIX) && \
	( echo "# installation makefile, generated for $${distnm}" && \
	  echo "" && \
	  echo "TAR:=$(TAR)" && \
	  echo 'include mk/functions.mk' && \
	  echo "" && \
	  echo 'DIST_DIR:=@prefix@' && \
	  echo 'DIST_PREFIX:=$$(DIST_DIR)/' && \
	  echo 'DIST_LIB_DIR:=$$(DIST_PREFIX)lib' && \
	  echo 'DIST_LIB_PREFIX:=$$(DIST_LIB_DIR)/' && \
	  echo 'DIST_BIN_PREFIX:=$$(DIST_PREFIX)bin/' && \
	  echo 'DIST_INSTALL_PREFIX:=$$(call FUN_DIR_VARIANT_PREFIX,$$(DIST_LIB_DIR),'"$(UHC_INSTALL_VARIANTNAME)"')' && \
	  echo 'DIST_EHCBINARY:=$$(DIST_INSTALL_PREFIX)bin/'"$(EHC_EXEC_NAME)$(EXEC_SUFFIX)" && \
	  echo 'DIST_UHCSHELL:=$$(DIST_BIN_PREFIX)'"$(UHC_EXEC_NAME)" && \
	  echo "" && \
	  echo "default:" && \
	  echo "	@echo This is a binary distribution, UHC is already built, install with \'make install\'" && \
	  echo "" && \
	  echo "install:" && \
	  echo '	@echo Installing files to $$(DIST_INSTALL_PREFIX) ...' && \
	  echo '	@$$(call FUN_COPY_FILES_BY_TAR,dist,$$(DIST_INSTALL_PREFIX),*)' && \
	  echo '	@$$(call FUN_INSTALLUHC_WRAPPER,$$(DIST_EHCBINARY),$$(DIST_UHCSHELL),$$(DIST_BIN_PREFIX),$$(DIST_LIB_PREFIX),'"$(UHC_INSTALL_VARIANTNAME)"')' && \
	  echo "" && \
	  echo "uninstall:" && \
	  echo '	@echo Removing installation $$(DIST_INSTALL_PREFIX) ...' && \
	  echo '	rm -rf $$(DIST_INSTALL_PREFIX) $$(DIST_UHCSHELL)' && \
	  echo "" \
	) > $${distdir}/Makefile.in && \
	( echo "# installation configure, generated for $${distnm}" && \
	  echo "AC_INIT([UHC],[$(EH_VERSION_FULL)],[uhc-users@lists.science.uu.nl, http://www.cs.uu.nl/wiki/UHC/WebHome])" && \
	  echo 'AC_CANONICAL_HOST' && \
	  echo 'AC_CONFIG_FILES([Makefile])' && \
	  echo 'AC_OUTPUT' && \
	  echo "" \
	) > $${distdir}/configure.ac && \
	cp LICENSE README \
		aclocal.m4 \
		install-sh \
		config.guess config.sub \
		$${distdir} && \
	mkdir -p $${distdir}/mk && \
	cp $(UHC_MK_PREFIX)functions.mk \
		$${distdir}/mk && \
	cd $${distdir} && \
	autoconf && \
	cd .. && \
	echo "Building distribution archive $${distnm}.tar.bz2 ..." && \
	tar cfj $${distnm}.tar.bz2 $${distnm} && \
	echo "Done"

###########################################################################################
# Target: UHC: installation
###########################################################################################

install: uhc-install

uninstall: uhc-uninstall

###########################################################################################
# Target: UHC: partial uhc via cabal
###########################################################################################

uhc-pkg:
	$(MAKE) 103/clean
	$(MAKE) uhc-light

###########################################################################################
# Target: UHC: regression test
###########################################################################################

uhc-test: thaw-test-expect
	@echo "WARNING: output may slightly differ for tests commented with 'platform',"
	@echo "         and (because of visible internal naming) for:" IO2.hs IO3.hs
	$(MAKE) test-regress TEST_VARIANTS=uhc

test: uhc-test

# buildfarm like testing
test-all:
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	make clean && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	./configure && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	make 100/ehc && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	make 100/ehclibs && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	make test-regress TEST_VARIANTS=100 ; \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	make test-regress TEST_VARIANTS=100 EHC_VARIANT_TARGET=js ; \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	make 100/clean && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	./configure --with-aspects="base" && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	make 100/ehc && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	make clean && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	./configure && \
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" && \
	echo DONE

###########################################################################################
# Target: clean build stuff
###########################################################################################

clean:
	$(MAKE) cleans
	rm -rf $(DIST_PREFIX) $(CABALDIST_UHCLIGHT_PREFIX)

#	$(MAKE) libutil-clean

#	@echo "NOTE: all but external libraries (gmp, ...) is cleaned. Use 'make clean-extlibs' for cleaning those."

clean-extlibs:
	#$(MAKE) bgc-clean
	#$(MAKE) gmp-clean

###########################################################################################
# Version incrementing/bumping/tagging
###########################################################################################

CHANGELOG		:= changelog.md

git-fixate-tagversion:
	( echo "" ; \
	  echo "## $(EH_VERSION_FULL) - $(DATE)" ; \
	  echo "" ; \
	  cat $(CHANGELOG).editthis ; \
	) > $(CHANGELOG).tmp
	( echo "# Changelog" ; \
	  cat $(CHANGELOG).tmp ; \
	) > $(CHANGELOG)
	( echo "- [edit this] and this, adding new entries as needed (version nr etc is prefixed when using version bumping Makefile targets)" ; \
	  cat $(CHANGELOG).tmp ; \
	) > $(CHANGELOG).editthis
	rm $(CHANGELOG).tmp
	git tag -a "v$(EH_VERSION_FULL)" -m "Version $(EH_VERSION_FULL)"
	git ci -m "Fixate/tag v$(EH_VERSION_FULL)"
	ghc-pkg hide uhc-light-$(EH_VERSION_FULL)
	$(MAKE) uhc-light

bump-major: git-fixate-tagversion
	@echo $$(($(EH_VERSION_MAJOR)+1)).0.0.0 > VERSION ; \
	echo "bumped version to `cat VERSION`"
	git ci -m "bumped version to `cat VERSION`"

bump-minor: git-fixate-tagversion
	@echo $(EH_VERSION_MAJOR).$$(($(EH_VERSION_MINOR)+1)).0.0 > VERSION ; \
	echo "bumped version to `cat VERSION`"
	git ci -m "bumped version to `cat VERSION`"

bump-minorminor: git-fixate-tagversion
	@echo $(EH_VERSION_MAJOR).$(EH_VERSION_MINOR).$$(($(EH_VERSION_MINORMINOR)+1)).0 > VERSION ; \
	echo "bumped version to `cat VERSION`"
	git ci -m "bumped version to `cat VERSION`"

bump-minorminorminor: git-fixate-tagversion
	@echo $(EH_VERSION_MAJOR).$(EH_VERSION_MINOR).$(EH_VERSION_MINORMINOR).$$(($(EH_VERSION_MINORMINORMINOR)+1)) > VERSION ; \
	echo "bumped version to `cat VERSION`"
	git ci -m "bumped version to `cat VERSION`"

# ... and shortcuts

bump-M: bump-major
bump-m: bump-minor
bump-mm: bump-minorminor
bump-mmm: bump-minorminorminor

###########################################################################################
# Releasing, currently just svn copying
###########################################################################################

release:
	cd ../.. ; \
	svn cp trunk/EHC releases/$(EH_VERSION_FULL)
	$(MAKE) uhc-src-dist

release-prepare:
	$(MAKE) uhc
	@echo "WARNING: password may be needed to install uhc"
	sudo $(MAKE) install
	$(MAKE) test-expect TEST_VARIANTS=uhc
	$(MAKE) freeze-test-expect

###########################################################################################
# Target: try outs and debugging of make variable definitions
###########################################################################################

FUN_PREFIX2DIR			= $(patsubst %/,%,$(1))

tst:
	@echo $(EHC_ALL_LIB_FROMAG_HS)

tstv:
	$(MAKE) INCLUDE_DERIVED_MK=yes EHC_VARIANT=100 tst

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

