package;

import Externs;
import colyseus.server.Server;
import js.Node;
import js.node.Http;

class Main {
	static var PORT: Int = 2567;

	static function main() {

		var app:Express = Express.create();
		var server = new Server({ server: Http.createServer(cast app), express: app });

		// register room handlers
		server.define("game_room", GameRoom);

		// attach the @colyseus/monitor web app
		app.use('/colyseus', Monitor.create());

		// get the port
		var env_port = Node.process.env.get('PORT');
		if (env_port != null) PORT = Std.parseInt(env_port);

		server.listen(PORT);

		trace('-- listening on 0.0.0.0:${PORT}... --');
	}
}
