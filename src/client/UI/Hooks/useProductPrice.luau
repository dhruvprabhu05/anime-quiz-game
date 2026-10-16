-- Looks up the current Robux price of a Developer Product or Game Pass, so buttons always
-- show what the player will actually pay. Returns nil until the price has loaded.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local function useProductPrice(id: number, infoType: Enum.InfoType): number?
	local price, setPrice = React.useState(nil :: number?)

	React.useEffect(function()
		local cancelled = false
		task.spawn(function()
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
			if ok and not cancelled and info then
				setPrice(info.PriceInRobux)
			end
		end)
		return function()
			cancelled = true
		end
	end, { id, infoType })

	return price
end

return useProductPrice
