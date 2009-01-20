%%[0
%include lhs2TeX.fmt
%include afp.fmt

%if style == poly
%format sl1
%format sl1'
%format sl2
%format sl2'
%endif
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Substitution for types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(2 hmtyinfer || hmtyast) module {%{EH}VarMp} import(Data.List, {%{EH}Base.Common}, {%{EH}Ty}) export(VarMp'(..), VarMp, emptyVarMp, varmpTyUnit, varmpTyLookup)
%%]

%%[(2 hmtyinfer || hmtyast) import(qualified Data.Map as Map,qualified Data.Set as Set,Data.Maybe)
%%]

%%[(2 hmtyinfer || hmtyast) import(EH.Util.Pretty, {%{EH}Ty.Pretty}) export(ppVarMpV)
%%]

%%[(4 hmtyinfer || hmtyast) export(varmpFilterTy,varmpDel,(|\>) ,varmpPlus, (|+>))
%%]

%%[(4 hmtyinfer || hmtyast) export(assocLToVarMp,varmpToAssocTyL)
%%]

%%[(4 hmtyinfer || hmtyast) import({%{EH}Error})
%%]

%%[(4_2 hmtyinfer || hmtyast) import(Maybe) export(varmpDelAlphaRename,varmpFilterAlphaRename,varmpFilterTyAltsMappedBy)
%%]

%%[(4_2 hmtyinfer || hmtyast) export(tyAsVarMp,varmpTyRevUnit)
%%]

%%[(9 hmtyinfer || hmtyast) import({%{EH}Base.Debug}) export(VarMpInfo(..),varmpToAssocL)
%%]

%%[(50 hmtyinfer || hmtyast) export(varmpKeys)
%%]

%%[(90 hmtyinfer || hmtyast) export(varmpMapTy)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Operator prio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(2 hmtyinfer || hmtyast)
infixr `varmpPlus`, |+>
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% VarMp'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(2 hmtyinfer || hmtyast).VarMpQ.Base
newtype VarMp' k v = VarMp (AssocL k v) deriving Show
%%]

%%[(9 hmtyinfer || hmtyast) -2.VarMpQ.Base
newtype VarMp' k v = VarMp (Map.Map k v)
%%]

%%[(99 hmtyinfer || hmtyast) export(varmpToMap)
varmpToMap :: VarMp' k v -> Map.Map k v
varmpToMap (VarMp m) = m
%%]

%%[(2 hmtyinfer || hmtyast).VarMp.emptyVarMp
emptyVarMp :: VarMp' k v
emptyVarMp = VarMp []

varmpIsEmpty :: VarMp' k v -> Bool
varmpIsEmpty (VarMp l) = null l
%%]

%%[(9 hmtyinfer || hmtyast).VarMp.emptyVarMp -2.VarMp.emptyVarMp
emptyVarMp :: VarMp' k v
emptyVarMp = VarMp Map.empty

varmpIsEmpty :: VarMp' k v -> Bool
varmpIsEmpty (VarMp m) = Map.null m
%%]

%%[(4 hmtyinfer || hmtyast).varmpFilter export(varmpFilter)
varmpFilter :: (k -> v -> Bool) -> VarMp' k v -> VarMp' k v
varmpFilter f (VarMp l) = VarMp (filter (uncurry f) l)

varmpPartition :: (k -> v -> Bool) -> VarMp' k v -> (VarMp' k v,VarMp' k v)
varmpPartition f (VarMp l)
  = (VarMp p1, VarMp p2)
  where (p1,p2) = partition (uncurry f) l
%%]

%%[(9 hmtyinfer || hmtyast).varmpFilter -4.varmpFilter
varmpFilter :: Ord k => (k -> v -> Bool) -> VarMp' k v -> VarMp' k v
varmpFilter f (VarMp c) = VarMp (Map.filterWithKey f c)

varmpPartition :: Ord k => (k -> v -> Bool) -> VarMp' k v -> (VarMp' k v,VarMp' k v)
varmpPartition f (VarMp m)
  = (VarMp p1, VarMp p2)
  where (p1,p2) = Map.partitionWithKey f m
%%]

%%[(2 hmtyinfer || hmtyast).varmpPlus
varmpPlus, (|+>) :: VarMp' k v -> VarMp' k v -> VarMp' k v
varmpPlus (VarMp l1) (VarMp l2) = VarMp (l1 ++ l2)
%%]

%%[(2 hmtyinfer || hmtyast).varmpPlusOp
(|+>) = varmpPlus
%%]

%%[(9 hmtyinfer || hmtyast).varmpPlus -2.varmpPlus
varmpPlus, (|+>) :: Ord k => VarMp' k v -> VarMp' k v -> VarMp' k v
varmpPlus (VarMp l1) (VarMp l2) = VarMp (l1 `Map.union` l2)
%%]

%%[(4 hmtyinfer || hmtyast) export(varmpUnion,varmpUnions)
varmpUnion :: Ord k => VarMp' k v -> VarMp' k v -> VarMp' k v
varmpUnion = varmpPlus

varmpUnions :: Ord k => [VarMp' k v] -> VarMp' k v
varmpUnions [x] = x
varmpUnions l   = foldr varmpPlus emptyVarMp l
%%]

%%[(4 hmtyinfer || hmtyast).varmpDel
varmpDel :: Ord k => [k] -> VarMp' k v -> VarMp' k v
varmpDel tvL c = varmpFilter (const.not.(`elem` tvL)) c

(|\>) :: Ord k => VarMp' k v -> [k] -> VarMp' k v
(|\>) = flip varmpDel
%%]

%%[(4 hmtyinfer || hmtyast).assocLToVarMp
assocLToVarMp :: AssocL k v -> VarMp' k v
assocLToVarMp = VarMp

varmpToAssocTyL :: VarMp' k v -> AssocL k v
varmpToAssocTyL (VarMp l) = l

varmpToAssocL :: VarMp' k v -> AssocL k v
varmpToAssocL = varmpToAssocTyL
%%]

%%[(9 hmtyinfer || hmtyast).assocLToVarMp -4.assocLToVarMp
assocLToVarMp :: Ord k => AssocL k v -> VarMp' k (VarMpInfo v)
assocLToVarMp = VarMp . Map.fromList . assocLMapElt VMITy

varmpToAssocL :: VarMp' k (VarMpInfo v) -> AssocL k (VarMpInfo v)
varmpToAssocL (VarMp l) = Map.toList l

varmpToAssocTyL :: VarMp' k (VarMpInfo v) -> AssocL k v
varmpToAssocTyL c = [ (v,t) | (v,VMITy t) <- varmpToAssocL c ]
%%]

%%[(9 hmtyinfer || hmtyast) export(varmpSize)
varmpSize :: VarMp' k v -> Int
varmpSize (VarMp m) = Map.size m
%%]

%%[(4 hmtyinfer || hmtyast).varmpKeys export(varmpKeys,varmpKeysSet)
varmpKeys :: VarMp' k v -> [k]
varmpKeys (VarMp l) = assocLKeys l

varmpKeysSet :: Ord k => VarMp' k v -> Set.Set k
varmpKeysSet = Set.fromList . varmpKeys
%%]

%%[(9 hmtyinfer || hmtyast).varmpKeys -4.varmpKeys export(varmpKeys,varmpKeysSet)
varmpKeys :: VarMp' k v -> [k]
varmpKeys (VarMp fm) = Map.keys fm

varmpKeysSet :: Ord k => VarMp' k v -> Set.Set k
varmpKeysSet (VarMp fm) = Map.keysSet fm
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% VarMp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(2 hmtyinfer || hmtyast).VarMp.Base
type VarMp  = VarMp' TyVarId Ty
%%]

20080610, AD, todo: use TvPurpose

%%[(9 hmtyinfer || hmtyast)
data VarMpInfo v
  = VMITy      !v
  | VMIImpls   !Impls
  | VMIScope   !PredScope
  | VMIPred    !Pred
  | VMIAssNm   !VarUIDHsName
%%[[10
  | VMILabel   !Label
  | VMIOffset  !LabelOffset
--  | VMIExts    !RowExts
%%]]
%%[[13
  | VMIPredSeq !PredSeq
%%]]
  deriving (Eq,Show)
%%]

%%[(9 hmtyinfer || hmtyast) -2.VarMp.Base
type VarMp  = VarMp' TyVarId (VarMpInfo Ty)

instance Show VarMp where
  show (VarMp c) = show (Map.toList c)
%%]

%%[(4 hmtyinfer || hmtyast).varmpFilterTy
varmpFilterTy :: (k -> v -> Bool) -> VarMp' k v -> VarMp' k v
varmpFilterTy = varmpFilter
%%]

%%[(9 hmtyinfer || hmtyast).varmpFilterTy -4.varmpFilterTy
varmpFilterTy :: Ord k => (k -> v -> Bool) -> VarMp' k (VarMpInfo v) -> VarMp' k (VarMpInfo v)
varmpFilterTy f = varmpFilter (\v i -> case i of {VMITy t -> f v t ; _ -> True})
%%]

%%[(4_2 hmtyinfer || hmtyast).varmpMapThr export(varmpMapThrTy)
varmpMapThrTy :: (TyVarId -> Ty -> thr -> (Ty,thr)) -> thr -> VarMp -> (VarMp,thr)
varmpMapThrTy f thr (VarMp l)
  =  let (l',thr')
           =  foldr    (\(v,t) (l,thr)
           				  ->  let  (t',thr') = f v t thr
           				      in   ((v,t'):l,thr')
                       )
                       ([],thr) l
     in  (VarMp l',thr')

varmpMapTy :: (TyVarId -> Ty -> Ty) -> VarMp -> VarMp
varmpMapTy f = fst . varmpMapThrTy (\v t _ -> (f v t,())) ()
%%]

%%[(9 hmtyinfer || hmtyast) -4_2.varmpMapThr export(varmpMapThr,varmpMapThrTy)
varmpMapThr :: (TyVarId -> VarMpInfo Ty -> thr -> (VarMpInfo Ty,thr)) -> thr -> VarMp -> (VarMp,thr)
varmpMapThr f thr (VarMp fm)
  =  let (fm',thr')
           =  Map.foldWithKey
                (\v i (fm,thr)
           		  ->  let  (i',thr') = f v i thr
           		      in   (Map.insert v i' fm,thr')
                )
                (Map.empty,thr) fm
     in  (VarMp fm',thr')

varmpMapThrTy :: (TyVarId -> Ty -> thr -> (Ty,thr)) -> thr -> VarMp -> (VarMp,thr)
varmpMapThrTy f = varmpMapThr (\v i thr -> case i of {VMITy t -> let (t',thr') = f v t thr in (VMITy t,thr'); _ -> (i,thr)})
%%]

%%[(9 hmtyinfer || hmtyast) hs export(varmpTailAddOcc)
varmpTailAddOcc :: ImplsProveOcc -> Impls -> (Impls,VarMp)
varmpTailAddOcc o (Impls_Tail i os) = (t, varmpImplsUnit i t)
                                    where t = Impls_Tail i (o:os)
varmpTailAddOcc _ x                 = (x,emptyVarMp)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Make var counterpart of VarMpInfo, for derivation tree pretty printing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(99 hmtyinfer || hmtyast).varmpinfoMkVar export(varmpinfoMkVar)
varmpinfoMkVar :: TyVarId -> VarMpInfo Ty -> Ty
varmpinfoMkVar v i
  = case i of
      VMITy       t -> mkTyVar v
      VMIImpls    i -> mkImplsVar v
      _             -> mkTyVar v					-- rest incomplete
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% VarMp singleton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(2 hmtyinfer || hmtyast).VarMp.varmpTyUnit
varmpTyUnit :: k -> v -> VarMp' k v
varmpTyUnit tv t = VarMp [(tv,t)]
%%]

%%[(9 hmtyinfer || hmtyast).VarMp.varmpTyUnit -2.VarMp.varmpTyUnit
varmpTyUnit :: Ord k => k -> v -> VarMp' k (VarMpInfo v)
varmpTyUnit v t = VarMp (Map.fromList [(v,VMITy t)])
%%]

%%[(4_2 hmtyinfer || hmtyast).varmpTyRevUnit
varmpTyRevUnit :: TyVarId -> Ty -> (Ty,VarMp)
varmpTyRevUnit tv t = maybe (t,varmpTyUnit tv t) (\v -> let t' = mkTyVar tv in (t',varmpTyUnit v t')) . tyMbVar $ t
%%]

%%[(9 hmtyinfer || hmtyast) export(varmpImplsUnit,assocLToVarMpImpls,varmpScopeUnit,varmpPredUnit,varmpAssNmUnit)
varmpImplsUnit :: ImplsVarId -> Impls -> VarMp
varmpImplsUnit v i = VarMp (Map.fromList [(v,VMIImpls i)])

varmpScopeUnit :: TyVarId -> PredScope -> VarMp
varmpScopeUnit v sc = VarMp (Map.fromList [(v,VMIScope sc)])

varmpPredUnit :: TyVarId -> Pred -> VarMp
varmpPredUnit v p = VarMp (Map.fromList [(v,VMIPred p)])

varmpAssNmUnit :: TyVarId -> VarUIDHsName -> VarMp
varmpAssNmUnit v p = VarMp (Map.fromList [(v,VMIAssNm p)])

assocLToVarMpImpls :: AssocL ImplsVarId Impls -> VarMp
assocLToVarMpImpls = VarMp . Map.fromList . assocLMapElt VMIImpls
%%]


%%[(10 hmtyinfer || hmtyast) export(varmpLabelUnit,varmpOffsetUnit)
varmpLabelUnit :: LabelVarId -> Label -> VarMp
varmpLabelUnit v l = VarMp (Map.fromList [(v,VMILabel l)])

varmpOffsetUnit :: UID -> LabelOffset -> VarMp
varmpOffsetUnit v l = VarMp (Map.fromList [(v,VMIOffset l)])

%%]
varmpExtsUnit :: UID -> RowExts -> VarMp
varmpExtsUnit v l = VarMp (Map.fromList [(v,VMIExts l)])

%%[(13 hmtyinfer || hmtyast) export(varmpPredSeqUnit)
varmpPredSeqUnit :: TyVarId -> PredSeq -> VarMp
varmpPredSeqUnit v l = VarMp (Map.fromList [(v,VMIPredSeq l)])
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% VarMp lookup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(2 hmtyinfer || hmtyast).varmpTyLookup
varmpTyLookup, varmpLookup :: Eq k => k -> VarMp' k v -> Maybe v
varmpTyLookup tv (VarMp s) = lookup tv s

varmpLookup = varmpTyLookup
%%]

%%[(9 hmtyinfer || hmtyast) -2.varmpTyLookup
varmpLookup' :: Ord k => (VarMpInfo v -> Maybe res) -> k -> VarMp' k (VarMpInfo v) -> Maybe res
varmpLookup' get v (VarMp s)
  = do { ci <- Map.lookup v s
       ; get ci
       }

varmpLookup :: Ord k => k -> VarMp' k (VarMpInfo v) -> Maybe (VarMpInfo v)
varmpLookup = varmpLookup' (Just . id)

varmpTyLookup :: Ord k => k -> VarMp' k (VarMpInfo v) -> Maybe v
varmpTyLookup = varmpLookup' (\ci -> case ci of {VMITy t -> Just t; _ -> Nothing})
%%]

%%[(9 hmtyinfer || hmtyast) export(varmpImplsLookup,varmpScopeLookup,varmpPredLookup)
varmpImplsLookup :: ImplsVarId -> VarMp -> Maybe Impls
varmpImplsLookup = varmpLookup' (\ci -> case ci of {VMIImpls i -> Just i; _ -> Nothing})

varmpScopeLookup :: TyVarId -> VarMp -> Maybe PredScope
varmpScopeLookup = varmpLookup' (\ci -> case ci of {VMIScope s -> Just s; _ -> Nothing})

varmpPredLookup :: TyVarId -> VarMp -> Maybe Pred
varmpPredLookup = varmpLookup' (\ci -> case ci of {VMIPred p -> Just p; _ -> Nothing})

varmpAssNmLookup :: TyVarId -> VarMp -> Maybe VarUIDHsName
varmpAssNmLookup = varmpLookup' (\ci -> case ci of {VMIAssNm p -> Just p; _ -> Nothing})
%%]

%%[(10 hmtyinfer || hmtyast) export(varmpLabelLookup,varmpOffsetLookup)
varmpLabelLookup :: LabelVarId -> VarMp -> Maybe Label
varmpLabelLookup = varmpLookup' (\ci -> case ci of {VMILabel l -> Just l; _ -> Nothing})

varmpOffsetLookup :: UID -> VarMp -> Maybe LabelOffset
varmpOffsetLookup = varmpLookup' (\ci -> case ci of {VMIOffset l -> Just l; _ -> Nothing})

%%]
varmpExtsLookup :: UID -> VarMp -> Maybe RowExts
varmpExtsLookup = varmpLookup' (\ci -> case ci of {VMIExts l -> Just l; _ -> Nothing})

%%[(13 hmtyinfer || hmtyast) export(varmpPredSeqLookup)
varmpPredSeqLookup :: TyVarId -> VarMp -> Maybe PredSeq
varmpPredSeqLookup = varmpLookup' (\ci -> case ci of {VMIPredSeq a -> Just a; _ -> Nothing})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% VarMp lookup: Cycle check variants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(4 hmtyinfer || hmtyast) export(varmpTyLookupCyc)
varmpTyLookupCyc :: TyVarId -> VarMp -> Maybe Ty
varmpTyLookupCyc x m = lookupLiftCycMb2 tyMbVar (varmpTyLookup2 m) x
%%]

%%[(9 hmtyinfer || hmtyast) export(varmpImplsLookupImplsCyc,varmpImplsLookupCyc,varmpScopeLookupScopeCyc,varmpAssNmLookupAssNmCyc)
varmpImplsLookupImplsCyc :: Impls -> VarMp -> Maybe Impls
varmpImplsLookupImplsCyc x m = lookupLiftCycMb1 implsMbVar (varmpImplsLookup2 m) x

varmpImplsLookupCyc :: TyVarId -> VarMp -> Maybe Impls
varmpImplsLookupCyc x m = lookupLiftCycMb2 implsMbVar (varmpImplsLookup2 m) x

varmpScopeLookupScopeCyc :: PredScope -> VarMp -> Maybe PredScope
varmpScopeLookupScopeCyc x m = lookupLiftCycMb1 pscpMbVar (varmpScopeLookup2 m) x

varmpAssNmLookupAssNmCyc :: VarUIDHsName -> VarMp -> Maybe VarUIDHsName
varmpAssNmLookupAssNmCyc x m = lookupLiftCycMb1 vunmMbVar (varmpAssNmLookup2 m) x
%%]

%%[(10 hmtyinfer || hmtyast) export(varmpLabelLookupCyc,varmpLabelLookupLabelCyc)
varmpLabelLookupLabelCyc :: Label -> VarMp -> Maybe Label
varmpLabelLookupLabelCyc x m = lookupLiftCycMb1 labelMbVar (varmpLabelLookup2 m) x

varmpLabelLookupCyc :: TyVarId -> VarMp -> Maybe Label
varmpLabelLookupCyc x m = lookupLiftCycMb2 labelMbVar (varmpLabelLookup2 m) x
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% VarMp lookup: Flipped variants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(4 hmtyinfer || hmtyast).varmpTyLookup2
varmpTyLookup2 :: Eq k => VarMp' k v -> k -> Maybe v
varmpTyLookup2 m v = varmpTyLookup v m
%%]

%%[(9 hmtyinfer || hmtyast) -4.varmpTyLookup2
varmpTyLookup2 :: Ord k => VarMp' k (VarMpInfo v) -> k -> Maybe v
varmpTyLookup2 m v = varmpTyLookup v m
%%]

%%[(4 hmtyinfer || hmtyast) export(varmpTyLookupCyc2)
varmpTyLookupCyc2 :: VarMp -> TyVarId -> Maybe Ty
varmpTyLookupCyc2 x m = varmpTyLookupCyc m x
%%]

%%[(9 hmtyinfer || hmtyast) export(varmpPredLookup2,varmpScopeLookup2,varmpAssNmLookup2,varmpImplsLookupCyc2)
varmpScopeLookup2 :: VarMp -> TyVarId -> Maybe PredScope
varmpScopeLookup2 m v = varmpScopeLookup v m

varmpImplsLookup2 :: VarMp -> ImplsVarId -> Maybe Impls
varmpImplsLookup2 m v = varmpImplsLookup v m

varmpImplsLookupCyc2 :: VarMp -> ImplsVarId -> Maybe Impls
varmpImplsLookupCyc2 m v = varmpImplsLookupCyc v m

varmpPredLookup2 :: VarMp -> TyVarId -> Maybe Pred
varmpPredLookup2 m v = varmpPredLookup v m

varmpAssNmLookup2 :: VarMp -> TyVarId -> Maybe VarUIDHsName
varmpAssNmLookup2 m v = varmpAssNmLookup v m
%%]

%%[(10 hmtyinfer || hmtyast)
varmpLabelLookup2 :: VarMp -> LabelVarId -> Maybe Label
varmpLabelLookup2 m v = varmpLabelLookup v m
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Closure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Faulty: computes cycles incorrectly, don't use 3d component of result.
20070705: obsolete now.

%%[(4 hmtyinfer || hmtyast)
%%]
 %%[[4
varmpClosure :: (TyVarId -> Bool) -> (x -> Set.Set TyVarId) -> VarMp' TyVarId x -> (Set.Set TyVarId,VarMp' TyVarId x,VarMp' TyVarId x)
 %%][9
varmpClosure :: (TyVarId -> Bool) -> (VarMpInfo x -> Set.Set TyVarId) -> VarMp' TyVarId (VarMpInfo x) -> (Set.Set TyVarId,VarMp' TyVarId (VarMpInfo x),VarMp' TyVarId (VarMpInfo x))
 %%]]
varmpClosure startWith tvof m
  = cl Set.empty m' emptyVarMp emptyVarMp
  where m' = varmpFilter (\k _ -> startWith k) m
        cl fvs mnew mcyc mres
          | varmpIsEmpty mnew
              = (fvs,mres,mcyc)
          | otherwise
              = cl (Set.unions fvsnew `Set.union` fvs) (varmpUnions mnew2) (varmpPlus mcyc1 mcyc) (varmpPlus mnew1 mres)
              where (mcyc1,mnew1) = varmpPartition (\k _ -> isJust $ varmpLookup k mres) mnew
                    (fvsnew,mnew2)
                      = unzip
                          [ (tvs,varmpFilter (\k _ -> k `Set.member` tvs) m)
                          | (_,x) <- varmpToAssocL mnew1
                          , let tvs = tvof x
                          ]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Remove alpha rename of tvars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(4_2 hmtyinfer || hmtyast)
varmpDelAlphaRename :: VarMp -> VarMp
varmpDelAlphaRename = varmpFilterTy (\_ t -> not (tyIsVar t))

varmpFilterAlphaRename :: VarMp -> VarMp
varmpFilterAlphaRename = varmpFilterTy (\_ t -> case t of {Ty_Var _ TyVarCateg_Plain -> True ; _ -> False})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Ty as cnstr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(4_2 hmtyinfer || hmtyast)
tyAsVarMp :: UID -> Ty -> (Ty,VarMp)
tyAsVarMp u ty
  =  case ty of
        Ty_Var _ TyVarCateg_Plain -> (ty,emptyVarMp)
        _ -> let t = mkNewTyVar u in (t,u `varmpTyUnit` ty)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Filter cnstr bound to Ty_Alts which has a cnstr in other
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(4_2 hmtyinfer || hmtyast)
varmpFilterTyAltsMappedBy :: VarMp -> VarMp -> VarMp
varmpFilterTyAltsMappedBy c cMp
  =  varmpFilterTy (\_ t -> case t of {Ty_Alts v _ -> isJust (varmpTyLookup v cMp) ; _ -> False}) c
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Pretty printing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(2 hmtyinfer || hmtyast).ppVarMp
ppVarMp :: ([PP_Doc] -> PP_Doc) -> VarMp -> PP_Doc
ppVarMp ppL (VarMp l) = ppL . map (\(n,v) -> pp n >|< ":->" >|< pp v) $ l
%%]

%%[(2 hmtyinfer || hmtyast)
ppVarMpV :: VarMp -> PP_Doc
ppVarMpV = ppVarMp vlist
%%]

%%[(9 hmtyinfer || hmtyast).ppVarMp -2.ppVarMp export(ppVarMp)
ppVarMp :: ([PP_Doc] -> PP_Doc) -> VarMp -> PP_Doc
ppVarMp ppL (VarMp l) = ppL . map (\(n,v) -> pp n >|< ":->" >|< pp v) . Map.toList $ l
%%]

%%[(2 hmtyinfer || hmtyast).PP
instance PP VarMp where
  pp = ppVarMp (ppListSepFill "" "" ", ")
%%]

%%[(99 hmtyinfer || hmtyast).ppVarMpInfoCfgTy export(ppVarMpInfoCfgTy,ppVarMpInfoDt)
ppVarMpInfoCfgTy :: CfgPPTy -> VarMpInfo Ty -> PP_Doc
ppVarMpInfoCfgTy c i
  = case i of
      VMITy       t -> ppTyWithCfg    c t
      VMIImpls    i -> ppImplsWithCfg c i
      VMIScope    s -> pp s						-- rest incomplete
      VMIPred     p -> pp p
      VMILabel    x -> pp x
      VMIOffset   x -> pp x
      VMIPredSeq  x -> pp "predseq" -- pp x

ppVarMpInfoDt :: VarMpInfo Ty -> PP_Doc
ppVarMpInfoDt = ppVarMpInfoCfgTy cfgPPTyDT
%%]

%%[(9 hmtyinfer || hmtyast)
instance PP v => PP (VarMpInfo v) where
  pp (VMITy       t) = pp t
  pp (VMIImpls    i) = pp i
  pp (VMIScope    s) = pp s
  pp (VMIPred     p) = pp p
%%[[10
  pp (VMILabel    x) = pp x
  pp (VMIOffset   x) = pp x
  -- pp (VMIExts     x) = pp "exts" -- pp x
%%]]
%%[[13
  pp (VMIPredSeq  x) = pp "predseq" -- pp x
%%]]
%%]
