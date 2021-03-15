local AGS = AwesomeGuildStore

AGS.internal.InitializeAugmentedMails = function(saveData)
	if(not saveData.augementMails) then return end
	local RegisterForEvent = AGS.internal.RegisterForEvent
	local WrapFunction = AGS.internal.WrapFunction
	local gettext = AGS.internal.gettext

	local iconMarkup = string.format("|t%u:%u:%s|t", 16, 16, "EsoUI/Art/currency/currency_gold.dds")
	local positiveColor = ZO_ColorDef:New("00FF00")
	local negativeColor = ZO_ColorDef:New("FF0000")
	local neutralColor = ZO_ColorDef:New("FFFFFF")

	local nextId = 1
	local hasData = false
	local currentMailTime = 0
	local guildHistory = AGS.class.GuildHistoryHelper:New()
	local transactionDataByMailIdString = {}
	local button

	local playerName = GetDisplayName()

    -- TRANSLATORS: this is used to find guild store sell mails. it has to be exactly the same as the subject of the ingame mails, otherwise the detection will fail
    local ITEM_SOLD_SUBJECT = gettext("Item Sold")
	local function IsGuildStoreMail(dataTable)
		return dataTable.fromSystem and dataTable.subject == ITEM_SOLD_SUBJECT
	end

	local function GetTransaction(secsSinceReceived, attachedMoney)
		local id, eventType, secsSinceEvent, sellerName, buyerName, itemCount, itemLink, sellPrice, tax, listingFee, houseCut, profit
		local potentialEvents = {}
		for i = 1, GetNumGuilds() do
			id = GetGuildId(i)
			for j = 1, guildHistory:GetNumPurchaseEvents(id) do
				eventType, secsSinceEvent, sellerName, buyerName, itemCount, itemLink, sellPrice, tax = guildHistory:GetPurchaseEvent(id, j)
				if(sellerName == playerName and math.abs(secsSinceEvent - secsSinceReceived) < 2) then
					listingFee, houseCut, profit = GetTradingHousePostPriceInfo(sellPrice)
					if (attachedMoney == 0 or attachedMoney == profit + listingFee) then
						potentialEvents[#potentialEvents + 1] = {
							guildId = id,
							guildName = GetGuildName(id),
							secsSinceEvent = secsSinceEvent,
							buyerName = buyerName,
							itemCount = itemCount,
							itemLink = itemLink,
							sellPrice = sellPrice,
							tax = tax,
							houseCut = houseCut,
							listingFee = listingFee,
							profit = profit
						}
					end
				end
			end
		end

		table.sort(potentialEvents, function(a, b)
			return a.secsSinceEvent < b.secsSinceEvent
		end)

		return potentialEvents[1]
	end

	local function GetTransactionDataForMail(dataTable)
		local mailIdString = Id64ToString(dataTable.mailId)
		if(not transactionDataByMailIdString[mailIdString]) then
			transactionDataByMailIdString[mailIdString] = GetTransaction(dataTable.secsSinceReceived, dataTable.attachedMoney)
		end
		return transactionDataByMailIdString[mailIdString]
	end

	local function SetValue(line, value)
		local valueControl, sign = line.value, line.sign
		if(sign == "+" and value ~= 0) then
			valueControl:SetColor(positiveColor:UnpackRGBA())
		elseif(sign == "-" and value ~= 0) then
			valueControl:SetColor(negativeColor:UnpackRGBA())
		else
			valueControl:SetColor(neutralColor:UnpackRGBA())
			sign = ""
		end
		valueControl:SetText(zo_strformat("<<3>><<1>> <<2>>", ZO_CurrencyControl_FormatCurrency(value), iconMarkup, sign or ""))
	end

	local function CreateLineContainer(container, height)
		local name = container:GetName() .. "Line" .. nextId
		local offset = (nextId == 1 and 0 or height)
		nextId = nextId + 1

		local line = container:CreateControl(name, CT_CONTROL)
		line:SetAnchor(TOPLEFT, container.previousLine, TOPLEFT, 0, offset)
		line:SetAnchor(TOPRIGHT, container.previousLine, TOPRIGHT, 0, offset)
		line:SetHeight(height)
		container.previousLine = line
		return line
	end

	local function CreateLine(container, label, sign)
		local line = CreateLineContainer(container, 20)
		local name = line:GetName()

		local labelControl = line:CreateControl(name .. "Label", CT_LABEL)
		labelControl:SetFont("ZoFontWinH4")
		labelControl:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
		labelControl:SetAnchor(TOPLEFT, line, TOPLEFT, 0, 0)
		labelControl:SetText(zo_strformat("<<1>>:", label))

		local valueControl = line:CreateControl(name .. "Value", CT_LABEL)
		valueControl:SetFont("ZoFontWinH4")
		valueControl:SetColor(neutralColor:UnpackRGBA())
		valueControl:SetAnchor(TOPRIGHT, line, TOPRIGHT, 0, 0)
		line.sign = sign
		line.value = valueControl

		line.SetValue = SetValue
		return line
	end

	local function CreateDivider(container)
		local line = CreateLineContainer(container, 8)
		local name = line:GetName() .. "Divider"
		local divider = line:CreateControl(name, CT_LINE)
		divider:SetTexture("EsoUI/Art/AvA/AvA_transitLine.dds")
		divider:SetAnchor(TOPLEFT, line, LEFT, 0, 14)
		divider:SetAnchor(BOTTOMRIGHT, line, RIGHT, 0, 14)
		divider:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
	end

	local function CreateInvoiceControl()
		local container = ZO_MailInboxMessagePaneScrollChild:CreateControl("AwesomeGuildStoreMailSaleInvoiceContainer", CT_CONTROL)
		container:SetAnchor(TOPLEFT, ZO_MailInboxMessageBody, BOTTOMLEFT, 50, 30)
		container:SetAnchor(TOPRIGHT, ZO_MailInboxMessageBody, BOTTOMRIGHT, -50, 30)
		container:SetHidden(true)
		container.previousLine = container

		container.sellValue = CreateLine(container, GetString(SI_TRADING_HOUSE_POSTING_PRICE_TOTAL):gsub(":", ""))
		CreateDivider(container)
		container.listingFee = CreateLine(container, GetString(SI_TRADING_HOUSE_POSTING_LISTING_FEE), "-")
		container.guildBank = CreateLine(container, GetString(SI_TRADING_HOUSE_POSTING_TH_CUT), "-")
		-- TRANSLATORS: label for the commission line in the guild store sell mail invoice
		container.commission = CreateLine(container, gettext("Commission"), "-")
		CreateDivider(container)
		container.profit = CreateLine(container, GetString(SI_TRADING_HOUSE_POSTING_PROFIT))
        -- TRANSLATORS: suffix for the refunded listing fee line in the guild store sell mail invoice. The other part of the string is taken from the ingame translation. The result is something like "Listing Fee (refund)"
		container.listingFeeRefund = CreateLine(container, GetString(SI_TRADING_HOUSE_POSTING_LISTING_FEE) .. gettext(" (refund)"), "+")
		CreateDivider(container)
		container.received = CreateLine(container, GetString(SI_MAIL_READ_SENT_GOLD_LABEL):gsub(":", ""))

		return container
	end

	RegisterForEvent(EVENT_GUILD_HISTORY_CATEGORY_UPDATED, function(_, guildId, category)
		if(category == GUILD_HISTORY_STORE and type(MAIL_INBOX.mailId) == "number" and not hasData) then
			local mailId = MAIL_INBOX.mailId
			local mailData = MAIL_INBOX:GetMailData(mailId)
			if(mailData and mailData.fromStore) then
				local messageControl = MAIL_INBOX.messageControl
				ZO_MailInboxShared_PopulateMailData(mailData, mailId)
				ZO_MailInboxShared_UpdateInbox(mailData, GetControl(messageControl, "From"), GetControl(messageControl, "Subject"), GetControl(messageControl, "Expires"), GetControl(messageControl, "Received"), GetControl(messageControl, "Body"))
			end
		end
	end)

	local function CreateDataRequestButton()
		local button = CreateControlFromVirtual("AwesomeGuildStoreMailSaleRequestDataButton", ZO_MailInboxMessagePaneScrollChild, "ZO_DefaultButton")
		button:SetAnchor(TOP, ZO_MailInboxMessageBody, BOTTOM, 0, 30)
        -- TRANSLATORS: label for the load details button in guild store sell mails where the invoice can not be shown due to lack of data
		button:SetText(gettext("Load Details"))
		button:SetWidth(200)
		button:SetHandler("OnMouseUp",function(control, button, isInside)
			if(control:GetState() == BSTATE_NORMAL and button == 1 and isInside) then
				if(not guildHistory:RequestData(currentMailTime)) then
					control:SetHidden(true)
				end
			end
		end)
		button:SetHidden(true)
		return button
	end

	local invoice = CreateInvoiceControl()
	button = CreateDataRequestButton()

	WrapFunction("ZO_MailInboxShared_PopulateMailData", function(originalPopulateMailData, dataTable, mailId)
		originalPopulateMailData(dataTable, mailId)
		if(IsGuildStoreMail(dataTable)) then
			dataTable.fromStore = true
			local transactionData = GetTransactionDataForMail(dataTable)
			if(transactionData) then
				dataTable.senderDisplayName = transactionData.guildName
				dataTable.eventData = transactionData
			end
		end
	end)

	WrapFunction("ZO_MailInboxShared_UpdateInbox", function(originalUpdateInbox, mailData, fromControl, subjectControl, expiresControl, recievedControl, bodyControl)
		originalUpdateInbox(mailData, fromControl, subjectControl, expiresControl, recievedControl, bodyControl)

		if(mailData.fromStore) then
			currentMailTime = ZO_NormalizeSecondsSince(mailData.secsSinceReceived)
			if(mailData.eventData) then
				hasData = true
				local saleData = mailData.eventData
				invoice.sellValue:SetValue(saleData.sellPrice)
				invoice.listingFee:SetValue(saleData.listingFee)
				invoice.guildBank:SetValue(saleData.tax)
				invoice.commission:SetValue(saleData.houseCut - saleData.tax)
				invoice.profit:SetValue(saleData.profit)
				invoice.listingFeeRefund:SetValue(saleData.listingFee)
				invoice.received:SetValue(saleData.profit + saleData.listingFee)
				button:SetHidden(true)
				invoice:SetHidden(not saveData.mailAugmentationShowInvoice)
			else
				hasData = false
				button:SetHidden(false)
				invoice:SetHidden(true)
			end
		else
			button:SetHidden(true)
			invoice:SetHidden(true)
		end
	end)

	WrapFunction("ReadMail", function(originalReadMail, mailId)
		local mailIdString = mailId
		if(type(mailIdString) ~= "string") then
			mailIdString = Id64ToString(mailId)
		end
		local transactionData = transactionDataByMailIdString[mailIdString]
		if(transactionData) then
			local buyerLink = neutralColor:Colorize(ZO_LinkHandler_CreateDisplayNameLink(transactionData.buyerName)):gsub("[%[%]]", "")
			local itemCount = neutralColor:Colorize(transactionData.itemCount .. "x")
			local sellPrice = ZO_Currency_FormatPlatform(CURT_MONEY, transactionData.sellPrice, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
			-- TRANSLATORS: Mail body for item sold mails from the guild store. <<t:1>> is replaced by the itemlink, <<2>> by the item count, <<3>> by the buyer name and <<4>> by the sell price. e.g. You sold 1 Rosin to sirinsidiator for 5000g.  
			return gettext("You sold <<2>> <<t:1>> to <<3>> for <<4>>.", transactionData.itemLink, itemCount, buyerLink, sellPrice)
		else
			return originalReadMail(mailId)
		end
	end)
end
