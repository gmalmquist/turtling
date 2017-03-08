-- Runs git programs.
PROPERTIES_FILE = "settings.gitrun.txt"


function load_properties()
  if not fs.exists(PROPERTIES_FILE) then
    return {}
  end
  local h = fs.open(PROPERTIES_FILE, "r")
  local text = h.readAll()
  h.close()
  local properties = {}
  while true do
    local eq = string.find(text, "=")
    if eq == nil then
      break
    end
    local key = string.sub(text, 1, eq - 1)
    local newline = string.find(text, "\n")
    local val = ""
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
  local h = fs.open(PROPERTIES_FILE, "w")
  for k, v in pairs(properties) do
    h.write(string.format("%s=%s\n", k, v))
  end
  h.close()
end


function process_download(properties, out)
  local included = properties.included or {}

  function get_url(properties)
    if properties["url"] ~= nil and string.len(properties["url"]) > 0 then
      return properties["url"]
    end
    local dir = properties.dir
    local path = properties.path
    if string.len(dir) > 0 then
      path = string.format("%s/%s", dir, path)
    end
    return string.format(
      "https://raw.githubusercontent.com/%s/%s/%s/%s",
      properties.org,
      properties.repo,
      properties.branch,
      path
    )
  end

  function process_line(line)
    local a, b = string.find(line, '#include')
    if a ~= nil then
      -- process file inclusion
      local path = string.sub(line, b + 1)
      while string.find(path, " ") == 1 do
        path = string.sub(path, 2)
      end
      while string.sub(string.len(path), string.len(path)) == " " do
        path = string.sub(path, 1, string.len(path) - 1)
      end
      local url = ""
      if string.find(path, "http:") == 1 or string.find(path, "https:") == 1 then
        url = path
      end
      local dir = properties.dir
      if string.find(path, "/") == 1 then
        dir = ""
        path = string.sub(path, 2)
      end
      return process_download({
        org = properties.org,
        repo = properties.repo,
        branch = properties.branch,
        dir = dir,
        path = path,
        url = url,
        included = included
      }, out)
    end
    out.write('\n')
    out.write(line)
    return true
  end

  local url = get_url(properties)
  if url == nil or string.len(url) == 0 then
    print("Cannot download nil or '' url.")
    return false
  end

  print(url)

  if included[url] then
    print(string.format("skipping already-downloaded %s", url))
    return true -- We already included this file.
  end
  included[url] = true

  local headers = {}
  headers["Cache-Control"] = "no-cache"
  headers["Pragma"] = "no-cache"
  headers["Expires"] = "0"

  local h = http.get(url, headers)
  if h ~= nil then
    if h.getResponseCode() ~= 200 then
      print(string.format("server returned %d", h.getResponseCode()))
      return false
    end
    local li = 0
    local line = h.readLine()
    while line ~= nil do
      li = li + 1
      if not process_line(line) then
        print(string.format("Unable to process: %s", line))
        h.close()
        return false
      end
      line = h.readLine()
    end
    h.close()
    print(string.format("  %d lines from %s", li, properties.path))
    return true
  else
    print(string.format("404 - %s", url))
    return false
  end
end


function download_script(properties)
  local org = properties["org"] or "gmalmquist"
  local repo = properties["repo"] or "turtling"
  local branch = properties["branch"] or "master"
  local dir = properties["dir"] or ""
  local path = properties["path"] or ""

  print(string.format("org=%s", org))
  print(string.format("repo=%s", repo))
  print(string.format("branch=%s", branch))
  print(string.format("dir=%s", dir))
  print(string.format("path=%s", path))

  local target_name = path
  -- Strip out extension.
  local dot_lua = string.find(target_name, ".lua")
  if dot_lua ~= nil then
    target_name = string.sub(target_name, 1, dot_lua - 1)
  end
  -- Strip out directory component.
  local last_slash = string.find(target_name, "/")
  while last_slash ~= nil do
    target_name = string.sub(target_name, last_slash + 1)
    last_slash = string.find(target_name, "/")
  end

  if target_name and string.len(target_name) > 0 then
    if target_name == shell.getRunningProgram() then
      print("GitRun cannot overwrite itself.")
      return
    end

    print(string.format("Downloading to '%s' ...", target_name))
    if fs.exists(target_name) then
      print("deleting existing ", target_name)
      fs.delete(target_name)
    end
    local h = fs.open(target_name, "w")
    local result = process_download({
      org = org,
      repo = repo,
      branch = branch,
      dir = dir,
      path = path
    }, h)
    h.close()
    if result then
      return target_name
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
