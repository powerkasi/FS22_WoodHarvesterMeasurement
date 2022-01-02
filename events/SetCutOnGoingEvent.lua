SetCutOnGoingEvent = {};
SetCutOnGoingEvent_mt = Class(SetCutOnGoingEvent, Event);

InitEventClass(SetCutOnGoingEvent, "SetCutOnGoingEvent");

---Create instance of Event class
-- @return table self instance of class event
function SetCutOnGoingEvent.emptyNew()
	local self = Event.new(SetCutOnGoingEvent_mt);
	return self;
end;

---Create new instance of event
-- @param table object object
-- @param bool cutOnGoing cut on going
function SetCutOnGoingEvent.new(object, cutOnGoing)
	local self = SetCutOnGoingEvent.emptyNew();
	self.object = object;
	self.cutOnGoing = cutOnGoing;
	return self;
end;

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCutOnGoingEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self.cutOnGoing = streamReadBool(streamId);
	self:run(connection);
end;

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCutOnGoingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
	streamWriteBool(streamId, self.cutOnGoing);
end;

---Run action on receiving side
-- @param integer connection connection
function SetCutOnGoingEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetCutOnGoingEvent.new(self.object, self.cutOnGoing), nil, connection, self.object);
	end;

	if self.object ~= nil and self.object:getIsSynchronized() then
    self.object:setCutOnGoing(self.cutOnGoing, true);
	end;
end;