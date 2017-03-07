-- Runs git programs.
PROPERTIES_FILE = "settings.gitrun.txt"


function load_properties()
  if not fs.exists(PROPERTIES_FILE) then
    return {}
  end
  h = fs.open(PROPERTIES_FILE, "r")
  text = h.readAll()
  h.close()
  properties = {}
  while true do
    eq = string.find(text, "=")
    if eq == nil then
      break
    end
    key = string.sub(text, 1, eq - 1)
    newline = string.find(text, "\n")
    val = ""
    if newline == nil then
      val = string.sub(text, eq + 1)
      properties[key] = val
      break
    else
      val = string.sub(text, eq + 1, newline - 1)
      text = string.sub(text, newline + 1)
      properties[key] = val
    end
  end
  return properties
end


function save_properties(properties)
  h = fs.open(PROPERTIES_FILE, "w")
  for k, v in pairs(properties) do
    h.write(string.format("%s=%s\n", k, v))
  end
  h.close()
end

function download_script(properties)
  org = properties["org"] or "gmalmquist"
  repo = properties["repo"] or "turtling"
  branch = properties["branch"] or "master"
  dir = properties["dir"] or ""
  path = properties["path"] or ""

  print(string.format("org=%s", org))
  print(string.format("repo=%s", repo))
  print(string.format("branch=%s", branch))
  print(string.format("dir=%s", dir))
  print(string.format("path=%s", path))

  if string.len(dir) > 0 then
    path = string.format("%s/%s", dir, path)
  end

  target_name = path
  -- Strip out extension.
  dot_lua = string.find(target_name, ".lua")
  if dot_lua ~= nil then
    target_name = string.sub(target_name, 1, dot_lua - 1)
  end
  -- Strip out directory component.
  last_slash = string.find(target_name, "/")
  while last_slash ~= nil do
    target_name = string.sub(target_name, last_slash + 1)
    last_slash = string.find(target_name, "/")
  end

  if target_name and string.len(target_name) > 0 then
    if target_name == shell.getRunningProgram() then
      print("GitRun cannot overwrite itself.")
      return
    end

    url = string.format(
      "https://raw.githubusercontent.com/%s/%s/%s/%s",
      org,
      repo,
      branch,
      path
    )

    print(url)
    print(string.format("Downloading to '%s' ...", target_name))

    h = http.get(url)
    if h ~= nil then
      content = h.readAll()
      h.close()

      h = fs.open(target_name, "w")
      h.write(content)
      h.close()
      return target_name
    else
      print("404")
    end
  else
    print(string.format("Could not infer destination file from '%s'.", path))
  end
end


function help_message()
  print("Downloads and runs code from git.")
  print("Usage:")
  print("  GitRun set-org <git organization or user>")
  print("  GitRun set-repo <repo in org>")
  print("  GitRun set-branch <branch in repo>")
  print("  GitRun set-dir <directory in repo>")
  print("  GitRun set-path <git path in dir>")
  print("  GitRun <path>")
  print("  GitRun reset")
  print("  GitRun settings")
  print("  GitRun auto")
end


function gitrun_main(args)
  properties = load_properties()

  should_run = false

  if (# args) == 2 then
    if args[1] == "set-org" then
      properties["org"] = args[2]
    elseif args[1] == "set-repo" then
      properties["repo"] = args[2]
    elseif args[1] == "set-branch" then
      properties["branch"] = args[2]
    elseif args[1] == "set-path" then
      properties["path"] = args[2]
    elseif args[1] == "set-dir" then
      properties["dir"] = args[2]
    end
    save_properties(properties)
  elseif (# args) == 1 then
    if args[1] == "reset" then
      fs.delete(PROPERTIES_FILE)
    elseif args[1] == "auto" then
      print(string.format("Run using last-specified path %s.", properties["path"]))
      should_run = true
    elseif args[1] == "settings" then
      print("Non-default settings:")
      for k,v in pairs(properties) do
        print(string.format("%s=%s", k, v))
      end
    else
      properties["path"] = args[1]
      save_properties(properties)
      should_run = true
    end
  elseif (# args) == 0 then
    help_message()
  end

  if should_run then
    script = download_script(properties)
    if script then
      print(string.format("Download successful, running '%s'.", script))
      shell.run(script)
    end
  end
end


gitrun_main({...})
