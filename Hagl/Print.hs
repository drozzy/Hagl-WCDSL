{-# OPTIONS_GHC -fglasgow-exts #-}

module Hagl.Print where

import Control.Monad.State
import Data.List

import Hagl.Core
import Hagl.Accessor

------------------------
-- Printing Functions --
------------------------

print :: (MonadIO m, Show a) => m a -> m ()
print = (>>= liftIO . putStr . show)

printLn :: (MonadIO m, Show a) => m a -> m ()
printLn = (>>= liftIO . putStrLn . show)

printStr :: MonadIO m => String -> m ()
printStr = liftIO . putStr

printStrLn :: MonadIO m => String -> m ()
printStrLn = liftIO . putStrLn

printTranscript :: (Game g, GameM m g, MonadIO m, Show (Move g)) => m ()
printTranscript = numGames >>= printTranscriptOfGame

printTranscripts :: (Game g, GameM m g, MonadIO m, Show (Move g)) => m ()
printTranscripts = do n <- numGames
                      mapM_ printTranscriptOfGame [1..n]

printTranscriptOfGame :: (Game g, GameM m g, MonadIO m, Show (Move g)) => Int -> m ()
printTranscriptOfGame n =
  do t <- transcripts `forGameM` n
     p <- payoff `forGameM` n
     ps <- players
     printStrLn $ "Game "++show n++":"
     let str (Just i, m) = "  " ++ show (ps !! (i-1)) ++ "'s move: " ++ show m
         str (Nothing, m) = "  Chance: " ++ show m
      in printStr $ unlines $ map str (reverse t) ++ ["  Payoff: " ++ show (toList p)]

printSummary :: (Game g, GameM m g, MonadIO m, Show (Move g)) => m ()
printSummary = numGames >>= printSummaryOfGame

printSummaries :: (Game g, GameM m g, MonadIO m, Show (Move g)) => m ()
printSummaries = do n <- numGames
                    mapM_ printSummaryOfGame [1..n]

printSummaryOfGame :: (Game g, GameM m g, MonadIO m, Show (Move g)) => Int -> m ()
printSummaryOfGame n = 
    do (ByPlayer mss, ByPlayer vs) <- summaries `forGameM` n
       ps <- players
       printStrLn $ "Summary of Game "++show n++":"
       printStr $ unlines ["  "++show p++" moves: "++show (reverse ms) | (p,ms) <- zip ps mss]
       printStrLn $ "  Score: "++show vs

printScore :: (Game g, GameM m g, MonadIO m, Show (Move g)) => m ()
printScore = do s  <- score
                ps <- players
                printStrLn "Score:"
                printStr (scoreString ps (toList s))

-----------------------
-- Utility functions --
-----------------------

-- Generate a string showing a set of players' scores.
scoreString :: [Player g] -> [Float] -> String 
scoreString ps vs = unlines ["  "++show p++": "++show v | (p,v) <- zip ps vs]
