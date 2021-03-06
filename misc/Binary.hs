-- This script creates a binary distribution at dist/bin/hlint-$ver.zip

import Control.Monad
import Data.List.Extra
import Data.Maybe
import System.Info.Extra
import System.IO.Extra
import System.Process.Extra
import System.FilePath
import System.Directory.Extra

exe = if isWindows then "exe" else ""


main :: IO ()
main = withTempDir $ \tdir -> do
    system_ $ "cabal sdist --output-directory=" ++ tdir
    vname <- ("hlint-" ++) . getVersion <$> readFile' "hlint.cabal"
    let zname = if isWindows then vname ++ "-x86_64-windows.zip" else vname ++ "-x86_64-linux.tar.gz"
    withCurrentDirectory tdir $ do
        system_ "cabal install --dependencies"
        system_ "cabal configure --datadir=nul --disable-library-profiling"
        system_ "cabal build"
        let out = "bin" </> vname
        createDirectoryIfMissing True $ out </> "data"
        copyFile ("dist/build/hlint/hlint" <.> exe) (out </> "hlint" <.> exe)
        files <- (["CHANGES.txt","LICENSE","README.md"]++) <$> listFiles "data"
        forM_ files $ \file -> copyFile file $ out </> file
        withCurrentDirectory "bin" $
            if isWindows then
                system_ $ "zip -r " ++ zname ++ " " ++ vname
            else
                system_ $ "tar -czvf " ++ zname ++ " " ++ vname
    let res = "dist/bin" </> zname
    createDirectoryIfMissing True $ takeDirectory res
    copyFile (tdir </> "bin" </> zname) res
    putStrLn $ "Completed, produced " ++ res

getVersion :: String -> String
getVersion = head . map trim .  mapMaybe (stripPrefix "version:") . lines
