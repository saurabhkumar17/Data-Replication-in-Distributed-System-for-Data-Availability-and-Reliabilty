require 'socket'
require 'json'
require 'em-websocket'

$clients_counter = 0
$data = Hash["0"=>0,"1"=>1,"2"=>2,"3"=>3,"4"=>4,"5"=>5,"6"=>6,"7"=>7,"8"=>8,"9"=>9]
current_port = '9012'
websocket_port = '9112'
socket = TCPServer.open(current_port)

hostname = 'localhost'
port_a3 = 9003

cl_a3 = TCPSocket.open(hostname, port_a3)

puts "B2 connected to Core Layer A3"

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
        ws.send "Client connected to Layer 1 B2"

        Thread.new{ send_data_to_websocket(ws) }
      }

      ws.onclose { puts "Connection closed" }
    end
  end
end

Thread.new{ run_websocket_server(hostname, websocket_port) }

def server_connection_handler(cl_a3)
  while (msg = cl_a3.gets)
    $data = JSON[msg]

    #File.write('./logs/b2', JSON[$data] + "\n", mode: 'a')

    $data.each do |key, value|
      puts "#{key} => #{value}"
    end
  end
end

def l3_server_connection_handler(l2_client)

  while (msg = l2_client.gets)
    puts msg
    if msg.chop.eql? "getData"
      l2_client.puts(JSON[$data])
    end
  end
end

def client_connection_handler(client)
  puts "New client connection! #{client}"

  client.puts("Core Layer - A2")

  transaction_id = client.gets
  puts transaction_id

  transaction = client.gets
  puts transaction

  transaction_commands = transaction.split(',')

  transaction_commands.each do |i|
    if i.include? "c"
      #File.write('./logs/b2', JSON[$data] + "\n", mode: 'a')
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

Thread.new{ server_connection_handler(cl_a3) }

loop do
  client = socket.accept

  $clients_counter += 1

  if $clients_counter <= 2
    Thread.new{ l3_server_connection_handler(client) }
  else
    Thread.new{ client_connection_handler(client) }
  end

end