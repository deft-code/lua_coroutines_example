say("Soldier on duty!")

msg = wait(msg_from("general"))

send(msg.Src.Id, "Reporting for duty")

which, msg = wait(any(msg_from("general"), seconds(20)))

attacking = false
if which == 1 then
  say("The general says %q", msg.Msg)
  attacking = true
else
  say("forever alone :.(")
end

repeat
  which, msg = wait(any(msg_from("orc"), seconds(20)))
  if which == 1 then
    if attacking then
      say("Attack %s", msg.Src.Name)
    else
      say("Run Away! Run Away!")
    end
  end
until which == 2

say("To the tavern to celebrate")
