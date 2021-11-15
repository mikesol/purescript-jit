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

## FAQ

If anyone asked questions about this repository, let alone frequently, this is what they may ask...

### Why does this code exist?

This code was copied from the Try PureScript and changed very slightly, mostly because I don't know how to use Argonaut.

### Why does the compile API look like a JS callback from hell?

`compile` is designed to be used anywhere, including from JS environments that use callback-style syntax. I use it in a couple Gatsby projects and pass React hooks to the callbacks.