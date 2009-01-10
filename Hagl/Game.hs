{-# OPTIONS_GHC -fglasgow-exts #-}

module Hagl.Game where

import Control.Monad.State hiding (State)

import Hagl.Core
import Hagl.Accessor

--
-- Non-monadic functions used in defining games.
--

-- Payoff where player w wins (1) and all other players, out of np, lose (-1).
winner :: Int -> PlayerIx -> Payoff
winner np w = ByPlayer $ replicate (w-1) (-1) ++ (fromIntegral np - 1) : replicate (np - w) (-1)

-- Payoff where player w loses (-1) and all other players, out of np, win (1).
loser :: Int -> PlayerIx -> Payoff
loser np l = ByPlayer $ replicate (l-1) 1 ++ (1 - fromIntegral np) : replicate (np - l) 1

-- All players, out of np, tie (0).
tie :: Int -> Payoff
tie np = ByPlayer $ replicate np 0

-- The next player index out of np players.
nextPlayer :: Int -> PlayerIx -> PlayerIx
nextPlayer np p | p == np   = 1
                | otherwise = p + 1

--
-- High-level monadic functions for defining games.
--

decide :: Game g => PlayerIx -> ExecM g (Move g)
decide i = do startTurn i
              p <- getPlayer i
              (m, p') <- runStrategy p
              setPlayer i p'
              playerMoved i m
              endTurn
              return m

allPlayers :: Game g => (PlayerIx -> ExecM g a) -> ExecM g (ByPlayer a)
allPlayers f = do n <- numPlayers
                  liftM ByPlayer (mapM f [1..n])

takeTurns :: Game g => (PlayerIx -> ExecM g a) -> ExecM g Bool -> ExecM g a
takeTurns go until = turn 1
  where turn p = do a <- go p
                    b <- until
                    n <- numPlayers
                    if b then return a else turn (nextPlayer n p)
                    

marginal :: Game g => (Payoff -> Payoff) -> ExecM g Payoff
marginal f = liftM f score

--
-- Lower-level monadic functions.
--

-- Player turns

startTurn :: Game g => PlayerIx -> ExecM g ()
startTurn i = setPlayerIx (Just i)

endTurn :: Game g => ExecM g ()
endTurn = setPlayerIx Nothing

-- Tracking moves

chanceMoved :: Game g => Move g -> ExecM g ()
chanceMoved = genericMoved Nothing

playerMoved :: Game g => PlayerIx -> Move g -> ExecM g ()
playerMoved = genericMoved . Just

genericMoved :: Game g => (Maybe PlayerIx) -> Move g -> ExecM g ()
genericMoved i m = do e <- getExec
                      put e { _transcript = (i, m) : _transcript e }

--
-- Getters and setters. (Also see Hagl.Exec for basic getters.)
--

setPlayerIx :: Game g => Maybe PlayerIx -> ExecM g ()
setPlayerIx i = do exec <- getExec
                   put exec { _playerIx = i }

putGameState :: Game g => State g -> ExecM g ()
putGameState s = getExec >>= \e -> put e { _gameState = s }

updateGameState :: Game g => (State g -> State g) -> ExecM g (State g)
updateGameState f = gameState >>= \s -> 
                    let s' = f s in putGameState s' >> return s'

getPlayer :: Game g => PlayerIx -> ExecM g (Player g)
getPlayer i = liftM (!! (i-1)) players

setPlayer :: Game g => PlayerIx -> Player g -> ExecM g ()
setPlayer i p = do e <- getExec
                   let (ph, _:pt) = splitAt (i-1) (_players e)
                    in put e { _players = ph ++ p : pt }
