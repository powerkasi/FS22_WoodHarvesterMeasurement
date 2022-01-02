SetCurrentDiameterEvent = {};
SetCurrentDiameterEvent_mt = Class(SetCurrentDiameterEvent, Event);

InitEventClass(SetCurrentDiameterEvent, "SetCurrentDiameterEvent");

---Create instance of Event class
-- @return table self instance of class event
function SetCurrentDiameterEvent.emptyNew()
	local self = Event.new(SetCurrentDiameterEvent_mt);
	return self;
end;

---Create new instance of event
-- @param table object object
-- @param float currentDiameter current diameter
function SetCurrentDiameterEvent.new(object, currentDiameter)
	local self = SetCurrentDiameterEvent.emptyNew();
	self.object = object;
	self.currentDiameter = currentDiameter;
	return self;
end;

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCurrentDiameterEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self.currentDiameter = streamReadFloat32(streamId);
	self:run(connection);
end;

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCurrentDiameterEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
	streamWriteFloat32(streamId, self.currentDiameter);
end;

---Run action on receiving side
-- @param integer connection connection
function SetCurrentDiameterEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetCurrentDiameterEvent.new(self.object, self.currentDiameter), nil, connection, self.object);
	end;

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setCurrentDiameter(self.currentDiameter, true);
	end;
end;