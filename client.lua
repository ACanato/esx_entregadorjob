ESX = nil
local PlayerData = {}
local blipEntrega = nil
local mostrarMarker = false
local currentDelivery = 1
local vehicle = nil
local totalEntregas = 0
local holdingBox = false
local boxEntity = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()

    if PlayerData.job ~= nil and PlayerData.job.name == 'entregador' then
        adicionarBlip()
        mostrarMarker = true
    else
        mostrarMarker = false
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        pegarCaixa()
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
    if job.name == 'entregador' then
        adicionarBlip()
        mostrarMarker = true
    else
        removerBlip()
        mostrarMarker = false
    end
end)

function adicionarBlip()
    if not blipEntrega then
        local pos = Config.Positions.JobStart
        blipEntrega = AddBlipForCoord(pos.x, pos.y, pos.z)
        SetBlipSprite(blipEntrega, Config.Blip.Sprite)
        SetBlipDisplay(blipEntrega, Config.Blip.Display)
        SetBlipScale(blipEntrega, Config.Blip.Scale)
        SetBlipColour(blipEntrega, Config.Blip.Colour)
        SetBlipAsShortRange(blipEntrega, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.Name)
        EndTextCommandSetBlipName(blipEntrega)
    end
end

function removerBlip()
    if blipEntrega then
        RemoveBlip(blipEntrega)
        blipEntrega = nil
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if mostrarMarker then
            local pos = Config.Positions.JobStart
            local coords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - vector3(pos.x, pos.y, pos.z))
            if dist < Config.Marker.DrawDistance then
                DrawMarker(Config.Marker.Type, pos.x, pos.y, pos.z - 1.0, 0, 0, 0, 0, 0, 0, Config.Marker.Size.x, Config.Marker.Size.y, Config.Marker.Size.z, Config.Marker.Colour.r, Config.Marker.Colour.g, Config.Marker.Colour.b, Config.Marker.Colour.a, false, true, 2, nil, nil, false)
                if dist < Config.Marker.InteractionDistance then
                    ESX.ShowHelpNotification('Pressiona ~INPUT_CONTEXT~ para aceder ao menu')
                    if IsControlJustReleased(0, 38) then
                        abrirMenuTrabalho()
                    end
                end
            end
        end
    end
end)

function abrirMenuTrabalho()
    local elements = {
        {label = 'Retirar Veículo', value = 'get_vehicle'}
    }

    ESX.UI.Menu.CloseAll() 

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'entregador_menu', {
        title    = 'Menu de Entrega',
        align    = 'left',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'get_vehicle' then
            menu.close()
            spawnarVeiculoEntrega()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function spawnarVeiculoEntrega()
    local vehicleModel = 'boxville2'
    local pos = Config.Positions.VehicleSpawn

    ESX.Game.SpawnVehicle(vehicleModel, vector3(pos.x, pos.y, pos.z), pos.heading, function(spawnedVehicle)
        vehicle = spawnedVehicle
        TaskWarpPedIntoVehicle(PlayerPedId(), spawnedVehicle, -1)
        iniciarEntrega()
    end)
end

function iniciarEntrega()
    atualizarProximaEntrega()
end

function atualizarProximaEntrega()
    if currentDelivery <= #Config.DeliveryPoints then
        local deliveryPoint = Config.DeliveryPoints[currentDelivery]
        
        local deliveryBlip = AddBlipForCoord(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z)
        SetBlipSprite(deliveryBlip, 1)
        SetBlipColour(deliveryBlip, 5)
        SetBlipRoute(deliveryBlip, true)

        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                local coords = GetEntityCoords(PlayerPedId())
                local dist = #(coords - vector3(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z))
                if dist < Config.Marker.DrawDistance then
                    DrawMarker(Config.Marker.Type, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z - 1.0, 0, 0, 0, 0, 0, 0, Config.Marker.Size.x, Config.Marker.Size.y, Config.Marker.Size.z, Config.Marker.Colour.r, Config.Marker.Colour.g, Config.Marker.Colour.b, Config.Marker.Colour.a, false, true, 2, nil, nil, false)
                    if dist < Config.Marker.InteractionDistance then
                        ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para entregar a encomenda")
                        if IsControlJustReleased(0, 38) then
                            completarEntrega(deliveryBlip)
                            return
                        end
                    end
                end
            end
        end)
    else
        ESX.ShowNotification("Todas as entregas foram concluídas! Devolve o veículo para receberes o dinheiro.")
        criarPontoDeRetorno()
    end
end

function completarEntrega(deliveryBlip)
    RemoveBlip(deliveryBlip)

    if holdingBox then
        DeleteObject(boxEntity)
        holdingBox = false

        ClearPedTasks(PlayerPedId())

        ESX.ShowNotification("Caixa Entregue!")
    end

    totalEntregas = totalEntregas + 1
    currentDelivery = currentDelivery + 1
    atualizarProximaEntrega()
