{-# LANGUAGE OverloadedStrings #-}
-- | Easy FSA visualisation
module Text.Dot.FSA where

import           Text.Dot

import           Control.Monad (forM, forM_, when)
import           Data.Maybe    (fromMaybe, isNothing)

import           Data.Text
import qualified Data.Text     as T
import qualified Data.Text.IO  as T

-- | An easy way to generate an FSA visualization
--
-- You only need to specify the FSA definition and Haphviz takes care of the rest.
--
-- > main :: IO ()
-- > main = renderToStdOut $ fsaGraph
-- >             ["a", "b", "c"]
-- >             "a"
-- >             ["b"]
-- >             [("a", "b", "p"), ("b", "b", "q"), ("b", "c", "p")]
--
-- >>> runhaskell fsa.hs
-- > digraph haphviz {
-- >     node [width=<0>, height=<0>];
-- >     rankdir = LR;
-- >     0 [label=<a>];
-- >     1 [label=<b>, shape=<doublecircle>];
-- >     2 [label=<c>];
-- >     3 [style=<invis>];
-- >     3 -> 0;
-- >     0 -> 1 [label=<p>];
-- >     1 -> 1 [label=<q>];
-- >     1 -> 2 [label=<p>];
-- > }
--
--
fsaGraph :: [Text] -- ^ Set of states
          -> Text -- ^ Initial state
          -> [Text] -- ^ Accepting states
          -> [(Text, Text, Text)] -- ^ Edges: From, To, Symbol
          -> DotGraph
fsaGraph states initial accepting edges = graph_ directed $ do
    nodeDec [width =: "0", height =: "0"] -- Nodes as small as possible
    rankdir leftRight

    stateNodes <- forM states $ \s -> do
        n <- newNode
        genNode n $
            if s `elem` accepting
                then [label =: s, shape =: "doublecircle"]
                else [label =: s]
        return (s, n)

    -- Check that accepting states are actually states
    forM_ accepting $ \s -> do
        when
            (isNothing $ lookup s stateNodes)
            (error $ "Accepting state is not in the set of states: " ++ T.unpack s)

    -- Draw an edge from an invisible state to the initial state
    case lookup initial stateNodes of
        Nothing -> error "Initial state is not in the set of states"
        Just initialNode -> do
            n <- newNode
            genNode n ["style" =: "invis"]
            n --> initialNode

    -- Draw the edges
    forM_ edges $ \(from, to, symbol) -> do
        let fromNode = fromMaybe
                    (error $ "From node not found: " ++ T.unpack from)
                    (lookup from stateNodes)
        let toNode = fromMaybe
                    (error $ "To node not found: " ++ T.unpack to)
                    (lookup to stateNodes)
        genEdge fromNode toNode [label =: symbol]


