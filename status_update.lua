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

function isJson(input)
    if pcall(function() return json.decode(input)end) then 
        return true
    else
        return false
    end
end

function isStatusFormat(input)
    if isJson(input) and json.decode(input)['power'] then
        return true
    else 
        return false
    end
end

function parsing_response(response)
    return json.decode(response)
end

function update_labels(status)
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblPower.value", status['power'])
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblroomtmp.value", status['roomtmp']..'℃')
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblsetpoint.value", status['setpoint']..'℃')
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblopstatus.value", status['opstatus'])
    fibaro:call(fibaro:getSelfId(), "setProperty", "ui.lblfandir.value", status['fandir'])   
end

function query_status_update(connection,D3netIP,UID)
    local qurey_cmd = "unitstat,"..D3netIP..","..UID
    bytes, errCode = connection:write(qurey_cmd)
    if not isSuccess(errCode) then
        print_error_message_on_labels("write cmd fail")
        fibaro:debug("write mes = "..qurey_cmd)
        fibaro:debug('write errCode = '..errCode)
    end

    rdata, errCode = connection:read()
    if not isSuccess(errCode) then
        print_error_message_on_labels("read cmd fail")
        fibaro:debug('read errCode = '..errCode)
        fibaro:debug('read rdata = '..rdata)
    end

    if isStatusFormat(rdata) then
        fibaro:debug(rdata)
        update_labels(parsing_response(rdata))
    else
        fibaro:debug("response data error")
        fibaro:debug("response data = "..rdata)
    end
end

fibaro:debug("button pressed")

Daikin_BOXIP,D3netIP,UID = parsing_ip_field(ip_field)

connection = build_connection(Daikin_BOXIP, tonumber(Daikin_BOXPORT))
query_status_update(connection,D3netIP,UID)
close_connection(connection)