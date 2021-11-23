module Test.Main where

import Prelude

import Control.Monad.Except (runExceptT, throwError)
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Milliseconds(..), error, launchAff_, makeAff)
import Effect.Class (liftEffect)
import JIT.Compile (compile)
import Foreign (Foreign)
import Foreign.Index (readProp)
import JIT.EvalSources (evalSources, freshModules)
import Simple.JSON as JSON
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (defaultConfig, runSpec')
import Unsafe.Coerce (unsafeCoerce)

main :: Effect Unit
main = do
  launchAff_
    $ runSpec' (defaultConfig { timeout = Just (Milliseconds 10_000.0) }) [ consoleReporter ] do
        describe "jit" do
          it "produces correct code" do
            modules <- liftEffect freshModules
            success <- makeAff \cb -> do
              compile
                { code:
                    """module Main where
import Prelude

add42 :: Int -> Int
add42 = add 42
"""
                , loaderUrl: "https://purescript-wags.netlify.app/js/output"
                , compileUrl: "https://supvghemaw.eu-west-1.awsapprunner.com"
                , ourFaultErrorCallback: Left >>> cb
                , yourFaultErrorCallback: JSON.writeJSON >>> error >>> Left >>> cb
                , successCallback: Right >>> cb
                }
              mempty
            add42' <- liftEffect $ evalSources modules success.js
              >>= runExceptT <<< readProp "add42"
              >>= either (throwError <<< error <<< show) pure
            let add42 = (unsafeCoerce :: Foreign -> Int -> Int) add42'
            43 `shouldEqual` add42 1
            success2 <- makeAff \cb -> do
              compile
                { code:
                    """module Main where
import Prelude

add43 :: Int -> Int
add43 = add 43
"""
                , loaderUrl: "https://purescript-wags.netlify.app/js/output"
                , compileUrl: "https://supvghemaw.eu-west-1.awsapprunner.com"
                , ourFaultErrorCallback: Left >>> cb
                , yourFaultErrorCallback: JSON.writeJSON >>> error >>> Left >>> cb
                , successCallback: Right >>> cb
                }
              mempty
            add43' <- liftEffect $ evalSources modules success2.js
              >>= runExceptT <<< readProp "add43"
              >>= either (throwError <<< error <<< show) pure
            let add43 = (unsafeCoerce :: Foreign -> Int -> Int) add43'
            44 `shouldEqual` add43 1