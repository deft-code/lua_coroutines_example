child_by_co = {}
child_by_id = {}

function _me()
  return child_by_co[coroutine.running()]
end

-- Child API

function id()
  return _me().Id
end

function who(id)
  return child_by_id[id]
end

function say(s)
  me = _me()
  print(string.format("%s(%d) says %s", me.Type, me.Id, s))
end

function recv()
  msgs = _me().Msgs
  if msgs > 0 then
    return table.remove(msgs, 0)
  end
  return nil
end

function send( who, what)
  me = _me()
  table.insert(child_by_id[who], {Src = me.Id, Msg = what})
end

function or_( a, b )
  return function()
    ready, extra = a()
    if ready then
      return true, 1, extra
    end
    ready, extra = b()
    return ready, 2, extra
  end
end

function any_msg()
  return msg_from("*")
end

function msg_from(who)
  me = _me()
  return function()
    for i, msg in ipairs(me.Msgs) do
      if msg.Src == who or who == "*" then
        table.remove(me.Msgs,i)
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
  return function()
    s = s - 1
    return s < 1, nil
  end
end

function wait( waiter )
  coroutine.yield(waiter)
end

-- Start Scheduler stuff

for i, name in ipairs(arg) do
  print( "loading file", i, name )
  f = loadfile(name)
  co = coroutine.create(f)
  child = {Type=name, Co=co, Msgs={}, Id=i, Waiter=function()return true end}
  child_by_co[co] = child
  child_by_name[name] = child
  child_by_id[i] = child
end

while next(child_by_co) do
  print("scheduler tick")
  for co, child in pairs(child_by_co) do
    if child.Waiter == nil then
      print(child.Type, child.Id, "exited")
      child_by_co[co] = nil
    else
      ready, extra = child.Waiter()
      if ready then
        success, child.Waiter = coroutine.resume(co,extra)
      end
    end
  end
end
