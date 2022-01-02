SetCubicMetreTotalEvent = {};
SetCubicMetreTotalEvent_mt = Class(SetCubicMetreTotalEvent, Event);

InitEventClass(SetCubicMetreTotalEvent, "SetCubicMetreTotalEvent");

---Create instance of Event class
-- @return table self instance of class event
function SetCubicMetreTotalEvent.emptyNew()
	local self = Event.new(SetCubicMetreTotalEvent_mt);
	return self;
end;

---Create new instance of event
-- @param table object object
-- @param float cubicMetreTotal cubic metre total
function SetCubicMetreTotalEvent.new(object, cubicMetreTotal)
	local self = SetCubicMetreTotalEvent.emptyNew();
	self.object = object;
	self.cubicMetreTotal = cubicMetreTotal;
	return self;
end;

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCubicMetreTotalEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self.cubicMetreTotal = streamReadFloat32(streamId);
	self:run(connection);
end;

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCubicMetreTotalEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
	streamWriteFloat32(streamId, self.cubicMetreTotal);
end;

---Run action on receiving side
-- @param integer connection connection
function SetCubicMetreTotalEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetCubicMetreTotalEvent.new(self.object, self.cubicMetreTotal), nil, connection, self.object);
	end;

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setCubicMetreTotal(self.cubicMetreTotal, true);
	end;
end;
