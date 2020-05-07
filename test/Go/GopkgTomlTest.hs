{-# language TemplateHaskell #-}

module Go.GopkgTomlTest
  ( spec_analyze
  , spec_buildGraph
  ) where

import Prologue

import qualified Data.Map.Strict as M
import qualified Data.Text.IO as TIO

import DepTypes
import Effect.Grapher
import Graphing (Graphing)
import Strategy.Go.GopkgToml
import Strategy.Go.Types (graphingGolang)
import qualified Toml

import Test.Tasty.Hspec

gopkg :: Gopkg
gopkg = Gopkg
  { pkgConstraints =
      [ PkgConstraint
          { constraintName = "cat/fossa"
          , constraintSource = Just "https://someotherlocation/"
          , constraintVersion = Just "v3.0.0"
          , constraintBranch = Nothing
          , constraintRevision = Nothing
          }
      , PkgConstraint
          { constraintName = "repo/name/A"
          , constraintSource = Nothing
          , constraintVersion = Just "v1.0.0"
          , constraintBranch = Nothing
          , constraintRevision = Nothing
          }
      , PkgConstraint
          { constraintName = "repo/name/B"
          , constraintSource = Nothing
          , constraintVersion = Nothing
          , constraintBranch = Nothing
          , constraintRevision = Just "12345"
          }
      , PkgConstraint
          { constraintName = "repo/name/C"
          , constraintSource = Nothing
          , constraintVersion = Nothing
          , constraintBranch = Just "branchname"
          , constraintRevision = Nothing
          }
      ]
  , pkgOverrides =
    [ PkgConstraint
        { constraintName = "repo/name/B"
        , constraintSource = Nothing
        , constraintVersion = Nothing
        , constraintBranch = Just "overridebranch"
        , constraintRevision = Nothing
        }
    ]
  }

expected :: Graphing Dependency
expected = run . evalGrapher $ do
  direct $ Dependency
             { dependencyType = GoType
             , dependencyName = "cat/fossa"
             , dependencyVersion = Just (CEq "v3.0.0")
             , dependencyLocations = ["https://someotherlocation/"]
             , dependencyEnvironments = []
             , dependencyTags = M.empty
             }
  direct $ Dependency
             { dependencyType = GoType
             , dependencyName = "repo/name/A"
             , dependencyVersion = Just (CEq "v1.0.0")
             , dependencyLocations = []
             , dependencyEnvironments = []
             , dependencyTags = M.empty
             }
  direct $ Dependency
             { dependencyType = GoType
             , dependencyName = "repo/name/B"
             , dependencyVersion = Just (CEq "overridebranch")
             , dependencyLocations = []
             , dependencyEnvironments = []
             , dependencyTags = M.empty
             }
  direct $ Dependency
             { dependencyType = GoType
             , dependencyName = "repo/name/C"
             , dependencyVersion = Just (CEq "branchname")
             , dependencyLocations = []
             , dependencyEnvironments = []
             , dependencyTags = M.empty
             }

spec_analyze :: Spec
spec_analyze = do
  contents <- runIO (TIO.readFile "test/Go/testdata/Gopkg.toml")

  describe "analyze" $
    it "should produce expected output" $ do
      case Toml.decode gopkgCodec contents of
        Left err -> expectationFailure ("decode failed: " <> show err)
        Right pkg -> do
          let result = buildGraph pkg & graphingGolang & run
          result `shouldBe` expected

spec_buildGraph :: Spec
spec_buildGraph = do
  describe "buildGraph" $
    it "should produce expected output" $ do
      let result = buildGraph gopkg & graphingGolang & run

      result `shouldBe` expected