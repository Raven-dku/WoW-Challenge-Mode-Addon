--------------------------------------------------------------------------------------------------------
-- Moncaí's Library
-- Author: Moncaí
-- Date: $Date april 25th 2009$
--------------------------------------------------------------------------------------------------------
local MAJOR, MINOR = "MoncaiLib", 3
local ML, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not ML then return end
oldminor = oldminor or 0

local _G = _G;

--------------------------------------------------------------------------------------------------------
--
-- Utility functions
-- 
--------------------------------------------------------------------------------------------------------

ML.util = {
	RGBPercToHex = function(r, g, b)
		r = r <= 1 and r >= 0 and r or 0
		g = g <= 1 and g >= 0 and g or 0
		b = b <= 1 and b >= 0 and b or 0
		return string.format("%02x%02x%02x", r*255, g*255, b*255)
	end,

	RGBToHex = function(r, g, b)
		r = r <= 255 and r >= 0 and r or 0
		g = g <= 255 and g >= 0 and g or 0
		b = b <= 255 and b >= 0 and b or 0
		return string.format("%02x%02x%02x", r, g, b)
	end,

	-- The pipe symbol is hardcoded for optimum performance
	wrap = function(...)
		return strjoin("|", ...)
	end,

	unwrap = function(packet)
		return strsplit("|", packet)
	end,
	
};

ML.console = {
	Print = function(msg, r, g, b, frame) 
		if (not r) then r = 1.0; end
		if (not g) then g = 1.0; end
		if (not b) then b = 1.0; end
		if ( frame ) then 
			frame:AddMessage(msg,r,g,b);
		else
			if ( DEFAULT_CHAT_FRAME ) then 
				DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b);
			end
		end
	end,
	
	Printf = function(msg, ...)
		ML.console.Print(string.format(msg, ...));
	end,
	
	PrintEx = function(msg, col, frame) 
		Print(msg, col.r, col.g, col.b, frame);
	end,
	
	
	print_r = function(thing, ...)
		local line = ML.console.tostring_r(thing) .. "\n";
		for v in string.gmatch(line, "([^\n]*)\n") do
			ML.console.Print(v, ...);
		end;
	end,
};

local function tostring_r(thing, indent, done)
	indent=indent or "";
	done = done or {};
	
	if not thing then 
		return "nil";
	elseif type(thing) == "table" and not done[thing] then
		done[thing] = true;
		local result = "{ ";
		indent = indent .. "  ";
		for key, value in pairs(thing) do
			result = result .. "\n" .. indent .. tostring(key) .. " = " .. tostring_r(value, indent .. "  ", done) .. ",";
		end;
		result = result .. "}";
		return result;
	else
		return tostring(thing);
	end;
end;
ML.console.tostring_r = tostring_r;

local deprecated = function() assert(nil, "deprecated"); end;

ML.api = {};
ML.api.hooking = {
	add = deprecated,
	addt = deprecated, 
	adds = deprecated,
	adda = deprecated, 
	del = deprecated,
	HookGlobalOnSelf = deprecated,
	HookGlobal = function(self, fname, func) 
		self.global.hooks[fname] = func or self.parent[fname];
	end,
	HookGlobals = function(self, obj)
		for fname, func in pairs(obj) do
			self.global.hooks[fname] = func;
		end;
	end,
	HookMethod = function(self, obj, fname, func)
		local hook = self.method.hooks[obj] or {this = obj};
		hook[fname] = func or self.parent[fname];
		self.method.hooks[obj] = hook;
	end,
	MethodDelegate = function(self, obj, fname, func, isBefore)
		local delegate;
		local fun = func or self.parent[fname];
		if isbefore then
			delegate = function(...) fun(...); self.method.originals[obj][fname](...); end;
		else
			delegate = function(...) self.method.originals[obj][fname](...); fun(...); end;		
		end;
		self:HookMethod(obj, fname, delegate);
	end,
	GlobalDelegate = function(self, fname, func, isBefore)
		local delegate;
		local fun = func or self.parent[fname];
		if isbefore then
			delegate = function(...) fun(...); self.global.originals[fname](...); end;
		else
			delegate = function(...) self.global.originals[fname](...); fun(...); end;	
		end;
		self:HookGlobal(fname, delegate);
	end,
	enable = function(self)
		for fname, func in pairs(self.global.hooks) do
			self.global.originals[fname] = _G[fname];
			_G[fname] = func;
		end;
		
		for obj, funcs in pairs(self.method.hooks) do
			self.method.originals[obj] = {};
			for fname, func in pairs(funcs) do
				self.method.originals[obj][fname] = obj[fname];
				obj[fname] = func;
			end;
		end;		
	end,
	disable = function(self)
		for fname, func in pairs(self.global.originals) do
			_G[fname] = func;
		end;
		
		for obj, funcs in pairs(self.method.originals) do
			for fname, func in pairs(funcs) do
				obj[fname] = func;
			end;
		end;
	end,	
	new = function(self, caller)
		local proto = {
			parent = caller,
			global = {
				originals = {},
				hooks = {},
			},
			method = {
				originals = {},
				hooks = {},			
			}
		};
		setmetatable(proto, { __index = self });
		return proto;
	end,
}

ML.init = function(self) 
	if (self.initialized) then return; end;
	self.initialized = true;
	
	if not Print then Print = ML.console.Print; end;
	if not Printf then Printf = ML.console.Printf; end;
	if not PrintEx then PrintEx = ML.console.PrintEx; end;
	if not print_r then print_r = ML.console.print_r; end;
end;
--------------------------------------------------------------------------------------------------------
--
-- Initialize library
-- 
--------------------------------------------------------------------------------------------------------
