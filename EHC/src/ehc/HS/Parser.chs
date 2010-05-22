%%[0
%include lhs2TeX.fmt
%include afp.fmt
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 module {%{EH}HS.Parser} import(UU.Parsing, UU.Parsing.Offside, EH.Util.ParseUtils, UU.Scanner.GenToken, EH.Util.ScanUtils, {%{EH}Base.Common}, {%{EH}Base.Builtin}, {%{EH}Scanner.Common}, {%{EH}HS})
%%]

%%[1 import(IO)
%%]

%%[5 import(Data.Maybe)
%%]

%%[(8 codegen) import ({%{EH}Base.Target})
%%]

%%[99 import (qualified EH.Util.FastSeq as Seq)
%%]

-- debugging
%%[1 import(EH.Util.Utils, EH.Util.Pretty)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scanner related
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
tokConcat :: Token -> Token -> Token
tokConcat t1 t2 = Reserved (tokenVal t1 ++ tokenVal t2) (position t1)

tokEmpty :: Token
tokEmpty = Reserved "" noPos
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 export(HSParser,HSParser')
type HSParser         ep    =    LayoutParser Token ep
type HSParser'        ep    =    PlainParser Token ep
%%]

%%[1 export(pAGItf)
pAGItf :: HSParser AGItf
pAGItf
%%[[1
  =   AGItf_AGItf <$> pModule pBody
%%][99
  =   AGItf_AGItf <$> pModule pBody'
  -- =   AGItf_AGItf <$> pModule (pBody ())
  where pBody :: () -> HSParser Body2Result
        pBody _ = fst (pBody2 ())
%%]]
%%]

%%[20 export(pAGItfImport)
pAGItfImport :: HSParser AGItf
pAGItfImport
%%[[1
  =   AGItf_AGItf <$> pModule pBodyImport
%%][99
  =   AGItf_AGItf <$> pModule (\_ -> pBodyImport)
  -- =   AGItf_AGItf <$> pModule (pBody ())
  where pBody :: () -> HSParser Body2Result
        pBody _ = snd (pBody2 ())
%%]]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Abstractions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
pPacked' :: HSParser Token -> HSParser Token -> HSParser (Range -> v) -> HSParser v
pPacked' pO pC pMk = (\o mk c -> mk (mkRange2 o c)) <$> pO <*> pMk <*> pC

pParens' :: HSParser (Range -> v) -> HSParser v
pParens' = pPacked' pOPAREN pCPAREN

pBracks' :: HSParser (Range -> v) -> HSParser v
pBracks' = pPacked' pOBRACK pCBRACK

pCurlys' :: HSParser (Range -> v) -> HSParser v
pCurlys' = pPacked' pOCURLY pCCURLY
%%]

%%[9
pImpls' :: HSParser (Range -> v) -> HSParser v
pImpls' = pPacked' pOIMPL pCIMPL

pImpls :: IsParser p Token => p v -> p v
pImpls = pPacked pOIMPL pCIMPL
%%]

%%[1.pApp
pApp            ::   SemApp ep => HSParser ep -> HSParser ep
pApp p          =    mkApp <$> pList1 p
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Pragma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99
pPragma' :: (Range -> Pragma -> x) -> HSParser x
pPragma' mk
  = pPacked' pOPRAGMA pCPRAGMA
      (   (\t ps r -> mk r $ Pragma_Language   (mkRange1 t) ps)
          <$> pLANGUAGE_prag   <*> pCommas (tokMkQName <$>           conid)
      <|> (\t cl fld val r -> mk r $ Pragma_Derivable (mkRange1 t) (tokMkQName cl) (tokMkQName fld) (tokMkQName val))
          <$> pDERIVABLE_prag  <*> gtycon' tyconsym <*> var <*> qvar
      -- <|> (\t ps r -> mk r $ Pragma_OptionsGHC (mkRange1 t) ps) <$> pOPTIONSGHC_prag <*> pCommas (tokMkQName <$ pMINUS <*> conid)
      )

pPragma :: HSParser Pragma
pPragma = pPragma' (flip const)

pDeclarationPragma :: HSParser Declaration
pDeclarationPragma
  = pPragma' Declaration_Pragma

%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Module
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
%%[[1
pModule :: HSParser Body -> HSParser Module
%%][99
pModule :: ((HSParser Declaration -> HSParser Declaration) -> HSParser Body) -> HSParser Module
-- pModule :: HSParser Body2Result -> HSParser Module
%%]]
pModule pBody
%%[[1
  =          (\      b   -> Module_Module emptyRange   Nothing                           b) <$> pBody
         <|> (\t m   b   -> Module_Module (mkRange1 t) (Just $ tokMkQName $ m)           b) <$> pMODULE <*> modid <* pWHERE <*> pBody
%%][20
  =          (\      b   -> Module_Module emptyRange   Nothing                   Nothing b) <$> pBody
         <|> (\t m e b   -> Module_Module (mkRange1 t) (Just $ tokMkQName $ m)   e       b) <$> pMODULE <*> modid <*> pMaybeExports <* pWHERE <*> pBody
%%][99
  = pList_gr pPragma
    <**> (   (\      b p -> Module_Module emptyRange   Nothing                 p Nothing b) <$> pBody id
         <|> (\t m e b p -> Module_Module (mkRange1 t) (Just $ tokMkQName $ m) p e       b) <$> pMODULE <*> modid <*> pMaybeExports <* pWHERE <*> pBody (\d -> d <|> pDeclarationPragma)
         )
{-
  = (\(pragmas,mbheaders,body)
       -> case mbheaders of
            [(r,nm,mbe)] -> Module_Module r          (Just nm) pragmas mbe     body
            _            -> Module_Module emptyRange Nothing   pragmas Nothing body
    )
    <$> pBody
-}
%%]]
  <?> "pModule"
%%]

%%[1
pBody' :: (HSParser Declaration -> HSParser Declaration) -> HSParser Body
pBody' addDecl
%%[[1
  =   Body_Body emptyRange <$> pDeclarations1' (addDecl pTopDeclaration)
  <|> pSucceed (Body_Body emptyRange [])
%%][20
  =   (\ids -> let (i,d) = foldr cmbid ([],[]) ids in Body_Body emptyRange i d)
      <$> pDeclarations' (   (\d -> ([],[d])) <$> (addDecl pTopDeclaration)
                         <|> (\i -> ([i],[])) <$> pImportDeclaration
                         )
%%]]
  <?> "pBody"
%%[[20
  where cmbid ([i],_) (is,ds) = (i:is,ds)
        cmbid (_,[d]) (_ ,ds) = ([],d:ds)
%%]]
%%]

%%[1
pBody :: HSParser Body
pBody = pBody' id
%%]

%%[99
type BodyModuleHeader = (Range,Name,MaybeExports)

pHeaderModule :: HSParser BodyModuleHeader
pHeaderModule
  =   (\t m e -> (mkRange1 t,tokMkQName m,e)) <$> pMODULE <*> modid <*> pMaybeExports <* pWHERE
%%]

%%[1
type Body2Result
%%[[1
  = Body
%%][20
  = Body
%%][99
  = ([Pragma],[BodyModuleHeader],Body)
%%]]
%%]

%%[1
pBody2 :: () {- dummy parameter -} ->
%%[[1
  (HSParser Body2Result,HSParser Body)
%%][99
  (HSParser Body2Result,HSParser Body2Result)
%%]]
pBody2 _
  = (pBody,pBodyImport)
  where pBody :: HSParser Body2Result
        pBody
%%[[1
          =   Body_Body emptyRange <$> pDeclarations1' pTopDeclaration
          <|> pSucceed (Body_Body emptyRange [])
%%][20
          =   (\ids -> let (i,d) = foldr cmb ([],[]) ids in Body_Body emptyRange i d)
              <$> pDeclarations' (   (\d -> ([],[d])) <$> pTopDeclaration
                                 <|> (\i -> ([i],[])) <$> pImportDeclaration
                                 )
%%][99
          =   (\ids -> let (p,m,i,d) = foldl cmb (emp,emp,emp,emp) ids
                       in  (l p, l m, Body_Body emptyRange (l i) (l d))
              )
              <$> pDeclarations' (pP <|> pM <|> pI <|> pD)
%%]]
          <?> "pBody"
        pBodyImport :: HSParser Body2Result
        pBodyImport
%%[[1
          =   undefined
%%][20
          =   (\d -> Body_Body emptyRange d [])
              <$> pDeclarations' pImportDeclaration
%%][99
          =   (\ids -> let (p,m,i,_) = foldl cmb (emp,emp,emp,emp) ids
                       in  (l p, l m, Body_Body emptyRange (l i) [])
              )
              <$> pDeclarations' (pP <|> pM <|> pI)
%%]]
          <?> "pBodyImport"
%%[[20
        -- combine declarations
        cmb ([i],_) (is,ds) = (i:is,ds)
        cmb (_,[d]) (_ ,ds) = ([],d:ds)
%%][99
        -- declaration parsers
        pM, pD, pP, pI :: HSParser (Seq.Seq Pragma,Seq.Seq BodyModuleHeader,Seq.Seq ImportDeclaration,Seq.Seq Declaration)
        pP = (\d -> (s d, emp, emp, emp)) <$> pPragma
        pM = (\d -> (emp, s d, emp, emp)) <$> pHeaderModule
        pI = (\d -> (emp, emp, s d, emp)) <$> pImportDeclaration
        pD = (\d -> (emp, emp, emp, s d)) <$> pTopDeclaration
        
        -- combine declarations
        cmb (ps,ms,is,ds) (p,_,_,_) | isnemp p && isemp ms && isemp is && isemp ds
                                               = (p+ps,ms ,  is,   ds)
                                    | isnemp p = (  ps,ms ,  is,p'+ds)
                                    where p' = s $ Declaration_Pragma emptyRange $ head $ l p
        cmb (ps,ms,is,ds) (_,m,_,_) | isnemp m = (  ps,m  ,  is,   ds)
        cmb (ps,ms,is,ds) (_,_,i,_) | isnemp i = (  ps,ms ,i+is,   ds)
        cmb (ps,ms,is,ds) (_,_,_,d) | isnemp d = (  ps,ms ,  is,d +ds)

        -- Seq aliases
        emp    = Seq.empty
        (+)    = Seq.union
        s      = Seq.singleton
        isemp  = Seq.null
        isnemp = not . isemp
        l      = Seq.toList
%%]]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Module header + import only
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20
pBodyImport :: HSParser Body
pBodyImport
  =   (\d -> Body_Body emptyRange d []) <$> pDeclarations' pImportDeclaration
  <?> "pBodyImport"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Export, import
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20
pImportExport :: (Range -> Name -> ie,Range -> Name -> MaybeNames -> ie,Range -> Name -> ie) -> HSParser ie
pImportExport (sem_Var,sem_tOrC,sem_tOrC_complete)
  =   mkRngNm sem_Var <$> qvar
  <|> qtycon
      <**> (   pParens
                 (   (\c n -> mkRngNm sem_tOrC n (Just (tokMkQNames c))) <$> qcnames
                 <|> mkRngNm sem_tOrC_complete <$ pDOTDOT
                 )
           <|> pSucceed (\n -> mkRngNm sem_tOrC n Nothing)
           )
  <?> "pImportExport"
%%]

