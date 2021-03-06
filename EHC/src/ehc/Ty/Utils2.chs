%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Utilities for Ty which cannot be placed elsewhere (e.g. because of module cycles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen hmtyinfer) module {%{EH}Ty.Utils2} import({%{EH}Base.Common}, {%{EH}Ty}) 
%%]

%%[(8 codegen hmtyinfer) import({%{EH}Base.HsName.Builtin}, {%{EH}Opts}) 
%%]
%%[(8 codegen hmtyinfer) import({%{EH}VarMp}) 
%%]
%%[(8 codegen hmtyinfer) import({%{EH}Ty.FitsInCommon}) 
%%]
%%[(8 codegen) import({%{EH}AbstractCore})
%%]
%%[(9 codegen hmtyinfer) import({%{EH}Core},{%{EH}Core.Subst})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Coercion application
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(9 codegen hmtyinfer) export(foAppLRCoeAsSubst)
foAppLRCoeAsSubst :: EHCOpts -> UID -> FIOut -> VarMp -> CSubst -> CExpr -> (CExpr,CSubst)
foAppLRCoeAsSubst opts uniq fo c cs ce
  = (ce', foCSubst fo `cSubstApp` s1 `cSubstApp` s2)
  where (u',u1,u2) = mkNewLevUID2 uniq
        -- s0 = cs `cSubstApp` foCSubst fo
        (ww ,s1) = lrcoeWipeWeaveAsSubst opts u1 c (foLRCoe fo)
        (ce',s2) = coeEvalOnAsSubst u2 ww ce
%%]

-- for use by Ruler
%%[(9 codegen && hmtyinfer && hmTyRuler) export(foAppLRCoe')
foAppLRCoe' :: EHCOpts -> (CSubst,LRCoe) -> VarMp -> CSubst -> CExpr -> CExpr
foAppLRCoe' opts (fCS,fLRCoe) c cs ce
  =  let  s = cs `cSubstApp` fCS
     in   cSubstApp s (lrcoeWipeWeave opts c s fLRCoe `coeEvalOn` ce)
%%]

