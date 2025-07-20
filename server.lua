ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('entregador:receberPagamento')
AddEventHandler('entregador:receberPagamento', function(valor)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.addAccountMoney('bank', valor)
    end
end)