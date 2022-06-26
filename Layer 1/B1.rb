require 'socket'
require 'json'
require 'em-websocket'

$clients_counter = 0
$data = Hash["0"=>0,"1"=>1,"2"=>2,"3"=>3,"4"=>4,"5"=>5,"6"=>6,"7"=>7,"8"=>8,"9"=>9]
current_port = '9011'
websocket_port = '9111'
socket = TCPServer.open(current_port)

hostname = 'localhost'
port_a2 = 9002

cl_a2 = TCPSocket.open(hostname, port_a2)

puts "B1 connected to Core Layer A2"

def send_data_to_websocket(ws)
  while true do
    ws.send JSON[$data]
    sleep 1
  end
end

def run_websocket_server(hostname, websocket_port)
  EM.run do
    EM::WebSocket.run(:host => hostname, :port => websocket_port) do |ws|
      ws.onopen{ |handshake|
        puts "WebSocket connection open"
        ws.send "Client connected to Layer 1 B1"

        Thread.new{ send_data_to_websocket(ws) }
      }

      ws.onclose { puts "Connection closed" }
    end
  end
end

Thread.new{ run_websocket_server(hostname, websocket_port) }

def server_connection_handler(cl_a2)
  while (msg = cl_a2.gets)
    $data = JSON[msg]

    #File.write('./logs/b1', JSON[$data] + "\n", mode: 'a')

    $data.each do |key, value|
      puts "#{key} => #{value}"
    end
  end
end

def client_connection_handler(client)
  puts "New client connection! #{client}"

  client.puts("Layer 1 - B1")

  transaction_id = client.gets
  puts transaction_id

  transaction = client.gets
  puts transaction

  transaction_commands = transaction.split(',')

  transaction_commands.each do |i|
    if i.include? "c"
      #File.write('./logs/b1', JSON[$data] + "\n", mode: 'a')
      client.puts("Full transaction processed")
      break
    else
      if i.include? "r"
        index = i.delete("^0-9")
        puts "READ: key[#{index}] => #{$data[index]}"
        #Return the data to the client
        client.puts("READ: key[#{index}] => #{$data[index]}")
      end
    end
  end
end

Thread.new{ server_connection_handler(cl_a2) }

loop do
  client = socket.accept

  Thread.new{ client_connection_handler(client) }
end