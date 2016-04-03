local JoinAlert = lukkit.addPlugin("JoinAlert", "v1.0",
    function(plugin)
        plugin.onEnable(
            function()
                plugin.config.setDefault("config")
                plugin.config.setDefault("alerts")
                plugin.config.setDefault("config.permission", "joinalert.notify")
                plugin.config.setDefault("config.message.created", "§aStaff will be notified if {name} joins later.")
                plugin.config.setDefault("config.message.cleared", "§cStaff will not be notified if {name} joins later.")
                plugin.config.setDefault("config.message.joiner", "§eYou have triggered a login alert!")
                plugin.config.setDefault("config.message.joined", "§bThe player {name} has triggered a login alert!")
                plugin.config.setDefault("config.message.offlined", "§bThe player {name} joined the server at {date}")
                plugin.config.save()
                plugin.print("Enabled version "..plugin.version.." successfully")
            end
        )
        
        events.add("playerJoin",
            function(event)
                local player = event:getPlayer()
                local uuid = player:getUniqueId():toString()
                if plugin.config.get("alerts."..uuid..".track") == true then
                    plugin.config.set("alerts."..uuid..".join", os.date("%A %d %B %Y - %I:%M:%S %p"))
                    plugin.config.save()
                    server:broadcast("§c"..player:getName().." is being tracked", plugin.config.get("config.permission"))
                end
            end
        )
        
        events.add("playerQuit",
            function(event)
                local uuid = event:getPlayer():getUniqueId():toString()
                if plugin.config.get("alerts."..uuid..".track") == true then
                    plugin.config.set("alerts."..uuid..".quit", os.date("%A %d %B %Y - %I:%M:%S %p"))
                    plugin.config.set("alerts."..uuid..".track", false)
                    plugin.config.save()
                    local message = "Alert: The user {name} was on from: {join}, to: {quit}"
                    message = string.gsub(message, "{name}", event:getPlayer():getName())
                    message = string.gsub(message, "{join}", plugin.config.get("alerts."..uuid..".join") )
                    message = string.gsub(message, "{quit}", plugin.config.get("alerts."..uuid..".quit") )
                    server:dispatchCommand( server:getConsoleSender(), "essentials:mail send Lord_Cuddles "..message)
                end
            end
        )
        
        plugin.addCommand("alert", "Start or cancel a session alert for a player", "/alert {name} {type}",
            function(sender, args)
                if sender:hasPermission(plugin.config.get("config.permission")) == true then
                    if args[1] then
                        local offline = server:getOfflinePlayer(args[1])
                        if offline:isOnline() or offline:hasPlayedBefore() then
                            local uuid = offline:getUniqueId():toString()
                            if plugin.config.get("alerts."..uuid..".track") == true then
                                plugin.config.clear("alerts."..uuid )
                                plugin.config.save()
                                sender:sendMessage("§cYou cancelled tracking for "..args[1])
                            else
                                plugin.config.set("alerts."..uuid..".track", true)
                                plugin.config.save()
                                sender:sendMessage("§cNow tracking "..args[1])
                            end
                        else
                            sender:sendMessage("§cThis player has never played before")
                        end
                    else
                        sender:sendMessage("§c/alert {username} - Toggles alerts for the username")
                    end
                else
                    sender:sendMessage("§cYou do not have permission to do that")
                end
            end
        )
        
    end
)
