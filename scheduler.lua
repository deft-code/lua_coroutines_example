child_by_co = {}
child_by_id = {}
id_count = 0

function sprintf(f, ...)
  return string.format(f, ...)
end

function printf(f, ...)
  print(sprintf(f, ...))
end

function dprintf(...)
  local info = debug.getinfo(2, "nSl")
  local co = coroutine.running()
  local child = child_by_co[co]
  if child == nil then
    name = "scheduler"
  else
    name = child.Name
  end
  printf("%s:%d:%s:%s %s", info.source, info.currentline, info.name, name, sprintf(...))
end

-- Disable debug printing
-- Comment this out to enable debug output
dprintf = function(...)end

function _make_selector(me, who)
  local not_me = function(child)
    dprintf("not me %d, %s", me.Id, child.Name)
    return child.Id ~= me.Id
  end

  dprintf("who: %s", tostring(who))
  if who == "*" then
    dprintf("selector not_me %s", tostring(not_me))
    return not_me

  elseif type(who) == "string" then
    dprintf("selector kind")
    return function(child)
      dprintf("kind select %s == %s for %s", who, child.Name, me.Name)
      return (child.Kind == who) and not_me(child)
    end

  else
    dprintf("selector id")
    return function(child)
      dprintf("id select %d, %s", who, child.Name)
      return child.Id == who
    end
  end
end

-- Child API

function me()
  return child_by_co[coroutine.running()]
end

function spawn(k, body)
  local co = coroutine.create(body)
  local id = id_count
  id_count = id_count + 1
  local child = {
    Kind = k,
    Id = id,
    Name = sprintf("%s:%d", k, id),
    Co = co,
    Msgs = {},
    Waiter = function() return true end,
  }
  child_by_co[co] = child
  child_by_id[id] = child
  dprintf("Spawned %s", child.Name)
  return child
end

function say(f, ...)
  local me = me()
  printf("%s says '%s'", me.Name, sprintf(f, ...))
end

function recv()
  local msgs = me().Msgs
  if next(msgs) then
    return table.remove(msg, 1)
  end
  return nil
end

function send(who, what)
  local me = me()
  local selector = _make_selector(me, who)
  dprintf("%s sending '%s' to %s", me.Name, what, who)
  for co, child in pairs(child_by_co) do
    if selector(child) then
      printf("%s tells %s '%s'", me.Name, child.Name, what)
      table.insert(child.Msgs, {Src = me, Msg = what})
    end
  end
end

function any(...)
  local waiters = {...}
  return function()
    dprintf("waiter %s", waiters)
    for i, waiter in ipairs(waiters) do
      local ready, resp = waiter()
      if ready then
        return true, i, resp
      end
    end
    return false, nil, nil
  end
end

function any_msg()
  return msg_from("*")
end

function msg_from(who)
  local me = me()

  dprintf("msg_from(%s)", tostring(who))
  local selector = _make_selector(me, who)
  dprintf("msg_from(%s) %s", tostring(who), tostring(selector))
  return function()
    dprintf("%s<%d> is waiting for %s", me.Name, #me.Msgs, tostring(who))
    for i, msg in ipairs(me.Msgs) do
      if selector(msg.Src) then
        printf("%s hears %s '%s'", me.Name, msg.Src.Name, msg.Msg)
        table.remove(me.Msgs, i)
        return true, msg
      end
    end
    return false, nil
  end
end

function minutes(m)
  return seconds(60*m)
end

function seconds(s)
  local me = me()
  return function()
    dprintf("%s<%d> is waiting for %s", me.Name, #me.Msgs, s)
    s = s - 1
    return s < 1, nil
  end
end

function wait( waiter )
  return coroutine.yield(waiter)
end

-- Start Scheduler stuff

function scheduler()
  for i, file in ipairs(arg) do
    dprintf("loading file %q as %d", file, i)
    local f = loadfile(file)
    local k = file:sub(1, -5)
    spawn(k, f)
  end


  local max_stall =100 
  local stall = 0
  while next(child_by_co) and stall < max_stall do
    dprintf("scheduler tick")
    for _, child in pairs(child_by_co) do
      if child.Waiter == nil then
        printf("%s is %s", child.Name, coroutine.status(child.Co))
        child_by_co[child.Co] = nil
        child.Co = nil
      else
        dprintf("checking child %s, %s", child.Name, tostring(child.Waiter))
        local function waiter_check(ready, ...)
          if ready then
            local success
            success, child.Waiter = coroutine.resume(child.Co, ...)
            if not success then
              printf("%s had an error %q", child.Name, child.Waiter)
              child.Waiter = nil
            end
            stall = 0
          end
        end
        waiter_check(child.Waiter())
      end
      dprintf("done with child %s", child.Name)
    end
    stall = stall + 1
  end
  if stall >= max_stall then
    printf("Scheduler stalled")
  else
    printf("All children completed")
  end
end

scheduler()
