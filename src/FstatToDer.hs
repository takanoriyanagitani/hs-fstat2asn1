module FstatToDer (
    path2base,
    path2stat,
    stat2size,
    stat2modified,
    stat2type,
    Unixtime,
    type2int,
    str2char,
    char2asn1,
    str2asn1,
    int2asn1,
    int2enum,
    dirent2asn1,
    dirent2der,
    der2stdout,
    path2dirent2der2stdout,
    FileType (..),
) where

import qualified Data.ByteString.Lazy as LBS

import qualified Data.ASN1.Types as AT

import Data.Int (Int64)

import System.FilePath (takeFileName)

import System.Posix.Types (
    EpochTime,
    FileOffset,
 )

import System.Posix.Files (
    FileStatus,
    fileSize,
    getSymbolicLinkStatus,
    isBlockDevice,
    isCharacterDevice,
    isDirectory,
    isNamedPipe,
    isRegularFile,
    isSocket,
    isSymbolicLink,
    modificationTime,
 )

import Data.ASN1.BinaryEncoding (DER (..))
import Data.ASN1.Encoding (encodeASN1)

path2base :: FilePath -> String
path2base = takeFileName

path2stat :: FilePath -> IO FileStatus
path2stat = getSymbolicLinkStatus

stat2size :: FileStatus -> FileOffset
stat2size = fileSize

long2int :: Int64 -> Integer
long2int = fromIntegral

epoch2long :: EpochTime -> Int64
epoch2long = round . toRational

epoch2int :: EpochTime -> Integer
epoch2int = long2int . epoch2long

stat2modified :: FileStatus -> EpochTime
stat2modified = modificationTime

data FileType
    = Directory
    | Regular
    | SoftLink
    | BlockDev
    | CharDev
    | NamedPipe
    | Socket
    | Unspecified
    deriving (Show, Eq, Enum)

stat2type :: FileStatus -> FileType
stat2type fstat
    | isDirectory fstat = Directory
    | isRegularFile fstat = Regular
    | isSymbolicLink fstat = SoftLink
    | isBlockDevice fstat = BlockDev
    | isCharacterDevice fstat = CharDev
    | isNamedPipe fstat = NamedPipe
    | isSocket fstat = Socket
    | otherwise = Unspecified

type2int :: FileType -> Integer
type2int Regular = 1
type2int Directory = 2
type2int SoftLink = 3
type2int BlockDev = 4
type2int CharDev = 5
type2int NamedPipe = 6
type2int Socket = 7
type2int Unspecified = 0

type Unixtime = Integer

data Dirent = Dirent
    { direntName :: String
    , direntSize :: Integer
    , direntModified :: Unixtime
    , direntType :: FileType
    }
    deriving (Show, Eq)

str2char :: String -> AT.ASN1CharacterString
str2char = AT.asn1CharacterString AT.UTF8

char2asn1 :: AT.ASN1CharacterString -> AT.ASN1
char2asn1 = AT.ASN1String

str2asn1 :: String -> AT.ASN1
str2asn1 = char2asn1 . str2char

int2asn1 :: Integer -> AT.ASN1
int2asn1 = AT.IntVal

int2enum :: Integer -> AT.ASN1
int2enum = AT.Enumerated

startObj :: AT.ASN1
startObj = AT.Start AT.Sequence

endObj :: AT.ASN1
endObj = AT.End AT.Sequence

encodeName :: Dirent -> AT.ASN1
encodeName = str2asn1 . direntName

encodeSize :: Dirent -> AT.ASN1
encodeSize = int2asn1 . direntSize

encodeModified :: Dirent -> AT.ASN1
encodeModified = int2asn1 . direntModified

typ2asn1 :: FileType -> AT.ASN1
typ2asn1 = int2enum . type2int

encodeType :: Dirent -> AT.ASN1
encodeType = typ2asn1 . direntType

dirent2asn1 :: Dirent -> [AT.ASN1]
dirent2asn1 ent =
    [ startObj
    , encodeName ent
    , encodeSize ent
    , encodeModified ent
    , encodeType ent
    , endObj
    ]

asn1toDER :: [AT.ASN1] -> LBS.ByteString
asn1toDER = encodeASN1 DER

der2stdout :: LBS.ByteString -> IO ()
der2stdout = LBS.putStr

dirent2der :: Dirent -> LBS.ByteString
dirent2der = asn1toDER . dirent2asn1

dirent2der2stdout :: Dirent -> IO ()
dirent2der2stdout ent = do
    let der :: LBS.ByteString = dirent2der ent
    der2stdout der

stat2dirent :: FilePath -> FileStatus -> Dirent
stat2dirent path stat =
    Dirent
        { direntName = path2base path
        , direntSize = fromIntegral (stat2size stat)
        , direntModified = epoch2int (stat2modified stat)
        , direntType = stat2type stat
        }

path2dirent :: FilePath -> IO Dirent
path2dirent fpath = do
    fstat :: FileStatus <- path2stat fpath
    let ent :: Dirent = stat2dirent fpath fstat
    return ent

path2dirent2der2stdout :: FilePath -> IO ()
path2dirent2der2stdout fpath = do
    ent :: Dirent <- path2dirent fpath
    dirent2der2stdout ent
