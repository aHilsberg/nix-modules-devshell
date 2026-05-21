def repo-root [] {
  let prj_root = ($env.PRJ_ROOT? | default "")

  if not ($prj_root | is-empty) {
    $prj_root
  } else {
    let git_root = do --ignore-errors { ^git rev-parse --show-toplevel | str trim }

    if ($git_root | is-empty) {
      pwd
    } else {
      $git_root
    }
  }
}

def absolute-file [root: path, file: path] {
  let file_string = ($file | into string)

  if ($file_string | str starts-with "/") {
    $file_string
  } else {
    $root | path join $file_string
  }
}

def editorconfig-props [file: path] {
  ^editorconfig $file
  | lines
  | where { |line| $line =~ '=' }
  | parse "{key}={value}"
  | reduce -f {} { |it, acc|
      $acc | insert ($it.key | str trim) ($it.value | str trim)
    }
}

def get-editorconfig-value [props: record, key: string, default: string] {
  let value = (
    $props
    | get --optional $key
    | default $default
    | str trim
  )

  if $value == "" or $value == "unset" or $value == "off" {
    $default
  } else {
    $value
  }
}

let root = repo-root
let file = absolute-file $root ($env.FILE? | default "any.yaml")

let props = editorconfig-props $file

let indent_style = get-editorconfig-value $props "indent_style" "space"
let indent_size = get-editorconfig-value $props "indent_size" "2"
let tab_width = get-editorconfig-value $props "tab_width" "2"
let max_line_length = get-editorconfig-value $props "max_line_length" "80"

let use_tabs = ($indent_style == "tab")

let indent_width = if $indent_size == "tab" {
  $tab_width
} else {
  $indent_size
}

let line_width = $max_line_length

{
  fmt: {
    useTabs: $use_tabs,
    indentWidth: ($indent_width | into int),
    lineWidth: ($line_width | into int)
  }
} | to json