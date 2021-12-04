module Test.Main where

import Prelude

import Control.Monad.Except (runExceptT, throwError)
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Milliseconds(..), error, launchAff_, makeAff)
import Effect.Class (liftEffect)
import Foreign (Foreign)
import Foreign.Index (readProp)
import JIT.Compile (compile)
import JIT.EvalSources (evalSources, freshModules)
import JIT.Loader (makeLoader)
import Simple.JSON as JSON
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (defaultConfig, runSpec')
import Unsafe.Coerce (unsafeCoerce)

loaderUrl = "https://purescript-wags.netlify.app/js/output" :: String
compileUrl = "https://supvghemaw.eu-west-1.awsapprunner.com" :: String

main :: Effect Unit
main = do
  fm <- freshModules
  launchAff_
    $ runSpec' (defaultConfig { timeout = Just (Milliseconds 10_000.0) }) [ consoleReporter ] do
        describe "jit" do
          it "produces correct code" do
            let loader = makeLoader loaderUrl
            success <- makeAff \cb -> do
              compile
                { code:
                    """module Main where
import Prelude

add42 :: Int -> Int
add42 = add 42
"""
                , loader
                , compileUrl
                , ourFaultErrorCallback: Left >>> cb
                , yourFaultErrorCallback: JSON.writeJSON >>> error >>> Left >>> cb
                , successCallback: Right >>> cb
                }
              mempty
            add42'' <- liftEffect $ evalSources fm success.js
            add42' <- (runExceptT $ readProp "add42" add42''.evaluated) >>= either (throwError <<< error <<< show) pure
            let add42 = (unsafeCoerce :: Foreign -> Int -> Int) add42'
            43 `shouldEqual` add42 1
            success2 <- makeAff \cb -> do
              compile
                { code:
                    """module Main where
import Prelude

add24 :: Int -> Int
add24 = add 24
"""
                , loader
                , compileUrl
                , ourFaultErrorCallback: Left >>> cb
                , yourFaultErrorCallback: JSON.writeJSON >>> error >>> Left >>> cb
                , successCallback: Right >>> cb
                }
              mempty
            add24'' <- liftEffect $ evalSources add42''.modules success2.js
            add24' <- (runExceptT $ readProp "add24" add24''.evaluated) >>= either (throwError <<< error <<< show) pure
            let add24 = (unsafeCoerce :: Foreign -> Int -> Int) add24'
            25 `shouldEqual` add24 1