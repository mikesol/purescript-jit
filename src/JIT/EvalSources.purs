module JIT.EvalSources where

import Effect (Effect)
import Foreign (Foreign)
import Foreign.Object (Object)

foreign import evalSources :: Object String -> String -> Effect Foreign