%%[20
pExport :: HSParser Export
pExport
  =   (\t m -> Export_Module (mkRange1 t) (tokMkQName m)) <$> pMODULE <*> modid
  <|> pImportExport (Export_Variable,Export_TypeOrClass,Export_TypeOrClassComplete)
  <?> "pExport"

pMaybeExports :: HSParser MaybeExports
pMaybeExports
  =   Just <$> pParens (pListSep_ng pCOMMA pExport <* pMb pCOMMA)
  <|> pSucceed Nothing
  <?> "pMaybeExports"
%%]

%%[20
pImport :: HSParser Import
pImport
  =   pImportExport (Import_Variable,Import_TypeOrClass,Import_TypeOrClassComplete)
  <?> "pImport"

pImportDeclaration :: HSParser ImportDeclaration
pImportDeclaration
  = (\q m a i -> ImportDeclaration_Import (mkRange1 m) q (tokMkQName m) (fmap tokMkQName a) i)
    <$  pIMPORT <*> (True <$ pQUALIFIED <|> pSucceed False)
    <*> modid
    <*> (Just <$ pAS <*> modid <|> pSucceed Nothing)
    <*> (Just <$> pImportSpecification <|> pSucceed Nothing)
  <?> "pImportDeclaration"
  where pImportSpecification :: HSParser ImportSpecification
        pImportSpecification
          = (True <$ pHIDING <|> pSucceed False)
            <**> pParens'
                   ((\i r h -> ImportSpecification_Import r h i) <$> pListSep_ng pCOMMA pImport <* pMb pCOMMA)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Declarations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
pDeclaration :: HSParser Declaration
pDeclaration
  =   pDeclarationValue
  <|> pDeclarationTypeSignature
%%[[5
  <|> pDeclarationData
%%]]
%%[[6
  <|> pDeclarationKindSignature
%%]]
%%[[9
  <|> pDeclarationInstance
%%]]
%%[[11
  <|> pDeclarationType
%%]]
  <?> "pDeclaration"
%%]

%%[1
pTopDeclaration :: HSParser Declaration
pTopDeclaration
  =   pDeclaration
  <|> pDeclarationFixity
%%[[8
  <|> pDeclarationForeign
%%]]
%%[[9
  <|> pDeclarationClass
  <|> pDeclarationDefault
%%]]
  <?> "pTopDeclaration"
%%]

%%[1
pDeclarations' :: HSParser d -> HSParser [d]
pDeclarations' pD
  =   pBlock pOCURLY pSEMI pCCURLY pD

pDeclarations1' :: HSParser d -> HSParser [d]
pDeclarations1' pD
  =   pBlock1 pOCURLY pSEMI pCCURLY pD

pDeclarations :: HSParser Declarations
pDeclarations
  =   pDeclarations' pDeclaration

pDeclarations1 :: HSParser Declarations
pDeclarations1
  =   pDeclarations1' pDeclaration
%%]

%%[1
pWhere' :: HSParser Declaration -> HSParser MaybeDeclarations
pWhere' pD = pMb (pWHERE *> pDeclarations' pD)

pWhere :: HSParser MaybeDeclarations
pWhere = pWhere' pDeclaration
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Fixity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 export(pFixity)
pDeclarationFixity :: HSParser Declaration
pDeclarationFixity
  = (\f p os@(o:_) -> Declaration_Fixity (mkRange1 o) f p (tokMkQNames os))
    <$> pFixity
    <*> ((Just . tokMkInt) <$> pInteger10Tk <|> pSucceed Nothing)
    <*> pList1Sep pCOMMA op

pFixity :: HSParser' Fixity
pFixity = Fixity_Infixl <$ pINFIXL <|> Fixity_Infixr <$ pINFIXR <|> Fixity_Infix <$ pINFIX
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Value definitions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
pDeclarationTypeSignature :: HSParser Declaration
pDeclarationTypeSignature
  =   (\(v:vs) t -> Declaration_TypeSignature (mkRange1 v) (tokMkQNames (v:vs)) t)
      <$> pList1Sep pCOMMA var <* pDCOLON <*> pType
  <?> "pDeclarationTypeSignature"

