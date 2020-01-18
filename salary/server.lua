local _ = function(k,...) return ImportPackage("i18n").t(GetPackageName(),k,...) end

local minutes = 1 -- TODO : DEV MODE
local minimumWage = 50
local medicAndCopsSalary = 150
local addMedicAndCopsSalaryToMinimumWage = true

CreateTimer(function()
    for key, player in pairs(GetAllPlayers()) do
        if PlayerData[player] then
            local salary = minimumWage
            if PlayerData[player].job == "police" or PlayerData[player].job == "medic" then
                if addMedicAndCopsSalaryToMinimumWage then
                    salary = salary + medicAndCopsSalary
                else
                    salary = medicAndCopsSalary
                end
            end
    
            PlayerData[player].bank_balance = PlayerData[player].bank_balance + salary
            CallRemoteEvent(player, "MakeSuccessNotification", _("salary_notification", _("price_in_currency", tostring(salary))))
        end
	end
end, minutes * 60000)