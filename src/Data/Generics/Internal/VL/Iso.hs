{-# LANGUAGE GADTs                     #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE Rank2Types                #-}
{-# LANGUAGE ScopedTypeVariables       #-}
{-# LANGUAGE TypeFamilies              #-}
{-# LANGUAGE TypeFamilyDependencies    #-}
{-# LANGUAGE TypeOperators             #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Generics.Internal.VL.Iso
-- Copyright   :  (C) 2018 Csongor Kiss
-- License     :  BSD3
-- Maintainer  :  Csongor Kiss <kiss.csongor.kiss@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable
--
-- Internal lens helpers. Only exported for Haddock
--
-----------------------------------------------------------------------------
module Data.Generics.Internal.VL.Iso where

import Data.Coerce (coerce)
import Data.Functor.Identity (Identity(..))
import Data.Profunctor (Profunctor(..))
import GHC.Generics
import Data.Generics.Internal.GenericN (Rec (..))

data Exchange a b s t = Exchange (s -> a) (b -> t)

instance Functor (Exchange a b s) where
  fmap f (Exchange sa bt) = Exchange sa (f . bt)
  {-# INLINE fmap #-}

instance Profunctor (Exchange a b) where
  dimap f g (Exchange sa bt) = Exchange (sa . f) (g . bt)
  {-# INLINE dimap #-}
  lmap f (Exchange sa bt) = Exchange (sa . f) bt
  {-# INLINE lmap #-}
  rmap f (Exchange sa bt) = Exchange sa (f . bt)
  {-# INLINE rmap #-}

type Iso' s a
  = forall p f. (Profunctor p, Functor f) => p a (f a) -> p s (f s)

type Iso s t a b
  = forall p f. (Profunctor p, Functor f) => p a (f b) -> p s (f t)

fromIso :: Iso s t a b -> Iso b a t s
fromIso l = withIso l $ \ sa bt -> iso bt sa
{-# inline fromIso #-}

-- | Extract the two functions, one from @s -> a@ and
-- one from @b -> t@ that characterize an 'Iso'.
withIso :: Iso s t a b -> ((s -> a) -> (b -> t) -> r) -> r
withIso ai k = case ai (Exchange id Identity) of
  Exchange sa bt -> k sa (coerce bt)
{-# inline withIso #-}

-- | A type and its generic representation are isomorphic
repIso :: (Generic a, Generic b) => Iso a b (Rep a x) (Rep b x)
repIso = iso from to

-- | 'M1' is just a wrapper around `f p`
mIso :: Iso (M1 i c f p) (M1 i c g p) (f p) (g p)
mIso = iso unM1 M1

kIso :: Iso (K1 r a p) (K1 r b p) a b
kIso = iso unK1 K1

recIso :: Iso (Rec r a p) (Rec r b p) a b
recIso = iso (unK1 . unRec) (Rec . K1)

prodIso :: Iso ((a :*: b) x) ((a' :*: b') x) (a x, b x) (a' x, b' x)
prodIso = iso (\(a :*: b) -> (a, b)) (\(a, b) -> (a :*: b))

iso :: (s -> a) -> (b -> t) -> Iso s t a b
iso sa bt = dimap sa (fmap bt)
{-# INLINE iso #-}