pDeclarationValue :: HSParser Declaration
pDeclarationValue
  =   mkF <$> pLhs <*> rhs
  <|> pPatternOp
      <**> (   (flip mkP) <$> rhs
           <|> (\o r rhs l -> mkF (mkLI l o r) rhs)
               <$> varop <*> pPatternOp <*> rhs
           )
  <?> "pDeclarationValue"
  where pLhsTail ::  HSParser [Pattern]
        pLhsTail =   pList1 pPatternBaseCon
        pLhs     ::  HSParser LeftHandSide
        pLhs     =   mkRngNm LeftHandSide_Function <$> var <*> pLhsTail
                 <|> pParens'
                       (   (\l r t -> mkLP r l t)
                           <$> pLhs
                       <|> (\pl o pr r t -> mkLP r (mkLI pl o pr) t)
                           <$> pPatternOp <*> varop <*> pPatternOp
                       )
                     <*> pLhsTail
        mkP  p     rhs = Declaration_PatternBinding emptyRange (p2p p) rhs'
                       where (p2p,rhs') = mkTyPat rhs
        mkF  lhs   rhs = Declaration_FunctionBindings emptyRange [FunctionBinding_FunctionBinding emptyRange (l2l lhs) rhs']
                       where (l2l,rhs') = mkTyLhs rhs
        mkLI l o r     = LeftHandSide_Infix (mkRange1 o) l (tokMkQName o) r
        mkLP r l t     = LeftHandSide_Parenthesized r l t
%%[[1
        rhs         =   pRhs pEQUAL
        mkTyLhs rhs = (id,rhs)
        mkTyPat     = mkTyLhs
%%][4
        rhs      =   pMbTy <+> pRhs pEQUAL
        pMbTy    ::  HSParser (Maybe (Token,Type))
        pMbTy    =   pMb (pDCOLON <+> pType)
        mkTyLhs (Just (tok,ty),rhs) = (\l -> LeftHandSide_Typed (mkRange1 tok) l ty,rhs)
        mkTyLhs (_            ,rhs) = (id                                          ,rhs)
        mkTyPat (Just (tok,ty),rhs) = (\p -> Pattern_Typed      (mkRange1 tok) p ty,rhs)
        mkTyPat (_            ,rhs) = (id                                          ,rhs)
%%]]
%%]

%%[8
pDeclarationSimpleValue :: HSParser Declaration
pDeclarationSimpleValue
  =   Declaration_PatternBinding emptyRange <$> lhs <*> rhs
  <?> "pDeclarationSimpleValue"
  where lhs = mkRngNm Pattern_Variable <$> var
        rhs = (\t e -> RightHandSide_Expression (mkRange1 t) e Nothing) <$> pEQUAL <*> pExpression
%%]

%%[1
pRhs :: HSParser Token -> HSParser RightHandSide
pRhs pSep
  =   (RightHandSide_Expression . mkRange1) <$> pSep <*> pExpression <*> pWhere
%%[[5
  <|> RightHandSide_Guarded emptyRange
      <$> pList1 ((GuardedExpression_GuardedExpression . mkRange1) <$> pVBAR <*> pExpression <* pSep <*> pExpression)
      <*> pWhere
%%]]
  <?> "pRhs"
%%]

%%[6
pDeclarationKindSignature :: HSParser Declaration
pDeclarationKindSignature
  =   (\(v:vs) t -> Declaration_KindSignature (mkRange1 v) (tokMkQNames (v:vs)) t)
      <$> pList1Sep pCOMMA con <* pDCOLON <*> pKind
  <?> "pDeclarationKindSignature"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Data definitions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[5
pDeclarationData :: HSParser Declaration
pDeclarationData
  =   pD pDATA    (Declaration_Data    . mkRange1) (pEQUAL *> pListSep pVBAR pDCon <|> pSucceed [])
  <|> pD pNEWTYPE (Declaration_Newtype . mkRange1) (pEQUAL *> pNCon)
  <?> "pDeclarationData"
  where pD pK sem pC
          = sem <$> pK
%%[[9
            <*> pContextItemsPrefixOpt
%%]]
            <*> pTypeLeftHandSide <*> pC
%%[[91
            <*> (pDERIVING *> ((:[]) <$> pDeriving <|> pParens (pList1Sep pCOMMA pDeriving)) <|> pSucceed [])
%%]]
        -- TBD, for now: ignore quantifiers
        pDCon, pNCon :: HSParser Constructor
%%[[5
        pDCon = pList pTypeQuantPrefix *> pConstructor
%%][9
        pDCon = pList pTypeQuantPrefix *> pContextedConstructor
%%]]
        pNCon = pList pTypeQuantPrefix *> pConstructor
%%]

%%[91
pDeriving :: HSParser Deriving
pDeriving
  = (\(n,u) t -> Deriving_Deriving (mkRange1 t) n u (tokMkQName t)) <$> pInstanceName <*> qconid
%%]

%%[5.pConstructor
pConstructor :: HSParser Constructor
pConstructor
  =   con
      <**> (   (\ts c -> mkRngNm Constructor_Constructor c ts) <$> pList pTB
%%]
%%[7
           <|> pCurlys' ((\fs r c -> mkRngNm Constructor_Record c fs) <$> pList1Sep pCOMMA pFieldDeclaration)
%%]
%%[5
           )
  <|> (\l o r -> Constructor_Infix (mkRange1 o) l (tokMkQName o) r) <$> pT <*> conop <*> pT
  where pT  = pAnnotatedType pType
        pTB = pAnnotatedType pTypeBase
%%]

%%[9
pContextedConstructor :: HSParser Constructor
pContextedConstructor
  =   Constructor_Contexted emptyRange <$> pContextItemsPrefix <*> pConstructor
  <|> pConstructor
%%]

%%[7
pFieldDeclaration :: HSParser FieldDeclaration
pFieldDeclaration
  = (\vs@(v:_) -> FieldDeclaration_FieldDeclaration (mkRange1 v) (tokMkQNames vs))
    <$> pList1Sep pCOMMA var <* pDCOLON <*> pAnnotatedType pType
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Foreign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen)
pDeclarationForeign :: HSParser Declaration
pDeclarationForeign
  = pFOREIGN
    <**> (   (\c s (i,n,t) r -> Declaration_ForeignImport (mkRange1 r) (fst c) s i (tokMkQName n) t)
             <$ pIMPORT <*> pFFIWay <*> pSafety <*> pFSpec
%%[[90
         <|> (\c (i,n,t) r -> Declaration_ForeignExport (mkRange1 r) (fst c) i (tokMkQName n) t)
             <$ pEXPORT <*> pFFIWay <*> pFSpec
%%]]
         )
  where pSafety =  (Just . tokMkStr) <$> safety <|> pSucceed Nothing
        pFSpec = (,,) <$> ((Just . tokMkStr) <$> pStringTk <|> pSucceed Nothing) <*> var{-id_no_foreign-} <* pDCOLON <*> pType
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Class & Instance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[9
pDeclarationClass :: HSParser Declaration
pDeclarationClass
  = (\t -> Declaration_Class (mkRange1 t))
    <$> pCLASS
    <*> pContextItemsPrefixOpt <*> pTypeLeftHandSide
%%[[15
    <*> (pVBAR *> pListSep pCOMMA pFunctionalDependency
        `opt` []
        )
%%]]
    <*> pWhere' (pDeclarationValue <|> pDeclarationTypeSignature)
%%[[15
  where pFunctionalDependency :: HSParser FunctionalDependency
        pFunctionalDependency
          = (\vs1@(v:_) vs2 -> FunctionalDependency_Dependency (mkRange1 v) (tokMkQNames vs1) (tokMkQNames vs2))
            <$> pList1 tyvar <* pRARROW <*> pList1 tyvar
%%]]
%%]

%%[9
pInstanceName :: HSParser (Maybe HsName,Bool)
pInstanceName
  =   (\n e -> (Just (tokMkQName n),e)) <$> varid <*> (True <$ pLTCOLON <|> False <$ pDCOLON)
  <|> pSucceed (Nothing,True)
%%]

%%[9
pDeclarationInstance :: HSParser Declaration
pDeclarationInstance
  = pINSTANCE
    <**> (   (\(n,u) c cl ts d t -> Declaration_Instance (mkRange1 t) n u c (tokMkQName cl) ts d)
             <$> pInstanceName
             <*> pContextItemsPrefixOpt <*> qconid <*> pList1 pTypeBase
             <*> pWhere' pDeclarationValue
         <|> (\e cl ts t -> Declaration_InstanceUseImplicitly (mkRange1 t) e (tokMkQName cl) ts)
             <$> pExpression <* pLTCOLON <*> qconid <*> pList1 pTypeBase
         )
%%]

%%[9
pDeclarationDefault :: HSParser Declaration
pDeclarationDefault
  = (Declaration_Default . mkRange1) <$> pDEFAULT <*> pMb (tokMkQName <$> qtyconid)
    <*> (   (:[]) <$> pTypeBaseCon
        <|> pParens (pListSep pCOMMA pTypeBaseCon)
        )
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Type synomym
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[11
pDeclarationType :: HSParser Declaration
pDeclarationType
  =   (Declaration_Type . mkRange1) <$> pTYPE <*> pTypeLeftHandSide <* pEQUAL <*> pType
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Kind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[6
pKindBase :: HSParser Kind
pKindBase
  =   mkRngNm Kind_Constructor <$> pSTAR
  <|> mkRngNm Kind_Variable <$> tyvar
  <|> pParens' pInParens
  <?> "pKindBase"
  where pInParens :: HSParser (Range -> Kind)
        pInParens
          =   (pKind
               <**> (   pSucceed (flip Kind_Parenthesized)
              )     )

pKind :: HSParser Kind
pKind
  =   mkK <$> pK
  <?> "pKind"
  where pK ::  HSParser (Kind,Int)
        pK =   pKindBase
               <**> (   pSucceed (\k -> (k,1))
                    <|> (\(op,rng) (r,opCnt) l -> (Kind_InfixApplication rng l op r,opCnt+1)) <$> pKindOp <*> pK
                    )
           <|> (\p e -> (p $ mkK $ e,1)) <$> pKindPrefix <*> pK
        mkK (e,1) = e
        mkK (e,_) = {- Expression_InfixApplicationChainTop emptyRange -} e
        pKindOp :: HSParser (Kind,Range)
        pKindOp = mkRngNm' Kind_Constructor <$> pRARROW

pKindPrefix :: HSParser (Kind -> Kind)
pKindPrefix
  =  ((Kind_Forall . mkRange1) <$> pFORALL)
     <*> (tokMkQNames <$> pTyVarBinds) <* pDOT
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Type
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
pTypeBaseCon :: HSParser Type
pTypeBaseCon
  =   mkRngNm Type_Constructor <$> gtycon_no_delims_commas

pTypeBase :: HSParser Type
pTypeBase
  =   pTypeBaseCon
%%[[2
  <|> (Type_Wildcard . mkRange1) <$> pTDOT
%%]]
%%[[3
  <|> mkRngNm Type_Variable <$> var_no_ty
  <|> mkRngNm Type_NamedWildcard <$ pPERCENT <*> tyvar
%%]]
%%[[5
  <|> pBracks'
        (   (\t r -> Type_NormalApplication r (Type_Constructor r hsnDataList) [t])
            <$> pType
        <|> pSucceed (\r -> Type_Constructor r hsnDataList)
        )
%%]]
  <|> pParens' pInParens
%%[[7
  <|> pPacked' pOROWROW pCROWROW
        (    pExtFlds Type_RowEmpty Type_RowUpdate
        <|> (\fs r -> Type_RowUpdate r (Type_RowEmpty r) fs) <$> pFlds
        )
  <|> pPacked' pOROWSUM pCROWSUM
        (    pExtFlds Type_RowSumEmpty Type_RowSumUpdate
        <|> (\fs r -> Type_RowSumUpdate r (Type_RowSumEmpty r) fs) <$> pFlds
        )
%%]]
  where pInParens :: HSParser (Range -> Type)
        pInParens
          =   (pType
               <**> (   pSucceed (flip Type_Parenthesized)
%%[[1
                    <|> (\es e r -> Type_NormalApplication r (Type_Constructor r $ hsnProd $ length es + 1) (e:es))
                        <$>  pList1 (pComma *> pType)
%%][7
                    <|> (\es e r -> Type_RowRecUpdate r (Type_RowRecEmpty r)
                                      (map (RowTypeUpdate_Extends r Nothing) (e:es)))
                        <$>  pList1 (pComma *> pType)
%%]]
%%[[11
                    <|> (\(o,_) e r -> Type_SectionApplication r (Just e) o Nothing)
                        <$> pTypeOpBase
%%]]
              )     )
%%[[11
          <|> (pTypeOpBase
               <**> (   (\e (o,_) r -> Type_SectionApplication r Nothing o (Just e)) <$> pType
                    -- <|> pSucceed (\(o,_) r -> Type_SectionApplication r Nothing o Nothing)
              )     )
          <|> (\ts r -> Type_TupleConstructor r (length ts + 1)) <$> commas'
%%]]
%%[[1
          <|> pSucceed (\r -> Type_Constructor r (hsnProd 0))
%%][7
          <|> pSucceed (\r -> Type_RowRecEmpty r)
          <|> (\fs r -> Type_RowRecUpdate r (Type_RowRecEmpty r) fs) <$> pFlds
          <|> pExtFlds Type_RowRecEmpty Type_RowRecUpdate
        pFld :: HSParser (Type -> RowTypeUpdate)
        pFld = qvarid
               <**> (   (\l -> RowTypeUpdate_Extends (mkRange1 l) (Just (tokMkQName l))) <$ pDCOLON
                    )
        pFlds :: HSParser [RowTypeUpdate]
        pFlds = pList1Sep pComma (pFld <*> pType)
        pExtFlds :: (Range -> Type) -> (Range -> Type -> [RowTypeUpdate] -> Type) -> HSParser (Range -> Type)
        pExtFlds semEmp semFromRow
             = (\e fs r -> semFromRow r e fs)
               <$> (   mkRngNm Type_Variable <$> qvarid
                   <|> pSucceed (semEmp emptyRange)
                   )
               <*  pVBAR <*> pFlds
%%]]
%%]

%%[1.pType
pType :: HSParser Type
pType =  pChainr (mk1Arrow <$ pRARROW) pTypeBase
%%]
%%[4.pType -1.pType
pType ::  HSParser Type
pType
  = mkT <$> pT
  where pT :: HSParser (Type,Int)
        pT = pTypeApp
			  <**> (   pSucceed unit
				   <|> (\(op,rng) (r,cnt) l -> (Type_InfixApplication rng l op r,cnt+1)) <$> pTypeOp <*> pT
				   )
%%[[9
			 <|> (\c t -> unit $ Type_Qualified emptyRange [c] t) <$> pContextItemImpl <* pRARROW <*> pType
%%]]
			 <|> unit <$> (pTypeQuantPrefix <*> pType)
        unit e    = (e,0)
%%[[4
        mkT (e,_) =  e
%%][5
        mkT (e,0) =  e
        mkT (e,_) =  Type_InfixApplicationChainTop emptyRange e
%%]]
%%]

%%[4.pTypeQuantPrefix
pTypeQuantPrefix :: HSParser (Type -> Type)
pTypeQuantPrefix
  =  ((Type_Forall . mkRange1) <$> pFORALL <|> (Type_Exists . mkRange1) <$> pEXISTS)
     <*> (tokMkQNames <$> pTyVarBinds) <* pDOT
%%]

%%[1
pTypeOpPrefix :: HSParser (Type -> Type)
pTypeOpPrefix
  =   (\l (op,rng) r -> Type_InfixApplication rng l op r) <$> pTypeApp <*> pTypeOp
%%[[9
  <|> (\c -> Type_Qualified emptyRange [c]) <$> pContextItemImpl <* pRARROW
%%]]
%%]

%%[1
pTypeOp :: HSParser (Type,Range)
pTypeOp
  =   pTypeOpBase
%%[[5
  <|> mkRngNm' Type_Variable    <$> varop_no_ty
%%]]
%%[[9
  <|> mkRngNm' Type_Constructor <$> pDARROW
%%]]
%%]

%%[1
pTypeOpBase :: HSParser (Type,Range)
pTypeOpBase
  = mkRngNm' Type_Constructor
    <$> (   gtycon_for_insection
        )
%%]

%%[1.pTypeApp
pTypeApp :: HSParser Type
pTypeApp =  pTypeBase
%%]
%%[5.pTypeApp -1.pTypeApp
pTypeApp :: HSParser Type
pTypeApp
  =  pT <??> pA
  where pT = pTypeBase
        pA = (\es e -> Type_NormalApplication emptyRange e es) <$> pList1 pT
%%]

%%[4
pTyVarBind :: HSParser Token
pTyVarBind =  tyvar

pTyVarBinds :: HSParser [Token]
pTyVarBinds =  pList1 pTyVarBind
%%]

%%[5555
pSimpleType :: HSParser SimpleType
pSimpleType
  = mkRngNm SimpleType_SimpleType <$> gtycon <*> (tokMkQNames <$> pList tyvar)
%%]

%%[5
pTypeLeftHandSide :: HSParser TypeLeftHandSide
pTypeLeftHandSide
  =   pLhs
  <|> (\c -> mkRngNm TypeLeftHandSide_Function c []) <$> gtycon' tyconsym
  <?> "pTypeLeftHandSide"
  where pLhs     :: HSParser TypeLeftHandSide
        pLhs     =   mkRngNm TypeLeftHandSide_Function <$> gtycon' tyconsym <*> pLhsTail
                 <|> pParens'
                       (   (\l r t -> TypeLeftHandSide_Parenthesized r l t)
                           <$> pLhs
                       )
                     <*> pLhsTail
                 <|> (\l o r -> TypeLeftHandSide_Infix (mkRange1 o) l (tokMkQName o) r)
                     <$> pTypePatternBase <*> tyconop <*> pTypePatternBase
        pLhsTail ::  HSParser [TypePattern]
        pLhsTail =   pList1 pTypePatternBase
%%]

%%[5
pAnnotatedType :: HSParser Type -> HSParser AnnotatedType
pAnnotatedType pT
  =   (\(r,s) t -> AnnotatedType_Type r s t)
      <$> ((\t -> (mkRange1 t,True)) <$> pBANG <|> pSucceed (emptyRange,False))
      <*> pT
%%]

%%[9.pTypeContextPrefix
pContextItemsPrefix1 :: HSParser ContextItems
pContextItemsPrefix1
  =   (:[]) <$> pContextItemImpl <* pRARROW

pContextItemsPrefix2 :: HSParser ContextItems
pContextItemsPrefix2
  =   (   (:[]) <$> (pContextItemBase <|> pContextItemImplWild)
      <|> pParens ((:) <$> pContextItemBase
                       <*> (   pImO
                           <|> (++) <$> pList1 (pCOMMA *> pContextItemBase) <*> pImO
                  )        )
      )
      <*  pDARROW
  where pImO  =  (:[]) <$ pCOMMA <*> pContextItemImplWild `opt` []
        pImO  :: HSParser ContextItems

pContextItemsPrefix :: HSParser ContextItems
pContextItemsPrefix
  =   pContextItemsPrefix1
  <|> pContextItemsPrefix2

pContextItemsPrefixOpt :: HSParser ContextItems
pContextItemsPrefixOpt = pContextItemsPrefix <|> pSucceed []

pTypeContextPrefix :: HSParser (Type -> Type)
pTypeContextPrefix
  = Type_Qualified emptyRange <$> pContextItemsPrefix
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parser for Predicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[9
pContextItemClass :: HSParser ContextItem
pContextItemClass
  =    mkRngNm ContextItem_Class <$> qconid <*> pList1 pTypeBase
%%]

%%[13
pContextItemPrefix :: HSParser (ContextItem -> ContextItem)
pContextItemPrefix
  =   (ContextItem_Forall . mkRange1) <$> pFORALL <*> (tokMkQNames <$> pTyVarBinds) <* pDOT
%%]

%%[9
pContextItem :: HSParser ContextItem
pContextItem
  =   pContextItemBase
%%[[13
      <**> (   pSucceed id
           <|> (\o r l -> ContextItem_Arrow (mkRange1 o) l r) <$> pDARROW <*> pContextItem
           )
%%]]
%%[[13
  <|> pContextItemPrefix <*> pContextItem
%%]]
%%]

%%[9
pContextItemImplWild :: HSParser ContextItem
pContextItemImplWild = (ContextItem_Implicits . mkRange1) <$> pTDOT
%%]

%%[9
pContextItemImpl :: HSParser ContextItem
pContextItemImpl
  = pImpls'
      (    const <$> (pContextItem <|> pContextItemImplWild)
      <|>  pSucceed ContextItem_NoImplicits
      )
%%]

%%[9
pContextItemBase ::   HSParser ContextItem
pContextItemBase
  =   pContextItemClass
%%]
%%[1010
  <|> ContextItem_DynVar <$> pDynVar <* pDCOLON <*> pType
%%]
%%[10
  <|> tyvar <**>  (    (\s v -> mkRngNm ContextItem_RowLacksLabel v (tokMkQName s))
                       <$ pLAM <*> pSelector
%%]
%%[50
                  <|>  (flip ContextItem_Equal)
                       <$ pKey "=" <*> pType
%%]
%%[10
                  )
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Literal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
pLiteralNumber :: HSParser Literal
pLiteralNumber
%%[[1
  =   mkRngStr Literal_Int <$> pIntegerTk
%%][97
  =   mk  8 <$> pInteger8Tk
  <|> mk 10 <$> pInteger10Tk
  <|> mk 16 <$> pInteger16Tk
%%]]
  <?> "pLiteralNumber"
%%[[97
  where mk b t = Literal_Int (mkRange1 t) b (tokMkStr t)
%%]]
%%]

%%[1
pLiteral :: HSParser Literal
pLiteral
  =   pLiteralNumber
  <|> mkRngStr Literal_Char <$> pCharTk
%%[[5
  <|> mkRngStr Literal_String <$> pStringTk
%%]]
%%[[97
  <|> mkRngStr Literal_Float  <$> pFractionTk
%%]]
  <?> "pLiteral"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Expression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
pExpressionMinusPrefix :: HSParser (Expression -> Expression)
pExpressionMinusPrefix
  =   (Expression_Negate . mkRange1) <$> pMINUS

pExpressionMbMinusPrefix :: HSParser (Expression -> Expression)
pExpressionMbMinusPrefix
  =   pExpressionMinusPrefix
  <|> pSucceed id

pExpressionBase :: HSParser Expression
pExpressionBase
  =   Expression_Literal emptyRange  <$> pLiteral
  <|> mkRngNm Expression_Variable    <$> qvar
%%[[5
  <|> pExpressionList
%%]]
  <|> pParens' pInParens
  <?> "pExpressionBase"
  where pInParens :: HSParser (Range -> Expression)
        pInParens
{-
          =   (\(e,res) r ->
                 let mk res e
                       = case res of
                           Expression3OpSection_None
                             -> Expression_Parenthesized r e
                           Expression3OpSection_Op (o,_)
                             -> Expression_SectionApplication r (Just e) o Nothing
                           Expression3OpSection_CommaList es
%%[[1
                             -> Expression_Tuple r (e:es)
%%][7
                             -> Expression_RowRecordUpdate r (Expression_RowRecordEmpty r)
                                                           (map (RowRecordExpressionUpdate_Extends r Nothing) (e:es))
%%]]
                           Expression3OpSection_Typed (t,r)
                             -> Expression_Typed r e t
                 in foldr mk e $ reverse res
              )
              <$> pExpression3OpSection pOp pExpressionPreBase
-}
{-
-}
          =   (\(e,_,res) r ->
                 let chk ress e
                       = case ress of
                           (Expression4Result_Op (o,_) : _)
                             -> Expression_SectionApplication r (Just e) o Nothing
                           (Expression4Result_CommaList es : _)
%%[[1
                             -> Expression_Tuple r (e:es)
%%][7
                             -> Expression_RowRecordUpdate r (Expression_RowRecordEmpty r)
                                                           (map (RowRecordExpressionUpdate_Extends r Nothing) (e:es))
%%]]
                           _ -> Expression_Parenthesized r e
                 in chk res e
              )
              <$> pExpression4'' True pOp pExpressionPrefix pExpressionLayout
{-
          =   (pExpression <**>
                    (   (\(o,_) e r -> Expression_SectionApplication r (Just e) o Nothing)
                        <$> pOp
                    <|> pSucceed (flip Expression_Parenthesized)
%%[[1
                    <|> (\es e r -> Expression_Tuple r (e:es))
                        <$> pList1 (pComma *> pExpression)
%%][7
                    <|> (\es e r -> Expression_RowRecordUpdate r (Expression_RowRecordEmpty r)
                                      (map (RowRecordExpressionUpdate_Extends r Nothing) (e:es)))
                        <$> pList1 (pComma *> pExpression)
%%]]
              )     )
-}
          <|> (\ts r -> Expression_TupleConstructor r (length ts + 1)) <$> commas'
          <|> (pOpm
               <**> (   (\e (o,_) r -> Expression_SectionApplication r Nothing o (Just e)) <$> pExpression
                    -- <|> pSucceed (\(o,_) r -> Expression_SectionApplication r Nothing o Nothing)
              )     )
%%[[1
          <|> pSucceed (\r -> Expression_Constructor r (hsnProd 0))
%%][7
          <|> pSucceed (\r -> Expression_RowRecordEmpty r)
          <|> (\fs r -> Expression_RowRecordUpdate r (Expression_RowRecordEmpty r) fs) <$> pFlds
          <|> pExtFlds
          where pFld :: HSParser (Expression -> RowRecordExpressionUpdate)
                pFld = qvarid
                       <**> (   (\l -> RowRecordExpressionUpdate_Extends (mkRange1 l) (Just (tokMkQName l))) <$ pEQUAL
                            <|> mkRngNm RowRecordExpressionUpdate_Update <$ pCOLEQUAL
                            )
                pFlds :: HSParser [RowRecordExpressionUpdate]
                pFlds = pList1Sep pComma (pFld <*> pExpression)
                pExtFlds :: HSParser (Range -> Expression)
                pExtFlds
                     = (\e fs r -> Expression_RowRecordUpdate r e fs)
                       <$> (   pParens' pExtFlds
                           <|> mkRngNm Expression_Variable <$> qvarid
                           <|> pSucceed (Expression_RowRecordEmpty emptyRange)
                           )
                       <*  pVBAR <*> pFlds
%%]]
%%]

%%[5
pExpressionList :: HSParser Expression
pExpressionList
  = pBracks'
      (pExpression
       <**> (   pDOTDOT
                *> (     (\e3 e1 r -> Expression_Enum r e1 Nothing (Just e3)) <$> pExpression
                   `opt` (\   e1 r -> Expression_Enum r e1 Nothing  Nothing )
                   )
            <|> pCOMMA
                *> (pExpression
                    <**> (   pDOTDOT
                             *> (     (\e3 e2 e1 r -> Expression_Enum r e1 (Just e2) (Just e3)) <$> pExpression
                                `opt` (\   e2 e1 r -> Expression_Enum r e1 (Just e2)  Nothing )
                                )
                         <|> (\es e2 e1 r -> Expression_List r (e1:e2:es)) <$> pList (pComma *> pExpression)
                   )     )
            <|> pVBAR
                *> ((\c e r -> Expression_Comprehension r e (c ++ [Qualifier_Empty emptyRange])) <$> pListSep pCOMMA pQualifier) 
            `opt` flip one
            )
      `opt` zero
      )
  <?> "pExpressionList"
  where zero r   = Expression_List r []
        one  r h = Expression_List r [h]
        pQualifier :: HSParser Qualifier
        pQualifier
          =   Qualifier_Guard emptyRange <$> pExpressionNoLet
          <|> (Qualifier_Let . mkRange1) <$> pLET <*> pDeclarations
          <|> Qualifier_Generator emptyRange <$> pPattern <* pLARROW <*> pExpression
%%]

%%[88.pExprBase
                <|>  Expr_Undefined  <$   pKey "..."
%%]
%%[1010.pExprBase
                <|>  Expr_DynVar     <$>  pDynVar
%%]

%%[9
pExpressionDo :: HSParser Expression
pExpressionDo
  =   (Expression_Do . mkRange1) <$> pDO <*> pBlock1 pOCURLY pSEMI pCCURLY pStatement
  <?> "pExpressionDo"
  where pStatement :: HSParser Statement
        pStatement
          =   Statement_Expression emptyRange <$> pExpression {- pExpressionNoLet -}
          <|> (\p t e -> Statement_Generator (mkRange1 t) p e) <$> pPattern <*> pLARROW <*> pExpression
              -- common prefix with 'let x=e in e' dies out
          <|> (Statement_Let . mkRange1) <$> pLET <*> pDeclarations
%%]

%%[9999
pExpressionDo :: HSParser Expression
pExpressionDo
  =   (Expression_Do . mkRange1) <$> pDO <*> pBlock1 pOCURLY pSEMI pCCURLY pStatement
  <?> "pExpressionDo"
  where pStatement :: HSParser Statement
        pStatement
          =   Statement_Expression emptyRange <$> pExpressionNoLet
          <|> (\p t e -> Statement_Generator (mkRange1 t) p e) <$> pPattern <*> pLARROW <*> pExpression
          -- left factorisation is not necessary, above variant works just as well
          <|> pLET
              <**> (pDeclarations
                    <**> (   (\e d t -> let r = mkRange1 t in Statement_Expression r $ Expression_Let r False d e) <$ pIN <*> pExpression
                         <|> pSucceed (\d t -> Statement_Let (mkRange1 t) d)
                   )     )
%%]

%%[9999
pExpressionDo :: HSParser Expression
pExpressionDo
  =   (Expression_Do . mkRange1) <$> pDO <*> pDo pOCURLY pSEMI pCCURLY pPlainStatement pLetPrefix pExpression
  <?> "pExpressionDo"
  where pPlainStatement :: HSParser Statement
        pPlainStatement
          =   Statement_Expression emptyRange <$> pExpressionNoLet
          <|> (\p t e -> Statement_Generator (mkRange1 t) p e) <$> pPattern <*> pLARROW <*> pExpression
        pLetPrefix
          = (\t d mbExpr -> case mbExpr of
                Just e -> Statement_Expression r $ Expression_Let r False d e
                       where r = mkRange1 t
                _      -> Statement_Let (mkRange1 t) d
            )
            <$> pLET <*> pDeclarations
%%]

%%[1
pExpressionConUpd :: HSParser Expression
pExpressionConUpd
  =   qcon
      <**> (   pSucceed (mkRngNm Expression_Constructor)
%%[[7
           <|> pCurlys' ((\bs _ c -> mkRngNm Expression_RecordConstruction c bs) <$> pListSep pCOMMA pRecordExpressionBinding)
%%]]
           )
  <|> pExpressionBase
%%[[7
      <**> ((\u e -> foldr ($) e u) <$> pList pU)
%%]]
  <?> "pExpressionConUpd"
%%[[7
  where pU =   pCurlys' ((\bs r e -> Expression_RecordUpdate r e bs) <$> pList1Sep pCOMMA pRecordExpressionBinding)
           <|> pRowRecordSelectionSuffix
%%]]
%%]

%%[7
pRecordExpressionBinding :: HSParser RecordExpressionBinding
pRecordExpressionBinding
  =   mkRngNm RecordExpressionBinding_Binding <$> qvar <* pEQUAL <*> pExpression
  <?> "pRecordExpressionBinding"
%%]

%%[1.pExpressionApp
pExpressionApp :: HSParser Expression
pExpressionApp
  =   pE <**> ((\as e -> foldl (flip ($)) e as) <$> pList pA)
  <?> "pExpressionApp"
  where pE =   pExpressionConUpd
        pA =   (\es e -> Expression_NormalApplication emptyRange e es) <$> pList1 pE
%%[[4
           <|> (\es e -> Expression_ImpredicativeApplication emptyRange e es) <$> pList1 (pTILDE *> pE)
%%]]
%%[[12
           <|> (\es e -> Expression_ImplicitApplication emptyRange e es) <$> pList1 (pImpls' pContextedExpression)
           where pContextedExpression = (\e c r -> ContextedExpression_Contexted r e c) <$> pExpression <* pLTCOLON <*> pContextItem
                 pContextedExpression :: HSParser (Range -> ContextedExpression)
%%]]
%%]

%%[1
pExpressionLayout :: HSParser Expression
pExpressionLayout
  =   pMaybe id id pExpressionMinusPrefix <*> pExpressionApp
%%[[5
  <|> (Expression_Case . mkRange1) <$> pCASE <*> pExpression <* pOptSEMISeparator <* pOF <*> pAlternatives
%%]]
%%[[9
  <|> pExpressionDo
%%]]
  <?> "pExpressionLayout"
%%]

%%[1
pOp, pOpm :: HSParser (Expression,Range)
pOp  = mkRngNm' Expression_Variable <$> qvarop          <|> mkRngNm' Expression_Constructor <$> qconop
pOpm = mkRngNm' Expression_Variable <$> qvarop_no_minus <|> mkRngNm' Expression_Constructor <$> qconop
%%]

%%[1
data Expression4Result
  = Expression4Result_Op                (Expression,Range)
  | Expression4Result_CommaList         [Expression]
  | Expression4Result_Typed
  | Expression4Result_NotOpPre
  -- deriving Eq

type Expression4 = (Expression,Int,[Expression4Result])

pExpression4'' :: Bool -> HSParser (Expression,Range) -> HSParser (Expression -> Expression) -> HSParser Expression -> HSParser Expression4
pExpression4'' inParen pOp pPreNotOp pBase
  =   ((\(e,cnt,res) -> (mkC cnt e,0,res)) <$> pE)
      <**> (addCommaP $ addOpP
            $ (   (addCommaP2
                   $ ((\c t (e,cnt,res) -> (Expression_Typed (mkRange1 c) (mkC cnt e) t, 0, Expression4Result_Typed : res))
                      <$> pDCOLON <*> pType
                  )  )
              <|> pSucceed id
           )  )
  where pE  ::  HSParser Expression4
        pE  =   pBase <**>
                  (   pSucceed (\e -> (e,0,[]))
                  <|> (\(op,rng) (r,opCnt,res) l -> (Expression_InfixApplication rng l op r, opCnt+1, res)) <$> pOp <*> pE
                  )
            <|> (\p (e,cnt,res) -> (p $ mkC cnt $ e, 0, Expression4Result_NotOpPre : res))
                <$> pPreNotOp <*> pE

        -- add trailing parsers, depending on being inside parenthesis
        addCommaP, addCommaP2, addOpP :: HSParser (Expression4 -> Expression4) -> HSParser (Expression4 -> Expression4)

        -- optionally add tuple expr remainder as choice
        addCommaP  p | inParen   = p <|> (\es (e,cnt,res) -> (mkC cnt e, 0, Expression4Result_CommaList es : res))
                                         <$> pList1 (pComma *> pExpression)
                     | otherwise = p

        -- optionally add tuple expr remainder as following in a sequence
        addCommaP2 p | inParen   = (\mkecntres es ecntres ->
                                      let (e,cnt,res) = mkecntres ecntres
                                      in  (mkC cnt e, 0, (if null es then [] else [Expression4Result_CommaList es]) ++ res)
                                   )
                                   <$> p <*> pList (pComma *> pExpression)
                     | otherwise = p

        -- optionally add operator as choice
        addOpP     p | inParen   = p <|> (\o (e,cnt,res) -> (mkC cnt e, 0, Expression4Result_Op o : res))
                                         <$> pOp
                     | otherwise = p

        -- add additional AST depending on nr of operators
        mkC cnt = if cnt > 0 then Expression_InfixApplicationChainTop emptyRange else id

pExpression4' :: HSParser (Expression -> Expression) -> HSParser Expression
pExpression4' pPreNotOp = (\(e,_,_) -> e) <$> pExpression4'' False pOp pPreNotOp pExpressionLayout
%%]

%%[1
%%]
pExpression3' :: HSParser Expression -> HSParser Expression
pExpression3' pBase
  =   pE <??> ((\c t e -> Expression_Typed (mkRange1 c) e t) <$> pDCOLON <*> pType)
  <?> "pExpression3'"
  where pE  ::  HSParser Expression
        pE     =   mkE 
                   <$> pChainr -- _ng
                           ((\(op,rng) (l,lc) (r,rc) ->
                               (Expression_InfixApplication rng l op r, lc+rc+1)
                            )
                            <$> pOp
                           )
                           ((\e -> (e,0)) <$> pBase)
        mkE (e,0) = e
        mkE (e,_) = Expression_InfixApplicationChainTop emptyRange e

data Expression3OpSectionResult
  = Expression3OpSection_None
  | Expression3OpSection_Op             (Expression,Range)
  | Expression3OpSection_CommaList      [Expression]
  | Expression3OpSection_Typed          (Type,Range)

pExpression3OpSection :: HSParser (Expression,Range) -> HSParser Expression -> HSParser (Expression,[Expression3OpSectionResult])
pExpression3OpSection pOp pBase
  =   mkE <$> pE
  <?> "pExpression3OpSection"
  where pE  ::  HSParser (Expression,Int,[Expression3OpSectionResult])
        pE = pBase <**>
               (   pOp <**>
                     (   (\(re,cnt,tailop) (op,rng) le ->
                            (Expression_InfixApplication rng le op re, cnt+1, tailop)
                         )
                         <$> pE
                     <|> pSucceed (\o e -> (e,0,[Expression3OpSection_Op o]))
                     )
               <|> (\es e -> (e,0,[Expression3OpSection_CommaList es]))
                   <$> pList1 (pComma *> pExpression)
               <|> (\c t es e -> (e,0,[Expression3OpSection_Typed (t,mkRange1 c)] ++ (if null es then [] else [Expression3OpSection_CommaList es])))
                   <$> pDCOLON <*> pType
                   <*> pList (pComma *> pExpression)
               <|> pSucceed (\e -> (e,0,[Expression3OpSection_None]))
               )
        mkE (e,0,tailop) = (e,tailop)
        mkE (e,_,tailop) = (Expression_InfixApplicationChainTop emptyRange e,tailop)



%%[1
%%]
pExpression2' :: HSParser (Expression -> Expression) -> HSParser Expression
pExpression2' pPre
  =   pE <??> ((\c t e -> Expression_Typed (mkRange1 c) e t) <$> pDCOLON <*> pType)
  <?> "pExpression2'"
  where pE  ::  HSParser Expression
        pE     =   mkE 
                   <$> pChainr -- _ng
                           ((\(op,rng) (l,lc) (r,rc) ->
                               (Expression_InfixApplication rng l op r, lc+rc+1)
                            )
                            <$> pOp
                           )
                           ((\e -> (e,0)) <$> pPreE)
        pPreE  ::  HSParser Expression
        pPreE  =   pExpressionLayout
               <|> (\ps e -> foldr ($) e ps) <$> pList1 pPre <*> pExpressionLayout
        mkE (e,0) = e
        mkE (e,_) = Expression_InfixApplicationChainTop emptyRange e

%%[1
%%]
pExpression1' :: HSParser (Expression -> Expression) -> HSParser Expression
pExpression1' pPreE
  =   (mkE <$> pE) <??> ((\c t e -> Expression_Typed (mkRange1 c) e t) <$> pDCOLON <*> pType)
  <?> "pExpression1'"
  where pE  ::  HSParser (Expression,Int)
        pE  =   pExpressionLayout
                <**> (   pSucceed (\e -> (e,0))
                     <|> (\(op,rng) (r,opCnt) l -> (Expression_InfixApplication rng l op r,opCnt+1)) <$> pOp <*> pE
                     )
            <|> (\p e -> (p $ mkE $ e,0)) <$> pPreE <*> pE
        mkE (e,0) = e
        mkE (e,_) = Expression_InfixApplicationChainTop emptyRange e

%%[1
pExpressionPreBase :: HSParser Expression
pExpressionPreBase = (\ps e -> foldr ($) e ps) <$> pList_gr pExpressionPrefix <*> pExpressionLayout

pExpression :: HSParser Expression
pExpression
  -- =   pExpression1' pExpressionPrefix
  -- =   pExpression2' pExpressionPrefix
  -- = pExpression3' pExpressionPreBase
  = pExpression4' pExpressionPrefix
    <?> "pExpression"
%%]

%%[1
pExpressionNoLet :: HSParser Expression
pExpressionNoLet
  -- =   pExpression' pExpressionNoLetPrefix
  -- =   pExpression2' pExpressionNoLetPrefix
  -- = pExpression3' pBase3
  =   pExpression4' pExpressionNoLetPrefix
    <?> "pExpressionNoLet"
  where pBase3 :: HSParser Expression
        pBase3 = (\ps e -> foldr ($) e ps) <$> pList pExpressionNoLetPrefix <*> pExpressionLayout
%%]

%%[1.pExpressionLetPrefix
pExpressionLetPrefix :: HSParser (Expression -> Expression)
pExpressionLetPrefix
%%[[1
  =   (Expression_Let . mkRange1)
      <$> pLET
      <*> pDeclarations <* pIN
%%][8
  =   (\(s,t,d) -> Expression_Let (mkRange1 t) s d)
      <$> (   (,,) False <$> pLET       <*> pDeclarations                          <* pIN
          <|> (,,) True  <$> pLETSTRICT <*> pDeclarations' pDeclarationSimpleValue <* pIN
          )
%%]]
  <?> "pExpressionLetPrefix"
%%]

%%[1.pExpressionNoLetPrefix
pExpressionNoLetPrefix :: HSParser (Expression -> Expression)
pExpressionNoLetPrefix
  =   pLAM <**> pLamArgs
%%[[5
  <|> (Expression_If . mkRange1) <$> pIF <*> pExpression <* pOptSEMISeparator <* pTHEN <*> pExpression <* pOptSEMISeparator <* pELSE
%%]]
  -- <|> pExpressionMinusPrefix
  <?> "pExpressionNoLetPrefix"
  where pLamArgs
          =   (\a1 a2 t e -> a1 t (a2 t e))
              <$> (   (\ps t e -> Expression_Lambda (mkRange1 t) ps e) <$> pList1 pPatternBaseCon
%%[[12
                  <|> (\ps t e -> Expression_ImplicitLambda (mkRange1 t) ps e) <$> pList1 (pImpls' pContextedPattern)
%%]]
                  )
              <*> pLamArgs
          <|> (\_ e -> e) <$ pRARROW
%%[[12
        pContextedPattern = (\p c r -> ContextedPattern_Contexted r p c) <$> pPattern <* pLTCOLON <*> pContextItem
        pContextedPattern :: HSParser (Range -> ContextedPattern)
%%]]
%%]

%%[1.pExpressionPrefix
pExpressionPrefix :: HSParser (Expression -> Expression)
pExpressionPrefix
  =   pExpressionLetPrefix
  <|> pExpressionNoLetPrefix
  <?> "pExpressionPrefix"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Alternatives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[5
pAlternative :: HSParser Alternative
pAlternative
  = Alternative_Alternative emptyRange <$> pPattern <*> pRhs pRARROW

pAlternatives :: HSParser Alternatives
pAlternatives
  = pBlock1 pOCURLY pSEMI pCCURLY pAlternative
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Try out layout parsing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hasSuccess :: Steps a s p -> Bool
hasSuccess (StRepair _ _ _ ) = False
hasSuccess (Best     _ _ _ ) = False 
hasSuccess _                 = True

pCloseTry :: (OutputState o, InputState i s p, Position p, Symbol s, Ord s) 
           => OffsideParser i o s p ()
pCloseTry = OP (pWrap f g ( () <$ pSym CloseBrace) )
  where g state steps1 k = (state,ar,k)
{-
-}
          where ar = case state of
                               Off _ _ _ (Just state')
                                 -> let steps2 = k state'
                                    in if not (hasSuccess steps1) && hasSuccess steps2
                                       then Cost 1# steps2
                                       else steps1
                               _ -> steps1
{-
          where ar = steps1
-}
            
        f acc state steps k = let (stl,ar,str2rr) = g state (val snd steps)  k
                              in (stl ,val (acc ()) ar , str2rr )

pOffsideTry :: (InputState i s p, OutputState o, Position p, Symbol s, Ord s) 
         => OffsideParser i o s p x 
         -> OffsideParser i o s p y 
         -> OffsideParser i o s p a 
         -> OffsideParser i o s p a 
         -> OffsideParser i o s p a
pOffsideTry open close bodyE bodyI = 
       open *> bodyE <* close
   <|> pOpen *> bodyI <* pClose

pBlockTry :: (InputState i s p, OutputState o, Position p, Symbol s, Ord s) 
       => OffsideParser i o s p x 
       -> OffsideParser i o s p y 
       -> OffsideParser i o s p z 
       -> OffsideParser i o s p a 
       -> OffsideParser i o s p [a]
pBlockTry open sep close p =  pOffsideTry open close explicit implicit
 where -- elem = (:) <$> p `opt` id
       elem = pMb p
       sep' = () <$ sep        
       -- elems s = ($[]) <$> pFoldr1Sep ((.),id) s elem
       elems s = (\h t -> catMaybes (h:t)) <$> elem <*> pList (s *> elem)
       explicit = elems sep'
       implicit = elems (sep' <|> pSeparator)

pBlock1Try :: (InputState i s p, OutputState o, Position p, Symbol s, Ord s) 
       => OffsideParser i o s p x 
       -> OffsideParser i o s p y 
       -> OffsideParser i o s p z 
       -> OffsideParser i o s p a 
       -> OffsideParser i o s p [a]
pBlock1Try open sep close p =  pOffsideTry open close explicit implicit
 where elem = (Just <$> p) `opt` Nothing
       sep' = () <$ sep
       -- elems s = (\h t -> catMaybes (h:t)) <$ pList s <*> (Just <$> p) <*> pList ( s *> elem)
       elems s = (\h t -> catMaybes (h:t)) <$ pList s <*> (Just <$> p) <*> pList (s *> pMb p)
       -- elems s = (\h t -> catMaybes (h:t)) <$ pList s <*> (Just <$> p) <*> pListSep (pList1 s) (Just <$> p)
       explicit = elems sep'
       implicit = elems (sep' <|> pSeparator)
%%[1
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Pattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1.pPatternBaseInParens
pPatternBaseInParens :: HSParser (Range -> Pattern)
pPatternBaseInParens
  =   (pPattern
       <**> (   pSucceed (flip Pattern_Parenthesized)
%%[[1
            <|> (\es e r -> Pattern_Tuple r (e:es))
                <$>  pList1 (pComma *> pPattern)
%%][7
            <|> (\es e r -> Pattern_RowRecordBinding r (Pattern_RowRecordEmpty r)
                              (map (RowRecordPatternBinding_Binding r Nothing) (e:es)))
                <$>  pList1 (pComma *> pPattern)
%%]]
      )     )
  <|> (\v _ -> mkRngNm Pattern_Variable v) <$> qvarsym_for_inparens
%%[[1
  <|> pSucceed (\r -> Pattern_Constructor r (hsnProd 0) [])
%%][7
  <|> pSucceed (\r -> Pattern_RowRecordEmpty r)
  <|> (\fs r -> Pattern_RowRecordBinding r (Pattern_RowRecordEmpty r) fs) <$> pFlds
  <|> pExtFlds
  <?> "pPatternBaseInParens"
  where pFld :: HSParser (Pattern -> RowRecordPatternBinding)
        pFld = qvarid
               <**> (   (\l -> RowRecordPatternBinding_Binding (mkRange1 l) (Just (tokMkQName l))) <$ pEQUAL
                    )
        pFlds :: HSParser [RowRecordPatternBinding]
        pFlds = pList1Sep pComma (pFld <*> pPattern)
        pExtFlds :: HSParser (Range -> Pattern)
        pExtFlds
             = (\e fs r -> Pattern_RowRecordBinding r e fs)
               <$> (   mkRngNm Pattern_Variable <$> qvar
                   <|> pSucceed (Pattern_RowRecordEmpty emptyRange)
                   )
               <*  pVBAR <*> pFlds
%%]]
%%]

%%[1
pPatternBaseMinusLiteral :: HSParser Pattern
pPatternBaseMinusLiteral = (\m n -> Pattern_Literal (mkRange1 m) (-1) n) <$> pMINUS <*> pLiteralNumber
%%]

%%[1.pPatternBaseNoParens
pPatternBaseNoParens :: HSParser Pattern
pPatternBaseNoParens
  =   qvarid
      <**> (   (\a p v -> Pattern_As (mkRange1 a) (tokMkQName v) p) <$> pAT <*> pPatternBaseCon
           <|> pSucceed (mkRngNm Pattern_Variable)
           )
  <|> Pattern_Literal emptyRange 1 <$> pLiteral
%%[[5
  <|> pBracks' (flip Pattern_List <$> pListSep pCOMMA pPattern)
%%]]
%%[[8
  <|> (Pattern_Irrefutable . mkRange1) <$> pTILDE <*> pPatternBaseCon
%%]]
  <?> "pPatternBaseNoParens"
%%]

%%[1.pPatternBase
pPatternBase :: HSParser Pattern
pPatternBase
  =   pPatternBaseNoParens
  <|> pParens' pPatternBaseInParens
  <?> "pPatternBase"
%%]

%%[1
pPatternConSuffix :: HSParser (Token -> Pattern)
pPatternConSuffix
  =   pSucceed (\c -> mkRngNm Pattern_Constructor c [])
%%[[7
  <|> pCurlys' ((\bs _ c -> mkRngNm Pattern_Record c bs) <$> pListSep pCOMMA pRecordPatternBinding)
%%]]
  <?> "pPatternConSuffix"
%%]

%%[1
pPatternBaseCon :: HSParser Pattern
pPatternBaseCon
  =   pPatternBase
  <|> qconid <**> pPatternConSuffix
  <?> "pPatternBaseCon"
%%]

%%[7
pRecordPatternBinding :: HSParser RecordPatternBinding
pRecordPatternBinding
  =   qvar
      <**> (   pSucceed (\v -> mkRngNm RecordPatternBinding_Pun v)
           <|> (\p v -> mkRngNm RecordPatternBinding_Binding v p) <$ pEQUAL <*> pPattern
           )
  <?> "pRecordPatternBinding"
%%]

%%[1
pPatternApp :: HSParser Pattern
pPatternApp
  =   pPatternBase
  <|> pPatternBaseMinusLiteral
  <|> qcon
      <**> (   (\l c -> mkRngNm Pattern_Constructor c l) <$> pList1 pPatternBaseCon
           <|> pPatternConSuffix
           )
  <?> "pPatternApp"
%%]

%%[1
pPatternOp :: HSParser Pattern
pPatternOp
  -- =   (\l rs -> foldr (\(o,r) mk -> \l -> o l (mk r)) id rs l) <$> pPatternApp <*> pList_ng (pOp <+> pPatternApp)
  = pChainr_ng pOp pPatternApp
  <?> "pPatternOp"
  where pOp = 
%%[[1
			((\o l r -> mkRngNm Pattern_Constructor o [l,r]) <$> qconop)
%%][5
			((\o l r -> Pattern_InfixConstructor (mkRange1 o) l (tokMkQName o) r) <$> qconop)
%%]]
%%]

%%[1.pPattern
pPattern :: HSParser Pattern
pPattern
  =   pPatternOp
%%[[4
      <??> ((\c t p -> Pattern_Typed (mkRange1 c) p t) <$> pDCOLON <*> pType)
%%]]
  <?> "pPattern"
%%]

%%[7
pRowRecordSelectionSuffix :: HSParser (Expression -> Expression)
pRowRecordSelectionSuffix
  = (\lbls e -> foldl (\e l -> Expression_RowRecordSelect (mkRange1 l) e (tokMkQName l)) e lbls)
    <$> pList1 (pHASH *> pSelector)
%%]

%%[7
pSelector :: HSParser Token
pSelector
  =   qvarid <|> qconid <|> pIntegerTk
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Pattern for type
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[5
pTypePatternBase :: HSParser TypePattern
pTypePatternBase
  =   mkRngNm TypePattern_Variable <$> var_no_ty
  <?> "pTypePatternBase"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FFI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
%%]
pFFIWay :: HSParser (FFIWay,Token)
pFFIWay
  =   pAnyKey (\way -> (,) way <$> pKeyTk (show way)) allFFIWays
  <?> "pFFIWay"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Names/Symbols of all sorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
commas' :: HSParser [Token]
commas' = pList1 pCOMMA

commas :: HSParser Token
commas =  (map (\s -> strProd (length s + 1)) . foldr tokConcat tokEmpty) <$> commas'
%%[[1
  where map = genTokMap
%%][5
  where map = tokenMap
%%]]
%%]

The separator used for after conditional+then expressions in an if-then-else in a do.

%%[5
pOptSEMISeparator :: HSParser (Maybe ())
pOptSEMISeparator = pMb (pSeparator <|> () <$ pSEMI)
%%]

%%[1
modid :: HSParser Token
modid
  =   pCONID
%%[[20
  <|> pQCONID
%%]]
  <?> "modid"
%%]

%%[20
qcnames :: HSParser [Token] 
qcnames
  =   pListSep pCOMMA qcname
  <?> "qcnames"

qcname  :: HSParser Token   -- Variable or data constructor
qcname
  =   qvar
  <|> gcon                    
  <?> "qcname"
%%]

%%[1
identifier :: HSParser Token 
identifier
  =   qvar      
  <|> gcon  
  <|> qop       
  <?> "identifier"

depreclist :: HSParser [Token] 
depreclist
  = pList1Sep pCOMMA deprec_var

deprec_var :: HSParser Token
deprec_var
  =   var
  <|> tyconid          
  <?> "deprec_var"

gcon    :: HSParser Token   -- Data constructor namespace
gcon
  =   sysdcon      
  <|> qcon         
-- the case of '[:' ':]' is part of the production `parr'
  <?> "gcon"

sysdcon :: HSParser Token   -- Wired in data constructors
sysdcon
  =   pParens commas 
  <|> tokConcat <$> pOBRACK <*> pCBRACK
  <?> "sysdcon"

%%]

{-
ipvar   :: HParser (IPName RdrName)
ipvar =  liftM (Dupable . mkUnqual varName) <$> pDUPIPVARID
     <|> liftM (Linear . mkUnqual varName)  <$> pSPLITIPVARID
-}

%%[1
qcon    :: HSParser Token
qcon
  =   qconid
  <|> pParens qconsym
  <?> "qcon"
       


conop :: HSParser Token
conop
  =   consym     
  <|> pBACKQUOTE *> conid <* pBACKQUOTE
  <?> "conop"

qconop :: HSParser Token
qconop
  =   qconsym       
  <|> pBACKQUOTE *> qconid <* pBACKQUOTE
  <?> "qconop"
%%]



-----------------------------------------------------------------------------
-- Data constructors

%%[1
qconid :: HSParser Token    -- Qualified or unqualifiedb
qconid
  =   conid
%%[[20
  <|> pQCONID
%%]]
  <?> "qconid"
%%]

%%[1
conid_nopragma   :: HSParser Token
conid_nopragma
  =   pCONID           
  <?> "conid_nopragma"

conid   :: HSParser Token
conid
  =   conid_nopragma           
%%[[99
  <|> pLANGUAGE_prag
  <|> pDERIVABLE_prag
%%]]
  <?> "conid"

qconsym :: HSParser Token   -- Qualified or unqualified
qconsym
  =   consym
%%[[20
  <|> pQCONSYM
%%]]
  <?> "qconsym"
%%]

%%[1
consym :: HSParser Token
consym
  =   pCONSYM       
  <|> pCOLON -- ':' means only list cons
  <?> "consym"
%%]

%%[1
con :: HSParser Token
con
  =   conid
  <|> pParens consym
  <?> "con"
%%]

%%[1
-----------------------------------------------------------------------------
-- Any operator

op  :: HSParser Token   -- used in infix decls
op
  =   varop
  <|> conop
  <?> "op"

qop :: HSParser Token   -- used in sections
qop
  =   qvarop
  <|> qconop
  <?> "qop"

%%]
qop_no_minus    :: HSParser  Token    -- used in sections
qop_no_minus
  =   qvarop_no_minus
  <|> qconop
  <?> "qop_no_minus"


-----------------------------------------------------------------------------
-- VarIds

%%[18
%%]
varid_unboxed :: HSParser Token
varid_unboxed
  =   pVARIDUNBOXED
  <?> "varid_unboxed"

-----------------------------------------------------------------------------
-- TyVarIds

%%[1
tyvar   :: HSParser Token
tyvar
  =   varid_no_ty
  <?> "tyvar"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Functions, values, variables, i.e. f (op, prefix), + (sym, infix)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
-- | special identifier: FFI safety
safety :: HSParser Token
safety
  =   pSAFE 
%%[[90       
  <|> pUNSAFE      
  <|> pTHREADSAFE
%%]] 
  <?> "safety"
%%]

%%[8
-- | special identifier: FFI calling convention
callconv :: HSParser Token
callconv
  =   snd <$> pFFIWay
  <?> "callconv"
%%]

%%[8
-- These special_ids are treated as keywords in various places, 
-- but as ordinary ids elsewhere.   'special_id' collects all these
-- except 'unsafe' and 'forall' whose treatment differs depending on context
-- | special identifier: some context sensitive meaningful
special_id_no_callconv :: HSParser Token 
special_id_no_callconv
  =   pLABEL   
  <|> pEXPORT
%%[[20
  <|> pAS      
  <|> pQUALIFIED   
  <|> pHIDING
%%]]
%%[[90
  <|> pDYNAMIC
%%]]
  <?> "special_id_no_callconv"
%%]

%%[8
special_id :: HSParser Token 
special_id
  =   special_id_no_callconv
  <|> callconv
  <?> "special_id"
%%]

%%[1
-- | Unqualified value/function, e.g.: f, except type related keywords
varid_no_ty :: HSParser Token
varid_no_ty
  =   pVARID
%%[[8
  <|> special_id_no_callconv
  <|> callconv
  <|> safety
%%]]
%%[[18
  <|> pVARIDUNBOXED
%%]]
  <?> "varid_no_ty"
%%]

%%[1
-- | Unqualified value/function, e.g.: f
varid :: HSParser Token
varid
  =   varid_no_ty
%%[[4
  <|> pFORALL
%%]]
  <?> "varid"
%%]

%%[1
-- | (Un)qualified value/function, e.g.: X.f
qvarid :: HSParser Token
qvarid
  =   varid
%%[[20
  <|> pQVARID
%%]]
  <?> "qvarid"
%%]

%%[1
-- | See comments with special_id
special_sym :: HSParser Token
special_sym 
  =   pBANG    
  <|> pDOT     
  <|> pSTAR
  <|> pPERCENT
  <?> "special_sym"
%%]

%%[1
-- | Unqualified operator, e.g.: +, except -
varsym_no_minus :: HSParser Token
varsym_no_minus
  =   pVARSYM
  <|> special_sym
  <?> "varsym_no_minus"
%%]

%%[1
-- | Unqualified operator, e.g.: +
varsym :: HSParser Token 
varsym
  =   varsym_no_minus  
  <|> pMINUS       
  <?> "varsym"
%%]

%%[20
-- | Qualified operator, e.g.: X.+, only base
qvarsym_base :: HSParser Token
qvarsym_base
  =   pQVARSYM 
  <?> "qvarsym1"
%%]

%%[1
-- | (Un)qualified operator, e.g.: X.+, except -
qvarsym_no_minus :: HSParser Token
qvarsym_no_minus
  =   varsym_no_minus
%%[[20
  <|> qvarsym_base
%%]]
  <?> "qvarsym_no_minus"
%%]

%%[1
-- | (Un)qualified operator, e.g.: X.+, for use inside parens
qvarsym_for_inparens :: HSParser Token
qvarsym_for_inparens
  =   varsym
%%[[20
  <|> qvarsym_base
%%]]
  <?> "qvarsym_for_inparens"
%%]

%%[1
-- | (Un)qualified operator, e.g.: X.+
qvarsym :: HSParser Token 
qvarsym
  =   qvarsym_for_inparens
  <?> "qvarsym"
%%]

%%[1
-- | (Un)qualified operator, e.g.: +, `f`, except -
varop_no_minus   :: HSParser Token
varop_no_minus
  =   varsym_no_minus 
  <|> pBACKQUOTE *> varid <* pBACKQUOTE
  <?> "varop_no_minus"
%%]

%%[1
-- | (Un)qualified operator, e.g.: +, `f`, except type related keywords
varop_no_ty   :: HSParser Token
varop_no_ty
  =   varsym
  <|> pBACKQUOTE *> varid_no_ty <* pBACKQUOTE
  <?> "varop_no_minus"
%%]

%%[1
-- | (Un)qualified operator, e.g.: +, `f`
varop   :: HSParser Token
varop
  =   varop_no_minus
  <|> pMINUS       
  <?> "varop"
%%]

%%[1
-- | (Un)qualified operator, e.g.: X.+, `X.f`, except -
qvarop_no_minus :: HSParser Token
qvarop_no_minus
  =   qvarsym_no_minus 
  <|> pBACKQUOTE *> qvarid <* pBACKQUOTE
  <?> "qvarop_no_minus"
%%]

%%[1
-- | (Un)qualified operator, e.g.: X.+, `X.f`
qvarop :: HSParser Token
qvarop
  =   qvarsym    
  <|> pBACKQUOTE *> qvarid <* pBACKQUOTE
  <?> "qvarop"
%%]

%%[1
-- | Unqualified value/function, e.g.: f, (+), except type related keywords
var_no_ty     :: HSParser Token
var_no_ty
  =   varid_no_ty            
  <|> pParens varsym 
  <?> "var"
%%]

%%[1
-- | Unqualified value/function, e.g.: f, (+)
var     :: HSParser Token
var
  =   varid            
  <|> pParens varsym 
  <?> "var"
%%]

%%[1
-- | (Un)qualified value/function, e.g.: X.f, (X.+)
qvar    :: HSParser Token
qvar
  =   qvarid      
  <|> pParens qvarsym_for_inparens
  <?> "qvar"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Data constructors, i.e. Left (op, prefix), :+: (sym, infix)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Type constructors, i.e. Either (op, prefix), :+: (sym, infix)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
-- | Unqualified type constructor, e.g.: :+:
tyconsym :: HSParser Token
tyconsym
  =   pCONSYM          
  <?> "tyconsym"
%%]

%%[1      
-- | (Un)qualified type constructor, e.g.: X.:+:
qtyconsym :: HSParser Token
qtyconsym
  =   tyconsym
%%[[20
  <|> pQCONSYM
%%]]
  <?> "qtyconsym"
%%]

%%[1
-- | Unqualified type constructor, e.g.: Either
tyconid   :: HSParser Token
tyconid
  =   pCONID
%%[[18
  <|> pCONIDUNBOXED
%%]]
  <?> "tyconid"
%%]

%%[1
-- | (Un)qualified type constructor, e.g.: X.Either
qtyconid :: HSParser Token 
qtyconid
  =   tyconid
%%[[20
  <|> pQCONID
%%]]
  <?> "qtyconid"
%%]

%%[8
-- | Unqualified infix type operator, e.g.: `Either`, :+:
tyconop :: HSParser Token   -- Unqualified
tyconop
  =   tyconsym  
  <|> pBACKQUOTE *> tyconid <* pBACKQUOTE
  <?> "tyconop"
%%]

%%[1
-- | (Un)qualified infix type operator, e.g.: `X.Either`, X.:+:
qtyconop :: HSParser Token
qtyconop
  =   qtyconsym
  <|> pBACKQUOTE *> qtyconid <* pBACKQUOTE
  <?> "qtyconop"
%%]

%%[1
-- | (Un)qualified prefix type constructor, e.g.: X.Either, (X.:+:)
qtycon :: HSParser Token
qtycon
  =   qtyconid
  <|> pParens qtyconsym  
  <?> "qtycon"
%%]

%%[1
-- | General (un)qualified prefix type constructor, no delimiting brackets (e.g. []), to be parameterized with the part inside parenthesis (the general part)
gtycon_no_delims' :: HSParser Token -> HSParser Token
gtycon_no_delims' pInParens
  =   qtyconid
  <|> pParens pInParens
  <?> "gtycon_no_delims"
%%]

%%[1
-- | Inside parenthesis part for gtycon
gtycon_for_inparens_arrow :: HSParser Token 
gtycon_for_inparens_arrow
  =   pRARROW
  <|> qtyconsym
  <?> "gtycon_for_inparens_arrow"

-- | Inside parenthesis part for gtycon
gtycon_for_inparens_arrow_commas :: HSParser Token 
gtycon_for_inparens_arrow_commas
  =   gtycon_for_inparens_arrow
  <|> commas
  <?> "gtycon_for_inparens_arrow"

-- | Inside parenthesis part for type sections
gtycon_for_insection :: HSParser Token
gtycon_for_insection
  =   pRARROW
%%[[5
  <|> qtyconop
%%]]
  <?> "gtycon_for_insection"
%%]

%%[1
-- | General (un)qualified prefix type constructor, e.g.: X.Either, (X.:+:), and (->)
gtycon_no_delims_commas :: HSParser Token
gtycon_no_delims_commas
  =   gtycon_no_delims' gtycon_for_inparens_arrow
  <?> "gtycon_no_delims_commas"
%%]

%%[1
-- | General (un)qualified prefix type constructor, e.g.: X.Either, (X.:+:), and (,,,), (->)
gtycon_no_delims :: HSParser Token   -- A "general" qualified tycon
gtycon_no_delims
  =   gtycon_no_delims' gtycon_for_inparens_arrow_commas
  <?> "gtycon_no_delims"
%%]

%%[5
gtycon_only_bracks :: HSParser Token   -- A "general" qualified tycon
gtycon_only_bracks
  =   tokConcat <$> pOBRACK <*> pCBRACK
  -- <|> tokConcat <$> pOPABRACK <*> pCPABRACK
  <?> "gtycon_only_delims"
%%]

%%[1
-- | General (un)qualified prefix type constructor, including delimiting brackets, to be parameterized with the part inside parenthesis (the general part)
gtycon' :: HSParser Token -> HSParser Token
gtycon' pInParens
  =   gtycon_no_delims' pInParens
%%[[5
  <|> gtycon_only_bracks
%%]]
  <?> "gtycon'"
%%]

%%[1
-- | General (un)qualified prefix type constructor, e.g.: X.Either, (X.:+:), and (,,,), (->), []
gtycon :: HSParser Token   -- A "general" qualified tycon
gtycon
  =   gtycon' gtycon_for_inparens_arrow_commas
  <?> "gtycon"
%%]



