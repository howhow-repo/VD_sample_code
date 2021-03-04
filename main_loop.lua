--[[
  @author Howard
  @date   107.11.26
  @brief  大金box室內機控制VD 
  @update 108.03.26 Howard 更正json decode fail條件、button retry秒數改維隨機
   update 107.12.21 Howard 新增按鈕"Update"，新增絕對溫度按鈕

   !! big change
   update 110.02.26 Howard
   	取消Global variable機制；
	取消retry機制
	已clean code原則更新全部的code
	
  1.port 5051
          
  2.socket cmd_table
    <address>:室外機D3net ID
	<UID>:室內機UID

	室內機目前狀態查詢
		○ unitstat,<address>,<uid>
	室內機開啟
		○ unitctrl,<address>,<uid>,on
	室內機關閉
		○ unitctrl,<address>,<uid>,off
	室內機模式(冷氣|送風|除濕|暖氣|自動)設定	
		○ unitctrl,<address>,<uid>,opmode,<fan|cooling|heating|dry|auto>
	室內機風量設定(強風|微風|弱風)
		○ unitctrl,<address>,<uid>,fanlevel,<h|m|l>
	室內機風向設定(水平|p1|p2|p3|垂直|擺動|停止擺動)
		○ unitctrl,<address>,<uid>,fandir,<h|p1|p2|p3|v|stop|swing>
	室內機溫度設定
		○ unitctrl,<address>,<uid>,setpoint,<Temperture>
         
]]
fibaro:debug("refresh")
fibaro:call(fibaro:getSelfId(), "pressButton", "10")
fibaro:sleep(60000-3)