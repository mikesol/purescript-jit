module JIT.API
  ( ErrorPosition(..)
  , CompilerError(..)
  , CompileError(..)
  , CompileWarning(..)
  , Suggestion(..)
  , SuccessResult(..)
  , FailedResult(..)
  , CompileResult(..)
  , get
  , compile
  ) where

import Prelude

import Affjax (URL, printError)
import Affjax as AX
import Affjax.RequestBody as AXRB
import Affjax.ResponseFormat as AXRF
import Affjax.StatusCode (StatusCode(..))
import Control.Alt ((<|>))
import Control.Monad.Except (ExceptT(..))
import Data.Bifunctor (lmap)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Effect.Aff (Aff)
import Foreign (Foreign, fail, ForeignError(..))
import Simple.JSON as JSON

-- | The range of text associated with an error
type ErrorPosition =
  { startLine :: Int
  , endLine :: Int
  , startColumn :: Int
  , endColumn :: Int
  }

type CompilerError =
  { message :: String
  , position :: Nullable ErrorPosition
  }

-- | An error reported from the compile API.
data CompileError
  = CompilerErrors (Array CompilerError)
  | OtherError String

instance decodeJsonCompileError :: JSON.ReadForeign CompileError where
  readImpl i = do
    tc :: { tag :: String, contents :: Foreign } <- JSON.readImpl i
    case tc.tag of
      "OtherError" ->
        map OtherError $ JSON.readImpl tc.contents
      "CompilerErrors" ->
        map CompilerErrors $ JSON.readImpl tc.contents
      _ ->
        fail $ ForeignError "Tag must be one of: OtherError, CompilerErrors"

type Suggestion =
  { replacement :: String
  , replaceRange :: Nullable ErrorPosition
  }

type CompileWarning =
  { errorCode :: String
  , message :: String
  , position :: Nullable ErrorPosition
  , suggestion :: Nullable Suggestion
  }

type SuccessResult =
  { js :: String
  , warnings :: Nullable (Array CompileWarning)
  }

type FailedResult =
  { error :: CompileError
  }

-- | The result of calling the compile API.
data CompileResult
  = CompileSuccess SuccessResult
  | CompileFailed FailedResult

-- | Parse the result from the compile API and verify it
instance decodeJsonCompileResult :: JSON.ReadForeign CompileResult where
  readImpl json =
    map CompileSuccess
      (JSON.readImpl json)
      <|> map CompileFailed (JSON.readImpl json)

get :: URL -> ExceptT String Aff String
get url = ExceptT $ AX.get AXRF.string url >>= case _ of
  Left e ->
    pure $ Left $ printError e
  Right { status } | status >= StatusCode 400 ->
    pure $ Left $ "Received error status code: " <> show status
  Right { body } ->
    pure $ Right body

-- | POST the specified code to the Try PureScript API, and wait for a response.
compile :: String -> String -> ExceptT String Aff (Either String CompileResult)
compile endpoint code = ExceptT $ AX.post AXRF.string (endpoint <> "/compile") requestBody >>= case _ of
  Left e ->
    pure $ Left $ printError e
  Right { status } | status >= StatusCode 400 ->
    pure $ Left $ "Received error status code: " <> show status
  Right { body } ->
    pure $ Right (lmap show $ JSON.readJSON body)
  where
  requestBody = Just $ AXRB.string code
