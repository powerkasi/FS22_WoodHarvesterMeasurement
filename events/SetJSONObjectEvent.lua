SetJSONObjectEvent = {};
SetJSONObjectEvent_mt = Class(SetJSONObjectEvent, Event);

InitEventClass(SetJSONObjectEvent, "SetJSONObjectEvent");

---Create instance of Event class
-- @return table self instance of class event
function SetJSONObjectEvent.emptyNew()
	local self = Event.new(SetJSONObjectEvent_mt);
	return self;
end;

---Create new instance of event
-- @param table object object
-- @param table objectName object name
-- @param string value object value
function SetJSONObjectEvent.new(object, objectName, value)
	local self = SetJSONObjectEvent.emptyNew();
	self.object = object;
	self.objectName = objectName;
	self[self.objectName] = value;
	return self;
end;

-- Called on client side
function SetJSONObjectEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self.objectName = streamReadString(streamId);
	self[self.objectName] = streamReadString(streamId);
	self:run(connection);
end;

-- Called on server side
function SetJSONObjectEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
	streamWriteString(streamId, self.objectName);
	streamWriteString(streamId, self[self.objectName]);
end;

---Run action on receiving side
-- @param integer connection connection
function SetJSONObjectEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetJSONObjectEvent.new(self.object, self.objectName, self[self.objectName]), nil, connection, self.object);
	end;

	if self.object ~= nil then
        self.object:setJSONObjectValue(self.objectName, self[self.objectName], true);
	end;
end;