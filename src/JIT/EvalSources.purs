module JIT.EvalSources where

import Prelude

import Effect (Effect)
import Foreign (Foreign)
import Foreign.Object (Object)

data Modules

type EvalResult = { evaluated :: Foreign, modules :: Modules }

foreign import freshModules :: Effect Modules

foreign import evalSources_ :: Modules -> Object String -> String -> Effect EvalResult

fileTag = "<file>" :: String

evalSources :: Modules -> Object String -> Effect EvalResult
evalSources mod os = evalSources_ mod os fileTag