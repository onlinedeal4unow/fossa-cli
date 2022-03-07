{-# LANGUAGE RecordWildCards #-}

module App.Fossa.Subcommand (
  runSubCommand,
  EffStack,
  GetSeverity (..),
  GetCommonOpts (..),
  SubCommand (..),
) where

import App.Fossa.Config.Common (CommonOpts, collectTelemetryScope)
import App.Fossa.Config.ConfigFile (ConfigFile)
import App.Fossa.Config.EnvironmentVars (EnvVars (envConfigDebug), getEnvVars)
import Control.Carrier.Diagnostics (DiagnosticsC, context, logWithExit_)
import Control.Carrier.Stack (StackC, runStack)
import Control.Carrier.Telemetry (TelemetryC, withTelemetry)
import Control.Effect.Telemetry (setSink, trackConfig)
import Data.Aeson (ToJSON)
import Data.String.Conversion (ToText (toText), toStrict)
import Effect.Exec (ExecIOC, runExecIO)
import Effect.Logger (
  LoggerC,
  Severity (SevInfo),
  logInfo,
  logStdout,
  withDefaultLogger,
 )
import Effect.ReadFS (ReadFSIOC, runReadFSIO)
import Options.Applicative (InfoMod, Parser)
import Text.Pretty.Simple (pShowNoColor)

data SubCommand cli cfg = SubCommand
  { commandName :: String
  , commandInfo :: InfoMod (IO ())
  , parser :: Parser cli
  , configLoader :: cli -> EffStack (Maybe ConfigFile) -- CLI args can control where we look for config file
  , optMerge :: Maybe ConfigFile -> EnvVars -> cli -> EffStack cfg
  , perform :: cfg -> EffStack ()
  }

type EffStack = ExecIOC (ReadFSIOC (DiagnosticsC (LoggerC (StackC (TelemetryC IO)))))

class GetSeverity a where
  getSeverity :: a -> Severity
  getSeverity = const SevInfo

class GetCommonOpts a where
  getCommonOpts :: a -> Maybe CommonOpts
  getCommonOpts = const Nothing

runSubCommand :: forall cli cfg. (GetCommonOpts cli, GetSeverity cli, Show cfg, ToJSON cfg) => SubCommand cli cfg -> Parser (IO ())
runSubCommand SubCommand{..} = uncurry (runEffs) . mergeAndRun <$> parser
  where
    -- We have to extract the severity from the options, which is not straightforward
    -- since the CLI parser is Applicative, but not Monad.
    mergeAndRun :: cli -> (Severity, EffStack ())
    mergeAndRun cliOptions = (getSeverity cliOptions,) $ do
      configFile <- context "Loading config file" $ configLoader cliOptions
      envvars <- context "Fetching environment variables" getEnvVars

      -- Telemetry
      maybeTelSink <- collectTelemetryScope configFile envvars $ getCommonOpts cliOptions
      case maybeTelSink of
        Nothing -> pure ()
        Just ts -> setSink ts

      cfg <- context "Validating configuration" $ optMerge configFile envvars cliOptions
      trackConfig (toText commandName) cfg

      if envConfigDebug envvars
        then do
          logInfo "Running in config-debug mode, no action will be performed"
          logStdout (toStrict $ pShowNoColor cfg)
          logStdout (toText $ show maybeTelSink)
          logStdout (toText $ show envvars)
        else perform cfg

runEffs :: Severity -> EffStack () -> IO ()
runEffs sev = withTelemetry . runStack . withDefaultLogger sev . logWithExit_ . runReadFSIO . runExecIO
