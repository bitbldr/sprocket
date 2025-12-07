import sprocket/internal/logger

pub fn throw_on_unexpected_deps_mismatch(meta: any) {
  logger.error_meta(
    "
    An unexpected change in hook dependencies was encountered. This means that the list of hook
    dependencies dynamically changed after the initial render. This is not supported and will 
    result in undefined behavior.
    ",
    meta,
  )

  // TODO: we probably want to try and handle this more gracefully in production configurations
  panic
}

pub fn throw_on_unexpected_hook_result(meta: any) {
  logger.error_meta(
    "
    An unexpected hook result was encountered. This means that a hook was dynamically added
    after the initial render. This is not supported and will result in undefined behavior.
    ",
    meta,
  )

  // TODO: we probably want to try and handle this more gracefully in production configurations
  panic
}
