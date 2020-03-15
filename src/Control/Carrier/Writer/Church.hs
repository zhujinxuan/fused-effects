{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
module Control.Carrier.Writer.Church
( -- * Writer carrier
  runWriter
, execWriter
, WriterC(WriterC)
  -- * Writer effect
, module Control.Effect.Writer
) where

import Control.Algebra
import Control.Applicative (Alternative)
import Control.Carrier.State.Church
import Control.Effect.Writer
import Control.Monad (MonadPlus)
import Control.Monad.Fail as Fail
import Control.Monad.Fix
import Control.Monad.IO.Class
import Control.Monad.Trans.Class

runWriter :: Monoid w => (w -> a -> m b) -> WriterC w m a -> m b
runWriter k = runState k mempty . runWriterC
{-# INLINE runWriter #-}

-- | Run a 'Writer' effect with a 'Monoid'al log, producing the final log and discarding the result value.
--
-- @
-- 'execWriter' = 'runWriter' ('const' '.' 'pure')
-- @
execWriter :: (Monoid w, Applicative m) => WriterC w m a -> m w
execWriter = runWriter (const . pure)
{-# INLINE execWriter #-}

newtype WriterC w m a = WriterC { runWriterC :: StateC w m a }
  deriving (Alternative, Applicative, Functor, Monad, Fail.MonadFail, MonadFix, MonadIO, MonadPlus, MonadTrans)

instance (Algebra sig m, Monoid w) => Algebra (Writer w :+: sig) (WriterC w m) where
  alg hdl sig ctx = WriterC $ case sig of
    L writer -> StateC $ \ k w -> case writer of
      Tell w'    -> (k $! mappend w w') ctx
      Listen   m -> runWriter (\ w' a -> (k $! mappend w w') ((,) w' <$> a)) (hdl (m <$ ctx))
      Censor f m -> runWriter (\ w' a -> (k $! mappend w (f $! w')) a) (hdl (m <$ ctx))
    R other  -> alg (runWriterC . hdl) (R other) ctx
  {-# INLINE alg #-}
