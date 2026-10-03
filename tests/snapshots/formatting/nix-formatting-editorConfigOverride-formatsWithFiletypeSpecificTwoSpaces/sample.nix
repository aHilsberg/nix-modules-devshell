{
  name ? "demo",
  enabled ? true,
}: {
  inherit name;
  settings = {
    inherit enabled;
    retries = 3;
    paths = ["alpha" "bravo" "charlie"];
    nested = {message = "hello";};
  };
}
