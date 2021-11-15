module JIT.EvalSources where

import Prelude

import Effect (Effect)
import Foreign (Foreign)
import Foreign.Object (Object)

foreign import evalSources_ :: Object String -> String -> Effect Foreign

fileTag = "<file>" :: String

evalSources :: Object String -> Effect Foreign
evalSources = flip evalSources_ fileTag