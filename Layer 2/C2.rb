require 'socket'
require 'json'
require 'em-websocket'

$data = Hash["0"=>0,"1"=>1,"2"=>2,"3"=>3,"4"=>4,"5"=>5,"6"=>6,"7"=>7,"8"=>8,"9"=>9]
current_port = '9022'
websocket_port = '9122'
socket = TCPServer.open(current_port)

hostname = 'localhost'
port_b2 = 9012

l1_b2 = TCPSocket.open(hostname, port_b2)

puts "B1 connected to Layer 1 B2"

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
        ws.send "Client connected to Layer 2 C2"

        Thread.new{ send_data_to_websocket(ws) }
      }

      ws.onclose { puts "Connection closed" }
    end
  end
end

Thread.new{ run_websocket_server(hostname, websocket_port) }

Signal.trap("ABRT") do
  #Fetch data from Layer 2
  l1_b2.puts("getData")

  $data = JSON[l1_b2.gets]

  #File.write('./logs/c2', JSON[$data] + "\n", mode: 'a')

  $data.each do |key, value|
    puts "#{key} => #{value}"
  end

  alarm(10)
end

def alarm(seconds)
  Thread.new do
    sleep seconds
    Process.kill("ABRT", Process.pid)
  end
end

alarm(10)

def client_connection_handler(client)
  puts "New server connection! #{client}"

  client.puts("Layer 2 - C2")

  transaction_id = client.gets
  puts transaction_id

  transaction = client.gets
  puts transaction

  transaction_commands = transaction.split(',')

  transaction_commands.each do |i|
    if i.include? "c"
      #File.write('./logs/c2', JSON[$data] + "\n", mode: 'a')
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

loop do
  client = socket.accept
  Thread.new{ client_connection_handler(client) }
end