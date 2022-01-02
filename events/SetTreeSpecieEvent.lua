SetTreeSpecieEvent = {};
SetTreeSpecieEvent_mt = Class(SetTreeSpecieEvent, Event);

InitEventClass(SetTreeSpecieEvent, "SetTreeSpecieEvent");

---Create instance of Event class
-- @return table self instance of class event
function SetTreeSpecieEvent.emptyNew()
	local self = Event.new(SetTreeSpecieEvent_mt);
	return self;
end;

---Create new instance of event
-- @param table object object
-- @param float treeSpecie tree specie
function SetTreeSpecieEvent.new(object, treeSpecie)
	local self = SetTreeSpecieEvent.emptyNew();
	self.object = object;
	self.treeSpecie = treeSpecie;
	return self;
end;

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetTreeSpecieEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self.treeSpecie = streamReadInt32(streamId);
	self:run(connection);
end;

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetTreeSpecieEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
	streamWriteInt32(streamId, self.treeSpecie);
end;

---Run action on receiving side
-- @param integer connection connection
function SetTreeSpecieEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetTreeSpecieEvent.new(self.object, self.treeSpecie), nil, connection, self.object);
	end;

	if self.object ~= nil and self.object:getIsSynchronized() then
    self.object:setTreeSpecie(self.treeSpecie, true);
	end;
end;
