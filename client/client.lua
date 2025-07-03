local VORPcore = exports.vorp_core:GetCore()
local FeatherMenu =  exports['feather-menu'].initiate()
local BccUtils = exports['bcc-utils'].initiate()

local YacaStatus = nil
local ImAdmin = false

RegisterNetEvent('mms-yacablock:client:ReciveUserGroup',function(Group)
    if Config.IgnoreAdmins then
        for h,v in ipairs(Config.AdminGroups) do
            if v.AdminGroup == Group then
                ImAdmin = true
                print('ImAdmin')
            end
        end
    end
end)
---------------------------------------------------------------------------------------------------------
--------------------------------------------- Main Menu -------------------------------------------------
---------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function ()
    YacaBlockMenu = FeatherMenu:RegisterMenu('YacaBlockMenu', {
        top = '13%',
        left = '11%',
        ['720width'] = '1000px',
        ['1080width'] = '1500px',
        ['2kwidth'] = '2400px',
        ['4kwidth'] = '4400px',
        style = {
            ['border'] = '5px solid orange',
            ['background-color'] = '#FF8C00'
        },
        contentslot = {
            style = {
                ['height'] = '800px',
                ['min-height'] = '800px'
            }
        },
        draggable = true,
        canclose = false
}, {
    opened = function()
        --print("MENU OPENED!")
    end,
    closed = function()
        --print("MENU CLOSED!")
    end,
    topage = function(data)
        --print("PAGE CHANGED ", data.pageid)
    end
})
YacaBlockMenuPage1 = YacaBlockMenu:RegisterPage('seite1')
    YacaBlockMenuPage1:RegisterElement('line', {
        slot = 'header',
        style = {
        ['color'] = 'orange',
        }
    })
    YacaBlockMenuPage1:RegisterElement("html", {
        slot = 'content',
        value = {
            [[
                <img width="1400px" height="800px" style="margin: 0 auto;" src="]] .. Config.PictureLink .. [[" />
            ]]
       }
    })
    YacaBlockMenuPage1:RegisterElement('line', {
        slot = 'footer',
        style = {
        ['color'] = 'orange',
        }
    })
end)


function CheckYacaStatus()
    while true do
        Citizen.Wait(Config.CheckTime * 1000)
        YacaStatus = exports['yaca-voice']:getPluginState()
        if YacaStatus ~= 'IN_INGAME_CHANNEL' and Config.KickAfterXMin == true then
            TriggerEvent('mms-yacablock:client:KickAfterXMin')

        elseif YacaStatus ~= 'IN_INGAME_CHANNEL' then -- Without Kick Function
            if Config.UsePicture then
                YacaBlockMenu:Open({
                    startupPage = YacaBlockMenuPage1,
                })
            elseif Config.BlockScreen then
                AnimpostfxPlay('skytl_0000_01clear')
                VORPcore.NotifyTip(Config.JoinYaca, 5000)
            end
        elseif YacaStatus == 2 then
            if Config.UsePicture then
                YacaBlockMenu:Close({})
            else
                AnimpostfxStop('skytl_0000_01clear')
            end
        end
        
        
        -- Just Prints
        if Config.PrintYacaStatus == true then
            if YacaStatus == 'NOT_CONNECTED' then 
                print('Yaca Not Connected')
            elseif YacaStatus == 'CONNECTED' then
                print('Yaca Connected but not Moved')
            elseif YacaStatus == 'IN_INGAME_CHANNEL' then
                print('Yaca Connected and Sucessfully Moved to Ingame Channel')
            elseif YacaStatus == 'IN_EXCLUDED_CHANNEL' then
                print('Yaca Connected but in Swiss Channel')
            end
        end

    end
end

RegisterNetEvent('mms-yacablock:client:KickAfterXMin',function ()
    local counter = Config.KickTime * 60
    while YacaStatus ~= 'IN_INGAME_CHANNEL' do
        YacaStatus = exports['yaca-voice']:getPluginState()
        if Config.UsePicture then
            YacaBlockMenu:Open({
                startupPage = YacaBlockMenuPage1,
            })
            VORPcore.NotifyTip(counter .. Config.CountDownText, 5000)
            Citizen.Wait(5000)
            counter = counter -5
        elseif Config.BlockScreen then
            AnimpostfxPlay('skytl_0000_01clear')
            VORPcore.NotifyTip(counter .. Config.CountDownText, 5000)
            Citizen.Wait(5000)
            counter = counter -5
        end
        
        -- Back to YacaStatus Check
        if YacaStatus == 'IN_INGAME_CHANNEL' then
            CheckYacaStatus()
        end

        -- Drop Player is Counter = 0
        if counter <= 0 then
            TriggerServerEvent('mms-yacablock:server:dropplayer')
        end
    end
end)


RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    Citizen.Wait(Config.InitialWaitTime * 1000)
    TriggerServerEvent('mms-yacablock:server:GetPlayerGourp')
    Citizen.Wait(10000)
    if not ImAdmin then
        CheckYacaStatus()
    end
end)


if Config.Debug then
    Citizen.CreateThread(function()
    Citizen.Wait(Config.InitialWaitTime * 1000)
    TriggerServerEvent('mms-yacablock:server:GetPlayerGourp')
    Citizen.Wait(10000)
    if not ImAdmin then
        CheckYacaStatus()
    end
end)
end


AddEventHandler("vorp_core:Client:OnPlayerDeath",function(killerserverid,causeofdeath)
    if not ImAdmin and Config.BlockDeathCom then
        TriggerServerEvent('mms-yacablock:server:PlayerDead')
        Citizen.Wait(5000)
        VORPcore.NotifyDead(Config.YouAreDead,nil,nil,10000)
    end
end)

RegisterNetEvent("vorp_core:Client:OnPlayerRevive",function()
    if not ImAdmin and Config.BlockDeathCom then
        TriggerServerEvent('mms-yacablock:server:PlayerAlive')
    end
end)

RegisterNetEvent("vorp_core:Client:OnPlayerRespawn",function()
    if not ImAdmin and Config.BlockDeathCom then
        TriggerServerEvent('mms-yacablock:server:PlayerAlive')
    end
end)

RegisterNetEvent('yaca:external:voiceRangeUpdate')
AddEventHandler('yaca:external:voiceRangeUpdate', function(VoiceRange)
    if Config.UseYacaCircle then
        Range = tonumber(VoiceRange)
        local myPos = GetEntityCoords(PlayerPedId())
        DrawIt(Range,myPos)
        Citizen.Wait(250)
    end
end)

function DrawIt(Range,myPos)
    local Counter = 0
    while Counter < Config.DrawTime do
        if Config.Show3dText then
            BccUtils.Misc.DrawText3D(myPos.x, myPos.y, myPos.z, Config.TextDrawn .. Range)
        end
        Citizen.Wait(3)
        DrawMarker(Config.MarkerType, myPos.x, myPos.y, myPos.z - 0.7, 0, 0, 0, 0, 0,0, Range * 2, Range * 2, 0.80, Config.Red, Config.Green, Config.Blue, Config.Alpha, 0, 0, 0)
        Counter = Counter + 14
    end
end