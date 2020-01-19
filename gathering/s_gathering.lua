local _ = function(k, ...) return ImportPackage("i18n").t(GetPackageName(), k, ...) end

gatherTable = {
    {-- LUMBERJACK STUFF
        gather_zone = {x = -107330, y = -95820, z = 5231}, -- Zone of initial gathering
        gather_item = "tree_log", -- item that is given by initial gathering
        gather_time = 10, -- Time in seconds to gather one item
        process_steps = {-- Describe the steps of processing
            {
                step_zone = {x = 0, y = 0, z = 0}, -- zone of processing
                step_require = "tree_log", -- item that is required (take the one from previous step)
                step_require_number = 1, -- number of item required
                step_processed_item = "wood_plank", -- item that will be given
                step_processed_item_number = 2, -- number of item that will be given
                step_process_time = 20, -- Time in seconds to process one item
                step_animation = "COMBINE", -- Animation for processing
                step_animation_attachement = nil
            },
            {
                step_zone = {x = 0, y = 0, z = 0},
                step_require = "wood_plank",
                step_require_number = 1,
                step_processed_item = "treated_wood_plank",
                step_processed_item_number = 1,
                step_process_time = 10,
                step_animation = "COMBINE",
                step_animation_attachement = nil
            }
        },
        require_job = "lumberjack", -- Job required,
        require_tool = "lumberjack_axe", -- Tool required in inventory,
        require_knowledge = false, -- Require knowledge (for processing illegal stuff → drugdealer, cocaine)
        gather_animation = "PICKAXE_SWING", -- Animation that the player will act when doing stuff
        gather_animation_attachement = {modelid = 1047, bone = "hand_r"},
        gather_rp_props = nil
    },
    {-- PEACH HARVESTION (FOR ALTIS LIFE FANS)
        gather_zone = {x = -174432, y = 10837, z = 1831},
        gather_item = "peach",
        gather_animation = "PICKUP_UPPER",
        gather_rp_props = {
            -- Peach trees
            {model = 145, x = -174006, y = 10457, z = 1773, rx = 0, ry = 10, rz = 0},
            {model = 145, x = -173829, y = 10894, z = 1743, rx = 0, ry = 30, rz = 0},
            {model = 145, x = -173980, y = 11396, z = 1698, rx = 0, ry = 45, rz = 0},
            {model = 145, x = -174691, y = 11532, z = 1709, rx = 0, ry = 0, rz = 0},
            {model = 145, x = -175204, y = 11094, z = 1755, rx = 0, ry = 145, rz = 0},
            {model = 145, x = -175449, y = 11528, z = 1757, rx = 0, ry = 80, rz = 0},
            {model = 145, x = -175171, y = 12038, z = 1719, rx = 0, ry = 50, rz = 0},
            {model = 145, x = -174581, y = 12021, z = 1686, rx = 0, ry = 40, rz = 0},
        }
    }
}

gatherPickupsCached = {}
processPickupsCached = {}

local defaultAnimation = "PICKUP_LOWER"

AddEvent("OnPackageStart", function()-- Initialize pickups and objects
    for k, v in pairs(gatherTable) do
        if v.gather_zone ~= nil then -- Create pickups for gathering zones
            v.gatherPickup = CreatePickup(2, v.gather_zone.x, v.gather_zone.y, v.gather_zone.z)
            CreateText3D(_("gather") .. "\n" .. _("press_e"), 18, v.gather_zone.x, v.gather_zone.y, v.gather_zone.z + 120, 0, 0, 0)
            table.insert(gatherPickupsCached, v.gatherPickup)
        end
        
        if v.process_steps ~= nil then -- Create pickups for processing zones
            for k2, v2 in pairs(v.process_steps) do -- each processing steps
                v2.processPickup = CreatePickup(2, v2.step_zone.x, v2.step_zone.y, v2.step_zone.z)
                CreateText3D(_("process") .. "\n" .. _("press_e"), 18, v2.step_zone.x, v2.step_zone.y, v2.step_zone.z + 120, 0, 0, 0)
                table.insert(processPickupsCached, v2.processPickup)
            end
        end
        
        if v.gather_rp_props ~= nil then -- Create RP objects
            for k2, v2 in pairs(v.gather_rp_props) do
                if v2.ry ~= nil then
                    CreateObject(v2.model, v2.x, v2.y, v2.z, v2.rx, v2.ry, v2.rx)
                else
                    CreateObject(v2.model, v2.x, v2.y, v2.z)
                end
            end
        end
    end
end)

