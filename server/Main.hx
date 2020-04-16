package;

import haxe.Timer;
import js.node.socketio.*;
import server.Room;

class Main
{
  static final rooms:Array<Room> = [];

  public static function main()
  {
    // var app = new Express();

    // Create the socket.io server and listen to the designated port
    var sio = new Server();
    sio.listen(Globals.port);

    // Handle a client connecting to the server
    sio.on('connection', (client:ClientSocket) -> {

      // Give the client a unique id
      client.uuid = Util.uuid();

      trace('\t socket.io:: player ' + client.uuid + ' connected');

      // Finds a Room for the client and adds them to it
      var room = find_room(client);
      
      // Emit a message to the client that youve connected to the server and have an id
      client.emit(cast ClientMessage.OnConnected, { id: client.uuid } );

       // Handle a message from the client to add an entity to the game
      client.on(cast ClientMessage.AddEntity, (data) -> {
        room.add_entity(data);
      });

       // Handle a message from the client to update an entity in the game
      client.on(cast ClientMessage.UpdateEntity, (data) -> {
        room.update_entity(data);
      });

      // Handle a message from the client to remove an entity from the game
      client.on(cast ClientMessage.RemoveEntity, (data) -> {
        room.remove_entity(data);
      });

      // Handle a client disconnecting from the server
      client.on('disconnect',  () -> {
        room.remove_client(client.uuid);
        trace('\t socket.io:: player ' + client.uuid + ' disconnected');
      });
    });

    // Start a Timer to close any empty rooms every 10 seconds
    new Timer(10000).run = close_empty_rooms;
  }

  static function find_room(client:ClientSocket):Room {
    var found = null;
    for (room in rooms) if (room.count < room.max_clients) found = room;

    if (found != null) {
      found.add_client(client);
      return found;
    }

    var room = new Room(client);
    rooms.push(room);
    return room;
  }

  static function close_empty_rooms() {
    var to_remove = [];

    for (room in rooms) {
      if (room.count == 0) to_remove.push(room);
    }

    for (room in to_remove) {
      room.dispose();
      rooms.remove(room);
    }
  }
}