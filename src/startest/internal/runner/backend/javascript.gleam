//// The test runner implementation specific to the JavaScript target.

@target(javascript)
import gleam/dynamic.{type Dynamic}
@target(javascript)
import gleam/javascript/array.{type Array}
@target(javascript)
import gleam/javascript/promise.{type Promise}
@target(javascript)
import gleam/list
@target(javascript)
import gleam/string
@target(javascript)
import startest/context.{type Context}
@target(javascript)
import startest/internal/runner/core
@target(javascript)
import startest/locator

@target(javascript)
pub fn run_tests(ctx: Context) -> Promise(Nil) {
  let assert Ok(test_files) = locator.locate_test_files()

  // TODO: Retrieve package name from `gleam.toml`.
  let package_name = "startest"

  use tests <- promise.await(
    test_files
    |> list.map(fn(filepath) {
      let js_module_path =
        "../" <> package_name <> "/" <> gleam_filepath_to_mjs_filepath(filepath)

      get_exports(js_module_path)
      |> promise.map(array.to_list)
    })
    |> promise.await_list
    |> promise.map(list.flatten)
    |> promise.map(locator.identify_tests(_, ctx)),
  )

  tests
  |> core.run_tests(ctx)
  |> promise.resolve
}

@target(javascript)
fn gleam_filepath_to_mjs_filepath(filepath: String) {
  filepath
  |> string.slice(
    at_index: string.length("test/"),
    length: string.length(filepath),
  )
  |> string.replace(".gleam", ".mjs")
}

@target(javascript)
@external(javascript, "../../../../startest_ffi.mjs", "get_exports")
fn get_exports(
  module_path: String,
) -> Promise(Array(#(String, fn() -> Dynamic)))