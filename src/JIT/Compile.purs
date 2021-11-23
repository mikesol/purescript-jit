module JIT.Compile where

import Prelude

import Control.Monad.Except (runExceptT)
import Data.Either (Either(..))
import Data.Newtype (unwrap)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Exception (Error, error)
import JIT.API as API
import JIT.Loader (Loader, runLoader)
import JIT.Types (JS(..))
import Foreign.Object as Object

type CompileSuccess =
  { js :: Object.Object String
  , warnings :: Nullable (Array API.CompileWarning)
  }

compile
  :: { code :: String
     , loader :: Loader
     , compileUrl :: String
     , ourFaultErrorCallback :: Error -> Effect Unit
     , yourFaultErrorCallback :: Array API.CompilerError -> Effect Unit
     , successCallback :: CompileSuccess -> Effect Unit
     }
  -> Effect Unit
compile
  { code
  , compileUrl
  , loader
  , ourFaultErrorCallback
  , yourFaultErrorCallback
  , successCallback
  } = launchAff_ do
  cres <- runExceptT (API.compile compileUrl code)
  case cres of
    Left err -> liftEffect $ ourFaultErrorCallback (error err)
    Right (Left err) -> liftEffect $ ourFaultErrorCallback (error err)
    Right (Right (API.CompileFailed cf)) ->
      case cf.error of
        API.OtherError e -> liftEffect $ ourFaultErrorCallback (error e)
        API.CompilerErrors errs -> liftEffect $ yourFaultErrorCallback errs
    Right (Right (API.CompileSuccess { js, warnings })) -> do
      mbSources <- runExceptT $ runLoader loader (JS js)
      case mbSources of
        Left e -> liftEffect $ ourFaultErrorCallback (error e)
        Right sources -> do
          let eventData = Object.insert "<file>" (JS js) sources
          liftEffect $ successCallback { warnings, js: map unwrap eventData }