end

function criarPontoDeRetorno()
    local returnBlip = AddBlipForCoord(Config.Positions.VehicleReturn.x, Config.Positions.VehicleReturn.y, Config.Positions.VehicleReturn.z)
    SetBlipSprite(returnBlip, 1)
    SetBlipColour(returnBlip, 5)
    SetBlipRoute(returnBlip, true)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local coords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - vector3(Config.Positions.VehicleReturn.x, Config.Positions.VehicleReturn.y, Config.Positions.VehicleReturn.z))
            if dist < Config.Marker.DrawDistance then
                DrawMarker(Config.Marker.Type, Config.Positions.VehicleReturn.x, Config.Positions.VehicleReturn.y, Config.Positions.VehicleReturn.z - 1.0, 0, 0, 0, 0, 0, 0, Config.Marker.Size.x, Config.Marker.Size.y, Config.Marker.Size.z, Config.Marker.Colour.r, Config.Marker.Colour.g, Config.Marker.Colour.b, Config.Marker.Colour.a, false, true, 2, nil, nil, false)
                if dist < Config.Marker.InteractionDistance then
                    ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para devolver o veículo e encerrar o turno")
                    if IsControlJustReleased(0, 38) then
                        devolverVeiculo(returnBlip)
                        return
                    end
                end
            end
        end
    end)
end

function devolverVeiculo(returnBlip)
    RemoveBlip(returnBlip)

    if vehicle then
        ESX.Game.DeleteVehicle(vehicle)
        vehicle = nil
    end

    if totalEntregas > 0 then
        local premio = totalEntregas * Config.PaymentPerDelivery
        TriggerServerEvent('entregador:receberPagamento', premio)
        ESX.ShowNotification("Devolves-te o veículo e recebes-te " .. premio .. "€ pelas entregas.")
        totalEntregas = 0
    else
        ESX.ShowNotification("Nenhuma entrega foi feita, nenhum pagamento recebido.")
    end

    currentDelivery = 1
end

function pegarCaixa()
    if not holdingBox then
        local coords = GetEntityCoords(PlayerPedId())
        local trunkCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.2, 0.5)
        local dist = #(coords - trunkCoords)
        if dist < 2.0 then
            DrawText3D(trunkCoords.x, trunkCoords.y, trunkCoords.z, "Pressiona [E] para retirar a caixa")
            if IsControlJustReleased(0, 38) then
                RequestModel(GetHashKey("prop_cs_cardbox_01"))
                while not HasModelLoaded(GetHashKey("prop_cs_cardbox_01")) do
                    Citizen.Wait(1)
                end

                boxEntity = CreateObject(GetHashKey("prop_cs_cardbox_01"), coords.x, coords.y, coords.z, true, true, true)
                AttachEntityToEntity(boxEntity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, -0.15, -0.3, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

                TriggerEvent('playCarryBoxAnimation')
                holdingBox = true
            end
        end
    end
end

RegisterNetEvent('playCarryBoxAnimation')
AddEventHandler('playCarryBoxAnimation', function()
    local playerPed = PlayerPedId()
    local animDict = "anim@heists@box_carry@"

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end

    TaskPlayAnim(playerPed, animDict, "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
end)

function atualizarProximaEntrega()
    if currentDelivery <= #Config.DeliveryPoints then
        local deliveryPoint = Config.DeliveryPoints[currentDelivery]
        
        local deliveryBlip = AddBlipForCoord(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z)
        SetBlipSprite(deliveryBlip, 1)
        SetBlipColour(deliveryBlip, 5)
        SetBlipRoute(deliveryBlip, true)

        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                local coords = GetEntityCoords(PlayerPedId())
                local dist = #(coords - vector3(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z))
                if dist < Config.Marker.DrawDistance then
                    DrawMarker(Config.Marker.Type, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z - 1.0, 0, 0, 0, 0, 0, 0, Config.Marker.Size.x, Config.Marker.Size.y, Config.Marker.Size.z, Config.Marker.Colour.r, Config.Marker.Colour.g, Config.Marker.Colour.b, Config.Marker.Colour.a, false, true, 2, nil, nil, false)
                    
                    if dist < Config.Marker.InteractionDistance then
                        if holdingBox then
                            ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para entregar a encomenda")                    
                            if IsControlJustReleased(0, 38) then
                                DeleteObject(boxEntity)
                                completarEntrega(deliveryBlip)
                                return
                            end
                        else
                            ESX.ShowNotification("Vai buscar a caixa á carrinha!")
                        end
                    end
                end
            end
        end)
    else
        ESX.ShowNotification("Todas as entregas foram concluídas! Devolve o veículo para receberes o dinheiro.")
        criarPontoDeRetorno()
    end
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end