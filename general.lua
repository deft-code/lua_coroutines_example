say("I Am the Very Model of a Modern Major-General")

wait(seconds(10))

send("soldier", "Report in")

function even(id)
  return id % 2 == 0
end

self = even(me().Id)

done = false

id = me().Id

spawn("secretary", function()
  say("I am the secretary")
  wait(minutes(1))
  say("We're done here")
  done = true
  send(id, "Go home")
end)

while not done do
  msg = wait(any_msg())
  if msg.Src.Kind == "soldier" then
    if self == even(msg.Src.Id) then
      send(msg.Src.Id, "Prepare for battle")
    else
      say("I don't like %s", msg.Src.Name)
    end
  elseif msg.Src.Kind == "orc" then
    say("We'll handle you %s", msg.Src.Name)
  end
end

say("I guess we're done")
