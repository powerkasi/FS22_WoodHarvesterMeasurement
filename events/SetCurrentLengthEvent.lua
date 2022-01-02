SetCurrentLengthEvent = {};
SetCurrentLengthEvent_mt = Class(SetCurrentLengthEvent, Event);

InitEventClass(SetCurrentLengthEvent, "SetCurrentLengthEvent");

---Create instance of Event class
-- @return table self instance of class event
function SetCurrentLengthEvent.emptyNew()
	local self = Event.new(SetCurrentLengthEvent_mt);
	return self;
end;

---Create new instance of event
-- @param table object object
-- @param float currentLength current length
function SetCurrentLengthEvent.new(object, currentLength)
	local self = SetCurrentLengthEvent.emptyNew();
	self.object = object;
	self.currentLength = currentLength;
	return self;
end;

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCurrentLengthEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self.currentLength = streamReadFloat32(streamId);
	self:run(connection);
end;

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCurrentLengthEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
	streamWriteFloat32(streamId, self.currentLength);
end;

---Run action on receiving side
-- @param integer connection connection
function SetCurrentLengthEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetCurrentLengthEvent.new(self.object, self.currentLength), nil, connection, self.object);
	end;

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setCurrentLength(self.currentLength, true);
	end;
end;