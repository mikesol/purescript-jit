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
import JIT.EvalSources (evalSources)
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
            add42' <- liftEffect $ evalSources success.js "<file>"
              >>= runExceptT <<< readProp "add42"
              >>= either (throwError <<< error <<< show) pure
            let add42 = (unsafeCoerce :: Foreign -> Int -> Int) add42'
            43 `shouldEqual` add42 1