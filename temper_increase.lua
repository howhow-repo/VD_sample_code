local cmd_label = "ui.lblsetpoint.value"
local ip_field = fibaro:getValue(fibaro:getSelfId(), 'IPAddress')
local Daikin_BOXPORT = fibaro:getValue(fibaro:getSelfId(), 'TCPPort')

function parsing_ip_field(raw_field_data)
    first_label = string.find(raw_field_data,":")
    second_label = string.find(raw_field_data,":",first_label+1)   

    Daikin_BOXIP = string.sub(raw_field_data,1,first_label -1)
    D3netIP = string.sub(raw_field_data,first_label+1,second_label -1)
    UID = string.sub(raw_field_data,second_label+1,#raw_field_data)

    return Daikin_BOXIP,D3netIP,UID
end

function get_target_temper()
    currentTmp = fibaro:get(fibaro:getSelfId(),"ui.lblsetpoint.value")
    if not string.find(currentTmp,"℃") then
        return 25
    end
    currentTmp = tonumber(string.sub(currentTmp,1,-4))
    return currentTmp
end

function increased_temper(currentTmp) -- max 32
    if currentTmp < 32 then
        return currentTmp + 1
    else
        return currentTmp
    end
end

function decreased_temper(currentTmp) -- min16 32
    if currentTmp > 16 then
        return currentTmp - 1
    else
        return currentTmp
    end
end

function print_error_message_on_labels(mes)
    fibaro:debug(tostring(mes))
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblPower.value", tostring(mes))
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblroomtmp.value", " ")
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblsetpoint.value", " ")
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblopstatus.value", " ")
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblfandir.value", " ")
end

function build_connection(ip,port) -- please remember to close connection after used
    tcpSocket = Net.FTcpSocket(Daikin_BOXIP, tonumber(Daikin_BOXPORT))
    tcpSocket:setReadTimeout(10000)
    return tcpSocket
end

function close_connection(connection)
    connection:disconnect()
end

function isSuccess(errCode)
    if errCode == 0 then
        return true
    else
        return false
    end
end

function is_read_response_ok(connection)
    rdata, errCode = connection:read()
    if not isSuccess(errCode) then
        print_error_message_on_labels("Daikinbox does not response")
        return false
    end

    if rdata == "{'response': 'OK'}"..string.char(0x0d)..string.char(0x0a) then 
        return true
    else
        print_error_message_on_labels("Daikinbox does not response ok")
        fibaro:debug("rdata = "..rdata)
        return false
    end
end

function update_label()
    fibaro:call(fibaro:getSelfId(), "setProperty", cmd_label, cmd_label_message)
end

function sent_cmd_message(connection,Daikin_message)
    bytes, errCode = connection:write(Daikin_message)
    if not isSuccess(errCode) then
        print_error_message_on_labels("write cmd fail")
        fibaro:debug('write errCode = '..errCode)
    end

    if is_read_response_ok(connection) then
        update_label()
    end
end

fibaro:debug("button pressed")

now_target = get_target_temper()
targetTmp = increased_temper(now_target)
cmd = "setpoint,"..targetTmp
cmd_label_message = targetTmp .."℃"

Daikin_BOXIP,D3netIP,UID = parsing_ip_field(ip_field)
Daikin_message = "unitctrl,"..D3netIP..","..UID..","..cmd

connection = build_connection(Daikin_BOXIP, tonumber(Daikin_BOXPORT))
sent_cmd_message(connection,Daikin_message)
close_connection(connection)