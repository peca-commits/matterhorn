module App
  ( runMatterhorn
  , closeMatterhorn
  )
where

import           Prelude ()
import           Prelude.Compat

import           Brick
import           Brick.BChan
import           Data.Monoid ((<>))
import qualified Control.Concurrent.STM as STM
import           Control.Monad.Trans.Except (runExceptT)
import qualified Graphics.Vty as Vty
import           Lens.Micro.Platform
import           System.IO (IOMode(WriteMode), openFile, hClose)
import           Text.Aspell (stopAspell)

import           Network.Mattermost

import           Config
import           Options
import           InputHistory
import           IOUtil
import           LastRunState
import           State.Setup
import           State.Setup.Threads (startAsyncWorkerThread)
import           Events
import           Draw
import           Types

app :: App ChatState MHEvent Name
app = App
  { appDraw         = draw
  , appChooseCursor = showFirstCursor
  , appHandleEvent  = onEvent
  , appStartEvent   = return
  , appAttrMap      = (^.csResources.crTheme)
  }

runMatterhorn :: Options -> Config -> IO ChatState
runMatterhorn opts config = do
    eventChan <- newBChan 25
    writeBChan eventChan RefreshWebsocketEvent

    requestChan <- STM.atomically STM.newTChan

    startAsyncWorkerThread config requestChan eventChan

    logFile <- case optLogLocation opts of
      Just path -> Just `fmap` openFile path WriteMode
      Nothing   -> return Nothing

    st <- setupState logFile config requestChan eventChan

    let mkVty = do
          vty <- Vty.mkVty Vty.defaultConfig
          let output = Vty.outputIface vty
          Vty.setMode output Vty.BracketedPaste True
          Vty.setMode output Vty.Hyperlink True
          return vty

    finalSt <- customMain mkVty (Just eventChan) app st

    case finalSt^.csEditState.cedSpellChecker of
        Nothing -> return ()
        Just (s, _) -> stopAspell s

    case logFile of
      Nothing -> return ()
      Just h -> hClose h

    return finalSt

-- | Cleanup resources and save data for restoring on program restart.
closeMatterhorn :: ChatState -> IO ()
closeMatterhorn finalSt = do
  logIfError (mmCloseSession $ finalSt^.csResources.crSession) "Error in closing session"
  logIfError (writeHistory (finalSt^.csEditState.cedInputHistory)) "Error in writing history"
  logIfError (writeLastRunState finalSt) "Error in writing last run state"
  where
    logIfError action msg = do
      done <- runExceptT $ convertIOException $ action
      case done of
        Left err -> putStrLn $ msg <> ": " <> err
        Right _  -> return ()
