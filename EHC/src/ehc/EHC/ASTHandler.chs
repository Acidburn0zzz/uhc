%%[0 hs
{-# LANGUAGE ExistentialQuantification #-}
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Abstraction for dealing with general functionaly required for specific AST/formats/file types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[doesWhat doclatex
Abstraction for dealing with AST formats
%%]

%%[8 module {%{EH}EHC.ASTHandler}
%%]

-- general imports
%%[8 import ({%{EH}EHC.Common}, {%{EH}EHC.CompileUnit}, {%{EH}EHC.CompileRun})
%%]

%%[8 import (Data.Typeable, GHC.Generics)
%%]

%%[8 import (qualified Data.Map as Map)
%%]

-- parsing
%%[8 import(qualified UHC.Util.ScanUtils as ScanUtils)
%%]
%%[8 import({%{EH}Base.ParseUtils})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% AST parser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(ASTParser(..))
data ASTParser ast
  = forall prs inp sym symmsg pos .
      ( EHParser prs inp sym symmsg pos
      ) =>
		ASTParser
		  { unASTParser 	:: EHPrs prs inp sym pos ast
		  }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% AST Handler, type parameterized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(ASTHandler'(..))
data ASTHandler' ast
  = -- forall prs inp sym symmsg pos . -- msg .
      -- ( PP msg
      -- , EHParser prs inp sym symmsg pos
      -- ) =>
		ASTHandler'
		  {
		  --- * Meta
	  
		  --- | Meta info: name of ast
			_asthdlrName				:: !String

		  --- * File
	  
		  --- | Construct FPath from module name, path, suffix
		  , _asthdlrMkFPath				:: EHCOpts -> HsName -> FPath -> String -> FPath

		  --- | Suffix info
		  , _asthdlrSuffixRel			:: ASTSuffixRel
	  
		  --- * Compile unit
	  
		  --- | Update EHCompileUnit
		  , _asthdlrEcuStore			:: EcuUpdater ast
	  
		  --- * Output
	  
		  --- | Write to an ast to a file in the IO monad, return True if could be done
		  , _asthdlrOutputIO			:: ASTFileContentVariation -> EHCOpts -> EHCompileUnit -> HsName -> FPath -> FilePath -> ast -> IO Bool
	  
		  --- * Input, textual, parsing
	  
		  --- | Scanning parameterisation
		  , _asthdlrParseScanOpts 		:: EHCOpts -> EHParseOpts -> ScanUtils.ScanOpts
	  
		  --- | Parsing
		  , _asthdlrParser				:: EHCOpts -> EHParseOpts -> Maybe (ASTParser ast)
	  
		  --- * Input, parsing

		  --- | Input an ast
		  , _asthdlrInput				:: forall m . EHCCompileRunner m => ASTFileContentVariation -> HsName -> EHCompilePhaseT m (Maybe ast)

		  }
		  deriving Typeable
%%]

%%[8 export(emptyASTHandler')
emptyASTHandler' :: forall ast . ASTHandler' ast
emptyASTHandler'
  = ASTHandler'
      { _asthdlrName 				= "Unknown AST"
      , _asthdlrSuffixRel 			= emptyASTSuffixRel
      
      , _asthdlrMkFPath				= mkOutputFPath
      
      , _asthdlrEcuStore			= const id

      , _asthdlrOutputIO 			= \_ _ _ _ _ _ _ -> return False

      , _asthdlrInput 				= \_ _ -> return Nothing
      , _asthdlrParseScanOpts		= \_ _ -> ScanUtils.defaultScanOpts
      , _asthdlrParser				= \_ _ -> (Nothing :: Maybe (ASTParser ast))
      }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% AST Handler, type hidden a la Dynamic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(ASTHandler(..))
data ASTHandler
  = forall ast .
      Typeable ast =>
        ASTHandler (ASTHandler' ast)
%%]

%%[8 export(ASTHandlerMp)
type ASTHandlerMp = Map.Map ASTType ASTHandler
%%]
