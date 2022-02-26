{-# LANGUAGE RecordWildCards #-}

module App.Fossa.RunThemis (
  execThemis,
  generateThemisOpts,
  ThemisCLIOpts (..),
) where

import Control.Carrier.Error.Either (Has)
import Control.Effect.Diagnostics (Diagnostics)
import Data.ByteString.Lazy qualified as BL
import Data.String.Conversion (toText, toString)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding (decodeUtf8)
import Path (Abs, Dir, Path, Rel, fromAbsFile, parseRelDir, (</>))

import App.Fossa.EmbeddedBinary (
  toExecutablePath,
  BinaryPaths (..),
  )
import Options.Applicative (CommandFields)

import Effect.Exec (
  AllowErr (Never),
  Command (..),
  Exec,
  execThrow,
 )
import Control.Monad (when)

data ThemisCLIOpts = ThemisCLIOpts
  { themisCLIScanDir :: Path Abs Dir
  , themisCLIArgs :: [Text]
  }

generateThemisOpts :: Path Abs Dir -> Path Rel Dir -> ThemisCLIOpts
generateThemisOpts baseDir vendoredDepDir =
  ThemisCLIOpts{ themisCLIScanDir = fullDir, themisCLIArgs = ["--help"]}
    where
      fullDir = baseDir </> vendoredDepDir

execThemis :: (Has Exec sig m, Has Diagnostics sig m) => BinaryPaths -> BinaryPaths -> ThemisCLIOpts -> m BL.ByteString
execThemis themisBinaryPath indexGobPath opts = execThrow (themisCLIScanDir opts) (themisCommand themisBinaryPath indexGobPath)

themisCommand :: BinaryPaths -> BinaryPaths -> Command
themisCommand themisBin indexGobBin = do
  Command
    { cmdName = toText $ fromAbsFile $ toExecutablePath themisBin
    , cmdArgs = generateThemisArgs indexGobBin
    , cmdAllowErr = Never
    }

generateThemisArgs :: BinaryPaths -> [Text]
generateThemisArgs BinaryPaths{..} =
  [ "--license-data-dir"
  , toText binaryPathContainer
  , "--srclib-with-match-string"
  , "."
  ]