AddEvent("OnPlayerJoin", function(player)-- Cache props and pickups client side
    CallRemoteEvent(player, "gathering:setup", gatherPickupsCached, processPickupsCached)
end)

AddEvent("OnPlayerDeath", function(player)
    PlayerData[player].onAction = false
    PlayerData[player].isActioned = false
end)

AddRemoteEvent("gathering:gather:start", function(player, gatherPickup)-- Start the gathering
    local gather = GetGatherByGatherPickup(gatherPickup)
    if gatherTable[gather] == nil then return end -- fail check
    
    if PlayerData[player].onAction == true then -- Stop gathering
        PlayerData[player].onAction = false
        StopGathering(player, gather)
        CallRemoteEvent(player, "MakeNotification", _("gather_cancelled"), "linear-gradient(to right, #ff5f6d, #ffc371)")
        return
    end
    
    -- #1 Check for jobs
    if gatherTable[gather].require_job ~= nil and gatherTable[gather].require_job ~= PlayerData[player].job then
        CallRemoteEvent(player, "MakeNotification", _("wrong_job", _(gatherTable[gather].require_job)), "linear-gradient(to right, #ff5f6d, #ffc371)")
        return
    end
    
    -- #2 Check for tools
    if gatherTable[gather].require_tool ~= nil and PlayerData[player].inventory[gatherTable[gather].require_tool] == nil then
        CallRemoteEvent(player, "MakeNotification", _("need_tool2", _(gatherTable[gather].require_tool)), "linear-gradient(to right, #ff5f6d, #ffc371)")
        return
    end
    
    -- #3 Attach tool if any
    if gatherTable[gather].gather_animation_attachement ~= nil then
        SetAttachedItem(player, gatherTable[gather].gather_animation_attachement.bone, gatherTable[gather].gather_animation_attachement.modelid)
    end
    
    PlayerData[player].onAction = true
    DoGathering(player, gather)
end)

function DoGathering(player, gather)
    -- #4 Lock and prepare player
    CallRemoteEvent(player, "LockControlMove", true)
    PlayerData[player].isActioned = true
    PlayerData[player].onAction = true
    
    -- #5 Start animation and loop
    SetPlayerAnimation(player, gatherTable[gather].gather_animation or defaultAnimation)
    if PlayerData[player].timerGathering ~= nil then DestroyTimer(PlayerData[player].timerGathering) end
    PlayerData[player].timerGathering = CreateTimer(function(player, anim)-- for anim loop
        SetPlayerAnimation(player, anim)
    end, 4000, player, gatherTable[gather].gather_animation or defaultAnimation)
    
    -- #6 Display loading bar
    CallRemoteEvent(player, "loadingbar:show", _("gather") .. " " .. _(gatherTable[gather].gather_item), gatherTable[gather].gather_time)-- LOADING BAR
    
    -- #7 When job is done, add to inventory and loop
    Delay(gatherTable[gather].gather_time * 1000, function()
        if PlayerData[player].isActioned and PlayerData[player].onAction then -- Check if the player didnt canceled the job
            if AddInventory(player, gatherTable[gather].gather_item, 1) == true then
                CallRemoteEvent(player, "MakeNotification", _("gather_success", _(gatherTable[gather].gather_item)), "linear-gradient(to right, #00b09b, #96c93d)")
                DoGathering(player, gather)
            else
                CallRemoteEvent(player, "MakeNotification", _("inventory_notenoughspace"), "linear-gradient(to right, #ff5f6d, #ffc371)")
                StopGathering(player, gather)
            end
        end
    end)
end

function StopGathering(player, gather)
    PlayerData[player].isActioned = false
    DestroyTimer(PlayerData[player].timerGathering)-- for anim loop
    PlayerData[player].timerGathering = nil
    SetPlayerAnimation(player, "STOP")
    CallRemoteEvent(player, "LockControlMove", false)
    SetAttachedItem(player, gatherTable[gather].gather_animation_attachement.bone, 0)
    -- TODO : stop loading bar
end

-- tools
function GetGatherByGatherPickup(gatherPickup)
    for k, v in pairs(gatherTable) do
        if v.gatherPickup == gatherPickup then
            return k
        end
    end
end

-- function GetGatherByProcessPickup(processPickup)
--     for k, v in pairs(gatherTable) do
--         if v.processPickup == processPickup then
--             return k
--         end
--     end
-- end
-- DEV MODE
AddCommand("job", function(player, job)
    PlayerData[player].job = job
    AddPlayerChat(player, "Vous êtes maintenant un " .. _(job))
end)
