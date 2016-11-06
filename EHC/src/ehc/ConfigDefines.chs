/* src/ehc/ConfigDefines.chs.  Generated from ConfigDefines.chs.in by configure.  */
%%[0
{-# OPTIONS_GHC -cpp #-}
%%]

%%[8 module {%{EH}ConfigDefines}
%%]
%%[8 import({%{EH}Opts.Base})
%%]
%%[50 import(Data.Word, Data.Char)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Magic number of .hi files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(magicNumberHI)
magicNumberHI :: [Word8]
magicNumberHI = map (fromInteger . toInteger . fromEnum) "UHI1"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Utils
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(mkB)
mkB :: Int -> Bool
mkB x = if x /= 0 then True else False
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GC variations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

The chose variant should correspond with the choice made in src/rts/rts.ch.
It is a temporary solution to make this dependent on the target.

%%[(8 codegen) export(GCVariant(..),gcVariant)
#define USE_BOEHM_GC 0

data GCVariant
  = GCVariant_Boehm | GCVariant_Uhc
  deriving Eq

gcVariant :: EHCOpts -> GCVariant
gcVariant opts | ehcOptEmitExecBytecode opts = GCVariant_Uhc
               | mkB USE_BOEHM_GC            = GCVariant_Boehm
               | otherwise                   = GCVariant_Uhc
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Configuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen) export(useBoehmGC)
useBoehmGC :: EHCOpts -> Bool
useBoehmGC opts = gcVariant opts == GCVariant_Boehm
%%]

%%[97 export(mpLib,MPLib(..))
#define USE_LTM 1
#define USE_GMP 0

data MPLib
  = MPLib_LTM | MPLib_GMP
  deriving (Show,Eq)

mpLib :: MPLib
mpLib | mkB USE_GMP = MPLib_GMP
      | otherwise   = MPLib_LTM
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Size of word, the basic unit of ptr/int/...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define SIZEOF_INTPTR_T 8
%%]

%%[8 export(sizeofWord,sizeofWordInBits,sizeofWordAsInteger,sizeofWordInLog)
sizeofWord :: Int
sizeofWord = SIZEOF_INTPTR_T

sizeofWordInBits :: Int
sizeofWordInBits = sizeofWord * 8

sizeofWordInLog :: Int
sizeofWordInLog = if sizeofWord == 8 then 3 else 2

sizeofWordAsInteger :: Integer
sizeofWordAsInteger = toInteger sizeofWord
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Minimal size of node, in words, see also remarks at GCVariant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen) export(nodeNeedsForwarding)
nodeNeedsForwarding :: EHCOpts -> Bool
nodeNeedsForwarding opts
  = case gcVariant opts of
      GCVariant_Boehm -> False -- header only
      GCVariant_Uhc   -> True  -- header + 1 fld for forwarding
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Size of other known types, on the target platform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[97
#define SIZEOF_FLOAT 4
#define SIZEOF_DOUBLE 8
#define SIZEOF_INT 4
%%]

%%[97 export(sizeofFloat,sizeofDouble,sizeofCInt)
sizeofFloat :: Int
sizeofFloat = SIZEOF_FLOAT

sizeofDouble :: Int
sizeofDouble = SIZEOF_DOUBLE

sizeofCInt :: Int
sizeofCInt = SIZEOF_INT
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Sizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin) export(sizeofPointer)
sizeofPointer :: Int
sizeofPointer = sizeofWord
%%]

%%[(8 codegen grin) export(sizeofGrWord,sizeofGrWordAsInteger)
sizeofGrWord :: Int
sizeofGrWord = sizeofWord

sizeofGrWordAsInteger :: Integer
sizeofGrWordAsInteger = sizeofWordAsInteger

%%]

%%[(8 codegen grin) export(gbLabelOffsetSize)
gbLabelOffsetSize :: Int
gbLabelOffsetSize = sizeofGrWord
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Predicates about sizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin) export(use64Bits,use32Bits)
-- which size is used for word?
use64Bits, use32Bits :: Bool
(use64Bits,use32Bits)
  = if sizeofGrWord == 8
    then (True,False)
    else (False,True)
%%]

%%[(97 codegen grin) export(isSameSizeForIntAndWord)
-- are sizes of machine int and word same?
isSameSizeForIntAndWord :: Bool
isSameSizeForIntAndWord = sizeofCInt == sizeofWord
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Endianness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin) export(machineIsBigEndian)
#define BIGENDIAN 0
#define LITTLEENDIAN 1

machineIsBigEndian :: Bool
machineIsBigEndian = mkB BIGENDIAN
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% RTS related
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin) export(rtsGlobalVarPrefix, rtsUseGC)
#define RTS_GLOBAL_VAR_PREFIX "global_"
#define USE_BOEHM_GC 0

rtsGlobalVarPrefix :: String
rtsGlobalVarPrefix = RTS_GLOBAL_VAR_PREFIX

rtsUseGC :: Bool
rtsUseGC = mkB USE_BOEHM_GC

%%]
