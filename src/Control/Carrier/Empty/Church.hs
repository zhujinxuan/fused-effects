{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE RankNTypes #-}
module Control.Carrier.Empty.Church
( -- * Empty carrier
  runEmpty
, EmptyC(..)
  -- * Empty effect
, module Control.Effect.Empty
) where

import Control.Applicative (liftA2)
import Control.Effect.Empty

runEmpty :: (a -> m b) -> m b -> EmptyC m a -> m b
runEmpty leaf nil (EmptyC m) = m leaf nil
{-# INLINE runEmpty #-}

newtype EmptyC m a = EmptyC (forall b . (a -> m b) -> m b -> m b)
  deriving (Functor)

instance Applicative (EmptyC m) where
  pure a = EmptyC $ \ leaf _ -> leaf a
  {-# INLINE pure #-}

  EmptyC f <*> EmptyC a = EmptyC $ \ leaf nil ->
    f (\ f' -> a (leaf . f') nil) nil
  {-# INLINE (<*>) #-}

  liftA2 f (EmptyC a) (EmptyC b) = EmptyC $ \ leaf nil ->
    a (\ a' -> b (leaf . f a') nil) nil
  {-# INLINE liftA2 #-}

  EmptyC a *> EmptyC b = EmptyC $ \ leaf nil ->
    a (\ _ -> b leaf nil) nil
  {-# INLINE (*>) #-}

  EmptyC a <* EmptyC b = EmptyC $ \ leaf nil ->
    a (\ a' -> b (const (leaf a')) nil) nil
  {-# INLINE (<*) #-}

instance Monad (EmptyC m) where
  EmptyC a >>= f = EmptyC $ \ leaf nil ->
    a (runEmpty leaf nil . f) nil
  {-# INLINE (>>=) #-}

  (>>) = (*>)
  {-# INLINE (>>) #-}
