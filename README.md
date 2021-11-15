# purescript-jit

JIT compilation of PureScript.

Tested with the following config that powers [mikesol.github.io/sf](https://mikesol.github.io/sf).

```purescript
module Config where

loaderUrl :: String
loaderUrl = "https://purescript-wags.netlify.app/js/output"

compileUrl :: String
compileUrl = "https://supvghemaw.eu-west-1.awsapprunner.com"
```

The API has two functions:

- `compile` from `JIT.Compile`
- `evalSources` from `JIT.EvalSources`

To see how to use this from your project (ie from a webpage), check out the [test](./test/Main.purs).