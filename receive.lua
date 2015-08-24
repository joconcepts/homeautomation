function on_msg_receive (msg)
  if started == 0 then
    return
  end
  if msg.out then
    return
  end
  if msg.text then
    mark_read (msg.from.print_name, ok_cb, false)
  end

  if msg.from.print_name ~= 'Jonas_Keidel' then
    return
  end

  local handle = io.popen("ruby /home/telegramd/telegram_server/script.rb ".. string.lower(msg.text))
  local res = handle:read("*a")
  handle:close()
  send_msg(msg.from.print_name, res, ok_cb, false)
end
