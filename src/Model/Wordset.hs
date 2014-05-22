{-# LANGUAGE OverloadedStrings #-}

module Model.Wordset (
              Wordset(..)
            , wordsetNames 
            , wordsetByName
            ) where

import Control.Monad.IO.Class (liftIO)
import qualified Data.Text.Lazy as T (Text)
import Database.PostgreSQL.Simple (Connection, Only(..), query_, query)
import Database.PostgreSQL.Simple.FromField ()
import Model.Definition (Definition(..))

data Wordset = Wordset { name :: T.Text
                       , topic :: T.Text
                       , size :: Int 
                       , definitions :: [Definition] 
                       } deriving (Eq, Show)

wordsetNames :: Connection -> IO [T.Text] 
wordsetNames conn = do wordsets <- query_ conn "SELECT name FROM wordset ORDER BY name" :: IO [Only T.Text] 
                       return $ map (\(Only ws) -> ws) wordsets 

wordsetByName :: Connection -> T.Text -> IO (Maybe Wordset)
wordsetByName conn wsName = do
    wordsets <- query conn "SELECT id, topic FROM wordset WHERE name = ?" [wsName] :: IO [(Integer, T.Text)]
    case wordsets of (wsId, wsTopic):_ -> liftIO $ constructWordset conn wsName wsTopic wsId
                     _ -> return Nothing

constructWordset :: Connection -> T.Text -> T.Text -> Integer -> IO (Maybe Wordset)
constructWordset conn wsName wsTopic wsId = do
    defs <- query conn "SELECT word, meaning FROM definition \
                      \ JOIN wordset_definition ON wordset_definition.definition_id = definition.id \
                      \ WHERE wordset_definition.wordset_id = ?" [wsId] :: IO [Definition]
    return $ Just $ Wordset wsName wsTopic (length defs) defs 
 