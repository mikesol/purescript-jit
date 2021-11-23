module JIT.EvalSources where

import Prelude

import Effect (Effect)
import Foreign (Foreign)
import Foreign.Object (Object)

foreign import evalSources_ :: Modules -> Object String -> String -> Effect Foreign

fileTag = "<file>" :: String

data Modules

foreign import freshModules :: Effect Modules

-- | Changes the modules that are loaded by the evaluator.
evalSources :: Modules -> Object String -> Effect Foreign
evalSources modules sourceMap = evalSources_ modules sourceMap fileTag