{-# OPTIONS -Wall -fno-warn-name-shadowing #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Create new paste controller.

module Hpaste.Controller.New
  (handle,NewStyle(..))
  where

import Control.Monad.IO.Class
import Data.Text.Encoding (decodeUtf8)
import Hpaste.Controller.Paste (pasteForm,getPasteId)
import Hpaste.Model.Channel (getChannels)
import Hpaste.Model.Language (getLanguages)
import Hpaste.Model.Paste (getPasteById,getLatestVersion)
import Hpaste.Types
import Hpaste.View.Annotate as Annotate (page)
import Hpaste.View.Edit as Edit (page)
import Hpaste.View.New as New (page)
import Snap.App
import Spam

data NewStyle = NewPaste | AnnotatePaste | EditPaste
 deriving Eq

-- | Make a new paste.
handle :: NewStyle -> HPCtrl ()
handle style = do
  spamDB <- liftIO (readDB "spam.db")
  chans <- model $ getChannels
  langs <- model $ getLanguages
  defChan <- fmap decodeUtf8 <$> getParam "channel"
  pid <- if style == NewPaste then return Nothing else getPasteId
  case pid of
    Just pid -> do
      paste <- model $ getPasteById pid
      let apaste | style == AnnotatePaste = paste
                 | otherwise = Nothing
      let epaste | style == EditPaste = paste
                 | otherwise = Nothing
      form <- pasteForm spamDB chans langs defChan apaste epaste
      justOrGoHome paste $ \paste -> do
        latest <- model $ getLatestVersion paste
        case style of
          AnnotatePaste -> output $ Annotate.page (pasteTitle latest) form
          EditPaste     -> output $ Edit.page (pasteTitle latest) form
          _ -> goHome
    Nothing -> do
      spamDB <- liftIO $ readDB "spam.db"
      form <- pasteForm spamDB chans langs defChan Nothing Nothing
      output $ New.page form
