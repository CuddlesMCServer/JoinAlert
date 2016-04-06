local JoinAlert = lukkit.addPlugin("JoinAlert", "v2.0",
    function( plugin )
        
        plugin.onEnable(
            function()
                
                -- This is the permission required to create and manage alerts
                plugin.config.setDefault("config.permission", "joinalert.alerts")
                
                -- This is what will be tracked for the session
                plugin.config.setDefault("config.logging.join", true) -- Log what date and time the player joins
                plugin.config.setDefault("config.logging.quit", true) -- Log what date and time the player quits
                plugin.config.setDefault("config.logging.chat", true) -- Log all chat messages the user sends
                plugin.config.setDefault("config.logging.blocks", true) -- Log data of all blocks broken and placed
                
                -- This is what messages will be sent in different circumstances
                plugin.config.setDefault("config.message.create", "&c{name} is now being tracked by {sender}")
                plugin.config.setDefault("config.message.cancel", "&c{sender} cancelled tracking for {name}")
                plugin.config.setDefault("config.message.alert", "&c{name} is being tracked by {sender}")
                plugin.config.setDefault("config.message.usage", "&cUsage: /alert {username}")
                plugin.config.save()
                
                plugin.print("Enabled successfully version "..plugin.version)
                
            end
        )
        
        plugin.onDisable(
            function()
                
                plugin.print("Disabled successfully, tracking may not work")
            
            end
        )
        
        plugin.addCommand("alert", "Create or cancel player alerts", "/alert {username}",
            function(sender, args)
                if sender:hasPermission(plugin.config.get("config.permission")) == true then
                    if args[1] then
                        local offline = server:getOfflinePlayer(args[1])
                        if offline:hasPlayedBefore() or offline:isOnline() then
                            local uuid = offline:getUniqueId():toString()
                            if plugin.config.get(uuid..".stage") == 1 then
                                plugin.config.clear(uuid)
                                plugin.config.save()
                                sender:sendMessage("§cYou have cancelled next login alert for "..offline:getName())
                            elseif plugin.config.get(uuid..".stage") == 2 then
                                plugin.config.clear(uuid)
                                plugin.config.save()
                                sender:sendMessage("§cYou have cancelled the current login event for "..offline:getName())
                            elseif plugin.config.get(uuid..".stage") == 3 then
                                sender:sendMessage("§6=============== "..offline:getName().." ===============")
                                sender:sendMessage("§eUnique User ID: "..uuid)
                                if plugin.config.get(uuid..".join") then 
                                    sender:sendMessage("§eJoin time: §f"..plugin.config.get(uuid..".join")) 
                                end
                                if plugin.config.get(uuid..".quit") then
                                    sender:sendMessage("§eQuit time: §f"..plugin.config.get(uuid..".quit"))
                                end
                                if plugin.config.get(uuid..".blockbreaks") or plugin.config.get(uuid.."blockplaces") then
                                    plugin.config.setDefault(uuid..".blockbreaks", 0)
                                    plugin.config.setDefault(uuid..".blockplaces", 0)
                                    plugin.config.save()
                                    sender:sendMessage("§eBlocks Broken/Placed: "..plugin.config.get(uuid..".blockbreaks").."/"..plugin.config.get(uuid..".blockplaces"))
                                end
                                if plugin.config.get(uuid..".chats") then
                                    sender:sendMessage("§eUser spoke "..plugin.config.get(uuid..".chats").." messages whilst online")
                                end
                            elseif 
                            end
                        else
                            sender:sendMessage("§cThe player "..offline:getName().." has never played before")
                        end
                    else
                        sender:sendMessage(plugin.config.get("config.message.usage"))
                    end
                else
                    sender:sendMessage("§cYou need the \""..plugin.config.get("config.permission").."\" permission to do that")
                end
            end
        )
        
        events.add("playerJoin", 
            function(event)
                
                local player = event:getPlayer()
                local uuid = player:getUniqueId():toString()
                
                if plugin.config.get(uuid..".stage") == 1 then
                    
                    plugin.config.set(uuid..".stage", 2)
                    
                    if plugin.config.get("config.logging.join") == true then
                        plugin.config.set(uuid..".join", os.date("%A %d %B - %X"))
                        plugin.print("Join data is being logged for this player!")
                    end
                    
                    plugin.config.save()
                    
                    local message = plugin.config.get("config.message.alert")
                    message = string.gsub(message, "{name}", player:getName())
                    message = string.gsub(message, "{sender}", plugin.config.get(uuid..".created"))
                    message = string.gsub(message, "&", "§")
                    server:broadcast(message, plugin.config.get("config.permission"))
                    
                end
                
            end
        )
        
        events.add("playerQuit",
            function(event)
                
                local player = event:getPlayer()
                local uuid = player:getUniqueId():toString()
                
                if plugin.config.get(uuid..".stage") == 2 then
                    
                    plugin.config.set(uuid..".stage", 3)
                    
                    if plugin.config.get("config.logging.quit") == true then
                        plugin.config.set(uuid..".quit", os.date("%A %d %B - %X"))
                        plugin.print("Quit data is being logged for this player!")
                    end
                    
                    plugin.config.save()
                    
                    local message = plugin.config.get("config.message.alert")
                    message = string.gsub(message, "{name}", player:getName())
                    message = string.gsub(message, "{sender}", plugin.config.get(uuid..".created"))
                    message = string.gsub(message, "&", "§")
                    server:broadcast(message, plugin.config.get("config.permission"))
                    
                end
                
            end
        )
        
        events.add("blockBreak",
            function(event)
                
                local player = event:getPlayer()
                local uuid = player:getUniqueId():toString()
                
                if plugin.config.get("config.logging.blocks") == true then
                    plugin.config.setDefault(uuid..".blockbreaks", 0)
                    plugin.config.save()
                    plugin.config.set(uuid..".blockbreaks", plugin.config.get(uuid..".blockbreaks") + 1)
                    plugin.config.save()
                end
                
            end
        )
        
        events.add("blockPlace",
            function(event)
                
                local player = event:getPlayer()
                local uuid = player:getUniqueId():toString()
                
                if plugin.config.get("config.logging.blocks") == true then
                    plugin.config.setDefault(uuid..".blockplaces", 0)
                    plugin.config.save()
                    plugin.config.set(uuid..".blockplaces", plugin.config.get(uuid..".blockbreaks") + 1)
                    plugin.config.save()
                end
                
            end
        )
        
        events.add("asyncPlayerChat",
            function(event)
                
                local player = event:getPlayer()
                local uuid = player:getUniqueId():toString()
                
                if plugin.config.get("config.logging.chat") == true then
                    plugin.config.setDefault(uuid..".chats", 0)
                    plugin.config.save()
                    plugin.config.set(uuid..".chats", plugin.config.get(uuid..".chats") + 1)
                    plugin.config.save()
                    
                    plugin.config.set(uuid..".chat"..plugin.config.get(uuid..".chats"), os.date("["..os.date("%d%b-%X").."] "..event:getMessage())
                    plugin.config.save()
                end
            end
        )
        
    end
)
