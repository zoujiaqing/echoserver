// Create by zoujiaqing

import eventcore.core;
import eventcore.internal.utils;
import std.functional : toDelegate;
import std.socket : InternetAddress;
import std.exception : enforce;
import core.time : Duration;

void main()
{
	ushort port = 1111;
	auto addr = new InternetAddress("127.0.0.1", port);

	auto listener = eventDriver.sockets.listenStream(addr, toDelegate(&onClientConnect));

	enforce(listener != StreamListenSocketFD.invalid, "Failed to listen for connections.");

	print("The echo server listening on port %d ...", port);

	while (eventDriver.core.waiterCount)
		eventDriver.core.processEvents(Duration.max);
}

void onClientConnect(StreamListenSocketFD listener, StreamSocketFD client, scope RefAddress) @trusted nothrow 
{
	Connection connection;
	connection.client = client;
	connection.handle();

	// Send welcome message to client
	connection.write("Welcome to use my echo server.\n");
}

struct Connection
{
	@safe: nothrow:

	StreamSocketFD client;

	ubyte[1024] buf = void;

	void handle()
	{
		eventDriver.sockets.read(client, buf, IOMode.once, &onRead);
	}

	void write(string data)
	{
		this.write(cast(ubyte[])data.dup);
	}

	void write(ubyte[] data)
	{
		eventDriver.sockets.write(client, data, IOMode.all, &onWriteFinished);
	}

	void onWriteFinished(StreamSocketFD fd, IOStatus status, size_t len)
	{
		print("Send size: %d", len);
	}

	void onRead(StreamSocketFD, IOStatus status, size_t bytes_read)
	{
		if (status != IOStatus.ok) {
			print("Client disconnect");
			eventDriver.sockets.shutdown(client, true, true);
			eventDriver.sockets.releaseRef(client);
			return;
		}

		this.write(buf[0..bytes_read]);
		
		eventDriver.sockets.read(client, buf, IOMode.once, &onRead);
	}
}
