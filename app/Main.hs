module Main (main) where

import System.Environment (lookupEnv)

import FstatToDer (path2dirent2der2stdout)

envkey2path :: String -> IO (Maybe String)
envkey2path = lookupEnv

env2path :: IO (Maybe String)
env2path = envkey2path "ENV_DIRENT_PATH"

opath2stat2der2stdout :: Maybe String -> IO ()
opath2stat2der2stdout Nothing = return ()
opath2stat2der2stdout (Just path) = path2dirent2der2stdout path

main :: IO ()
main = do
    opath :: Maybe String <- env2path
    opath2stat2der2stdout opath
